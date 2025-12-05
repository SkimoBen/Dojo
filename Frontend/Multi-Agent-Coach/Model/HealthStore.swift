//
//  HealthStore.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-21.
//

import HealthKit
import SwiftUI
import CoreLocation
import Combine

// MARK: - ViewModel

class RunningHealthStore: ObservableObject {
    @Published var workouts: [HKWorkout] = []
    
    // These are the data for the selected workout
    var heartRates: [HKQuantitySample] = []
    var workoutRoute: HKWorkoutRoute? = nil
    var routeData: [CLLocation] = []
    var paceDistanceData: [PaceDistanceData] = []
    
    @Published var rawRunningData: [RawData] = []
    
    let healthStore = HKHealthStore()
    
    //MARK: Fetch all workouts of a certain workout type
    func fetchWorkouts() {
        print("fetching workouts")
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running) // Change this based on the workout type
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let s = samples else { return }
            
            if let newWorkouts = s as? [HKWorkout] {
                DispatchQueue.main.async {
                    self.workouts = newWorkouts
                }
                
            }
        }

        healthStore.execute(query)
    }
    
    // helper function to extract summary data
    func workoutSummary(for workout: HKWorkout) -> (distance: Double?, duration: TimeInterval) {
        // Duration is directly available
        let duration = workout.duration
        
        // Total distance is stored as a quantity sample
        let distance = workout.totalDistance?.doubleValue(for: .meter())
        
        return (distance, duration)
    }
    
    func activeEnergy(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(quantityType: energyType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
            if let quantity = stats?.sumQuantity() {
                completion(quantity.doubleValue(for: .kilocalorie()))
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }

    // Get the heart rate list using the selected workout
    func queryHeartRateData(for workout: HKWorkout){
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Define the anchor and interval for the query
        let startDate = workout.startDate
        let endDate = workout.endDate
        let anchorDate = Calendar.current.startOfDay(for: startDate)
        let interval = DateComponents(minute: 5)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, statisticsCollection, _ in
            var samples: [HKQuantitySample] = []
            
            if let statisticsCollection = statisticsCollection {
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let quantity = statistics.averageQuantity() {
                        let sample = HKQuantitySample(
                            type: heartRateType,
                            quantity: quantity,
                            start: statistics.startDate,
                            end: statistics.endDate
                        )
                        samples.append(sample)
                    }
                }
            }
            
            self.heartRates = samples
            
        }
        
        healthStore.execute(query)
    }
    
    //MARK: Location queries. Get the WorkoutRoute object of a given workout
    func fetchWorkoutRoute(for workout: HKWorkout, completion: @escaping () -> Void) {
        print("Inside fetchWorkoutRoute")
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, error in
            if let err = error{
                print(err.localizedDescription)
            }
            // Error is this gets skipped
            if let s = samples {
               
                if let hkwr = s.first as? HKWorkoutRoute {
                    self.workoutRoute = hkwr
                    completion()
                }
            } else {
                print("No samples ")
            }
        }
        

        healthStore.execute(query)
    }
    
    //MARK: get the location data from the workout route object, samples every 5 minutes.
    func queryRouteData(route: HKWorkoutRoute, completion: @escaping () -> Void) {
        var allLocations: [CLLocation] = []
        var lastSampleTime: Date? = nil
        let samplingInterval: TimeInterval = 5 * 60 // 5 minutes in seconds

        let routeQuery = HKWorkoutRouteQuery(route: route) { _, locationsOrNil, isDone, _ in
            if let locations = locationsOrNil {
                for location in locations {
                    if let lastSample = lastSampleTime {
                        if location.timestamp.timeIntervalSince(lastSample) >= samplingInterval {
                            allLocations.append(location)
                            lastSampleTime = location.timestamp
                            
                        }
                    } else {
                        // Include the first location and set it as the last sampled time
                        allLocations.append(location)
                        lastSampleTime = location.timestamp
                    }
                }
            }

            if isDone {
                self.routeData = allLocations
                completion()
            }
        }

        healthStore.execute(routeQuery)
    }




    func getDistanceAndPaceIntervals(workout: HKWorkout) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        // Predicate to get samples during the workout
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        // Set interval to 5 minutes
        var intervalComponents = DateComponents()
        intervalComponents.minute = 5
        
        // Use the workout's start date as the anchor date
        let anchorDate = workout.startDate
        
        let statisticsOptions: HKStatisticsOptions = .cumulativeSum
        
        // Create the statistics collection query
        let query = HKStatisticsCollectionQuery(quantityType: distanceType,
                                                quantitySamplePredicate: predicate,
                                                options: statisticsOptions,
                                                anchorDate: anchorDate,
                                                intervalComponents: intervalComponents)
        
        query.initialResultsHandler = { query, statisticsCollection, error in
            if let error = error {
                print("Error fetching statistics: \(error.localizedDescription)")
                return
            }
            
            var intervals: [PaceDistanceData] = []
            
            if let statisticsCollection = statisticsCollection {
         
                statisticsCollection.enumerateStatistics(from: workout.startDate, to: workout.endDate) { (statistics, stop) in
                    let startDate = statistics.startDate
                    let endDate = statistics.endDate
                    let duration = endDate.timeIntervalSince(startDate)
                    
                    if let sumQuantity = statistics.sumQuantity() {
                        // Distance in kilometers for this interval
                        let distanceKm = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                        // Average speed (km per minute) over the interval
                        let averageSpeedKmPerMin = distanceKm / (duration / 60.0)
                        
                        let intervalData = PaceDistanceData(startTime: startDate,
                                                            endTime: endDate,
                                                            distance: distanceKm,
                                                            averagePace: averageSpeedKmPerMin)
                        intervals.append(intervalData)
                    } else {
                        print("No sum quantity for interval from \(startDate) to \(endDate)")
                    }
                }
            } else {
                print("StatisticsCollection is nil")
            }
            self.paceDistanceData = intervals
         
        }
        

        healthStore.execute(query)
    }
    
    //MARK: Create Raw Data
    /// Creates raw workout data by combining location samples and heart rate samples.
    /// Most healthkit things are async even though they don't say that. Must use a completion
    /// to fire the next set of calculations after it's ready.
    func creatRawData(completion: @escaping () -> Void) {
        let minSamples = min(self.routeData.count, self.heartRates.count, self.paceDistanceData.count)

        var rawData: [RawData] = []
        guard let startingPoint = self.routeData.first, minSamples > 0 else {
            // Return an empty array if there are no location samples
            DispatchQueue.main.async {
                self.rawRunningData = []
                completion()
            }
            return
        }
        
        
        for i in 0..<minSamples {
            let location = self.routeData[i]
            let hr = Int(self.heartRates[i].quantity.doubleValue(for: HKUnit(from: "count/min")))
            // CLLocation.distance(from:) returns meters; convert to kilometers to match the comment/unit.
            let displacementKm = startingPoint.distance(from: location) / 1000.0
            let altitude = Float(location.altitude) // meters
            let coords = location.coordinate
            let distanceKm = self.paceDistanceData[i].distance
            let speedKmPerMin = self.paceDistanceData[i].averagePace
            
            rawData.append(RawData(hr: hr,
                                   displacement: displacementKm,
                                   altitude: altitude,
                                   coords: coords,
                                   distance: distanceKm,
                                   pace: speedKmPerMin))
        }
        DispatchQueue.main.async {
            self.rawRunningData = rawData
            completion()
        }
        
        
    }
    
    //MARK: Authorize health kit
    func authorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        healthStore.requestAuthorization(toShare: [], read: healthKitTypes) { _, _ in }
    }
    
    struct PaceDistanceData {
        var startTime: Date
        var endTime: Date
        var distance: Double  // in km, the actual recorded distance (not straight line)
        var averagePace: Double  // in km/min (average speed)
    }
    
    struct RawData {
        let hr: Int                         // Heart rate
        let displacement: Double            // displacement in KM from the starting point (Straight line)
        let altitude: Float                 // Altitude in Meters
        let coords: CLLocationCoordinate2D  // Location (lat lon)
        let distance: Double                // Distance (km) recorded for the interval
        let pace: Double                    // km / min. Average speed for the interval.
    }
}

