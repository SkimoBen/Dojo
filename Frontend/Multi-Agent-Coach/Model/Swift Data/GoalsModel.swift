//
//  GoalsModel.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-10.
//

import SwiftUI
import SwiftData

//MARK: Persistent Class
@Model
final class UserDefinedGoal: Identifiable {
 //   @Attribute(.unique) var id: UUID
    var goalActivity: ActivityTypeEnum = ActivityTypeEnum.running
    var title: String = ""
    var goalDescription: String = ""
    var goalDeadline: Date = Date()
    var isCompleted: Bool = false


    var secondsRemaining: TimeInterval { goalDeadline.timeIntervalSinceNow }
    var daysRemaining: Int { Int(ceil(secondsRemaining / 86_400)) }

    init(
    //    id: UUID = UUID(),
        goalActivity: ActivityTypeEnum = .running,
        title: String = "",
        description: String = "",
        goalDeadline: Date = Date(),
        isCompleted: Bool = false,
    ) {
    //    self.id = id
        self.goalActivity = goalActivity
        self.title = title
        self.goalDescription = description
        self.goalDeadline = goalDeadline
        self.isCompleted = isCompleted
    }
}

//MARK: Data Transfer Object
struct UserDefinedGoalDTO: Codable {
    var id: UUID
    var goalActivity: ActivityTypeEnum = ActivityTypeEnum.running
    var title: String = ""
    var description: String = ""
    var goalDeadline: Date = Date()
    var isCompleted: Bool = false

}
