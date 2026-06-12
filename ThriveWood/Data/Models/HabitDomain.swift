//
//  HabitDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var iconSystemName: String = "leaf.fill"
    var colorRaw: String = ""
    var pointsRaw: Int = 0
    var frequencyRaw: String = ""
    var activeWeekdays: [Int] = []
    var reminderTime: Date?
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var archivedAt: Date?

    var trackingModeRaw: String = ""
    var targetValue: Double = 1
    var incrementValue: Double = 1
    var unitLabel: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]? = []

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        iconSystemName: String = "leaf.fill",
        color: HabitColor = .green,
        points: HabitPoints = .low,
        frequency: HabitFrequency = .daily,
        activeWeekdays: [Weekday] = Weekday.allCases,
        reminderTime: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        archivedAt: Date? = nil,
        trackingMode: HabitTrackingMode = .simple,
        targetValue: Double = 1,
        incrementValue: Double = 1,
        unitLabel: String = ""
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.pointsRaw = points.rawValue
        self.frequencyRaw = frequency.rawValue
        self.activeWeekdays = activeWeekdays.map(\.rawValue)
        self.reminderTime = reminderTime
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        self.trackingModeRaw = trackingMode.rawValue
        self.targetValue = targetValue
        self.incrementValue = incrementValue
        self.unitLabel = unitLabel
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .green }
        set { colorRaw = newValue.rawValue }
    }
    var points: HabitPoints {
        get { HabitPoints(rawValue: pointsRaw) ?? .low }
        set { pointsRaw = newValue.rawValue }
    }
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }
    var trackingMode: HabitTrackingMode {
        get { HabitTrackingMode(rawValue: trackingModeRaw) ?? .simple }
        set { trackingModeRaw = newValue.rawValue }
    }
    var isArchived: Bool { archivedAt != nil }
    var isMeasurable: Bool { trackingMode == .measurable }
}

@Model
final class HabitCompletion {
    var id: UUID = UUID()
    var day: Date = Date()
    var completedAt: Date = Date()
    var pointsAwarded: Int = 0
    var note: String?

    var currentValue: Double = 0

    var habit: Habit?

    init(
        id: UUID = UUID(),
        habit: Habit,
        day: Date = Calendar.current.startOfDay(for: .now),
        completedAt: Date = .now,
        pointsAwarded: Int? = nil,
        note: String? = nil,
        currentValue: Double? = nil
    ) {
        self.id = id
        self.habit = habit
        self.day = Calendar.app.startOfDay(day)
        self.completedAt = completedAt
        self.note = note

        switch habit.trackingMode {
        case .simple:
            self.currentValue = currentValue ?? habit.targetValue
            self.pointsAwarded = pointsAwarded ?? habit.points.rawValue
        case .measurable:
            self.currentValue = currentValue ?? 0
            self.pointsAwarded = pointsAwarded ?? 0
        }
    }

    var progress: Double {
        guard let habit, habit.targetValue > 0 else { return 1 }
        return min(1.0, currentValue / habit.targetValue)
    }

    var isComplete: Bool { progress >= 1.0 }

    func recalculatePoints() {
        guard let habit else { return }
        switch habit.trackingMode {
        case .simple:
            pointsAwarded = habit.points.rawValue
        case .measurable:
            let ratio = min(1.0, currentValue / max(1, habit.targetValue))
            pointsAwarded = Int(floor(ratio * Double(habit.points.rawValue)))
        }
    }
}
