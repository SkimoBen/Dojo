//
//  NewGoalView.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-11.
//

import SwiftUI
import SwiftData

struct NewGoalView: View {
    @EnvironmentObject var dojo: DojoViewModel
    @Environment(\.dismiss) private var dismiss
    //@State var activitySelection: ActivityTypeEnum
    
    //@State var title: String
    @FocusState private var titleIsFocused: Bool
    
    @FocusState private var descriptionIsFocused: Bool
    //@State var description: String
    
    @State private var showDatePicker: Bool = false
    @FocusState private var datPickerIsFocused: Bool
   // @State var goalDeadline: Date
    @State var showDescriptionInfo: Bool = false
    
    @State var showInfo: Bool = false
    //@FocusState private var fitnessLevelIsFocused: Bool
    //@State var fitnessLevel: String
    @State var editingGoal: UserDefinedGoal
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            //MARK: Header
//            VStack(spacing: 0) {
//                HStack(alignment: .center) {
//
//                    LogDecaySpin()
//                        .offset(y: 4)
//
//                    Text("New Goal")
//                        .font(.zenTitle)
//                    Spacer()
//                    Button(action: {
//                        dismiss()
//                    }, label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundStyle(raspberry)
//                            .font(.system(size: 30))
//                    })
//                    
//        
//                }
//                // Spread the Japanese characters to fill the full width
//                JustifiedCharacterText(
//                    text: "もう これで. 終わってもいい. だから ありったけを.",
//                    uiFont: .zenCaption2,
//                    textColor: UIColor(raspberry),
//                    includeSpacesAndPunctuation: false // set true if you want spaces/punctuation to spread too
//                )
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .foregroundStyle(raspberry)
            
            //MARK: Activity Picker
            ActivityPicker(selection: $editingGoal.goalActivity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.zenHeadline)
                    .foregroundStyle(raspberry)
                VStack {
                    TextField("Title", text: $editingGoal.title)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(titleIsFocused ? raspberry : ash, lineWidth: 1)
                        )
                        .foregroundColor(vermillion)
                        .focused($titleIsFocused)
                        .font(.zenBody)
                    if titleIsFocused {
                        HStack {
                            Spacer()
                            Button(action: {
                                titleIsFocused = false
                            }) {
                                Text("Done")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(raspberry)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
            }
            //MARK: Goal Deadline
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal Deadline")
                    .font(.zenHeadline)
                    .foregroundStyle(raspberry)
                
                Button(action: {
                    //First unfocus the keyboards
                    titleIsFocused = false
                    descriptionIsFocused = false
                    // Action for date button
                    showDatePicker.toggle()
                }) {
                    Text("\(formattedActivityDate($editingGoal.goalDeadline.wrappedValue))")
                        .foregroundColor(vermillion)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ash, lineWidth: 2)
                        )
                }
                .popover(
                    isPresented: $showDatePicker,
                    attachmentAnchor: .rect(.bounds), // anchor to the button’s bounds
                    arrowEdge: .top                    // point the arrow up
                ) {
                    
                    VStack {
                        DatePicker(
                            "Start Date",
                            selection: $editingGoal.goalDeadline,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .presentationCompactAdaptation(.popover) // keep as popover on iPhone (iOS 16.4+)
                        .focused($datPickerIsFocused)
                    }
                    .frame(minWidth: 280, idealWidth: 300, maxWidth: 360,
                           minHeight: 300, idealHeight: 300, maxHeight: 420)

                    
                }
                
            }
            //MARK: Description
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    
                    Text("Goal Description")
                        .font(.zenHeadline)
                        .foregroundStyle(raspberry)
                    Button(action: {showDescriptionInfo.toggle()}, label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(raspberry)
                    })
                    
                    .popover(isPresented: $showDescriptionInfo) {
                        Text("Describe your goal in as much detail as you you think is necessary.")
                            .font(.zenBody)
                            .foregroundStyle(jet)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                 //AshTextEditor(text: $editingGoal.description)
                VStack {
                    TextEditor(text: $editingGoal.goalDescription)
                        .frame(minHeight: 100, maxHeight: 150) // ✅ good size range
                    
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(descriptionIsFocused ? raspberry : ash, lineWidth: 1)
                        )
                        .foregroundColor(vermillion)
                        .focused($descriptionIsFocused)
                        .font(.zenBody)
                    if descriptionIsFocused {
                        HStack {
                            Spacer()
                            Button(action: {
                                descriptionIsFocused = false
                            }) {
                                Text("Done")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(raspberry)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                }
               
           
                
            }
            

            //MARK: Save to ViewModel
            Button(action: {
                //TODO: Send to chatty
//                if let index = dojo.userDefinedGoals.firstIndex(where: { $0.id == editingGoal.id }) {
//                    // ✅ Update existing goal in-place
//                    dojo.userDefinedGoals[index] = editingGoal
//                } else {
//                    // ✅ Add new goal
//                    dojo.userDefinedGoals.append(editingGoal)
//                }
                
                // Save to SwiftData
                modelContext.insert(editingGoal)
                do {
                    print("Attempting to save goal")
                    try modelContext.save()
                } catch {
                    print("Error saving goal: \(error.localizedDescription)")
                }
                
                dismiss()
                
            }, label: {
                Text("Commit Goal")
                    .font(.zenTitle2)
                    .foregroundStyle(papaya)
                    .frame(maxWidth: .infinity)      // expand the label
                    .padding(.vertical, 12)
                    .background(raspberry)           // now covers the full width
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
            })
            
        }
        .toolbar {
            // Leading
//            ToolbarItem(placement: .topBarLeading) {
//                
//            }
            
            // Title (center)
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    HStack {
                        LogDecaySpin(spins: 3, tau: 0.6)
                            .offset(y: 4)
                            .foregroundStyle(raspberry)
                        Text("New Goal")
                            .font(.zenTitle)
                            .foregroundStyle(raspberry)
                    }
                    
                    
                    // Subhead stretched to width: use a separate line that
                    // naturally wraps instead of forcing maxWidth inside the nav bar.
                    // For a guaranteed full-width “sticky” subtitle, see the inset below.
                    Text("もう これで. 終わってもいい. だから ありったけを.")
                        .font(.zenCaption2)
                        .foregroundStyle(raspberry)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.bottom, -2) // gentle nudge; avoid big negative offsets
            }
            
            // Trailing
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        //.font(.system(size: 30))
                }
                .tint(raspberry)
            }
        }
