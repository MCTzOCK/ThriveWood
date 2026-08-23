//
//  UnioExportModels.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.08.26.
//
//  Stabile Export-DTOs und Unio-Schemas für alle analytisch relevanten
//  Entitäten von ThriveWood. Die internen SwiftData-Modelle werden nicht
//  direkt exportiert (siehe Unio/UnioKit.md).
//

import Foundation

// MARK: - Wald

nonisolated struct ForestExport: Codable, Sendable {
    let id: String
    let name: String
    let spentPoints: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "forests",
        entityType: "forest",
        title: "Wälder",
        description: "Alle angelegten Wälder",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["spentPoints"],
                title: "Ausgegebene Punkte",
                valueType: .integer,
                semanticType: UnioSemanticType.count,
                unit: "point"
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

nonisolated struct TreeExport: Codable, Sendable {
    let id: String
    let forestID: String?
    let species: String
    let growthPoints: Int
    let plantedAt: Date
    let nickname: String?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "trees",
        entityType: "tree",
        title: "Bäume",
        description: "Alle gepflanzten Bäume und ihr Wachstum",
        primaryKeyPath: ["id"],
        createdAtPath: ["plantedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["species"],
                title: "Baumart",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["growthPoints"],
                title: "Wachstumspunkte",
                valueType: .integer,
                semanticType: UnioSemanticType.count,
                unit: "point"
            ),
            UnioFieldDefinition(
                path: ["plantedAt"],
                title: "Gepflanzt am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["nickname"],
                title: "Spitzname",
                valueType: .string,
                semanticType: UnioSemanticType.name,
                isSensitive: true
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["forestID"],
                relationType: "plantedInForest",
                targetEntityType: "forest",
                targetDatasetID: "forests"
            )
        ]
    )
}

// MARK: - Habits

nonisolated struct HabitExport: Codable, Sendable {
    let id: String
    let title: String
    let details: String
    let points: Int
    let frequency: String
    let activeWeekdays: [Int]
    let trackingMode: String
    let targetValue: Double
    let incrementValue: Double
    let unitLabel: String
    let createdAt: Date
    let archivedAt: Date?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "habits",
        entityType: "habit",
        title: "Habits",
        description: "Alle angelegten Gewohnheiten",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["title"],
                title: "Titel",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["points"],
                title: "Punkte pro Erledigung",
                valueType: .integer,
                semanticType: UnioSemanticType.count,
                unit: "point"
            ),
            UnioFieldDefinition(
                path: ["frequency"],
                title: "Frequenz",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["activeWeekdays"],
                title: "Aktive Wochentage",
                valueType: .array,
                description: "ISO-8601-Wochentagsnummern (1 = Sonntag … 7 = Samstag)"
            ),
            UnioFieldDefinition(
                path: ["trackingMode"],
                title: "Tracking-Modus",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["targetValue"],
                title: "Tagesziel",
                valueType: .number,
                semanticType: "habitTargetValue",
                description: "Zielwert pro Tag bei messbaren Habits"
            ),
            UnioFieldDefinition(
                path: ["incrementValue"],
                title: "Schrittgröße",
                valueType: .number
            ),
            UnioFieldDefinition(
                path: ["unitLabel"],
                title: "Einheit",
                valueType: .string,
                description: "Einheiten-Label des Zielwerts, z.B. ml, Seiten oder min"
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            ),
            UnioFieldDefinition(
                path: ["archivedAt"],
                title: "Archiviert am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            )
        ]
    )
}

