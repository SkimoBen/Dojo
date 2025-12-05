//
//  Plan View.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-10-08.
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject var viewModel: DojoViewModel
    var size: CGFloat = 32
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "xmark.triangle.circle.square")
                    .foregroundStyle(raspberry)
                    .offset(y:4)
                Text("Plan")
                    .font(.zenTitle)
                    .foregroundStyle(raspberry)
                Spacer()
            }
            
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.dailyWorkoutPlans) { dailyPlan in
                        DailyWorkoutPlanContainer(dailyPlan: dailyPlan)
                            .id(dailyPlan.id) //
                    }
                }
                
            }
            .scrollClipDisabled()
            
        }
        .padding()
        
    }
}


#Preview {
    PlanView()
        .environmentObject(dummyViewModel)
}


struct ChevronRotateButton: View {
 
    var size: CGFloat = 44
    var action: (() -> Void)? = nil

    @Binding var isRotated: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isRotated.toggle()
            }
            action?()
        } label: {
            Image(systemName: "chevron.up")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(vermillion)
                .padding(size * 0.3)
                .background(
                    Circle()
                        .fill(Color.white)
                )
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
                .rotationEffect(.degrees(isRotated ? 180 : 0))
                .contentShape(Circle())
                .accessibilityLabel(isRotated ? "Collapse" : "Expand")
        }
        .buttonStyle(.plain)
    }
}


struct DailyWorkoutPlanContainer: View {
    @State private var isExpanded = false
    var dailyPlan: DailyWorkout
    var size: CGFloat = 28

    var body: some View {
        Group {
            if !isExpanded {
                DailyWorkoutSmallView(workouts: dailyPlan.sessions, date: dailyPlan.date.customFormatted)
            } else {
                DailyWorkoutExpandedView(workouts: dailyPlan.sessions, date: dailyPlan.date.customFormatted)
            }
        }

        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Button {
   
                isExpanded.toggle()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(vermillion)
                    .padding(size * 0.3)
                    .padding(.top, 3)
                    .background(Circle().fill(.white))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .contentShape(Circle())
                    .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
                    .animation(.spring(response: 1.3, dampingFraction: 0.8), value: isExpanded) 
            }
            .buttonStyle(.plain)
            .offset(y: -8)
        }
    }
}

