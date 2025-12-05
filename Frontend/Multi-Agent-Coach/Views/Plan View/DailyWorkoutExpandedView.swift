//
//  DailyWorkoutExpandedView.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-10-08.
//


import SwiftUI

struct DailyWorkoutExpandedView: View {
    var workouts: [WorkoutSession]
    var date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(date)
                .font(.zenTitle3)
                .foregroundStyle(raspberry)

            ForEach(workouts, id: \.id) { workout in
                WorkoutContentView(workout: workout)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.50))
                //.shadow(color: .black.opacity(0.55), radius: 4, x: 0, y: 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(vermillion, lineWidth: 2)
        )
    }
}

struct WorkoutContentView: View {
    var workout: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                activityTag(activityType: workout.activity)
                Spacer()
            }

            // Show the text description from the model
            if !workout.sessionDescription.isEmpty {
                Text(workout.sessionDescription)
                    .font(.zenBody)
            }

            // Downcast to concrete session types instead of switching on the enum payload
            if let session = workout as? ClimbingWorkout {
                ClimbingSessionView(session: session)
            } else if let session = workout as? RunningWorkout {
                RunningSessionView(session: session)
            } else {
                // Optional: a fallback for unexpected / new activity types
                Text("Unsupported workout type")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ClimbingSessionView: View {
    let session: ClimbingWorkout
    private let cornerRadiusInner = 8.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(session.routes, id: \.id) { route in
                HStack(alignment: .center) {
                    // Grade
                    Text(route.gradeValue.display) // or String(describing: route.gradeValue)
                        .frame(width: 50)
                        .font(.zenHeadline)
                        .foregroundStyle(papaya_50)
                        .background(raspberry)

                    // Description
                    VStack(alignment: .leading) {
                        Text(route.shortDescription)
                            .font(.custom("ZenMaruGothic-medium", size: 16))
                            .foregroundStyle(jet)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 6)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadiusInner)
                            .foregroundStyle(papaya_50)
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: cornerRadiusInner)
                        .foregroundStyle(raspberry)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadiusInner, style: .continuous)
                        .stroke(raspberry, lineWidth: 2)
                )
            }
        }
    }
}

struct RunningSessionView: View {
    let session: RunningWorkout
    let cornerRadiusInner = 8.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                runningSessionMetricSquare(title: "Km", value: String(format: "%.0f", session.distanceKm))
                runningSessionMetricSquare(title: "BPM", value: "\(session.heartRate)")
                runningSessionMetricSquare(title: "Min/km", value: session.paceMinPerKm.paceString)
                runningSessionMetricSquare(title: "Meters Gain", value: "\(session.elevationGain)")
            }

            Text(session.sessionDescription)
                .font(.custom("ZenMaruGothic-medium", size: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.top, 6)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: cornerRadiusInner)
                .foregroundStyle(papaya_50)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadiusInner, style: .continuous)
                .stroke(raspberry, lineWidth: 2)
        )
    }
    @ViewBuilder
    func runningSessionMetricSquare(title: String, value: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadiusInner / 2 + 3)
                .foregroundStyle(raspberry)

            VStack(spacing: 2) {
                Text(value)
                    .font(.zenTitle4)
                    .foregroundStyle(papaya)
                Text(title)
                    .font(.zenFootnote)
                    .foregroundStyle(papaya)
            }
            .padding(2) // keep content from touching edges
        }
        .frame(maxWidth: .infinity)        // share row space equally
        .aspectRatio(1, contentMode: .fit) // height now derives from width -> perfect square
    }

}

#Preview {
    
    VStack {
        DailyWorkoutExpandedView(workouts: [dummyClimbingSession1, dummyClimbingSession2], date: date)
            .padding()
    }
   
}
