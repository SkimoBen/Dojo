//
//  ActivityGrid.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-22.
//

import SwiftUI


struct AddClimbingWorkoutView: View {
    @Bindable var climbingWorkout: CompletedClimbingWorkout
    @State var editingRoute: CompletedClimbingWorkoutRoute = CompletedClimbingWorkoutRoute(grade: .yds(.g5_10a), attempts: 1, send: true, style: .onSite)
    @State var showSheet: Bool = false

    var body: some View {
        @State var maxScrollViewHeight: CGFloat = CGFloat(min(max(climbingWorkout.routes.count * 52, 0), 240))
        VStack {
            // MARK: ScrollView
            ScrollView {
                ClimbingRouteGrid(climbingRoutes: $climbingWorkout.routes)
                    .padding(.trailing, 8)
                    .padding(.top, 6)
            }
            .sunkenPanel()
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: maxScrollViewHeight)

            Button(action: {
                // Reset editor to a sensible default each time
                editingRoute = CompletedClimbingWorkoutRoute(
                    grade: .yds(.g5_10a),
                    attempts: 1,
                    send: true,
                    style: .onSite
                )
                showSheet = true
            }, label: {
                Text("+ Route")
                    .font(.body)
                    .italic().bold()
                    .foregroundStyle(vermillion)
                    .frame(height: 16, alignment: .center)
            })
            .buttonStyle(GradientOutlineButtonStyle())
            .padding(.top, 8)
        }
        .fullScreenCover(isPresented: $showSheet) {
            NavigationStack {
                EditRouteView(route: $editingRoute) { updated in
                    // Persist into workout and close
                    climbingWorkout.routes.append(updated)
                    showSheet = false
                } onCancel: {
                    showSheet = false
                }
            }
        }
    }
}

struct ClimbingRouteGrid: View {
    @Binding var climbingRoutes: [CompletedClimbingWorkoutRoute]
    var body: some View {
        @State var activityLength = climbingRoutes.count
        
        Grid(horizontalSpacing: 2, verticalSpacing: -6) {
            
            ForEach(climbingRoutes) { activity in
//                if activity.id == activities.first?.id {
//                    GridRow{
//                        Rectangle()
//                            .frame(width: 2, height: 18)
//                            .foregroundStyle(vermillion)
//                    }
//                }
                GridRow {
                    Button(action: {
                        climbingRoutes.removeAll(where: { $0.id == activity.id })
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundStyle(raspberry)
                            .rotationEffect(.degrees(45))
                    })
                    
                        
                    ClimbingActivityInfoCard(climb: activity)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                
                
                if activity.id != climbingRoutes.last?.id {
                    GridRow{
                        Rectangle()
                            .frame(width: 2, height: 18)
                            .foregroundStyle(vermillion)
                    }
                }
                
            }

        }
        .animation(.spring, value: climbingRoutes)

    }
}

#Preview {
    
    let activities: [CompletedClimbingWorkoutRoute] = [
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: false, style: .nosend),
        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 2, send: true, style: .nosend)
    ]
    let cw = CompletedClimbingWorkout(activity: .climbing, userNotes: "", date: Date(), routes: activities)
    AddClimbingWorkoutView(climbingWorkout: cw)
}

//#Preview {
//    let activities: [CompletedClimbingWorkoutRoute] = [
//        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
//        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
//        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 1, send: false, style: .nosend),
//        CompletedClimbingWorkoutRoute(grade: .yds(.g5_10b), attempts: 2, send: true, style: .nosend)
//    ]
//    ClimbingRouteGrid(climbingRoutes: .constant(activities))
//}

private struct EditRouteView: View {
    @Binding var route: CompletedClimbingWorkoutRoute

    let onSave: (CompletedClimbingWorkoutRoute) -> Void
    let onCancel: () -> Void

    // UI State
    enum GradeScale: String, CaseIterable { case yds = "YDS", v = "V-Scale" }

    @State private var selectedScale: GradeScale = .yds
    @State private var ydsSelection: YDSGrade = .g5_10a
    @State private var vSelection: VGrade = .v4

    @Environment(\.dismiss) private var dismiss

    init(route: Binding<CompletedClimbingWorkoutRoute>,
         onSave: @escaping (CompletedClimbingWorkoutRoute) -> Void,
         onCancel: @escaping () -> Void)
    {
        self._route = route
        self.onSave = onSave
        self.onCancel = onCancel

        // Pre-seed scale pickers from incoming route
        switch route.wrappedValue.grade {
        case .yds(let g):
            _selectedScale = State(initialValue: .yds)
            _ydsSelection  = State(initialValue: g)
        case .v(let g):
            _selectedScale = State(initialValue: .v)
            _vSelection    = State(initialValue: g)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Text("Add Route")
                    .font(.headline)
                Spacer()
                Button("Save") {
                    onSave(route)
                }
                .bold()
                .disabled(!isValid)
            }
            .padding()
            .background(.ultraThinMaterial)
            .zIndex(1)

            // Content
            Form {
                // Scale picker
                Section {
                    Picker("Scale", selection: $selectedScale) {
                        ForEach(GradeScale.allCases, id: \.self) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedScale) {
                        // Flip underlying grade when the scale changes
                        switch selectedScale {
                        case .yds:
                            route.grade = .yds(ydsSelection)
                        case .v:
                            route.grade = .v(vSelection)
                        }
                    }
                }

                // Grade picker reflecting chosen scale
                Section(header: Text("Grade")) {
                    if selectedScale == .yds {
                        Picker("YDS", selection: $ydsSelection) {
                            ForEach(YDSGrade.allCases, id: \.self) { g in
                                Text(g.display).tag(g)
                            }
                        }
                        .onChange(of: ydsSelection) { route.grade = .yds(ydsSelection) }
                    } else {
                        Picker("V-Scale", selection: $vSelection) {
                            ForEach(VGrade.allCases, id: \.self) { g in
                                Text(g.display).tag(g)
                            }
                        }
                        .onChange(of: vSelection) { route.grade = .v(vSelection) }
                    }
                }

                // Attempts
                Section {
                    Stepper(value: $route.attempts, in: 1...99) {
                        HStack {
                            Text("Attempts")
                            Spacer()
                            Text("\(route.attempts)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Send + Style
                Section {
                    Toggle(isOn: $route.send) {
                        Text("Sent?")
                    }
                    .onChange(of: route.send) {
                        // Keep style coherent with "send"
                        if !route.send {
                            route.style = .nosend
                        } else if route.style == .nosend {
                            route.style = .onSite
                        }
                    }

                    Picker("Style", selection: $route.style) {
                        ForEach(ClimbStyle.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .disabled(!route.send)
                }

                // Live preview row
                Section(header: Text("Preview")) {
                    LabeledContent("Grade", value: route.grade.display)
                    LabeledContent("Attempts", value: "\(route.attempts)")
                    LabeledContent("Result", value: route.send ? route.style.displayName : "-")
                }
            }
        }
        .onAppear {
            // Ensure the bound route and UI state are synced
            switch route.grade {
            case .yds(let g): selectedScale = .yds; ydsSelection = g
            case .v(let g):   selectedScale = .v;   vSelection   = g
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var isValid: Bool {
        // Extend with more validation if needed
        route.attempts >= 1
    }
}
