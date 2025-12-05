//
//  ContentView.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//

import SwiftUI
import SwiftData

struct ContentView: View {
 
    @EnvironmentObject var dojo: DojoViewModel
    @Query(sort: [SortDescriptor(\UserDefinedGoal.goalDeadline, order: .reverse)])
    private var goals: [UserDefinedGoal]
    @Query(sort: [SortDescriptor(\DailyWorkout.date, order: .reverse)])
    private var plans: [DailyWorkout]
    @Query private var fitness: [FitnessLevel]
    @Query private var workouts: [CompletedWorkout]
    
    var body: some View {
        
        TabView {
            Tab("Chat", systemImage: "message") {
                NavigationStack {
                    ChatView()
                }
                
            }
            
            Tab("+Workout", systemImage: "figure.mixed.cardio") {
                NavigationStack {
                    AddWorkoutView()
                }
                
            }
     
            Tab("Plan", systemImage: "calendar") {
                NavigationStack {
                    PlanView()
                    
                }
                
            }
            
            Tab("Goals", systemImage: "flag.pattern.checkered.2.crossed") {
                NavigationStack {
                    GoalsView()
                }
                
                
            }
            
            
            Tab("Fitness", systemImage: "calendar") {
                NavigationStack {
                    FitnessLevelView()
                    
                }
                
            }

        }
        .onAppear {
            dojo.userDefinedGoals = goals
            dojo.dailyWorkoutPlans = plans
            dojo.activityFitnessLevel = fitness
            dojo.workoutHistory = workouts
            
            dojo.fillEmptyFitnessLevels() //Needed for the FitnessLevelView
        }
        .onChange(of: goals) { dojo.userDefinedGoals = goals}
        .onChange(of: plans)   { dojo.dailyWorkoutPlans = plans }
        .onChange(of: fitness) { dojo.activityFitnessLevel = fitness }
        .onChange(of: workouts) {
            print("Change in Workouts Detected")
            dojo.workoutHistory = workouts
        }
    }
}



#Preview {
    ContentView()
        .environmentObject(dummyViewModel)
}
