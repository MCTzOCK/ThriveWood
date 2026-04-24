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
    /// Wenn `frequency == .custom`: aktive Wochentage (Weekday.rawValue).
    var activeWeekdays: [Int]
    var reminderTime: Date?
    var sortOrder: Int
    var createdAt: Date
    var archivedAt: Date?

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
        archivedAt: Date? = nil
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
    var isArchived: Bool { archivedAt != nil }
}

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    /// Normalisiert auf Tagesanfang (lokale Zeitzone) zur Deduplizierung.
    var day: Date
    var completedAt: Date
    /// Gespeichert zum Zeitpunkt des Abhakens → historisch korrekt,
    /// auch wenn der Habit später auf andere Punkte geändert wird.
    var pointsAwarded: Int
    var note: String?

    var habit: Habit?

    init(
        id: UUID = UUID(),
        habit: Habit,
        day: Date = Calendar.current.startOfDay(for: .now),
        completedAt: Date = .now,
        pointsAwarded: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.habit = habit
        self.day = Calendar.current.startOfDay(for: day)
        self.completedAt = completedAt
        self.pointsAwarded = pointsAwarded ?? habit.points.rawValue
        self.note = note
    }
}
