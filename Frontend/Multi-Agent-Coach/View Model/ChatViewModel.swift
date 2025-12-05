//
//  ChatViewModel.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-22.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var coordinatorContext: CoordinatorContext = CoordinatorContext()
    
    //var chatEndpoint: String = "https://dojo-backend-676434902275.us-west1.run.app/chat"
    let chatEndpoint: String = "http://192.168.1.71:8000/chat" // Local endopoint from iLab Mac 

    struct ChatPayload: Codable {
        let messages: [ChatMessage]
        let coordinatorContext: CoordinatorContext
        let timestamp: Date
        var userId = staticUserID.uuidString.lowercased()
        var conversation_id = staticConversationID
    }
    
    struct ChatResponse: Decodable {
        let server_msg: String
        let messages: [ChatMessage]
        let context: CoordinatorContext
    }
    
    struct CoordinatorContext: Codable {
        var userId = staticUserID
        var goals: [UserDefinedGoalDTO] = []
        var currentTrainingPlan: [DailyWorkoutDTO] = []
        var activityFitnessLevels: [FitnessLevelDTO] = []
    }

    enum ChatMessage: Codable {
        case user(UserMessage)
        case assistant(AssistantMessage)
        case reasoning(ReasoningMessage)
        case functionCall(FunctionCallMessage)
        case functionCallOutput(FunctionCallOutputMessage)

        private enum CodingKeys: String, CodingKey {
            case type
            case role
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // 1. If there's a type, it's not a simple user message.
            if let type = try? container.decode(String.self, forKey: .type) {
                switch type {
                case "reasoning":
                    self = .reasoning(try ReasoningMessage(from: decoder))
                case "message":
                    self = .assistant(try AssistantMessage(from: decoder))
                case "function_call":
                    self = .functionCall(try FunctionCallMessage(from: decoder))
                case "function_call_output":
                    self = .functionCallOutput(try FunctionCallOutputMessage(from: decoder))
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .type,
                        in: container,
                        debugDescription: "Unknown message type: \(type)"
                    )
                }
                return
            }

            // 2. No "type" means it's a simple user message.
            let role = try container.decode(String.self, forKey: .role)
            if role == "user" {
                self = .user(try UserMessage(from: decoder))
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .role,
                    in: container,
                    debugDescription: "Unexpected message without type but role=\(role)"
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            switch self {
            case .user(let m): try m.encode(to: encoder)
            case .assistant(let m): try m.encode(to: encoder)
            case .reasoning(let m): try m.encode(to: encoder)
            case .functionCall(let m): try m.encode(to: encoder)
            case .functionCallOutput(let m): try m.encode(to: encoder)
            }
        }
    }
    
    struct UserMessage: Codable {
        let content: String
        let role: String   // always "user"
    }
    
    struct ReasoningMessage: Codable {
        let id: String
        let summary: [String]
        let type: String   // "reasoning"
    }
    
    struct AssistantMessage: Codable {
        let id: String
        let content: [AssistantContent]
        let role: String        // "assistant"
        let status: String      // "completed"
        let type: String        // "message"
    }

    struct AssistantContent: Codable {
        let annotations: [String]?
        let text: String
        let type: String
        let logprobs: [Double]?
    }

    struct FunctionCallMessage: Codable {
        let arguments: String
        let call_id: String
        let name: String
        let type: String        // "function_call"
        let id: String
        let status: String

    }
    
    struct FunctionCallOutputMessage: Codable {
        let call_id: String
        let output: String
        let type: String    // "function_call_output"

    }

}

/// Extension to hold the functions for converting the SwiftData models into data transfer objects
extension ChatViewModel {
    
    func appendUserMessageToChatMessages(newMsg: String) {
        let newUserMessage = UserMessage(content: newMsg, role: "user")
        let newChatMessage: ChatMessage = ChatMessage.user(newUserMessage)
        self.messages.append(newChatMessage)
    }
    


    func updateCoordinatorContextFromViewModel(goals: [UserDefinedGoal], fitness: [FitnessLevel], workoutPlans: [DailyWorkout]) {
        // Populate the coordinator context from the dojo view model
        coordinatorContext.goals = ChatViewModel.createUserDefinedGoalsDTO(userDefinedGoals: goals)
        coordinatorContext.activityFitnessLevels = ChatViewModel.createFitnessLevelsDTO(fitnessLevels: fitness)
        coordinatorContext.currentTrainingPlan = ChatViewModel.createDailyWorkoutsDTO(dailyWorkouts: workoutPlans)
    }
    
