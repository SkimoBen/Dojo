//
//  Workout View.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//

import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext //Swift Data
    @EnvironmentObject var dojo: DojoViewModel
    // Keep an editable instance for each activity
    @State private var climbing =
    CompletedClimbingWorkout(activity: .climbing, userNotes: "", date: Date(), routes: [])

    @State private var running = CompletedRunningWorkout(activity: .running,userNotes: "", date: Date(), distanceKm: 0,avgHeartRate: 0,elevationGain: 0, avgPacePerKm: 0)
    
    @State var freeText: String = ""
    @State var activity: ActivityTypeEnum = .climbing
    @State var activityDate = Date()
    @State var showDatePicker = false
    
    //Alerts
    @State var alertTitle: String = "Success"
    @State var alertMessage: String = ""
    @State var alertIsPresented: Bool = false
    
    var body: some View {
        
        
        HStack {
            
            VStack {
                Image(systemName: "circle")
                    .foregroundStyle(raspberry)
                    .padding(.top, 6)
                
                outer_line
                
                
                Spacer()
            }
            .frame(width: 5)
            .padding(.top, 16)
            //.background(.green.opacity(0.3))
            
            VStack(spacing: 4) {
                header
                    .padding(.leading, 4)
                date_and_activity_buttons
                
                HStack(alignment: .bottom) {
                    Image(systemName: "circle")
                        .foregroundStyle(vermillion)
                        .padding(.bottom, 8)
                    Text("Session Data")
                        .font(.zenTitle2)
                        .foregroundStyle(vermillion)
                    Spacer()
                }

                if activity == .climbing {
                    AddClimbingWorkoutView(climbingWorkout: climbing)
                
                } else {
                    AddRunningWorkoutView(runningWorkout: running, activityDate: $activityDate)
                }
                
                AshTextEditor(text: $freeText)
                    .padding(.top, 12)
                Spacer()
                
                Button(action: {
                    //MARK: Save to local storage
                    if activity == .climbing {
                        climbing.userNotes = freeText
                        modelContext.insert(climbing)
                        print("Changed Models: ", modelContext.changedModelsArray)
                        print("Inserted Models: ", modelContext.insertedModelsArray)
                        
                        //TODO: Show a toast
                    } else {
                        running.userNotes = freeText
                        print(running)
                        modelContext.insert(running)
                        print("Changed Models: ", modelContext.changedModelsArray)
                        print("Inserted Models: ", modelContext.insertedModelsArray)
                    }
                    print(modelContext.container)
                    do {
                        print("Trying to save")
                        try modelContext.save()
                        alertMessage = "Workout saved!"
                        alertTitle = "Success"
                    } catch {
                        print("Didn't save")
                        alertMessage = "Ran into a problem saving your workout."
                        alertTitle = "Error"
                    }
                    alertIsPresented = true
                    
                    //TODO: Send to vector storage
                    Task {
                        if activity == .climbing {
                            var routesDTO: [CompletedClimbingWorkoutRouteDTO] = []
                            for completedRoute in climbing.routes {
                                routesDTO.append(completedRoute.toDTO())
                            }
                            let climbingWorkout: AnyCompletedWorkoutDTO = .climbing(CompletedClimbingWorkoutDTO(activity: .climbing, userNotes: climbing.userNotes, date: climbing.date, routes: routesDTO))
                            
                            await uploadWorkoutToCloud(workout: climbingWorkout)
                            
                        } else {
                            let minPerKmh = running.avgPacePerKm / 60
                            
                            let runningWorkout: AnyCompletedWorkoutDTO = AnyCompletedWorkoutDTO.running(CompletedRunningWorkoutDTO(activity: .running, userNotes: running.userNotes, date: running.date, distanceKm: running.distanceKm, avgHeartRate: running.avgHeartRate, elevationGain: running.elevationGain, avgPacePerKm: minPerKmh))
                            
                                await uploadWorkoutToCloud(workout: runningWorkout)
           
                        }
                    }
                    
                    
                }, label: {
                    Text("Submit")
                        .font(.zenTitle2)
                        .foregroundStyle(papaya)
                        .frame(maxWidth: .infinity)      // expand the label
                        .padding(.vertical, 12)
                        .background(raspberry)           // now covers the full width
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                })
                //Spacer()
            }
           // .background(.cyan.opacity(0.1))
        }
        .padding(.horizontal, 12)
        .alert(alertTitle, isPresented: $alertIsPresented, actions: {
            
            if alertTitle == "Error" {
                Button("Try Again") {
                    alertIsPresented = false
                }
            } else {
                Button("OK") {
                    alertIsPresented = false
                    // Clear the Climbing workout after saving
                    withAnimation(.easeInOut) {
                        climbing = CompletedClimbingWorkout(activity: .climbing, userNotes: "", date: Date(), routes: [])
                        running = CompletedRunningWorkout(activity: .running,userNotes: "", date: Date(), distanceKm: 0,avgHeartRate: 0,elevationGain: 0, avgPacePerKm: 0)
                        freeText = ""
                    }
                    
                    
                }
            }
           
        }, message: {
            Text(alertMessage)
        })
        
        //.padding(.trailing, 4)
        //.background(.pink.opacity(0.1))
        
        
    }
    
    private var header: some View {
        HStack(alignment: .center) {
            Text("Workout")
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
    
//    @ViewBuilder
//    private func date_and_activity_buttons() -> some View {
//        
//    }
    
    private var date_and_activity_buttons: some View {
        HStack(spacing: 14) {


            Button(action: {
                // Action for date button
                showDatePicker.toggle()
            }) {
                Text("\(formattedActivityDate(activityDate))")
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
                // Your popover content
                VStack {
                    DatePicker(
                        "Start Date",
                        selection: $activityDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .presentationCompactAdaptation(.popover) // keep as popover on iPhone (iOS 16.4+)
                }
                .frame(width: 300)
                .onChange(of: activityDate) {
                    climbing.date = activityDate
                    running.date = activityDate
                }
                
            }
            
            Menu(content: {
                VStack {
                    ForEach(ActivityTypeEnum.allCases) { act in
                        Button("\(act.displayName)") {
                            activity = act
                        }
                    }
                }
            }, label: {
                HStack(spacing: 4) {
                    Text("\(activity.displayName)")
                        .bold()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(vermillion)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ash, lineWidth: 2)
                )
                
            })
        }
    }
    
    struct WorkoutPayload: Codable {
        let userId: UUID
        let workout: AnyCompletedWorkoutDTO
        let coordinatorContext: ChatViewModel.CoordinatorContext
    }
    
    struct WorkoutResponse: Decodable {
        let server_msg: String
        let context: ChatViewModel.CoordinatorContext
    }
    
    func makeCoordinatorContext() -> ChatViewModel.CoordinatorContext{
        var coordinatorContext = ChatViewModel.CoordinatorContext()
        coordinatorContext.goals = ChatViewModel.createUserDefinedGoalsDTO(userDefinedGoals: dojo.userDefinedGoals)
        coordinatorContext.activityFitnessLevels = ChatViewModel.createFitnessLevelsDTO(fitnessLevels: dojo.activityFitnessLevel)
        coordinatorContext.currentTrainingPlan = ChatViewModel.createDailyWorkoutsDTO(dailyWorkouts: dojo.dailyWorkoutPlans)
        
        return coordinatorContext
    }
    
    //MARK: Upload Workout to Cloud
    func uploadWorkoutToCloud(workout: AnyCompletedWorkoutDTO) async {
        //var submit_workout_endpoint: String = "https://dojo-backend-676434902275.us-west1.run.app/submit_workout"
        let submit_workout_endpoint: String = "http://192.168.1.71:8000/submit_workout" // Local endopoint from iLab Mac
        
        
        
        let payload = WorkoutPayload(userId: staticUserID, workout: workout, coordinatorContext: makeCoordinatorContext())
 
        // 2. Encode to JSON with a consistent date format
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let uploadData = try? encoder.encode(payload) else {
            print("❌ Error: Failed to encode WorkoutPayload.")
            return
        }
        
        // 3. Prepare URL Request
        guard let url = URL(string: submit_workout_endpoint) else {
            print("❌ Error: Invalid URL endpoint.")
            return
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 75
        config.timeoutIntervalForResource = 75
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = uploadData
        request.timeoutInterval = TimeInterval(75)
        // 4. Send Request
        do {
            print("🚀 Sending payload to \(submit_workout_endpoint)...")
            
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(for: request)
            
            // Optional: Print HTTP Status Code for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            // 5. Print Response JSON
            print("\n⬇️ --- Server Response JSON ---")
                prettyPrintJSON(from: data)
            try await decodeWorkoutResponseAndUpdateViewModel(data)
            print("⬆️ ----------------------------\n")
            
            return  // Complete the function
            
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            return
        }
    }
    
    func decodeWorkoutResponseAndUpdateViewModel(_ data: Data) async throws {
        let decoder = JSONDecoder()
        // Accept multiple date formats, including backend's "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            
            // 1) Try ISO8601 with fractional seconds
            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFrac.date(from: s) { return d }
            
            // 2) Try standard ISO8601 (may include Z or offset)
            let iso = ISO8601DateFormatter()
            if let d = iso.date(from: s) { return d }
            
            // 3) Try "yyyy-MM-dd'T'HH:mm:ss" (no timezone)
            let plain = DateFormatter()
            plain.calendar = Calendar(identifier: .iso8601)
            plain.locale = Locale(identifier: "en_US_POSIX")
            plain.timeZone = TimeZone(secondsFromGMT: 0)
            plain.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let d = plain.date(from: s) { return d }
            
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Expected date string to be ISO8601-formatted or 'yyyy-MM-dd'T'HH:mm:ss', got \(s)")
        }
        
        do {
            let workoutResponse: WorkoutResponse = try decoder.decode(WorkoutResponse.self, from: data)
            print("\n----Previous Fitness Levels:-----")
            for fl in dojo.activityFitnessLevel {
                print(fl.activity.displayName, fl.agentDefinedFitnessLevel as Any)
            }
            dojo.updateDojoViewModelFromWorkoutResponse(workoutResponse)
            print("\n-----Updated coach defined fitness level-----")
            for fl in dojo.activityFitnessLevel {
                print(fl.activity.displayName, fl.agentDefinedFitnessLevel as Any)
            }
        } catch {
            print("❌ Error decoding data from Workout Response. \(error.localizedDescription)")
            print("Full Error:\n", error)
  
        }
    }
    
}




#Preview {
//    let activities: [ClimbingRoute_StateView] = [
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 1, send: true, style: .redpoint),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 1, send: false, style: .nosend),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 2, send: true, style: .onSite),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 1, send: true, style: .flash),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 1, send: false, style: .nosend),
//        ClimbingRoute_StateView(grade: .yds(.g5_10b), attempts: 2, send: true, style: .nosend),
        //ClimbingActivity(grade: .g5_12a, attempts: 1, send: true, style: .flash),
        //ClimbingActivity(grade: .g5_12d, attempts: 1, send: false, style: .nosend),
        //ClimbingActivity(grade: .g5_10a, attempts: 2, send: true, style: .nosend)
    //]
    
    AddWorkoutView()
}




