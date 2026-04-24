//
//  UserProfile.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var preferredWeightUnitRaw: String
    var weekStartsOnRaw: Int           // Weekday.rawValue
    var dailyPointGoal: Int
    var enableHapticFeedback: Bool
    var enableNotifications: Bool
    var onboardingCompletedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String = "",
        preferredWeightUnit: WeightUnit = .kilograms,
        weekStartsOn: Weekday = .monday,
        dailyPointGoal: Int = 5,
        enableHapticFeedback: Bool = true,
        enableNotifications: Bool = true,
        onboardingCompletedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.preferredWeightUnitRaw = preferredWeightUnit.rawValue
        self.weekStartsOnRaw = weekStartsOn.rawValue
        self.dailyPointGoal = dailyPointGoal
        self.enableHapticFeedback = enableHapticFeedback
        self.enableNotifications = enableNotifications
        self.onboardingCompletedAt = onboardingCompletedAt
        self.createdAt = createdAt
    }

    var preferredWeightUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kilograms }
        set { preferredWeightUnitRaw = newValue.rawValue }
    }
    var weekStartsOn: Weekday {
        get { Weekday(rawValue: weekStartsOnRaw) ?? .monday }
        set { weekStartsOnRaw = newValue.rawValue }
    }
}
