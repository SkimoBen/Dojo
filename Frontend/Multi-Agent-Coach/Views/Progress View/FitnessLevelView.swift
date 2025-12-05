//
//  ProgressView.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-28.
//

import SwiftUI
import SwiftData

//TODO: Finish this view
struct FitnessLevelView: View {
    @EnvironmentObject var dojo: DojoViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFitnessLevelToEdit: FitnessLevel?
    @State private var fitnessLevelInput: String = ""
    
    var body: some View {
        ScrollView {
            HStack {
                VStack {
                    Image(systemName: "circle")
                        .foregroundStyle(raspberry)
                        .padding(.top, 6)
                    
                    outer_line
                    
                    Spacer()
                }
                .frame(width: 5)
                .padding(.top, 20)
                
                VStack(spacing: 8) {
                    
                    header
                        .padding(.leading, 4)
                    
                    if !dojo.activityFitnessLevel.isEmpty {
                        ForEach(dojo.activityFitnessLevel) { activityFitnessLevel in
                            
                            fitnessLevelCard(activityFitnessLevel: activityFitnessLevel)
                            
                            ForEach(dojo.workoutHistory.filter {$0.activity == activityFitnessLevel.activity}) { workout in
                                if let climbingWorkout = workout as? CompletedClimbingWorkout {
                                    
                                    DisclosureGroup {
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            
                                            ClimbingRouteGrid(climbingRoutes: .constant(climbingWorkout.routes))
                                                .padding(4)
                                                .transition(.opacity.combined(with: .move(edge: .top)))
              
                                            Button(role: .destructive) {
                                                
                                                deleteWorkout(workout)
                                                
                                            } label: {
                                                
                                                Label("Delete this workout", systemImage: "trash")
                                                
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.red)
                                            .accessibilityIdentifier("deleteClimbingWorkoutButton")
                                            
                                        }
                                        
                                    } label: {
                                        
                                        Text(climbingWorkout.date.formattedWithOrdinal())
                                            .font(.zenHeadline)
                                            .foregroundStyle(raspberry)
                                        
                                    }
                                    
                                    .padding(.vertical, 8)
                                    
                                }
                                
                                
                                
                                if let runningWorkout = workout as? CompletedRunningWorkout {
                                    
                                    DisclosureGroup {

                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            
                                            RunningInfoCard(runningWorkout: runningWorkout)
 
                                            Button(role: .destructive) {
                                                
                                                deleteWorkout(workout)
                                                
                                            } label: {
                                                
                                                Label("Delete this workout", systemImage: "trash")
                                                
                                            }
                                            
                                            .buttonStyle(.borderedProminent)
                                            
                                            .tint(.red)
                                            
                                            .accessibilityIdentifier("deleteRunningWorkoutButton")
                                            
                                        }
                                        
                                    } label: {
                                        
                                        Text(runningWorkout.date.formattedWithOrdinal())
                                        
                                            .font(.zenHeadline)
                                        
                                            .foregroundStyle(raspberry)
                                        
                                    }
                                    
                                    .padding(.vertical, 8)
                                    
                                }
                                
                                
                                
                            }
                            
                        }
                        
                    }
                    
                    
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
        }
        .sheet(item: $selectedFitnessLevelToEdit, onDismiss: {
            fitnessLevelInput = ""
        }) { levelToEdit in
            BottomSheetContent(
                title: "Describe \(levelToEdit.activity.rawValue) fitness",
                text: $fitnessLevelInput,
                onCancel: {
                    selectedFitnessLevelToEdit = nil
                },
                onSave: {
                
                    handleSaveFitnessLevel(activityFitnessLevel: levelToEdit)
                    selectedFitnessLevelToEdit = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    

    @ViewBuilder
    func fitnessLevelCard(activityFitnessLevel: FitnessLevel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Activity Header
            HStack(alignment: .center) {
                activityTag(activityType: activityFitnessLevel.activity)
                Rectangle()
                    .fill(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 1.0)
            }
            
            // User Fitness Level Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(raspberry)
                    Text("Your Described Fitness Level")
                        .font(.body)
                        .bold()
                        .foregroundStyle(raspberry)
                    
          
                    Button(action: {
                
                        fitnessLevelInput = activityFitnessLevel.userDefinedFitnessLevel ?? ""
                        
                    
                        selectedFitnessLevelToEdit = activityFitnessLevel
                    }, label: {
                        Image(systemName: "square.and.pencil")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(raspberry)
                    })
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("editFitnessLevelButton")
                }
                
                Text(activityFitnessLevel.userDefinedFitnessLevel ?? "Not yet defined")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.leading, 16)
                
                if let date = activityFitnessLevel.userDefinedFitnessLevelUpdatedDate {
                    Text("Updated \(formattedDate(date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ash, lineWidth: 1)
            )
            
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(jet)
                    Text("Coach Described Fitness Level")
                        .font(.body)
                        .bold()
                        .foregroundStyle(jet)
                }
                
                Text(activityFitnessLevel.agentDefinedFitnessLevel ?? "Not yet assessed")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.leading, 16)
                
                if let date = activityFitnessLevel.agentFitnessLevelUpdatedDate {
                    Text("Updated \(formattedDate(date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ash, lineWidth: 1)
            )
        }
        .padding(.bottom, 12)
    }

  
    private var header: some View {
        HStack(alignment: .center) {
            Text("Progress")
                .font(.zenLargeTitle)
                .foregroundStyle(raspberry)
            Spacer()
        }
    }
    
    private var outer_line: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
            }
            .stroke(vermillion, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func deleteWorkout(_ workout: CompletedWorkout) {
         withAnimation {
             dojo.workoutHistory.removeAll { $0 === workout }
             modelContext.delete(workout)
             try? modelContext.save()
         }
    }
    
    private func handleSaveFitnessLevel(activityFitnessLevel: FitnessLevel) {
        // Save logic remains the same
        activityFitnessLevel.userDefinedFitnessLevel = fitnessLevelInput
        activityFitnessLevel.userDefinedFitnessLevelUpdatedDate = Date()
        
        do {
            try modelContext.save()
   
        } catch {
            print("Error saving fitness level: \(error.localizedDescription)")
        }
    }
}

// MARK: - Bottom Sheet Content
private struct BottomSheetContent: View {
    let title: String
    @Binding var text: String
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Describe your current fitness level. Be as specific as you like.")
                    .font(.zenBody)
                    .foregroundStyle(.secondary)
                
                TextField("e.g., Beginner — training 1–2x/week", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .padding(.top, 4)
                
                Spacer()
            }
            .padding(16)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    FitnessLevelView()
        .environmentObject(dummyViewModel)
}