nonisolated struct HabitCompletionExport: Codable, Sendable {
    let id: String
    let habitID: String?
    let day: Date
    let completedAt: Date
    let pointsAwarded: Int
    let currentValue: Double
    let note: String?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "habit-completions",
        entityType: "habitCompletion",
        title: "Habit-Erledigungen",
        description: "Alle historischen Erledigungen und Fortschritte von Habits",
        primaryKeyPath: ["id"],
        createdAtPath: ["completedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["day"],
                title: "Tag",
                valueType: .date,
                semanticType: "day",
                description: "Zugeordneter Kalendertag (Tagesbeginn)"
            ),
            UnioFieldDefinition(
                path: ["completedAt"],
                title: "Erledigt am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["pointsAwarded"],
                title: "Punkte",
                valueType: .integer,
                semanticType: UnioSemanticType.count,
                unit: "point"
            ),
            UnioFieldDefinition(
                path: ["currentValue"],
                title: "Fortschrittswert",
                valueType: .number,
                semanticType: "habitProgressValue",
                description: "Aktueller Messwert bei messbaren Habits"
            ),
            UnioFieldDefinition(
                path: ["note"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["habitID"],
                relationType: "completesHabit",
                targetEntityType: "habit",
                targetDatasetID: "habits"
            )
        ]
    )
}

nonisolated struct HabitGroupExport: Codable, Sendable {
    let id: String
    let title: String
    let habitIDs: [String]
    let sortOrder: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "habit-groups",
        entityType: "habitGroup",
        title: "Habit-Gruppen",
        description: "Gruppen zur Ordnung von Habits",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["title"],
                title: "Titel",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["habitIDs"],
                relationType: "containsHabit",
                targetEntityType: "habit",
                targetDatasetID: "habits",
                cardinality: .many
            )
        ]
    )
}

nonisolated struct HabitRoutineExport: Codable, Sendable {
    let id: String
    let title: String
    let habitIDs: [String]
    let sortOrder: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "habit-routines",
        entityType: "habitRoutine",
        title: "Habit-Routinen",
        description: "Geordnete Abläufe von Habits",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["title"],
                title: "Titel",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["habitIDs"],
                relationType: "containsHabit",
                targetEntityType: "habit",
                targetDatasetID: "habits",
                cardinality: .many
            )
        ]
    )
}

// MARK: - Sport

nonisolated struct ExerciseExport: Codable, Sendable {
    let id: String
    let name: String
    let details: String
    let category: String
    let trackingType: String
    let primaryMuscleGroups: [String]
    let secondaryMuscleGroups: [String]
    let isBuiltIn: Bool
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "exercises",
        entityType: "exercise",
        title: "Übungen",
        description: "Alle verfügbaren Übungen inklusive Muskelgruppen",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["category"],
                title: "Kategorie",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["trackingType"],
                title: "Tracking-Typ",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["primaryMuscleGroups"],
                title: "Primäre Muskelgruppen",
                valueType: .array
            ),
            UnioFieldDefinition(
                path: ["secondaryMuscleGroups"],
                title: "Sekundäre Muskelgruppen",
                valueType: .array
            ),
            UnioFieldDefinition(
                path: ["isBuiltIn"],
                title: "Vordefiniert",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

nonisolated struct WorkoutExport: Codable, Sendable {
    let id: String
    let name: String
    let details: String
    let estimatedDurationMinutes: Int
    let sortOrder: Int
    let createdAt: Date
    let archivedAt: Date?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "workouts",
        entityType: "workout",
        title: "Workouts",
        description: "Alle definierten Workout-Vorlagen",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["estimatedDurationMinutes"],
                title: "Geschätzte Dauer",
                valueType: .integer,
                semanticType: UnioSemanticType.duration,
                unit: "minute"
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            ),
            UnioFieldDefinition(
                path: ["archivedAt"],
                title: "Archiviert am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            )
        ]
    )
}

