//
//  RotationPlanDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import Foundation
import SwiftData

/// Fortlaufender Trainingsplan mit Rotations-Logik (A/B/C-Sequenz).
/// Workouts rotieren kontinuierlich, unabhaengig von festen Wochentagen.
/// Beispiel: 3 Workouts A, B, C -> Woche 1: A(Mo), B(Mi), C(Fr)
///          Woche 2: A(Sa), B(Mo), C(Mi) usw.
@Model
final class RotationTrainingsPlan {
    @Attribute(.unique) var id: UUID

    var name: String
    var details: String
    var createdAt: Date
    var isActive: Bool
    var color: String

    /// Aktueller Index in der Workout-Sequenz (0-basiert).
    /// Gibt an, welches Workout als naechstes ansteht.
    var currentWorkoutIndex: Int

    /// Gesamtanzahl abgeschlossener Rotationen.
    var completedRotations: Int

    @Relationship(deleteRule: .cascade, inverse: \RotationPlanEntry.plan)
    var entries: [RotationPlanEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        createdAt: Date = .now,
        isActive: Bool = false,
        color: String = "#4CAF50",
        currentWorkoutIndex: Int = 0,
        completedRotations: Int = 0
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.createdAt = createdAt
        self.isActive = isActive
        self.color = color
        self.currentWorkoutIndex = currentWorkoutIndex
        self.completedRotations = completedRotations
    }

    /// Sortierte Entries nach Reihenfolge.
    var sortedEntries: [RotationPlanEntry] {
        entries.sorted { $0.order < $1.order }
    }

    /// Das naechste Workout in der Rotation.
    var nextWorkout: Workout? {
        guard !sortedEntries.isEmpty else { return nil }
        let idx = currentWorkoutIndex % sortedEntries.count
        return sortedEntries[safe: idx]?.workout
    }

    /// Anzahl der Workouts in der Sequenz.
    var sequenceCount: Int { sortedEntries.count }

    /// Label fuer das naechste Workout, z.B. "A", "B", "C".
    var nextWorkoutLabel: String {
        guard !sortedEntries.isEmpty else { return "–" }
        let idx = currentWorkoutIndex % sortedEntries.count
        return sortedEntries[safe: idx]?.label ?? "Workout \(idx + 1)"
    }
}

/// Ein Workout-Slot innerhalb einer RotationTrainingsPlan-Sequenz.
@Model
final class RotationPlanEntry {
    @Attribute(.unique) var id: UUID

    var order: Int
    var label: String

    var plan: RotationTrainingsPlan?
    var workout: Workout?

    init(
        id: UUID = UUID(),
        order: Int,
        label: String = "",
        plan: RotationTrainingsPlan? = nil,
        workout: Workout? = nil
    ) {
        self.id = id
        self.order = order
        self.label = label
        self.plan = plan
        self.workout = workout
    }
}
