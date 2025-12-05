//
//  Multi_Agent_CoachApp.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//

import SwiftUI
import SwiftData

@main
struct Multi_Agent_CoachApp: App {
    
    @StateObject var dojo = DojoViewModel()
  
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, .custom("Zen Maru Regular", size: 16))
                .environmentObject(dojo)
                .preferredColorScheme(.light)
                .modelContainer(for: [UserDefinedGoal.self,
                                      FitnessLevel.self,
                                      DailyWorkout.self,
                                      WorkoutSession.self,
                                      RunningWorkout.self,
                                      ClimbingWorkout.self,
                                      ClimbRoute.self,
                                      CompletedWorkout.self,
                                      CompletedClimbingWorkout.self,
                                      CompletedClimbingWorkoutRoute.self,
                                      CompletedRunningWorkout.self
                                     ])
        }
    }
}