nonisolated struct WorkoutExerciseExport: Codable, Sendable {
    let id: String
    let workoutID: String?
    let exerciseID: String?
    let order: Int
    let targetSets: Int
    let targetReps: Int?
    let targetWeight: Double?
    let targetDurationSeconds: Int?
    let targetDistanceMeters: Double?
    let restSeconds: Int
    let notes: String
    let supersetGroup: Int?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "workout-exercises",
        entityType: "workoutExercise",
        title: "Workout-Übungen",
        description: "Plan-Slots: Übungen innerhalb eines Workouts mit Soll-Vorgaben",
        primaryKeyPath: ["id"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["order"],
                title: "Reihenfolge",
                valueType: .integer
            ),
            UnioFieldDefinition(
                path: ["targetSets"],
                title: "Soll-Sätze",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["targetReps"],
                title: "Soll-Wiederholungen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["targetWeight"],
                title: "Soll-Gewicht",
                valueType: .number,
                semanticType: "weight",
                unit: "kilogram"
            ),
            UnioFieldDefinition(
                path: ["targetDurationSeconds"],
                title: "Soll-Dauer",
                valueType: .integer,
                semanticType: UnioSemanticType.duration,
                unit: "second"
            ),
            UnioFieldDefinition(
                path: ["targetDistanceMeters"],
                title: "Soll-Distanz",
                valueType: .number,
                semanticType: UnioSemanticType.distance,
                unit: "meter"
            ),
            UnioFieldDefinition(
                path: ["restSeconds"],
                title: "Pause",
                valueType: .integer,
                semanticType: UnioSemanticType.duration,
                unit: "second"
            ),
            UnioFieldDefinition(
                path: ["notes"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["supersetGroup"],
                title: "Satz-Gruppe",
                valueType: .integer,
                description: "Superset-Gruppierung"
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["workoutID"],
                relationType: "partOfWorkout",
                targetEntityType: "workout",
                targetDatasetID: "workouts"
            ),
            UnioRelationDefinition(
                path: ["exerciseID"],
                relationType: "plannedExercise",
                targetEntityType: "exercise",
                targetDatasetID: "exercises"
            )
        ]
    )
}

nonisolated struct WorkoutSessionExport: Codable, Sendable {
    let id: String
    let workoutID: String?
    let startedAt: Date
    let endedAt: Date?
    let perceivedExertion: Int?
    let notes: String
    let weightUnit: String

    static let unioSchema = UnioDatasetSchema(
        datasetID: "workout-sessions",
        entityType: "workoutSession",
        title: "Trainingseinheiten",
        description: "Alle tatsächlich durchgeführten Trainingseinheiten",
        primaryKeyPath: ["id"],
        createdAtPath: ["startedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["startedAt"],
                title: "Beginn",
                valueType: .date,
                semanticType: UnioSemanticType.startTime
            ),
            UnioFieldDefinition(
                path: ["endedAt"],
                title: "Ende",
                valueType: .date,
                semanticType: UnioSemanticType.endTime
            ),
            UnioFieldDefinition(
                path: ["perceivedExertion"],
                title: "Wahrgenommene Anstrengung",
                valueType: .integer,
                semanticType: "perceivedExertion",
                description: "RPE-Skala 1–10"
            ),
            UnioFieldDefinition(
                path: ["notes"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["weightUnit"],
                title: "Gewichtseinheit",
                valueType: .string
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["workoutID"],
                relationType: "performedWorkout",
                targetEntityType: "workout",
                targetDatasetID: "workouts"
            )
        ]
    )
}

nonisolated struct SetEntryExport: Codable, Sendable {
    let id: String
    let sessionID: String?
    let exerciseID: String?
    let order: Int
    let reps: Int?
    let weight: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let isWarmup: Bool
    let isCompleted: Bool
    let completedAt: Date?
    let assistedReps: Int?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "set-entries",
        entityType: "setEntry",
        title: "Sätze",
        description: "Alle geloggten Sätze mit Wiederholungen, Gewicht, Dauer und Distanz",
        primaryKeyPath: ["id"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["order"],
                title: "Reihenfolge",
                valueType: .integer
            ),
            UnioFieldDefinition(
                path: ["reps"],
                title: "Wiederholungen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["weight"],
                title: "Gewicht",
                valueType: .number,
                semanticType: "weight",
                unit: "kilogram"
            ),
            UnioFieldDefinition(
                path: ["durationSeconds"],
                title: "Dauer",
                valueType: .integer,
                semanticType: UnioSemanticType.duration,
                unit: "second"
            ),
            UnioFieldDefinition(
                path: ["distanceMeters"],
                title: "Distanz",
                valueType: .number,
                semanticType: UnioSemanticType.distance,
                unit: "meter"
            ),
            UnioFieldDefinition(
                path: ["isWarmup"],
                title: "Aufwärmsatz",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["isCompleted"],
                title: "Abgeschlossen",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["completedAt"],
                title: "Abgeschlossen am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["assistedReps"],
                title: "Assistierte Wiederholungen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["sessionID"],
                relationType: "partOfSession",
                targetEntityType: "workoutSession",
                targetDatasetID: "workout-sessions"
            ),
            UnioRelationDefinition(
                path: ["exerciseID"],
                relationType: "performedExercise",
                targetEntityType: "exercise",
                targetDatasetID: "exercises"
            )
        ]
    )
}

