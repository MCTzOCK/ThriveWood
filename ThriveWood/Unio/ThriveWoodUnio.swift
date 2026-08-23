//
//  ThriveWoodUnio.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.08.26.
//
//  Zentrale Unio-Integration: Quelle, Scheduler und vollständiger Export
//  des analytisch relevanten Datenbestands (siehe Unio/UnioKit.md).
//

import Foundation
import SwiftData

// MARK: - Quelle

nonisolated enum ThriveWoodUnio {
    /// Dauerhaft eindeutige Source-ID. Dar nach Veröffentlichung nicht mehr
    /// geändert werden.
    static let source = UnioSource(
        id: "thrivewood",
        displayName: "ThriveWood"
    )

    static let enabledKey = "unioExportEnabled"

    /// Zentrale Scheduler-Instanz (Debounce für Exporte nach Änderungen).
    static let scheduler = UnioExportScheduler()

    /// Unio-Integration ist standardmäßig aktiv und kann deaktiviert werden.
    static var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: enabledKey) == nil
                ? true
                : UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
        }
    }

    // MARK: - Export steuern

    /// Plant einen debounceten Voll-Export nach einer Datenänderung.
    /// Ein Fehler beim Export blockiert niemals die primäre App-Funktion.
    static func scheduleExport() {
        guard isEnabled else { return }
        Task { await scheduler.schedule() }
    }

    /// Erstellt und veröffentlicht den vollständigen Export-Snapshot.
    /// Die Tracker-Datenbank bleibt immer die Source of Truth.
    static func publishFullExport() async throws {
        guard isEnabled else { return }

        // Export nicht auf dem Main Actor erzeugen: eigener ModelContext
        // in einem detached Task lesen, DTOs sind Sendable.
        let datasets = try await Task.detached(priority: .utility) {
            try Self.buildDatasets()
        }.value

        let exporter = try UnioExporter()
        try await exporter.export(source: source, datasets: datasets)
    }

    /// Entfernt den Unio-Export dieser App vollständig.
    static func removeExport() async throws {
        await scheduler.cancel()
        let exporter = try UnioExporter()
        try await exporter.removeExport(for: source.id)
    }

    // MARK: - Export-Info für Einstellungen

    struct ExportSummary: Sendable {
        let exportedAt: Date
        let datasetCount: Int
        let recordCount: Int
    }

    /// Liest den zuletzt aktivierten Export über den UnioReader.
    static func loadExportSummary() async -> ExportSummary? {
        guard let reader = try? UnioReader() else { return nil }

        let discovery = await reader.discover()

        guard let installed = discovery.sources.first(where: {
            $0.id == source.id
        }) else {
            return nil
        }

        return ExportSummary(
            exportedAt: installed.manifest.export.createdAt,
            datasetCount: installed.manifest.datasets.count,
            recordCount: installed.manifest.datasets.reduce(0) {
                $0 + $1.recordCount
            }
        )
    }

    // MARK: - Datasets erstellen

    /// Liest den vollständigen logischen Datenbestand aus einem eigenen
    /// ModelContext und wandelt ihn in stabil exportierbare DTOs um.
    /// Die Persistenzarchitektur der App bleibt unverändert (read-only).
    nonisolated static func buildDatasets() throws -> [UnioDatasetExport] {
        let context = ModelContext(SharedModelContainer.shared)
        context.autosaveEnabled = false

        func fetch<M: PersistentModel>(_ type: M.Type) throws -> [M] {
            try context.fetch(FetchDescriptor<M>())
        }

        // MARK: Wald

        let forests = try fetch(Forest.self).map {
            ForestExport(
                id: $0.id.uuidString,
                name: $0.name,
                spentPoints: $0.spentPoints,
                createdAt: $0.createdAt
            )
        }

        let trees = try fetch(TreeEntity.self).map {
            TreeExport(
                id: $0.id.uuidString,
                forestID: $0.forest?.id.uuidString,
                species: $0.species.rawValue,
                growthPoints: $0.growthPoints,
                plantedAt: $0.plantedAt,
                nickname: $0.nickname
            )
        }

        // MARK: Habits

        let habits = try fetch(Habit.self).map {
            HabitExport(
                id: $0.id.uuidString,
                title: $0.title,
                details: $0.details,
                points: $0.points.rawValue,
                frequency: $0.frequency.rawValue,
                activeWeekdays: $0.activeWeekdays,
                trackingMode: $0.trackingMode.rawValue,
                targetValue: $0.targetValue,
                incrementValue: $0.incrementValue,
                unitLabel: $0.unitLabel,
                createdAt: $0.createdAt,
                archivedAt: $0.archivedAt
            )
        }

        let habitCompletions = try fetch(HabitCompletion.self).map {
            HabitCompletionExport(
                id: $0.id.uuidString,
                habitID: $0.habit?.id.uuidString,
                day: $0.day,
                completedAt: $0.completedAt,
                pointsAwarded: $0.pointsAwarded,
                currentValue: $0.currentValue,
                note: $0.note
            )
        }

        let habitGroups = try fetch(HabitGroup.self).map {
            HabitGroupExport(
                id: $0.id.uuidString,
                title: $0.title,
                habitIDs: $0.habitIDs.map(\.uuidString),
                sortOrder: $0.sortOrder,
                createdAt: $0.createdAt
            )
        }

        let habitRoutines = try fetch(HabitRoutine.self).map {
            HabitRoutineExport(
                id: $0.id.uuidString,
                title: $0.title,
                habitIDs: $0.habitIDs.map(\.uuidString),
                sortOrder: $0.sortOrder,
                createdAt: $0.createdAt
            )
        }

        // MARK: Sport

        let exercises = try fetch(Exercise.self).map {
            ExerciseExport(
                id: $0.id.uuidString,
                name: $0.name,
                details: $0.details,
                category: $0.category.rawValue,
                trackingType: $0.trackingType.rawValue,
                primaryMuscleGroups: $0.primaryMuscleGroupsRaw,
                secondaryMuscleGroups: $0.secondaryMuscleGroupsRaw,
                isBuiltIn: $0.isBuiltIn,
                createdAt: $0.createdAt
            )
        }

        let workouts = try fetch(Workout.self).map {
            WorkoutExport(
                id: $0.id.uuidString,
                name: $0.name,
                details: $0.details,
                estimatedDurationMinutes: $0.estimatedDurationMinutes,
                sortOrder: $0.sortOrder,
                createdAt: $0.createdAt,
                archivedAt: $0.archivedAt
            )
        }

        let workoutExercises = try fetch(WorkoutExercise.self).map {
            WorkoutExerciseExport(
                id: $0.id.uuidString,
                workoutID: $0.workout?.id.uuidString,
                exerciseID: $0.exercise?.id.uuidString,
                order: $0.order,
                targetSets: $0.targetSets,
                targetReps: $0.targetReps,
                targetWeight: $0.targetWeight,
                targetDurationSeconds: $0.targetDurationSeconds,
                targetDistanceMeters: $0.targetDistanceMeters,
                restSeconds: $0.restSeconds,
                notes: $0.notes,
                supersetGroup: $0.supersetGroup
            )
        }

        let workoutSessions = try fetch(WorkoutSession.self).map {
            WorkoutSessionExport(
                id: $0.id.uuidString,
                workoutID: $0.workout?.id.uuidString,
                startedAt: $0.startedAt,
                endedAt: $0.endedAt,
                perceivedExertion: $0.perceivedExertion,
                notes: $0.notes,
                weightUnit: $0.weightUnit.rawValue
            )
        }

        let setEntries = try fetch(SetEntry.self).map {
            SetEntryExport(
                id: $0.id.uuidString,
                sessionID: $0.session?.id.uuidString,
                exerciseID: $0.exercise?.id.uuidString,
                order: $0.order,
                reps: $0.reps,
                weight: $0.weight,
                durationSeconds: $0.durationSeconds,
                distanceMeters: $0.distanceMeters,
                isWarmup: $0.isWarmup,
                isCompleted: $0.isCompleted,
                completedAt: $0.completedAt,
                assistedReps: $0.assistedReps
            )
        }

        let trainingsPlans = try fetch(TrainingsPlan.self).map {
            TrainingsPlanExport(
                id: $0.id.uuidString,
                name: $0.name,
                details: $0.details,
                isActive: $0.isActive,
                planType: $0.planType.rawValue,
                currentRotationIndex: $0.currentRotationIndex,
                completedRotations: $0.completedRotations,
                createdAt: $0.createdAt
            )
        }

        let trainingsPlanDays = try fetch(TrainingsPlanDay.self).map {
            TrainingsPlanDayExport(
                id: $0.id.uuidString,
                planID: $0.plan?.id.uuidString,
                workoutID: $0.workout?.id.uuidString,
                weekday: $0.weekday.rawValue,
                isRestDay: $0.isRestDay,
                notes: $0.notes,
                rotationOrder: $0.rotationOrder,
                label: $0.label
            )
        }

        // MARK: Ernährung

        let foods = try fetch(Food.self).map {
            FoodExport(
                id: $0.id.uuidString,
                name: $0.name,
                brand: $0.brand,
                barcode: $0.barcode,
                caloriesPer100g: $0.caloriesPer100g,
                proteinPer100g: $0.proteinPer100g,
                carbsPer100g: $0.carbsPer100g,
                fatPer100g: $0.fatPer100g,
                fiberPer100g: $0.fiberPer100g,
                sugarPer100g: $0.sugarPer100g,
                sodiumPer100g: $0.sodiumPer100g,
                defaultServingSize: $0.defaultServingSize,
                servingUnit: $0.servingUnit,
                category: $0.category.rawValue,
                isUserCreated: $0.isUserCreated,
                usageCount: $0.usageCount,
                createdAt: $0.createdAt
            )
        }

        let foodEntries = try fetch(FoodEntry.self).map {
            FoodEntryExport(
                id: $0.id.uuidString,
                foodID: $0.food?.id.uuidString,
                day: $0.day,
                mealType: $0.mealType.rawValue,
                servingAmount: $0.servingAmount,
                loggedAt: $0.loggedAt,
                note: $0.note
            )
        }

        let mealTemplates = try fetch(MealTemplate.self).map {
            MealTemplateExport(
                id: $0.id.uuidString,
                name: $0.name,
                usageCount: $0.usageCount,
                createdAt: $0.createdAt
            )
        }

        let mealTemplateItems = try fetch(MealTemplateItem.self).map {
            MealTemplateItemExport(
                id: $0.id.uuidString,
                templateID: $0.template?.id.uuidString,
                foodID: $0.food?.id.uuidString,
                servingAmount: $0.servingAmount,
                sortOrder: $0.sortOrder
            )
        }

        let supplements = try fetch(Supplement.self).map {
            SupplementExport(
                id: $0.id.uuidString,
                name: $0.name,
                dosage: $0.dosage,
                details: $0.details,
                frequency: $0.frequency.rawValue,
                activeWeekdays: $0.activeWeekdays,
                timesPerDay: $0.timesPerDay,
                sortOrder: $0.sortOrder,
                createdAt: $0.createdAt,
                archivedAt: $0.archivedAt
            )
        }

        let supplementEntries = try fetch(SupplementEntry.self).map {
            SupplementEntryExport(
                id: $0.id.uuidString,
                supplementID: $0.supplement?.id.uuidString,
                day: $0.day,
                doseNumber: $0.doseNumber,
                takenAt: $0.takenAt,
                skipped: $0.skipped
            )
        }

        // MARK: Körper & Wellness

        let bodyMeasurements = try fetch(BodyProgressEntry.self).map {
            BodyMeasurementExport(
                id: $0.id.uuidString,
                date: $0.date,
                weightKg: $0.weightKg,
                bodyFatPercentage: $0.bodyFatPercentage,
                muscleMassKg: $0.muscleMassKg,
                waterPercentage: $0.waterPercentage,
                heightCm: $0.heightCm,
                chestCm: $0.chestCm,
                waistCm: $0.waistCm,
                hipCm: $0.hipCm,
                shoulderCm: $0.shoulderCm,
                neckCm: $0.neckCm,
                leftBicepCm: $0.leftBicepCm,
                rightBicepCm: $0.rightBicepCm,
                leftForearmCm: $0.leftForearmCm,
                rightForearmCm: $0.rightForearmCm,
                leftThighCm: $0.leftThighCm,
                rightThighCm: $0.rightThighCm,
                leftCalfCm: $0.leftCalfCm,
                rightCalfCm: $0.rightCalfCm,
                notes: $0.notes,
                tags: $0.tags,
                energyLevel: $0.energyLevel,
                onPump: $0.onPump,
                weightUnit: $0.weightUnitRaw,
                measurementUnit: $0.measurementUnitRaw
            )
        }

        let wellnessEntries = try fetch(WellnessEntry.self).map {
            WellnessEntryExport(
                id: $0.id.uuidString,
                date: $0.date,
                mood: $0.mood,
                energy: $0.energy,
                sleepQuality: $0.sleepQuality,
                stress: $0.stress,
                note: $0.note,
                tags: $0.tagsRaw,
                createdAt: $0.createdAt
            )
        }

        // MARK: Gyms & Erfolge

        let gyms = try fetch(Gym.self).map {
            GymExport(
                id: $0.id.uuidString,
                name: $0.name,
                details: $0.details,
                address: $0.address,
                createdAt: $0.createdAt,
                archivedAt: $0.archivedAt
            )
        }

        let achievements = try fetch(AchievementRecord.self).map {
            AchievementExport(
                id: $0.id.uuidString,
                definition: $0.definitionRaw,
                unlockedAt: $0.unlockedAt
            )
        }

        // MARK: Datasets bündeln

        return [
            try UnioDatasetExport(
                id: "forests",
                entityType: "forest",
                title: "Wälder",
                schema: ForestExport.unioSchema,
                records: forests
            ),
            try UnioDatasetExport(
                id: "trees",
                entityType: "tree",
                title: "Bäume",
                schema: TreeExport.unioSchema,
                records: trees
            ),
            try UnioDatasetExport(
                id: "habits",
                entityType: "habit",
                title: "Habits",
                schema: HabitExport.unioSchema,
                records: habits
            ),
            try UnioDatasetExport(
                id: "habit-completions",
                entityType: "habitCompletion",
                title: "Habit-Erledigungen",
                schema: HabitCompletionExport.unioSchema,
                records: habitCompletions
            ),
            try UnioDatasetExport(
                id: "habit-groups",
                entityType: "habitGroup",
                title: "Habit-Gruppen",
                schema: HabitGroupExport.unioSchema,
                records: habitGroups
            ),
            try UnioDatasetExport(
                id: "habit-routines",
                entityType: "habitRoutine",
                title: "Habit-Routinen",
                schema: HabitRoutineExport.unioSchema,
                records: habitRoutines
            ),
            try UnioDatasetExport(
                id: "exercises",
                entityType: "exercise",
                title: "Übungen",
                schema: ExerciseExport.unioSchema,
                records: exercises
            ),
            try UnioDatasetExport(
                id: "workouts",
                entityType: "workout",
                title: "Workouts",
                schema: WorkoutExport.unioSchema,
                records: workouts
            ),
            try UnioDatasetExport(
                id: "workout-exercises",
                entityType: "workoutExercise",
                title: "Workout-Übungen",
                schema: WorkoutExerciseExport.unioSchema,
                records: workoutExercises
            ),
            try UnioDatasetExport(
                id: "workout-sessions",
                entityType: "workoutSession",
                title: "Trainingseinheiten",
                schema: WorkoutSessionExport.unioSchema,
                records: workoutSessions
            ),
            try UnioDatasetExport(
                id: "set-entries",
                entityType: "setEntry",
                title: "Sätze",
                schema: SetEntryExport.unioSchema,
                records: setEntries
            ),
            try UnioDatasetExport(
                id: "trainings-plans",
                entityType: "trainingsPlan",
                title: "Trainingspläne",
                schema: TrainingsPlanExport.unioSchema,
                records: trainingsPlans
            ),
            try UnioDatasetExport(
                id: "trainings-plan-days",
                entityType: "trainingsPlanDay",
                title: "Trainingsplan-Tage",
                schema: TrainingsPlanDayExport.unioSchema,
                records: trainingsPlanDays
            ),
            try UnioDatasetExport(
                id: "foods",
                entityType: "food",
                title: "Lebensmittel",
                schema: FoodExport.unioSchema,
                records: foods
            ),
            try UnioDatasetExport(
                id: "food-entries",
                entityType: "foodEntry",
                title: "Ernährungseinträge",
                schema: FoodEntryExport.unioSchema,
                records: foodEntries
            ),
            try UnioDatasetExport(
                id: "meal-templates",
                entityType: "mealTemplate",
                title: "Mahlzeit-Vorlagen",
                schema: MealTemplateExport.unioSchema,
                records: mealTemplates
            ),
            try UnioDatasetExport(
                id: "meal-template-items",
                entityType: "mealTemplateItem",
                title: "Mahlzeit-Vorlagen-Positionen",
                schema: MealTemplateItemExport.unioSchema,
                records: mealTemplateItems
            ),
            try UnioDatasetExport(
                id: "supplements",
                entityType: "supplement",
                title: "Supplemente",
                schema: SupplementExport.unioSchema,
                records: supplements
            ),
            try UnioDatasetExport(
                id: "supplement-entries",
                entityType: "supplementEntry",
                title: "Supplement-Einnahmen",
                schema: SupplementEntryExport.unioSchema,
                records: supplementEntries
            ),
            try UnioDatasetExport(
                id: "body-measurements",
                entityType: "bodyMeasurement",
                title: "Körpermessungen",
                schema: BodyMeasurementExport.unioSchema,
                records: bodyMeasurements
            ),
            try UnioDatasetExport(
                id: "wellness-entries",
                entityType: "wellnessEntry",
                title: "Wellness-Tagebücher",
                schema: WellnessEntryExport.unioSchema,
                records: wellnessEntries
            ),
            try UnioDatasetExport(
                id: "gyms",
                entityType: "gym",
                title: "Studios",
                schema: GymExport.unioSchema,
                records: gyms
            ),
            try UnioDatasetExport(
                id: "achievements",
                entityType: "achievement",
                title: "Erfolge",
                schema: AchievementExport.unioSchema,
                records: achievements
            )
        ]
    }
}

// MARK: - Export-Scheduler

/// Einfache Debounce-Logik, die zu viele Exporte nach häufigen
/// Datenänderungen verhindert.
actor UnioExportScheduler {
    private var pendingTask: Task<Void, Never>?

    func schedule() {
        guard ThriveWoodUnio.isEnabled else { return }

        pendingTask?.cancel()

        pendingTask = Task {
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else { return }

            await exportNow()
        }
    }

    /// Exportiert sofort (z.B. beim Wechsel in den Hintergrund).
    func exportImmediately() async {
        pendingTask?.cancel()
        pendingTask = nil

        await exportNow()
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    private func exportNow() async {
        do {
            try await ThriveWoodUnio.publishFullExport()
        } catch {
            print("Unio export failed:", error)
        }
    }
}
