//
//  Goals View.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-10-08.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @EnvironmentObject var dojo: DojoViewModel
    @State var activities: [ActivityTypeEnum] = []
    @State var goalData: UserDefinedGoal? = nil
    
    @Environment(\.modelContext) private var modelContext
    //@Query(sort: \UserDefinedGoal.title) var goals: [UserDefinedGoal]
    
    var body: some View {
        let goals = dojo.userDefinedGoals
        ScrollView {
            LazyVStack {
                //Header View
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        Image(systemName: "xmark")
                            .offset(y:4)
                        Text("Goals")
                            .font(.zenTitle)
                        Spacer()
                    }
                    // Spread the Japanese characters to fill the full width
                    JustifiedCharacterText(
                        text: "もう これで. 終わってもいい. だから ありったけを.",
                        uiFont: .zenCaption2,
                        textColor: UIColor(raspberry),
                        includeSpacesAndPunctuation: false // set true if you want spaces/punctuation to spread too
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(raspberry)
      
                // Goal List (grouped by activity)
                //let groups = Dictionary(grouping: dojo.userDefinedGoals, by: { $0.goalActivity }) // unordered
                let groups = Dictionary(grouping: goals, by: { $0.goalActivity })
                // consistently ordered by the Enum order that is hardcoded
                let orderedActivities: [ActivityTypeEnum] =
                    ActivityTypeEnum.allCases.filter { groups[$0] != nil }

                ForEach(orderedActivities, id: \.self) { activity in
                    // One header per activity
                    ActivityHeader(activityName: activity.displayName)
                        .padding(.top, 8)

                    // Goals under that header
                    ForEach(groups[activity]!.sorted(by: { lhs, rhs in
                        // inner sort by date
                        lhs.goalDeadline > rhs.goalDeadline
                    })) { goal in
                        GoalCardView(goal: goal)
                    }
                }
                
                Button(action: {
                    goalData = UserDefinedGoal()
                }, label: {
                    
                    Text("+ Goal")
                        .font(.body)
                        .italic().bold()
                        .foregroundStyle(vermillion)
                        .frame(height: 16, alignment: .center)
                })
                .buttonStyle(GradientOutlineButtonStyle())
                
                Spacer()
            }
            .padding()
            
        }
        // GoalsView.swift
        .fullScreenCover(item: $goalData, onDismiss: { goalData = nil }) { gd in
            NavigationStack {                    // <— host for keyboard toolbar
                NewGoalView(editingGoal: gd)
                    .padding()
            }
        }
//
//        .fullScreenCover(item: $goalData, onDismiss: {
//            goalData = nil
//        }, content: { gd in
//            NewGoalView(editingGoal: gd)
//                .padding()
//            
//        })
    }
    @ViewBuilder func ActivityHeader(activityName: String) -> some View {
        HStack {
            Spacer()
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(.white)
                .frame(height:12)
                
            Text(activityName)
                .font(.zenHeadline)
                .foregroundStyle(.white)
                
                .padding(.bottom, 3)
            Spacer()
                
        }
        .frame(maxWidth: .infinity, maxHeight: 30)
        .padding(.vertical, 6)
        .padding(.leading, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ash)
        )
    }
    
    
    
}

#Preview {
    GoalsView()
        .environmentObject(dummyViewModel)
        .preferredColorScheme(.light)
}



// MARK: - Public SwiftUI view
struct JustifiedCharacterText: View {
    let text: String
    let uiFont: UIFont
    var textColor: UIColor = .label
    var includeSpacesAndPunctuation: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            KernedLabel(
                text: text,
                width: proxy.size.width,
                uiFont: uiFont,
                textColor: textColor,
                includeSpacesAndPunctuation: includeSpacesAndPunctuation
            )
        }
        // Single line height based on the font
        .frame(height: uiFont.lineHeight)
        // Prevent SwiftUI from wrapping/ellipsizing
        .clipped()
    }
}

// MARK: - UILabel representable that applies dynamic kerning
private struct KernedLabel: UIViewRepresentable {
    let text: String
    let width: CGFloat
    let uiFont: UIFont
    let textColor: UIColor
    let includeSpacesAndPunctuation: Bool
    
    func makeUIView(context: Context) -> UILabel {
        let l = UILabel()
        l.numberOfLines = 1
        l.lineBreakMode = .byClipping
        return l
    }
    
    func updateUIView(_ label: UILabel, context: Context) {
        label.font = uiFont
        label.textColor = textColor
        
        // Measure base width with no kerning
        let baseWidth = (text as NSString).size(withAttributes: [.font: uiFont]).width
        
        // Count characters that will be “spread”
        let spreadString: String
        if includeSpacesAndPunctuation {
            spreadString = text
        } else {
            // Exclude all Unicode whitespace from the spread calculation
            spreadString = text.replacingOccurrences(
                of: "\\p{Z}+",
                with: "",
                options: .regularExpression
            )
        }
        let pairs = max(0, spreadString.count - 1)  // number of gaps between characters
        
        // Calculate per-gap kerning needed to fill the available width
        let extra = max(0, width - baseWidth)
        let kernPerPair = pairs > 0 ? extra / CGFloat(pairs) : 0
        
        // Build attributed string
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttributes([
            .font: uiFont,
            .kern: kernPerPair
        ], range: NSRange(location: 0, length: attributed.length))
        
        label.attributedText = attributed
    }
}

struct GoalCardView: View {
    @Environment(\.modelContext) private var modelContext
    let goal: UserDefinedGoal
    @State var editingGoal: UserDefinedGoal? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.zenHeadline)
                    .foregroundColor(raspberry)
                Spacer()
                
                Button(action: {
                    modelContext.delete(goal)
                    do {
                        try modelContext.save()
                    } catch {
                        print("error deleting: \(error)")
                    }
                    
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(raspberry)
                })
                .padding(.trailing, 12)
                Button(action: {
                    editingGoal = goal
                }, label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(raspberry)
                })
               
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Goal Deadline")
                        .foregroundColor(vermillion)
                   
                    Spacer()
                    Text(goal.goalDeadline.formattedWithOrdinal())
                        .foregroundColor(vermillion)
                        .bold()
                }
                
                HStack {
                    Text("Time Remaining:")
                        .foregroundColor(vermillion)
                    
                    Spacer()
                    Text("\(goal.daysRemaining)")
                        .foregroundColor(vermillion)
                        .bold()
                }

            }
            .font(.zenSubheadline)
        }
        .padding()
  
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ash, lineWidth: 1)
        )
        .fullScreenCover(item: $editingGoal, onDismiss: {
            editingGoal = nil
        }, content: { gd in
            
            NewGoalView(editingGoal: gd)
                .padding()
        })

    }
}

