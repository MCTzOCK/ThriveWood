//
//  HabitRoutineDomain.swift
//  ThriveWood
//
//  Additive @Model für "Routinen" — geordnete Abläufe von Habit-IDs.
//  Keine @Relationship zum Habit; IDs werden zur Laufzeit per Repo-Join
//  aufgelöst (reine ID-Liste, wie bei HabitGroup).
//

import Foundation
import SwiftData

@Model
final class HabitRoutine {
    @Attribute(.unique) var id: UUID
    var title: String
    var iconSystemName: String
    var colorRaw: String
    /// Geordnete Liste der Habit-IDs in dieser Routine.
    var habitIDs: [UUID]
    /// Optionaler Routine-Zielwert pro messbarem Habit (UUID -> Wert).
    /// Fehlt der Eintrag oder ist 0, gilt das Tagesziel des Habits.
    /// Wird nicht geordnet — `habitIDs` ist die Quell-Wahrheit für die Reihenfolge.
    var habitTargets: [UUID: Double] = [:]
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        iconSystemName: String = "sun.max.fill",
        color: HabitColor = .orange,
        habitIDs: [UUID] = [],
        habitTargets: [UUID: Double] = [:],
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.habitIDs = habitIDs
        self.habitTargets = habitTargets
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .orange }
        set { colorRaw = newValue.rawValue }
    }
}
