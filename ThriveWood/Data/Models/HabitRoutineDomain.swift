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
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        iconSystemName: String = "sun.max.fill",
        color: HabitColor = .orange,
        habitIDs: [UUID] = [],
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.habitIDs = habitIDs
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .orange }
        set { colorRaw = newValue.rawValue }
    }
}
