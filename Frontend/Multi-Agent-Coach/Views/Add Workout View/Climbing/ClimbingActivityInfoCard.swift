//
//  ClimbCard.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//
import SwiftUI

struct ClimbingActivityInfoCard: View {
    var climb: CompletedClimbingWorkoutRoute

    var body: some View {
        HStack(alignment: .center ,spacing:4) {
            HStack {
                HStack(spacing: 2)  {
                    Text("Grade: ")
                        .font(.zenCaption)
                    Text(climb.grade.display)
                        .font(.zenCaption2)
                }
                .frame(maxWidth: 70, alignment: .leading)
                
                HStack(spacing: 2)  {
                    Text("Tries: ")
                        .font(.zenCaption)
                    Text("\(climb.attempts)")
                        .font(.zenCaption2)
                }
                .frame(maxWidth: 56, alignment: .leading)
                
                HStack(spacing: 2) {
                    Text("Send: ")
                        .font(.zenCaption)
                    Text(climb.send ? "Yes" : "No")
                        .font(.zenCaption2)
                }
                .frame(maxWidth: 56, alignment: .leading)
                
                HStack(spacing: 2)  {
                    Text("Style: ")
                        .font(.zenCaption)
                    Text(climb.style.displayName)
                        .font(.zenCaption2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 2)
        )
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cell(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(title):")
                    .font(.zenCaption)
                Text(value)
                    .font(.zenCaption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
        
    }
}

// MARK: - Preview
struct InfoPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            ClimbingActivityInfoCard(climb: CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b),attempts: 2,send: false, style: .onSite))
            
        }
        .padding()
    }
}

#Preview {
    InfoPreview()
}

struct ClimbingRoute_StateView: Identifiable, Hashable {
    let id: UUID = UUID()
    var grade: GradeValue
    var attempts: Int
    var send: Bool
    var style: ClimbStyle

}
