//
//  AddRunningWorkoutView.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-06.
//

import SwiftUI
import Foundation
import HealthKit


struct AddRunningWorkoutView: View {
    @Bindable var runningWorkout: CompletedRunningWorkout
    @Binding var activityDate: Date
    @State var showSheet: Bool = false
    
    var body: some View {
        VStack {
            if runningWorkout.distanceKm > 0 {
                // Running Info Card
                RunningInfoCard(runningWorkout: runningWorkout)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            
            //Import Run Button
            Button(action: {
                // Reset editor to a sensible default each time
                
                showSheet = true
            }, label: {
                Text("+ Run")
                    .font(.body)
                    .italic().bold()
                    .foregroundStyle(vermillion)
                    .frame(height: 16, alignment: .center)
            })
            .buttonStyle(GradientOutlineButtonStyle())
            .padding(.top, 8)
        }
        .onChange(of: runningWorkout.date) {
            activityDate = runningWorkout.date
        }
        .fullScreenCover(isPresented: $showSheet) {
            NavigationStack {
                RunningWorkoutListView(runningWorkout: runningWorkout, showSheet: $showSheet)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cancel") {
                                showSheet = false
                            }
                            .glassEffect()
                        }
                    }
            }
        }
    }
}

struct RunningWorkoutListView: View {
    @ObservedObject var vm = RunningHealthStore()
    @Bindable var runningWorkout: CompletedRunningWorkout
    @Binding var showSheet: Bool
    
