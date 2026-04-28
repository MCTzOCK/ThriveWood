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
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String
    var iconSystemName: String
    var colorRaw: String
    var pointsRaw: Int
    var frequencyRaw: String
    var activeWeekdays: [Int]
    var reminderTime: Date?
    var sortOrder: Int
    var createdAt: Date
    var archivedAt: Date?

    // MARK: - Tracking-Modus
    var trackingModeRaw: String
    /// Zielwert pro Tag (nur bei .measurable, z.B. 2000 für 2000ml)
    var targetValue: Double
    /// Schrittgröße pro Tap (z.B. 200 für 200ml)
    var incrementValue: Double
    /// Einheiten-Label (z.B. "ml", "Seiten", "min")
    var unitLabel: String

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

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

    // MARK: - Typed Accessors

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
    @Attribute(.unique) var id: UUID
    var day: Date
    var completedAt: Date
    var pointsAwarded: Int
    var note: String?

    /// Aktueller Fortschritt bei messbaren Habits (z.B. 1400 von 2000ml).
    /// Bei einfachen Habits immer == targetValue des Habits (also 1).
    var currentValue: Double

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

    /// Fortschritt 0...1
    var progress: Double {
        guard let habit, habit.targetValue > 0 else { return 1 }
        return min(1.0, currentValue / habit.targetValue)
    }

    /// Ist der Zielwert erreicht?
    var isComplete: Bool { progress >= 1.0 }

    /// Berechnet die anteiligen Punkte basierend auf dem Fortschritt.
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