nonisolated struct TrainingsPlanExport: Codable, Sendable {
    let id: String
    let name: String
    let details: String
    let isActive: Bool
    let planType: String
    let currentRotationIndex: Int
    let completedRotations: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "trainings-plans",
        entityType: "trainingsPlan",
        title: "Trainingspläne",
        description: "Alle Trainingspläne (Wochentags- und Rotationspläne)",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["isActive"],
                title: "Aktiv",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["planType"],
                title: "Plantyp",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["currentRotationIndex"],
                title: "Aktueller Rotationsindex",
                valueType: .integer
            ),
            UnioFieldDefinition(
                path: ["completedRotations"],
                title: "Abgeschlossene Rotationen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

nonisolated struct TrainingsPlanDayExport: Codable, Sendable {
    let id: String
    let planID: String?
    let workoutID: String?
    let weekday: Int
    let isRestDay: Bool
    let notes: String
    let rotationOrder: Int
    let label: String

    static let unioSchema = UnioDatasetSchema(
        datasetID: "trainings-plan-days",
        entityType: "trainingsPlanDay",
        title: "Trainingsplan-Tage",
        description: "Tage und Rotations-Slots der Trainingspläne",
        primaryKeyPath: ["id"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["weekday"],
                title: "Wochentag",
                valueType: .integer,
                description: "1 = Montag … 7 = Sonntag"
            ),
            UnioFieldDefinition(
                path: ["isRestDay"],
                title: "Ruhetag",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["notes"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["rotationOrder"],
                title: "Rotationsreihenfolge",
                valueType: .integer
            ),
            UnioFieldDefinition(
                path: ["label"],
                title: "Rotations-Label",
                valueType: .string
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["planID"],
                relationType: "partOfPlan",
                targetEntityType: "trainingsPlan",
                targetDatasetID: "trainings-plans"
            ),
            UnioRelationDefinition(
                path: ["workoutID"],
                relationType: "plannedWorkout",
                targetEntityType: "workout",
                targetDatasetID: "workouts"
            )
        ]
    )
}

// MARK: - Ernährung

nonisolated struct FoodExport: Codable, Sendable {
    let id: String
    let name: String
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let sugarPer100g: Double
    let sodiumPer100g: Double
    let defaultServingSize: Double
    let servingUnit: String
    let category: String
    let isUserCreated: Bool
    let usageCount: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "foods",
        entityType: "food",
        title: "Lebensmittel",
        description: "Alle Lebensmittel mit Nährwerten pro 100 g",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["brand"],
                title: "Marke",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["barcode"],
                title: "Barcode",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["caloriesPer100g"],
                title: "Kalorien pro 100 g",
                valueType: .number,
                semanticType: "energy",
                unit: "kilocalorie",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["proteinPer100g"],
                title: "Protein pro 100 g",
                valueType: .number,
                semanticType: "protein",
                unit: "gram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["carbsPer100g"],
                title: "Kohlenhydrate pro 100 g",
                valueType: .number,
                semanticType: "carbohydrate",
                unit: "gram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["fatPer100g"],
                title: "Fett pro 100 g",
                valueType: .number,
                semanticType: "fat",
                unit: "gram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["fiberPer100g"],
                title: "Ballaststoffe pro 100 g",
                valueType: .number,
                semanticType: "fiber",
                unit: "gram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["sugarPer100g"],
                title: "Zucker pro 100 g",
                valueType: .number,
                semanticType: "sugar",
                unit: "gram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["sodiumPer100g"],
                title: "Natrium pro 100 g",
                valueType: .number,
                semanticType: "sodium",
                unit: "milligram",
                description: "Nährwert pro 100 g"
            ),
            UnioFieldDefinition(
                path: ["defaultServingSize"],
                title: "Standard-Portion",
                valueType: .number,
                semanticType: "servingSize",
                unit: "gram"
            ),
            UnioFieldDefinition(
                path: ["servingUnit"],
                title: "Portionseinheit",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["category"],
                title: "Kategorie",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["isUserCreated"],
                title: "Selbst erstellt",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["usageCount"],
                title: "Verwendungen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

nonisolated struct FoodEntryExport: Codable, Sendable {
    let id: String
    let foodID: String?
    let day: Date
    let mealType: String
    let servingAmount: Double
    let loggedAt: Date
    let note: String?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "food-entries",
        entityType: "foodEntry",
        title: "Ernährungseinträge",
        description: "Alle geloggten Mahlzeiten- und Lebensmittel-Einträge",
        primaryKeyPath: ["id"],
        createdAtPath: ["loggedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["day"],
                title: "Tag",
                valueType: .date,
                semanticType: "day",
                description: "Zugeordneter Kalendertag (Tagesbeginn)"
            ),
            UnioFieldDefinition(
                path: ["mealType"],
                title: "Mahlzeit",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["servingAmount"],
                title: "Menge",
                valueType: .number,
                semanticType: "servingSize",
                unit: "gram"
            ),
            UnioFieldDefinition(
                path: ["loggedAt"],
                title: "Erfasst am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["note"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["foodID"],
                relationType: "consumedFood",
                targetEntityType: "food",
                targetDatasetID: "foods"
            )
        ]
    )
}