//        .toolbar {
//            ToolbarItemGroup(placement: .topBarLeading)  {
//              
//                    LogDecaySpin()
//                        .padding(.trailing, -4)
//                    Text("New Goal")
//                        .font(.zenTitle)
//                        .padding(.bottom, 8)
//                        .padding(.trailing, 6)
//            }
//            ToolbarSpacer(.flexible)
//            ToolbarItem(placement: .topBarTrailing) {
//                Button(action: {
//                    dismiss()
//                }, label: {
//                    Image(systemName: "xmark.circle")
//                        //.foregroundStyle(raspberry)
//                        //.font(.system(size: 30))
//                })
//            }
//            
//        }
        //MARK: === Sticky top bar ===
//        .navigationBarTitleDisplayMode(.large) // avoids the "squish" on scroll
//        .toolbarBackground(.visible, for: .navigationBar)
//        .toolbar {
//            ToolbarItem(placement: .title) {
//                VStack(spacing: 0) {
//                    HStack(alignment: .center) {
//                        
//                        LogDecaySpin()
//                            .offset(y: 4)
//                        
//                        Text("New Goal")
//                            .font(.zenTitle)
//                        Spacer()
//                        Button(action: {
//                            dismiss()
//                        }, label: {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundStyle(raspberry)
//                                .font(.system(size: 30))
//                        })
//                        
//                        
//                    }
//                    // Spread the Japanese characters to fill the full width
//                    JustifiedCharacterText(
//                        text: "もう これで. 終わってもいい. だから ありったけを.",
//                        uiFont: .zenCaption2,
//                        textColor: UIColor(raspberry),
//                        includeSpacesAndPunctuation: false // set true if you want spaces/punctuation to spread too
//                    )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                .padding(.bottom, -30)
//                .foregroundStyle(raspberry)
//            }
//        }
        Spacer()
    }
}

#Preview {
    NavigationStack {
        NewGoalView(editingGoal: climbingGoal2)
            .padding()
            .environmentObject(dummyViewModel)
    }
    .preferredColorScheme(.light)
}

//#Preview {
//    NewGoalView(editingGoal: climbingGoal2)
//        .padding()
//        .environmentObject(dummyViewModel)
//        .preferredColorScheme(.light)
//}

struct ActivityPicker: View {
    @Binding var selection: ActivityTypeEnum
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isExpanded)
                    
                    Text(selection.displayName)
                        .font(.zenBigHeadline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ash)
                )
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(ActivityTypeEnum.allCases) { option in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                selection = option
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .font(.zenSubheadline)
                                Spacer()
                                if option == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if option != ActivityTypeEnum.allCases.last {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}


/// Exponential-decay spinner: starts fast, slows “log-like”, and stops.

struct LogDecaySpin: View {
    @State private var startDate = Date()   // <- initialized once per view identity
    var spins: Double = 10
    var tau: Double = 0.3

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(startDate)
            let theta = 360 * spins * (1 - exp(-t / tau))
            let visibleTheta = theta.truncatingRemainder(dividingBy: 360)

            Image(systemName: "plus")
                .rotationEffect(.degrees(visibleTheta))
        }
    }
}

