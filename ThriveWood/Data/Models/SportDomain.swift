//
//  SportDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var details: String
    var categoryRaw: String
    var primaryMuscleGroupsRaw: [String]
    var secondaryMuscleGroupsRaw: [String]
    var iconSystemName: String
    /// `true` für vorinstallierte Stock-Übungen.
    var isBuiltIn: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        category: ExerciseCategory = .strength,
        primaryMuscleGroups: [MuscleGroup] = [],
        secondaryMuscleGroups: [MuscleGroup] = [],
        iconSystemName: String = "dumbbell.fill",
        isBuiltIn: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.categoryRaw = category.rawValue
        self.primaryMuscleGroupsRaw = primaryMuscleGroups.map(\.rawValue)
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroups.map(\.rawValue)
        self.iconSystemName = iconSystemName
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }
    var primaryMuscleGroups: [MuscleGroup] {
        get { primaryMuscleGroupsRaw.compactMap(MuscleGroup.init(rawValue:)) }
        set { primaryMuscleGroupsRaw = newValue.map(\.rawValue) }
    }
    var secondaryMuscleGroups: [MuscleGroup] {
        get { secondaryMuscleGroupsRaw.compactMap(MuscleGroup.init(rawValue:)) }
        set { secondaryMuscleGroupsRaw = newValue.map(\.rawValue) }
    }
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var details: String
    var colorRaw: String
    var estimatedDurationMinutes: Int
    var sortOrder: Int
    var createdAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.workout)
    var sessions: [WorkoutSession] = []

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        color: HabitColor = .blue,
        estimatedDurationMinutes: Int = 45,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.colorRaw = color.rawValue
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }
    var isArchived: Bool { archivedAt != nil }
}

/// Plan-Slot: Exercise innerhalb eines Workouts mit Soll-Vorgaben.
@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetSets: Int
    var targetReps: Int?
    var targetWeight: Double?
    var targetDurationSeconds: Int?
    var restSeconds: Int
    var notes: String

    var workout: Workout?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        workout: Workout? = nil,
        targetSets: Int = 3,
        targetReps: Int? = 10,
        targetWeight: Double? = nil,
        targetDurationSeconds: Int? = nil,
        restSeconds: Int = 90,
        notes: String = ""
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.workout = workout
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetDurationSeconds = targetDurationSeconds
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

/// Tatsächlich durchgeführte Trainingseinheit.
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var perceivedExertion: Int?   // RPE 1–10
    var notes: String
    var weightUnitRaw: String

    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var sets: [SetEntry] = []

    init(
        id: UUID = UUID(),
        workout: Workout? = nil,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        perceivedExertion: Int? = nil,
        notes: String = "",
        weightUnit: WeightUnit = .kilograms
    ) {
        self.id = id
        self.workout = workout
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.perceivedExertion = perceivedExertion
        self.notes = notes
        self.weightUnitRaw = weightUnit.rawValue
    }

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kilograms }
        set { weightUnitRaw = newValue.rawValue }
    }
    var durationSeconds: Int? {
        guard let endedAt else { return nil }
        return Int(endedAt.timeIntervalSince(startedAt))
    }
}

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var order: Int
    var reps: Int?
    var weight: Double?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var isWarmup: Bool
    var isCompleted: Bool
    var completedAt: Date?

    var session: WorkoutSession?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        session: WorkoutSession? = nil,
        reps: Int? = nil,
        weight: Double? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.session = session
        self.reps = reps
        self.weight = weight
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