nonisolated struct MealTemplateExport: Codable, Sendable {
    let id: String
    let name: String
    let usageCount: Int
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "meal-templates",
        entityType: "mealTemplate",
        title: "Mahlzeit-Vorlagen",
        description: "Gespeicherte Vorlagen für wiederkehrende Mahlzeiten",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.title
            ),
            UnioFieldDefinition(
                path: ["usageCount"],
                title: "Verwendungen",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

nonisolated struct MealTemplateItemExport: Codable, Sendable {
    let id: String
    let templateID: String?
    let foodID: String?
    let servingAmount: Double
    let sortOrder: Int

    static let unioSchema = UnioDatasetSchema(
        datasetID: "meal-template-items",
        entityType: "mealTemplateItem",
        title: "Mahlzeit-Vorlagen-Positionen",
        description: "Lebensmittel-Positionen der Mahlzeit-Vorlagen",
        primaryKeyPath: ["id"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["servingAmount"],
                title: "Menge",
                valueType: .number,
                semanticType: "servingSize",
                unit: "gram"
            ),
            UnioFieldDefinition(
                path: ["sortOrder"],
                title: "Reihenfolge",
                valueType: .integer
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["templateID"],
                relationType: "partOfTemplate",
                targetEntityType: "mealTemplate",
                targetDatasetID: "meal-templates"
            ),
            UnioRelationDefinition(
                path: ["foodID"],
                relationType: "containsFood",
                targetEntityType: "food",
                targetDatasetID: "foods"
            )
        ]
    )
}

nonisolated struct SupplementExport: Codable, Sendable {
    let id: String
    let name: String
    let dosage: String
    let details: String
    let frequency: String
    let activeWeekdays: [Int]
    let timesPerDay: Int
    let sortOrder: Int
    let createdAt: Date
    let archivedAt: Date?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "supplements",
        entityType: "supplement",
        title: "Supplemente",
        description: "Alle angelegten Supplemente und ihre Dosierung",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["dosage"],
                title: "Dosierung",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["frequency"],
                title: "Frequenz",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["activeWeekdays"],
                title: "Aktive Wochentage",
                valueType: .array,
                description: "ISO-8601-Wochentagsnummern (1 = Sonntag … 7 = Samstag)"
            ),
            UnioFieldDefinition(
                path: ["timesPerDay"],
                title: "Einnahmen pro Tag",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            ),
            UnioFieldDefinition(
                path: ["archivedAt"],
                title: "Archiviert am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            )
        ]
    )
}