    var body: some View {
        ZStack {
            // App background
            papaya_50
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workouts")
                            .font(.zenTitle)
                            .foregroundColor(jet)
                        Text("Your recent runs from Apple Health")
                            .font(.zenSubheadline)
                            .foregroundColor(jet.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Content
                    LazyVStack(spacing: 14) {
                        if vm.workouts.isEmpty {
                            EmptyStateCard()
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                        } else {
                            //MARK: Workout List
                            ForEach(vm.workouts, id: \.uuid) { workout in
                                WorkoutCard(
                                    workout: workout,
                                    uploadAction: {
                                        // Calculate Raw Data
                                        print("calculate VM data")
                                        calculateWorkoutDataInViewModel(for: workout) {
                                            // Then calculate the reductions & add it to the
                                            // currentRunningWorkout.
                                            calculateCompletedRunningWorkout()
                                            // Distance is in meters from HKWorkout; convert to kilometers.
                                            if let distanceMeters = workout.totalDistanceMeters {
                                                runningWorkout.distanceKm = Float(distanceMeters / 1000.0)
                                            }
                                            runningWorkout.date = workout.startDate
                                            showSheet = false // Dismiss the list view.
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            vm.authorizeHealthKit()
            vm.fetchWorkouts()
        }
    }
    
    func calculateCompletedRunningWorkout() {
        //------- Heart Rate -------
        let hrPoints = vm.rawRunningData.map({ $0.hr })
        let hrSum = hrPoints.reduce(0, +)
        let hrAvg = hrPoints.isEmpty ? 0 : hrSum / hrPoints.count
        
        //------ Elevation Gain (sum of positive deltas, ignore small noise) ------
        let altitudes = vm.rawRunningData.map { Double($0.altitude) } // meters
        let noiseThreshold = 1.0 // meters; tweak if needed
        var elevationGainMeters = 0.0
        for (prev, curr) in zip(altitudes, altitudes.dropFirst()) {
            let delta = curr - prev
            if delta > noiseThreshold {
                elevationGainMeters += delta
            }
        }
        let ttlElevation = Float(elevationGainMeters)
        
        //------ Pace ----
        // vm.rawRunningData.pace is km per minute (speed).
        // Convert to seconds per km for display.
        let paceValues = vm.rawRunningData.map({ $0.pace })
        let paceAvgSpeedKmPerMin = paceValues.isEmpty ? 0 : paceValues.reduce(0, +) / Double(paceValues.count)
        let avgSecPerKm: TimeInterval = paceAvgSpeedKmPerMin > 0 ? (1.0 / paceAvgSpeedKmPerMin) * 60.0 : 0
        
        // Add the values to the current workout.
        runningWorkout.avgHeartRate = Float(hrAvg)
        runningWorkout.elevationGain = ttlElevation
        runningWorkout.avgPacePerKm = avgSecPerKm
        
    }
    
    /// Calculates the selected workouts raw data inside the RunningHealthStore view model.
    func calculateWorkoutDataInViewModel(for workout: HKWorkout, completion: @escaping () -> Void) {
        // First fetch the route
        vm.fetchWorkoutRoute(for: workout) {
            guard let workoutRoute = vm.workoutRoute else {
                print("No workout found")
                return
            }
            /// These can run concurrently, but must be checked
            /// before calculating raw data.
            print("Getting distance and pace")
            vm.getDistanceAndPaceIntervals(workout: workout)
            vm.queryHeartRateData(for: workout)
            vm.queryRouteData(route: workoutRoute) {
                //This should actually be a recursive call, but this is fine for now
                if vm.paceDistanceData.count == 0 {
                    // Wait 0.2 seconds before trying again once.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { }
                    if vm.paceDistanceData.count == 0 {
                        return
                    }
                }
                guard vm.heartRates.count > 0 else { return }
                
                // Create list of data points
                vm.creatRawData() {
                    completion()
                }
            }
        }
    }
}


// MARK: - Workout Card
private struct WorkoutCard: View {
    let workout: HKWorkout
    let uploadAction: () -> Void
    var kcal: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row — date + activity type
            HStack(alignment: .firstTextBaseline) {
                Text(workout.startDate.formattedWithOrdinal())
                    .font(.zenHeadline)
                    .foregroundColor(jet)
                Spacer()
 
            }
            
            // Metrics row
            HStack(spacing: 16) {
                MetricPill(
                    title: "Distance",
                    value: workout.totalDistanceMetersString
                )
                MetricPill(
                    title: "Duration",
                    value: workout.durationString
                )
                
                if let kcal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    
                    MetricPill(
                        title: "Energy",
                        value: "\(Int(kcal)) kcal"
                    )

                }
            }
            
            // Upload button
            Button(action: uploadAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Upload")
                        .font(.zenHeadline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(UploadButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: jet.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ash.opacity(0.35), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Metric Pill
private struct MetricPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.zenCaption2)
                .foregroundColor(jet.opacity(0.6))
            Text(value)
                .font(.zenBody)
                .foregroundColor(jet)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(papaya.opacity(0.55))
        )
    }
}

// MARK: - Empty State
private struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 44, weight: .black))
                .foregroundColor(vermillion)
            
            Text("No workouts yet")
                .font(.zenTitle3)
                .foregroundColor(jet)
            
            Text("Once you grant Health access, your runs will appear here.")
                .font(.zenCallout)
                .foregroundColor(jet.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: jet.opacity(0.06), radius: 14, x: 0, y: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ash.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Button Style
private struct UploadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [raspberry, vermillion],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: raspberry.opacity(configuration.isPressed ? 0.15 : 0.28),
                    radius: configuration.isPressed ? 6 : 12,
                    x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - Formatting Helpers
private enum NumberFormat {
    static let km: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf
    }()
    
    static let compactNoDec: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        return nf
    }()
    
    
}

private extension HKWorkout {
    var totalDistanceMeters: Double? {
        totalDistance?.doubleValue(for: .meter())
    }
    
    var totalDistanceMetersString: String {
        guard let m = totalDistanceMeters else { return "—" }
        let kmValue = m / 1000.0
        return (NumberFormat.km.string(from: kmValue as NSNumber) ?? "\(kmValue)") + " km"
    }
    
    var durationString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "\(Int(duration))s"
    }
}

#Preview {
    let running = CompletedRunningWorkout(activity: .running,userNotes: "", date: Date(), distanceKm: 0,avgHeartRate: 0,elevationGain: 0, avgPacePerKm: 0)
    
    //AddRunningWorkoutView(runningWorkout: running)
    NavigationStack {
        RunningWorkoutListView(runningWorkout: running, showSheet: .constant(true))
    }
    
    
}
