// Test Data
// Created by Ben Pearman

import SwiftUI

//MARK: View Model. Used globally app for testing
let dummyViewModel: DojoViewModel = {
    let vm = DojoViewModel()

    vm.dailyWorkoutPlans = [dummyDay2]
    vm.userDefinedGoals = [climbingGoal1]

    vm.activityFitnessLevel = [climbingActivityProgress, runningActivityProgress]
    vm.workoutHistory = [
        climbingWorkout1, climbingWorkout2, climbingWorkout3,
        runningWorkout1,  runningWorkout2,  runningWorkout3
    ]

    // If you still want the sorted behavior from the old init:
    vm.dailyWorkoutPlans.sort { $0.date > $1.date }
    vm.userDefinedGoals.sort { $0.goalDeadline > $1.goalDeadline }

    return vm
}()


let climbingActivityProgress = FitnessLevel(activity: .climbing,
                                                userDefinedFitnessLevel: "Currently I can climb 13a on limestone sport climbs",
                                                userDefinedFitnessLevelUpdatedDate: Date(),
                                                agentDefinedFitnessLevel: nil,
                                                agentFitnessLevelUpdatedDate: nil)

let runningActivityProgress = FitnessLevel(activity: .running,
                                                userDefinedFitnessLevel: "Currently I am not very good at running. I probably could not finish a marathon. My legs are weak, but my cardio is okay ish.",
                                                userDefinedFitnessLevelUpdatedDate: Date(),
                                                agentDefinedFitnessLevel: nil,
                                                agentFitnessLevelUpdatedDate: nil)



let date = "Monday - Oct 6th"
//MARK: Planned Workouts
// MARK: - Climbing
@available(iOS 26.0, *)
let dummyClimbingSession1 = ClimbingWorkout(
    sessionDescription: "Focus on a solid warm up followed by a few limit bouldering problems. This could be tricky but you should be able to flash 12a on the first go. Cool down with a face climb.",
    routes: [
        ClimbRoute(gradeValue: .yds(.g5_10a),
                   shortDescription: "Warm-up circuit – smooth feet, then some nails routes, go for the send"),
        ClimbRoute(gradeValue: .yds(.g5_11b),
                   shortDescription: "Compression boulder with big slopers"),
        ClimbRoute(gradeValue: .v(.v5),
                   shortDescription: "Steep overhangs and power endurance"),
        ClimbRoute(gradeValue: .v(.v4),
                   shortDescription: "Crimpy face climb to cool down")
    ]
)

@available(iOS 26.0, *)
let dummyClimbingSession2 = ClimbingWorkout(
    sessionDescription: "Focus on a solid warm up followed by a few limit bouldering problems. This could be tricky but you should be able to flash 12a on the first go. Cool down with a face climb.",
    routes: [
        ClimbRoute(gradeValue: .yds(.g5_12a),
                   shortDescription: "climb a 5.12a"),
        // ClimbRoute(id: UUID(), gradeValue: .yds(.g5_12b), shortDescription: "hard!"),
        ClimbRoute(gradeValue: .v(.v2),
                   shortDescription: "chill")
        // ClimbRoute(id: UUID(), gradeValue: .v(.v5), shortDescription: "easy")
    ]
)

// MARK: - Running
@available(iOS 26.0, *)
let dummyRunningSession1 = RunningWorkout(
    sessionDescription: "Aim for a hard run, you should be kinda fast by now.",
    distanceKm: 24.0,
    heartRate: 140,
    elevationGain: 150,
    paceMinPerKm: 400 // 6:40 / km
)

@available(iOS 26.0, *)
let dummyRunningSession2 = RunningWorkout(
    sessionDescription: "Aim for a long zone 2 run, for recovery",
    distanceKm: 8.0,
    heartRate: 110,
    elevationGain: 50,
    paceMinPerKm: 400
)

// MARK: - Days (use `sessions:` not `workouts:`)
@available(iOS 26.0, *)
let dummyDay1 = DailyWorkout(
    //id: UUID(),
    date: Date(timeIntervalSinceNow: 86_400),
    sessions: [dummyClimbingSession1, dummyRunningSession1]
)


let dummyDay2 = DailyWorkout(
    //id: UUID(),
    date: Date(timeIntervalSinceNow: 86_400 * 2),
    sessions: [dummyClimbingSession2]
)


let dummyDay3 = DailyWorkout(
    //id: UUID(),
    date: Date(timeIntervalSinceNow: 86_400 * 3),
    sessions: [dummyRunningSession2]
)