nonisolated struct SupplementEntryExport: Codable, Sendable {
    let id: String
    let supplementID: String?
    let day: Date
    let doseNumber: Int
    let takenAt: Date
    let skipped: Bool

    static let unioSchema = UnioDatasetSchema(
        datasetID: "supplement-entries",
        entityType: "supplementEntry",
        title: "Supplement-Einnahmen",
        description: "Alle historischen Einnahmen und übersprungenen Dosen",
        primaryKeyPath: ["id"],
        createdAtPath: ["takenAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["day"],
                title: "Tag",
                valueType: .date,
                semanticType: "day",
                description: "Zugeordneter Kalendertag (Tagesbeginn)"
            ),
            UnioFieldDefinition(
                path: ["doseNumber"],
                title: "Einnahme-Nummer",
                valueType: .integer,
                semanticType: UnioSemanticType.count
            ),
            UnioFieldDefinition(
                path: ["takenAt"],
                title: "Eingenommen/Übersprungen am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["skipped"],
                title: "Übersprungen",
                valueType: .boolean
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["supplementID"],
                relationType: "takenSupplement",
                targetEntityType: "supplement",
                targetDatasetID: "supplements"
            )
        ]
    )
}

// MARK: - Körper & Wellness

nonisolated struct BodyMeasurementExport: Codable, Sendable {
    let id: String
    let date: Date
    let weightKg: Double?
    let bodyFatPercentage: Double?
    let muscleMassKg: Double?
    let waterPercentage: Double?
    let heightCm: Double?
    let chestCm: Double?
    let waistCm: Double?
    let hipCm: Double?
    let shoulderCm: Double?
    let neckCm: Double?
    let leftBicepCm: Double?
    let rightBicepCm: Double?
    let leftForearmCm: Double?
    let rightForearmCm: Double?
    let leftThighCm: Double?
    let rightThighCm: Double?
    let leftCalfCm: Double?
    let rightCalfCm: Double?
    let notes: String
    let tags: [String]?
    let energyLevel: Int?
    let onPump: Bool
    let weightUnit: String
    let measurementUnit: String

    static let unioSchema = UnioDatasetSchema(
        datasetID: "body-measurements",
        entityType: "bodyMeasurement",
        title: "Körpermessungen",
        description: "Alle Körperwerte, Umfänge und Messungen",
        primaryKeyPath: ["id"],
        createdAtPath: ["date"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["date"],
                title: "Datum",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["weightKg"],
                title: "Gewicht",
                valueType: .number,
                semanticType: "bodyWeight",
                unit: "kilogram"
            ),
            UnioFieldDefinition(
                path: ["bodyFatPercentage"],
                title: "Körperfettanteil",
                valueType: .number,
                semanticType: "bodyFatPercentage",
                unit: "percent"
            ),
            UnioFieldDefinition(
                path: ["muscleMassKg"],
                title: "Muskelmasse",
                valueType: .number,
                semanticType: "muscleMass",
                unit: "kilogram"
            ),
            UnioFieldDefinition(
                path: ["waterPercentage"],
                title: "Wasseranteil",
                valueType: .number,
                unit: "percent"
            ),
            UnioFieldDefinition(
                path: ["heightCm"],
                title: "Größe",
                valueType: .number,
                semanticType: "bodyHeight",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["chestCm"],
                title: "Brustumfang",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["waistCm"],
                title: "Taillenumfang",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["hipCm"],
                title: "Hüftumfang",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["shoulderCm"],
                title: "Schulterumfang",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["neckCm"],
                title: "Halsumfang",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["leftBicepCm"],
                title: "Bizeps links",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["rightBicepCm"],
                title: "Bizeps rechts",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["leftForearmCm"],
                title: "Unterarm links",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["rightForearmCm"],
                title: "Unterarm rechts",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["leftThighCm"],
                title: "Oberschenkel links",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["rightThighCm"],
                title: "Oberschenkel rechts",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["leftCalfCm"],
                title: "Wade links",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["rightCalfCm"],
                title: "Wade rechts",
                valueType: .number,
                semanticType: "bodyCircumference",
                unit: "centimeter"
            ),
            UnioFieldDefinition(
                path: ["notes"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["tags"],
                title: "Tags",
                valueType: .array
            ),
            UnioFieldDefinition(
                path: ["energyLevel"],
                title: "Energie-Level",
                valueType: .integer,
                semanticType: "energyLevel"
            ),
            UnioFieldDefinition(
                path: ["onPump"],
                title: "Nach dem Training (Pump)",
                valueType: .boolean
            ),
            UnioFieldDefinition(
                path: ["weightUnit"],
                title: "Gewichtseinheit",
                valueType: .string
            ),
            UnioFieldDefinition(
                path: ["measurementUnit"],
                title: "Messeinheit",
                valueType: .string
            )
        ]
    )
}

