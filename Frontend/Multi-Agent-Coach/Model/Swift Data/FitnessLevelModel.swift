//
//  FitnessLevelModel.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-17.
//

import Foundation
import SwiftData


@Model
final class FitnessLevel: Identifiable {
 //   @Attribute(.unique) var id: UUID = UUID()
    var activity: ActivityTypeEnum
    // User updates
    var userDefinedFitnessLevel: String?
    var userDefinedFitnessLevelUpdatedDate: Date?
    // Agent updates
    var agentDefinedFitnessLevel: String?
    var agentFitnessLevelUpdatedDate: Date?
    
    // MARK: - Init
    init(
        activity: ActivityTypeEnum,
        userDefinedFitnessLevel: String? = nil,
        userDefinedFitnessLevelUpdatedDate: Date? = nil,
        agentDefinedFitnessLevel: String? = nil,
        agentFitnessLevelUpdatedDate: Date? = nil
    ) {
        self.activity = activity
        self.userDefinedFitnessLevel = userDefinedFitnessLevel
        self.userDefinedFitnessLevelUpdatedDate = userDefinedFitnessLevelUpdatedDate
        self.agentDefinedFitnessLevel = agentDefinedFitnessLevel
        self.agentFitnessLevelUpdatedDate = agentFitnessLevelUpdatedDate
    }
    
    func toDTO() -> FitnessLevelDTO {
        return FitnessLevelDTO(activity: self.activity,
                               userDefinedFitnessLevel: self.userDefinedFitnessLevel,
                               userDefinedFitnessLevelUpdatedDate: self.userDefinedFitnessLevelUpdatedDate,
                               agentDefinedFitnessLevel: self.agentDefinedFitnessLevel,
                               agentFitnessLevelUpdatedDate: self.agentFitnessLevelUpdatedDate)
    }
    
}


struct FitnessLevelDTO: Codable {
    var activity: ActivityTypeEnum
    // User updates
    var userDefinedFitnessLevel: String?
    var userDefinedFitnessLevelUpdatedDate: Date?
    // Agent updates
    var agentDefinedFitnessLevel: String?
    var agentFitnessLevelUpdatedDate: Date?
}