    static func createUserDefinedGoalsDTO(userDefinedGoals: [UserDefinedGoal]) -> [UserDefinedGoalDTO] {
        return userDefinedGoals.map {
            UserDefinedGoalDTO(
                id: UUID(),
                goalActivity: $0.goalActivity,
                title: $0.title,
                description: $0.goalDescription,
                goalDeadline: $0.goalDeadline,
                isCompleted: $0.isCompleted
            )
        }
    }
    
    static func createDailyWorkoutsDTO(dailyWorkouts: [DailyWorkout]) -> [DailyWorkoutDTO] {
        var dailyWorkoutsDTO: [DailyWorkoutDTO] = []
        
        for dailyWorkout in dailyWorkouts {
            var newDailyWorkoutDTO: DailyWorkoutDTO = DailyWorkoutDTO(tracking_id: dailyWorkout.tracking_id, date: dailyWorkout.date, sessions: [])
            
            for sesh in dailyWorkout.sessions {
                // If it's a climbing workout
                if let climbingSesh = sesh as? ClimbingWorkout {
                    // Build a concrete ClimbingWorkoutDTO
                    var climbDTO = ClimbingWorkoutDTO(sessionDescription: climbingSesh.sessionDescription, routes: [])
                    // Add the routes to the Climbing Session DTO
                    for cr in climbingSesh.routes {
                        let newClimbRouteDTO = ClimbRouteDTO(gradeValue: cr.gradeValue, shortDescription: cr.shortDescription)
                        climbDTO.routes.append(newClimbRouteDTO)
                    }
                    // Wrap it in the type-erased enum and append
                    newDailyWorkoutDTO.sessions.append(.climbing(climbDTO))
                    
                // If it's a running session
                } else if let runningSesh = sesh as? RunningWorkout {
                    let runDTO = RunningWorkoutDTO(
                        sessionDescription: runningSesh.sessionDescription,
                        distanceKm: runningSesh.distanceKm,
                        heartRate: runningSesh.heartRate,
                        elevationGain: runningSesh.elevationGain,
                        paceMinPerKm: runningSesh.paceMinPerKm
                    )
                    newDailyWorkoutDTO.sessions.append(.running(runDTO))
                }
            }
            
            // Append the daily workout
            dailyWorkoutsDTO.append(newDailyWorkoutDTO)
        }
        return dailyWorkoutsDTO
    }
    
    static func createFitnessLevelsDTO(fitnessLevels: [FitnessLevel]) -> [FitnessLevelDTO] {
        var fitnessLevelsDTO: [FitnessLevelDTO] = []
        
        for fl in fitnessLevels {
            fitnessLevelsDTO.append(fl.toDTO())
        }
        return fitnessLevelsDTO
    }
}

/// Extension for housing the networking services
extension ChatViewModel {
    
    /// Sends the current chat state to the backend and prints the raw JSON response.
    /// Call this inside a Task { await sendChatPayload() } from your View.
    func sendChatPayload() async -> Data? {
        // 1. Construct the Payload
        // Note: 'userID' and 'conversation_id' will use the default values
        // (staticUserID, staticConversationID) defined in your struct.
        let payload = ChatPayload(
            messages: self.messages,
            coordinatorContext: self.coordinatorContext,
            timestamp: Date()
        )
        
        // 2. Encode to JSON with a consistent date format
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let uploadData = try? encoder.encode(payload) else {
            print("❌ Error: Failed to encode ChatPayload.")
            return nil
        }
        
        // 3. Prepare URL Request
        guard let url = URL(string: self.chatEndpoint) else {
            print("❌ Error: Invalid URL endpoint.")
            return nil
        }
        
        // Make a custom URL Config
        //let config =
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
     
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = uploadData
        request.timeoutInterval = TimeInterval(300)
        // 4. Send Request
        do {
            print("🚀 Sending payload to \(self.chatEndpoint)...")
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(for: request)
            //let (data, response) = try await URLSession.shared.data(for: request)
            
            // Optional: Print HTTP Status Code for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            // 5. Print Response JSON
            print("\n⬇️ --- Server Response JSON ---")
            prettyPrintJSON(from: data)
            print("⬆️ ----------------------------\n")
            
            return data // Complete the function
            
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    func createChatResponseFromData(_ data: Data) -> (ChatResponse?, Error?) {
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
            let chatResponse: ChatResponse = try decoder.decode(ChatResponse.self, from: data)
            return (chatResponse, nil)
        } catch {
            print("❌ Error decoding data from sendChatPayload function. \(error.localizedDescription)")
            print("Full Error:\n", error)
            return (nil, error)
        }
    }
    


}

func prettyPrintJSON(from data: Data) {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])

        if let prettyString = String(data: prettyData, encoding: .utf8) {
            print(prettyString)
        } else {
            print("⚠️ Could not convert JSON data to String.")
        }

    } catch {
        print("Failed to pretty print JSON:", error)
    }
}
