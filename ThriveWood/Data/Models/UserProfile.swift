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
    var id: UUID = UUID()
    var displayName: String = ""
    var preferredWeightUnitRaw: String = "kg"
    var weekStartsOnRaw: Int = 2
    var dailyPointGoal: Int = 5
    var enableHapticFeedback: Bool = true
    var enableNotifications: Bool = true
    var onboardingCompletedAt: Date?
    var createdAt: Date = Date()
    var appearanceRaw: String = "system"
    var accentThemeRaw: String = "forest"
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Date()
    var quietHoursEnd: Date = Date()
    var defaultRestSeconds: Int = 90
    var iCloudSyncEnabled: Bool = true
    var nutritionGoalsData: Data?

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
        self.appearanceRaw = AppAppearance.system.rawValue
        self.accentThemeRaw = AccentTheme.forest.rawValue
        self.quietHoursEnabled = false
        self.quietHoursStart = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now
        self.quietHoursEnd   = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: .now) ?? .now
        self.defaultRestSeconds = 90
        self.iCloudSyncEnabled = true

    }

    var preferredWeightUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kilograms }
        set { preferredWeightUnitRaw = newValue.rawValue }
    }
    var weekStartsOn: Weekday {
        get { Weekday(rawValue: weekStartsOnRaw) ?? .monday }
        set { weekStartsOnRaw = newValue.rawValue }
    }
    
    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
    var accentTheme: AccentTheme {
        get { AccentTheme(rawValue: accentThemeRaw) ?? .forest }
        set { accentThemeRaw = newValue.rawValue }
    }
    
    var nutritionGoals: NutritionGoals {
        get {
            guard let data = nutritionGoalsData,
                  let goals = try? JSONDecoder().decode(NutritionGoals.self, from: data)
            else { return .default }
            return goals
        }
        set {
            nutritionGoalsData = try? JSONEncoder().encode(newValue)
        }
    }

}
