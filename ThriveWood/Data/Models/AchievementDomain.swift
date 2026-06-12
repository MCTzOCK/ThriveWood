//
//  AchievementDomain.swift
//  ThriveWood
//

import Foundation
import SwiftData

@Model
final class AchievementRecord {
    var id: UUID = UUID()
    var definitionRaw: String = ""
    var unlockedAt: Date = Date()

    init(definition: AchievementDefinition, unlockedAt: Date = .now) {
        self.id = UUID()
        self.definitionRaw = definition.rawValue
        self.unlockedAt = unlockedAt
    }

    var definition: AchievementDefinition {
        get { AchievementDefinition(rawValue: definitionRaw) ?? .firstHabit }
        set { definitionRaw = newValue.rawValue }
    }
}