nonisolated struct WellnessEntryExport: Codable, Sendable {
    let id: String
    let date: Date
    let mood: Int
    let energy: Int
    let sleepQuality: Int
    let stress: Int
    let note: String
    let tags: [String]
    let createdAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "wellness-entries",
        entityType: "wellnessEntry",
        title: "Wellness-Tagebücher",
        description: "Tägliche Selbstauskünfte zu Stimmung, Energie, Schlaf und Stress",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["date"],
                title: "Datum",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            ),
            UnioFieldDefinition(
                path: ["mood"],
                title: "Stimmung",
                valueType: .integer,
                semanticType: "mood",
                description: "Skala 1–5, höher ist besser"
            ),
            UnioFieldDefinition(
                path: ["energy"],
                title: "Energie",
                valueType: .integer,
                semanticType: "energyLevel",
                description: "Skala 1–5, höher ist besser"
            ),
            UnioFieldDefinition(
                path: ["sleepQuality"],
                title: "Schlafqualität",
                valueType: .integer,
                semanticType: "sleepQuality",
                description: "Skala 1–5, höher ist besser"
            ),
            UnioFieldDefinition(
                path: ["stress"],
                title: "Stress",
                valueType: .integer,
                semanticType: "stressLevel",
                description: "Skala 1–5, höher bedeutet mehr Stress"
            ),
            UnioFieldDefinition(
                path: ["note"],
                title: "Notiz",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["tags"],
                title: "Tags",
                valueType: .array
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            )
        ]
    )
}

// MARK: - Gyms & Erfolge

nonisolated struct GymExport: Codable, Sendable {
    let id: String
    let name: String
    let details: String
    let address: String
    let createdAt: Date
    let archivedAt: Date?

    static let unioSchema = UnioDatasetSchema(
        datasetID: "gyms",
        entityType: "gym",
        title: "Studios",
        description: "Alle angelegten Fitnessstudios",
        primaryKeyPath: ["id"],
        createdAtPath: ["createdAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["name"],
                title: "Name",
                valueType: .string,
                semanticType: UnioSemanticType.name
            ),
            UnioFieldDefinition(
                path: ["details"],
                title: "Beschreibung",
                valueType: .string,
                isSensitive: true
            ),
            UnioFieldDefinition(
                path: ["address"],
                title: "Adresse",
                valueType: .string,
                semanticType: UnioSemanticType.locationName
            ),
            UnioFieldDefinition(
                path: ["createdAt"],
                title: "Erstellt am",
                valueType: .date,
                semanticType: UnioSemanticType.createdAt
            ),
            UnioFieldDefinition(
                path: ["archivedAt"],
                title: "Archiviert am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            )
        ]
    )
}

nonisolated struct AchievementExport: Codable, Sendable {
    let id: String
    let definition: String
    let unlockedAt: Date

    static let unioSchema = UnioDatasetSchema(
        datasetID: "achievements",
        entityType: "achievement",
        title: "Erfolge",
        description: "Alle freigeschalteten Erfolge",
        primaryKeyPath: ["id"],
        createdAtPath: ["unlockedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["definition"],
                title: "Erfolg",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["unlockedAt"],
                title: "Freigeschaltet am",
                valueType: .date,
                semanticType: UnioSemanticType.timestamp
            )
        ]
    )
}
