//
//  CompletedWorkoutModel.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-28.
//

import SwiftData
import Foundation

//MARK: Superclass
@Model
class CompletedWorkout {
//    @Attribute(.unique) var id: UUID
    
    var activity: ActivityTypeEnum
    var userNotes: String
    var date: Date
    init(
 //       id: UUID = UUID(),
        activity: ActivityTypeEnum,
        userNotes: String = "",
        date: Date
    ) {
 //       self.id = id
        self.activity = activity
        self.userNotes = userNotes
        self.date = date
    }
}

//MARK: Complete Climbing Workout
@available(iOS 26.0, *)
@Model
class CompletedClimbingWorkout: CompletedWorkout {
    @Relationship(deleteRule: .cascade) var routes: [CompletedClimbingWorkoutRoute] = []
    
    init(
         activity: ActivityTypeEnum = .climbing,
         userNotes: String,
         date: Date,
         routes: [CompletedClimbingWorkoutRoute])
    {
        self.routes = routes
        super.init(activity: activity, userNotes: userNotes, date: date)
    }
}

@available(iOS 26.0, *)
@Model
class CompletedClimbingWorkoutRoute: Identifiable {
//    @Attribute(.unique) var id: UUID = UUID()
    var grade: GradeValue
    var attempts: Int
    var send: Bool
    var style: ClimbStyle
    
    init(grade: GradeValue,
         attempts: Int,
         send: Bool,
         style: ClimbStyle)
    {
        self.grade = grade
        self.attempts = attempts
        self.send = send
        self.style = style
    }
    func toDTO() -> CompletedClimbingWorkoutRouteDTO {
        return CompletedClimbingWorkoutRouteDTO(grade: self.grade.display, attempts: self.attempts, send: self.send, style: self.style)
    }
}

//MARK: Complete Running Workout
@available(iOS 26.0, *)
@Model
class CompletedRunningWorkout: CompletedWorkout {
    var distanceKm: Float //Kms
    var avgHeartRate: Float //BPM
    var elevationGain: Float // meters
    var avgPacePerKm: TimeInterval // min / km
    
    init(activity: ActivityTypeEnum = .running, userNotes: String, date: Date, distanceKm: Float, avgHeartRate: Float, elevationGain: Float, avgPacePerKm: TimeInterval) {
        self.distanceKm = distanceKm
        self.avgHeartRate = avgHeartRate
        self.elevationGain = elevationGain
        self.avgPacePerKm = avgPacePerKm
        super.init(activity: activity, userNotes: userNotes, date: date)
    }
}



// MARK: - Simple Codable DTOs (with shared protocol)

protocol CompletedWorkoutDTOProtocol: Codable {
    var activity: ActivityTypeEnum { get }
    var userNotes: String { get set }
    var date: Date { get set }
}

struct CompletedRunningWorkoutDTO: CompletedWorkoutDTOProtocol, Codable {
    var activity: ActivityTypeEnum = .running
    var userNotes: String
    var date: Date
    
    var distanceKm: Float
    var avgHeartRate: Float
    var elevationGain: Float
    var avgPacePerKm: TimeInterval
}

struct CompletedClimbingWorkoutDTO: CompletedWorkoutDTOProtocol, Codable {
    var activity: ActivityTypeEnum = .climbing
    var userNotes: String
    var date: Date
    
    var routes: [CompletedClimbingWorkoutRouteDTO]
}

struct CompletedClimbingWorkoutRouteDTO: Codable {
    var grade: String
    var attempts: Int
    var send: Bool
    var style: ClimbStyle
}

// Type-erased wrapper for polymorphic encoding/decoding based on `activity`
enum AnyCompletedWorkoutDTO: Codable {
    case running(CompletedRunningWorkoutDTO)
    case climbing(CompletedClimbingWorkoutDTO)
    
    private enum DiscriminatorCodingKeys: String, CodingKey {
        case activity
    }
    
    func encode(to encoder: any Encoder) throws {
        switch self {
        case .running(let dto):
            try dto.encode(to: encoder)
        case .climbing(let dto):
            try dto.encode(to: encoder)
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorCodingKeys.self)
        let activity = try container.decode(ActivityTypeEnum.self, forKey: .activity)
        switch activity {
        case .running:
            self = .running(try CompletedRunningWorkoutDTO(from: decoder))
        case .climbing:
            self = .climbing(try CompletedClimbingWorkoutDTO(from: decoder))
        }
    }
}