//MARK: Goals

let climbingGoal1 = UserDefinedGoal(goalActivity: .climbing, title: "Climb 14a", description: "I want to be able to send a 13b sport route.", goalDeadline: Date(timeIntervalSinceNow: 86_400*60), isCompleted: false)

let climbingGoal2 = UserDefinedGoal(goalActivity: .climbing, title: "Climb the Beckey-Chouinard", description: "I want to climb the Beckey-Chouinard, the famous granite alpine rock climb in the Bugaboos", goalDeadline: Date(timeIntervalSinceNow: 86_400*360), isCompleted: false, )

let runningGoal1 = UserDefinedGoal(goalActivity: .running, title: "Sub 3 hour marathon", description: "Run a marathon in 3 hours", goalDeadline: Date(timeIntervalSinceNow: 86_400*180), isCompleted: false)
let runningGoal2 = UserDefinedGoal(goalActivity: .running, title: "Sub 3 hour marathon", description: "Run a marathon in 3 hours", goalDeadline: Date(timeIntervalSinceNow: 86_400*180), isCompleted: false)
let runningGoal3 = UserDefinedGoal(goalActivity: .running, title: "Sub 3 hour marathon", description: "Run a marathon in 3 hours", goalDeadline: Date(timeIntervalSinceNow: 86_400*180), isCompleted: false)
let runningGoal4 = UserDefinedGoal(goalActivity: .running, title: "Sub 3 hour marathon", description: "Run a marathon in 3 hours", goalDeadline: Date(timeIntervalSinceNow: 86_400*180), isCompleted: false)


//MARK: Completed Workouts


// MARK: - Climbing Workouts

let climbingWorkout1 = CompletedClimbingWorkout(
    activity: .climbing,
    userNotes: "Felt strong today, worked steep problems.",
    date: Date(timeIntervalSinceNow: -86400 * 2),
    routes: [
        CompletedClimbingWorkoutRoute(grade: .v(.v4), attempts: 3, send: true,  style: .redpoint),
        CompletedClimbingWorkoutRoute(grade: .v(.v5), attempts: 5, send: false, style: .nosend),
        CompletedClimbingWorkoutRoute(grade: .v(.v3), attempts: 2, send: true,  style: .flash)
    ]
)

let climbingWorkout2 = CompletedClimbingWorkout(
    activity: .climbing,
    userNotes: "Endurance laps on moderate ropes.",
    date: Date(timeIntervalSinceNow: -86400 * 5),
    routes: [
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: true,  style: .redpoint),
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10d), attempts: 2, send: false, style: .nosend),
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_9),   attempts: 1, send: true,  style: .flash)
    ]
)

let climbingWorkout3 = CompletedClimbingWorkout(
    activity: .climbing,
    userNotes: "Outdoor circuit, cool temps, good friction.",
    date: Date(timeIntervalSinceNow: -86400 * 9),
    routes: [
        CompletedClimbingWorkoutRoute(grade: .v(.v2), attempts: 1, send: true,  style: .flash),
        CompletedClimbingWorkoutRoute(grade: .v(.v3), attempts: 2, send: true,  style: .onSite),
        CompletedClimbingWorkoutRoute(grade: .v(.v4), attempts: 6, send: false, style: .nosend)
    ]
)

// MARK: - Running Workouts

let runningWorkout1 = CompletedRunningWorkout(
    activity: .running,
    userNotes: "Tempo run, even splits.",
    date: Date(timeIntervalSinceNow: -86400),
    distanceKm: 8.5,
    avgHeartRate: 155,
    elevationGain: 120,
    avgPacePerKm: 5 * 60 + 5 // 5:05 / km
)

let runningWorkout2 = CompletedRunningWorkout(
    activity: .running,
    userNotes: "Easy recovery jog.",
    date: Date(timeIntervalSinceNow: -86400 * 3),
    distanceKm: 5.0,
    avgHeartRate: 135,
    elevationGain: 45,
    avgPacePerKm: 6 * 60 + 10 // 6:10 / km
)

let runningWorkout3 = CompletedRunningWorkout(
    activity: .running,
    userNotes: "Long run with hills, felt strong.",
    date: Date(timeIntervalSinceNow: -86400 * 7),
    distanceKm: 15.2,
    avgHeartRate: 148,
    elevationGain: 310,
    avgPacePerKm: 5 * 60 + 40 // 5:40 / km
)


