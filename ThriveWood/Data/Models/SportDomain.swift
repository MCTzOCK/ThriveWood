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
    var trackingTypeRaw: String
    var primaryMuscleGroupsRaw: [String]
    var secondaryMuscleGroupsRaw: [String]
    var iconSystemName: String
    var isBuiltIn: Bool
    var createdAt: Date
    
    var images: [String] = []
    var instructions: [String] = []

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        category: ExerciseCategory = .strength,
        trackingType: ExerciseTrackingType = .repsWeight,
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
        self.trackingTypeRaw = trackingType.rawValue
        self.primaryMuscleGroupsRaw = primaryMuscleGroups.map(\.rawValue)
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroups.map(\.rawValue)
        self.iconSystemName = iconSystemName
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }
    
    
    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        category: ExerciseCategory = .strength,
        trackingType: ExerciseTrackingType = .repsWeight,
        primaryMuscleGroups: [MuscleGroup] = [],
        secondaryMuscleGroups: [MuscleGroup] = [],
        iconSystemName: String = "dumbbell.fill",
        isBuiltIn: Bool = false,
        createdAt: Date = .now,
        images: [String],
        instructions: [String]
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.categoryRaw = category.rawValue
        self.trackingTypeRaw = trackingType.rawValue
        self.primaryMuscleGroupsRaw = primaryMuscleGroups.map(\.rawValue)
        self.secondaryMuscleGroupsRaw = secondaryMuscleGroups.map(\.rawValue)
        self.iconSystemName = iconSystemName
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.images = images
        self.instructions = instructions
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }
    var trackingType: ExerciseTrackingType {
        get { ExerciseTrackingType(rawValue: trackingTypeRaw) ?? .repsWeight }
        set { trackingTypeRaw = newValue.rawValue }
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
    var targetDistanceMeters: Double?
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
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        targetDurationSeconds: Int? = nil,
        targetDistanceMeters: Double? = nil,
        restSeconds: Int = 90,
        notes: String = ""
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.workout = workout
        self.targetSets = targetSets
        self.restSeconds = restSeconds
        self.notes = notes

        // Sinnvolle Defaults je nach Tracking-Typ
        switch exercise.trackingType {
        case .repsWeight:
            self.targetReps = targetReps ?? 10
            self.targetWeight = targetWeight
            self.targetDurationSeconds = nil
            self.targetDistanceMeters = nil
        case .reps:
            self.targetReps = targetReps ?? 12
            self.targetWeight = nil
            self.targetDurationSeconds = nil
            self.targetDistanceMeters = nil
        case .duration:
            self.targetReps = nil
            self.targetWeight = nil
            self.targetDurationSeconds = targetDurationSeconds ?? 60
            self.targetDistanceMeters = nil
        case .distanceDuration:
            self.targetReps = nil
            self.targetWeight = nil
            self.targetDurationSeconds = targetDurationSeconds ?? 1200
            self.targetDistanceMeters = targetDistanceMeters ?? 3000
        }
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

    /// Volumen-Berechnung je nach Tracking-Typ.
    /// - Strength: kg × reps
    /// - Reps: reps (als Pseudo-Volumen)
    /// - Duration: Sekunden
    /// - Distance/Duration: Meter
    var volumeValue: Double {
        guard let type = exercise?.trackingType else { return 0 }
        switch type {
        case .repsWeight:
            return (weight ?? 0) * Double(reps ?? 0)
        case .reps:
            return Double(reps ?? 0)
        case .duration:
            return Double(durationSeconds ?? 0)
        case .distanceDuration:
            return distanceMeters ?? 0
        }
    }

    /// Kompakte Beschreibung für Zusammenfassungen.
    var summaryText: String {
        guard let type = exercise?.trackingType else { return "" }
        switch type {
        case .repsWeight:
            let r = reps ?? 0
            let w = weight ?? 0
            return w > 0 ? "\(r) × \(w.clean) kg" : "\(r) Reps"
        case .reps:
            return "\(reps ?? 0) Reps"
        case .duration:
            return formatDuration(durationSeconds ?? 0)
        case .distanceDuration:
            let d = (distanceMeters ?? 0) / 1000
            return String(format: "%.2f km · %@", d, formatDuration(durationSeconds ?? 0))
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

extension Double {
    /// Entfernt unnötige Nachkommastellen ("70.0" → "70", "70.5" → "70.5")
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}


@Model
final class TrainingsPlan {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var details: String
    var createdAt: Date
    var isActive: Bool  // Nur ein Plan kann aktiv sein
    var color: String   // Hex-String für UI-Farbe
    
    @Relationship(deleteRule: .cascade, inverse: \TrainingsPlanDay.plan)
    var days: [TrainingsPlanDay]
    
    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        createdAt: Date = .now,
        isActive: Bool = false,
        color: String = "#4CAF50",
        days: [TrainingsPlanDay] = []
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.createdAt = createdAt
        self.isActive = isActive
        self.color = color
        self.days = days
    }
    
    /// Sortierte Tage (Montag bis Sonntag)
    var sortedDays: [TrainingsPlanDay] {
        days.sorted { $0.weekday.rawValue < $1.weekday.rawValue }
    }
    
    /// Workout für einen bestimmten Wochentag
    func workout(for weekday: TPWeekday) -> Workout? {
        days.first { $0.weekday == weekday }?.workout
    }
    
    /// Anzahl der Trainingstage pro Woche
    var trainingDaysPerWeek: Int {
        days.filter { $0.workout != nil }.count
    }
    
    /// Gesamtanzahl Übungen im Plan
    var totalExercises: Int {
        days.compactMap(\.workout).reduce(0) { $0 + $1.exercises.count }
    }
}

// MARK: - TrainingsPlanDay

@Model
final class TrainingsPlanDay {
    @Attribute(.unique) var id: UUID
    
    var weekday: TPWeekday
    var isRestDay: Bool
    var notes: String
    
    var plan: TrainingsPlan?
    var workout: Workout?
    
    init(
        id: UUID = UUID(),
        weekday: TPWeekday,
        isRestDay: Bool = false,
        notes: String = "",
        plan: TrainingsPlan? = nil,
        workout: Workout? = nil
    ) {
        self.id = id
        self.weekday = weekday
        self.isRestDay = isRestDay
        self.notes = notes
        self.plan = plan
        self.workout = workout
    }
    
    var displayName: String {
        if isRestDay {
            return "Rest Day"
        } else if let workout {
            return workout.name
        } else {
            return "Rest Day"
        }
    }
}

// MARK: - Weekday Enum

enum TPWeekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var id: Int { rawValue }
    
    var label: String {
        switch self {
        case .monday: "Montag"
        case .tuesday: "Dienstag"
        case .wednesday: "Mittwoch"
        case .thursday: "Donnerstag"
        case .friday: "Freitag"
        case .saturday: "Samstag"
        case .sunday: "Sonntag"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .monday: "Mo"
        case .tuesday: "Di"
        case .wednesday: "Mi"
        case .thursday: "Do"
        case .friday: "Fr"
        case .saturday: "Sa"
        case .sunday: "So"
        }
    }
    
    var icon: String {
        switch self {
        case .monday: "1.circle.fill"
        case .tuesday: "2.circle.fill"
        case .wednesday: "3.circle.fill"
        case .thursday: "4.circle.fill"
        case .friday: "5.circle.fill"
        case .saturday: "6.circle.fill"
        case .sunday: "7.circle.fill"
        }
    }
    
    static func < (lhs: TPWeekday, rhs: TPWeekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// Aktueller Wochentag
    static var today: TPWeekday {
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: .now)
        // Calendar.weekday: 1 = Sonntag, 2 = Montag, ...
        // Unsere Enum: 1 = Montag, 7 = Sonntag
        let adjusted = weekdayInt == 1 ? 7 : weekdayInt - 1
        return TPWeekday(rawValue: adjusted) ?? .monday
    }
}
