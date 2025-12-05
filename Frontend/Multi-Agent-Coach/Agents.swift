//
//  Agents.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-20.
//
/// This was a little experiment with running the on device LLM.

//import FoundationModels
//import Playgrounds
//import Foundation
//
//class RunningCoach {
//    let instructions: String = "You are a running coach for the user."
//    let model = SystemLanguageModel.default
//    let session: LanguageModelSession
//    
//    init() {
//        self.session = LanguageModelSession(instructions: instructions)
//        
//    }
//    
//    func replyToUser(prompt: String) async -> String {
//        do {
//            return try await session.respond(to: prompt).content
//        } catch {
//            print("Error: \(error)")
//            return "\(error.localizedDescription)"
//        }
//        
//    }
//    
//    func checkAvailability() -> String {
//        
//        switch model.availability{
//        case .available:
//            // Show your intelligence UI.
//            return "Available"
//        case .unavailable(.deviceNotEligible):
//            // Show an alternative UI.
//            return"Not eligible"
//        case .unavailable(.appleIntelligenceNotEnabled):
//            // Ask the person to turn on Apple Intelligence.
//            return "Not enabled"
//        case .unavailable(.modelNotReady):
//            // The model isn't ready because it's downloading or because
//            return "Not ready"
//            // of other system reasons.
//        case .unavailable(let other):
//            // The model is unavailable for an unknown reason.
//            return "Unknown \(other)"
//        }
//    }
//    
//    func stream(prompt: String) async -> String.PartiallyGenerated? {
//        
//        let stream = session.streamResponse(to: prompt)
//        
//        do {
//            for try await partial in stream {
//                return partial.content
//            }
//        } catch {
//            print(error.localizedDescription)
//            return "Error: \(error.localizedDescription)"
//        }
//        return "CompletedStream"
//    }
//   
//}

//#Playground {
//    var partialResponse: String.PartiallyGenerated?
//    
//    let runningCoach = RunningCoach()
//    let availability = runningCoach.model.availability
//    
//    let prompt = "Hey I ran 10km today at 7:00' min / km. Am I ready for a 3 hour marathon?"
//    partial = runningCoach.stream(prompt)
//    //let reponse = await runningCoach.replyToUser(prompt: prompt)
//}
