//
//  ViewModel.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-10.
//

import SwiftUI
import Combine
import SwiftData

class DojoViewModel: ObservableObject {
    @Published var dailyWorkoutPlans: [DailyWorkout] = []
    @Published var userDefinedGoals: [UserDefinedGoal]  = [] // Persistent data is working
    @Published var activityFitnessLevel: [FitnessLevel] = []
    @Published var workoutHistory: [CompletedWorkout] = []
    
    // For the ChatView
    @Published var isSending: Bool = false

    
    /// Currently unused
    func refreshAll(modelContext: ModelContext) {
        do {
            dailyWorkoutPlans = try modelContext.fetch(
                FetchDescriptor<DailyWorkout>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
            )
            userDefinedGoals = try modelContext.fetch(
                FetchDescriptor<UserDefinedGoal>(
                    sortBy: [SortDescriptor(\.goalDeadline, order: .reverse)]
                )
            )
            activityFitnessLevel = try modelContext.fetch(
                FetchDescriptor<FitnessLevel>()
            )
            workoutHistory = try modelContext.fetch(
                FetchDescriptor<CompletedWorkout>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
            )
        } catch {
            print("SwiftData fetch failed: \(error)")
        }
    }
    
    func fillEmptyFitnessLevels() {
        if activityFitnessLevel.isEmpty {
            let climbingFitness = FitnessLevel(activity: .climbing)
            let runningFitness = FitnessLevel(activity: .running)
            activityFitnessLevel.append(climbingFitness)
            activityFitnessLevel.append(runningFitness)
        }
    }
    
    func sortDailyWorkoutPlansByDate() {
        dailyWorkoutPlans.sort { $0.date > $1.date }
    }
    func sortUserDefinedGoalsByDeadline() {
        userDefinedGoals.sort { $0.goalDeadline > $1.goalDeadline }
    }
    
    func updateDojoViewModelFromWorkoutResponse(_ wr: AddWorkoutView.WorkoutResponse) {
        let updatedContext = wr.context
        var newFitnessLevels: [FitnessLevel] = []
        
        for fitnessLevel in updatedContext.activityFitnessLevels {
            let newFitnessLevel = FitnessLevel(activity: fitnessLevel.activity,
                                               userDefinedFitnessLevel: fitnessLevel.userDefinedFitnessLevel,
                                               userDefinedFitnessLevelUpdatedDate: fitnessLevel.userDefinedFitnessLevelUpdatedDate,
                                               agentDefinedFitnessLevel: fitnessLevel.agentDefinedFitnessLevel,
                                               agentFitnessLevelUpdatedDate: fitnessLevel.agentFitnessLevelUpdatedDate
                                               
            )
            newFitnessLevels.append(newFitnessLevel)
            print("Updated Fitness LEvel: \n\(newFitnessLevel)")
        }
        
        self.activityFitnessLevel = newFitnessLevels
    }
    
    func updateDojoViewModelFromChatResponse(_ cr: ChatViewModel.ChatResponse) {
        let updatedContext = cr.context
        
        // Define the containers to store the updated context
        var newDailyWorkouts: [DailyWorkout] = []
        var newGoals: [UserDefinedGoal] = []
        var newFitnessLevels: [FitnessLevel] = []
        
        // First update the Training Schedule
        for workoutDTO in updatedContext.currentTrainingPlan {
            /// For each workout day in the plan
            let dailyWorkout = DailyWorkout(date: workoutDTO.date)
            for sesh in workoutDTO.sessions {
                if case let .climbing(climbingDTO) = sesh {
                    // climbingDTO is a ClimbingWorkoutDTO
                    /// First add the session description
                    let climbingWorkout = ClimbingWorkout(sessionDescription: climbingDTO.sessionDescription)
                    for routeDTO in climbingDTO.routes {
                        /// Then add all the routes to the climbing workout.
                        let climbRoute = ClimbRoute(dto: routeDTO)
                        climbingWorkout.routes.append(climbRoute)
                    }
                    
                    // Add the climbing workout to the model.
                    dailyWorkout.sessions.append(climbingWorkout)
                } else if case let .running(runningDTO) = sesh {
                    // runningDTO is a RunningWorkoutDTO
                    let runningWorkout = RunningWorkout(sessionDescription: runningDTO.sessionDescription,
                                                        distanceKm: runningDTO.distanceKm,
                                                        heartRate: runningDTO.heartRate,
                                                        elevationGain: runningDTO.elevationGain,
                                                        paceMinPerKm: runningDTO.paceMinPerKm)
                    dailyWorkout.sessions.append(runningWorkout)
                }
            }
            newDailyWorkouts.append(dailyWorkout)
            print("Updated Daily Workout: \n\(dailyWorkout)")
        }
        
        // Then update the User Defined Goals
        for goalDTO in updatedContext.goals {
            let newGoal = UserDefinedGoal(goalActivity: goalDTO.goalActivity,
                                          title: goalDTO.title,
                                          description: goalDTO.description,
                                          goalDeadline: goalDTO.goalDeadline,
                                          isCompleted: goalDTO.isCompleted)
            newGoals.append(newGoal)
            print("Updated Goal: \n\(goalDTO)")
        }
        
        // Then update the fitness level
        for fitnessLevel in updatedContext.activityFitnessLevels {
            let newFitnessLevel = FitnessLevel(activity: fitnessLevel.activity,
                                               userDefinedFitnessLevel: fitnessLevel.userDefinedFitnessLevel,
                                               userDefinedFitnessLevelUpdatedDate: fitnessLevel.userDefinedFitnessLevelUpdatedDate,
                                               agentDefinedFitnessLevel: fitnessLevel.agentDefinedFitnessLevel,
                                               agentFitnessLevelUpdatedDate: fitnessLevel.agentFitnessLevelUpdatedDate
                                               
            )
            newFitnessLevels.append(newFitnessLevel)
            print("Updated Fitness LEvel: \n\(newFitnessLevel)")
        }
        
        // Update the view model context
        self.dailyWorkoutPlans = newDailyWorkouts
        self.userDefinedGoals = newGoals
        self.activityFitnessLevel = newFitnessLevels
    
    }
    
    /// Saves the currently loaded @Published arrays into SwiftData.
    /// Warning: This uses a "Wipe and Replace" strategy for Plans, Goals, and Levels
    /// to ensure the database matches the AI's latest response.
    func persistFreshContext(modelContext: ModelContext) {
        do {
            // 1. Clear existing "Future" data to avoid duplicates.
            // Note: We do NOT delete 'CompletedWorkout' (History) here,
            // because we don't want to lose what the user has actually finished.
            
            // Batch delete requires iOS 17+, ensures we start fresh for the schedule
            try modelContext.delete(model: DailyWorkout.self)
            try modelContext.delete(model: UserDefinedGoal.self)
            try modelContext.delete(model: FitnessLevel.self)
            
            // 2. Insert the new items currently held in the ViewModel
            for plan in dailyWorkoutPlans {
                modelContext.insert(plan)
            }
            
            for goal in userDefinedGoals {
                modelContext.insert(goal)
            }
            
            for level in activityFitnessLevel {
                modelContext.insert(level)
            }
            
            // 3. Save changes
            try modelContext.save()
            print("✅ DojoViewModel successfully persisted to SwiftData.")
            
        } catch {
            print("❌ Failed to persist DojoViewModel: \(error)")
        }
    }
    
}

