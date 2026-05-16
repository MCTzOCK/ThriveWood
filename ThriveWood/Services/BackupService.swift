//
//  BackupService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 30.04.26.
//


import Foundation

@MainActor
final class BackupService {
    private let env: AppEnvironment

    init(env: AppEnvironment) { self.env = env }

    // MARK: - Export

    func exportAll() async throws -> Data {
        let profile = try? env.profileRepo.currentProfile()
        let habits = try env.habitRepo.fetchAll(includeArchived: true)
        let completions = try env.completionRepo.allCompletions()
        let forest = try? env.forestRepo.currentForest()
        let trees: [TreeEntity] = {
            guard let f = forest else { return [] }
            return (try? env.treeRepo.fetchAll(in: f)) ?? []
        }()
        let exercises = try env.exerciseRepo.fetchAll()
        let workouts = try env.workoutRepo.fetchAll(includeArchived: true)
        let sessions = try env.sessionRepo.fetchAll()
        let supplements = try env.supplementRepo.fetchAll(includeArchived: true)
        let supplementEntries = try env.supplementEntryRepo.fetchAll()

        let backup = ThriveWoodBackup(
            version: ThriveWoodBackup.currentVersion,
            exportedAt: .now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–",

            profile: profile.map { mapProfile($0) },

            habits: habits.map { mapHabit($0) },

            completions: completions.compactMap { mapCompletion($0) },

            forest: forest.map { mapForest($0) },

            trees: trees.map { mapTree($0) },

            exercises: exercises.filter { !$0.isBuiltIn }.map { mapExercise($0) },

            workouts: workouts.map { mapWorkout($0) },

            workoutExercises: workouts.flatMap { w in
                w.exercises.compactMap { mapWorkoutExercise($0, workoutID: w.id) }
            },

            sessions: sessions.map { mapSession($0) },

            sets: sessions.flatMap { s in
                s.sets.compactMap { mapSetEntry($0, sessionID: s.id) }
            },
            
            supplements: supplements.map { mapSupplement($0) },
            
            supplementEntries: supplementEntries.map { mapSupplementEntry($0)  }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    // MARK: - Import

    struct ImportResult {
        var habits: Int
        var completions: Int
        var trees: Int
        var exercises: Int
        var workouts: Int
        var sessions: Int
        var sets: Int
        var supplements: Int
        var supplementEntries: Int
        var total: Int { habits + completions + trees + exercises + workouts + sessions + sets + supplements + supplementEntries }
    }

    func importAll(_ data: Data) async throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(ThriveWoodBackup.self, from: data)

        guard backup.version <= ThriveWoodBackup.currentVersion else {
            throw BackupError.unsupportedVersion(backup.version)
        }

        var result = ImportResult(
            habits: 0, completions: 0, trees: 0,
            exercises: 0, workouts: 0, sessions: 0, sets: 0,
            supplements: 0, supplementEntries: 0
        )

        // 1. Profil (merge, nicht überschreiben)
        if let dto = backup.profile {
            try importProfile(dto)
        }

        // 2. Exercises (vor Workouts, da referenziert)
        let exerciseMap = try importExercises(backup.exercises)
        result.exercises = exerciseMap.count

        // 3. Habits
        let habitMap = try importHabits(backup.habits)
        result.habits = habitMap.count

        // 4. Completions
        result.completions = try importCompletions(backup.completions, habitMap: habitMap)

        // 5. Forest + Trees
        if let forestDTO = backup.forest {
            result.trees = try importForest(forestDTO, trees: backup.trees)
        }

        // 6. Workouts + WorkoutExercises
        let workoutMap = try importWorkouts(backup.workouts, backup.workoutExercises, exerciseMap: exerciseMap)
        result.workouts = workoutMap.count

        // 7. Sessions + Sets
        result.sessions = try importSessions(
            backup.sessions, backup.sets,
            workoutMap: workoutMap, exerciseMap: exerciseMap
        )
        result.sets = backup.sets.count
        
        // 8. Supplements + SupplementEntries
        let supplementMap = try importSupplements(backup.supplements)
        result.supplements = supplementMap.count
        
        let supplementEntryCount = try importSupplementEntries(backup.supplementEntries, supplementMap: supplementMap)
        result.supplementEntries = supplementEntryCount
        
        
        return result
    }

    // MARK: - Export Mappings

    private func mapProfile(_ p: UserProfile) -> ThriveWoodBackup.ProfileDTO {
        .init(
            displayName: p.displayName,
            preferredWeightUnit: p.preferredWeightUnitRaw,
            weekStartsOn: p.weekStartsOnRaw,
            dailyPointGoal: p.dailyPointGoal,
            appearance: p.appearanceRaw,
            accentTheme: p.accentThemeRaw,
            quietHoursEnabled: p.quietHoursEnabled,
            quietHoursStart: p.quietHoursStart,
            quietHoursEnd: p.quietHoursEnd,
            defaultRestSeconds: p.defaultRestSeconds,
            enableNotifications: p.enableNotifications,
            enableHapticFeedback: p.enableHapticFeedback,
            onboardingCompletedAt: p.onboardingCompletedAt
        )
    }

    private func mapHabit(_ h: Habit) -> ThriveWoodBackup.HabitDTO {
        .init(
            id: h.id, title: h.title, details: h.details,
            iconSystemName: h.iconSystemName, color: h.colorRaw,
            points: h.pointsRaw, frequency: h.frequencyRaw,
            activeWeekdays: h.activeWeekdays,
            reminderTime: h.reminderTime, sortOrder: h.sortOrder,
            createdAt: h.createdAt, archivedAt: h.archivedAt,
            trackingMode: h.trackingModeRaw,
            targetValue: h.targetValue,
            incrementValue: h.incrementValue,
            unitLabel: h.unitLabel
        )
    }

    private func mapCompletion(_ c: HabitCompletion) -> ThriveWoodBackup.CompletionDTO? {
        guard let habitID = c.habit?.id else { return nil }
        return .init(
            id: c.id, habitID: habitID, day: c.day,
            completedAt: c.completedAt, pointsAwarded: c.pointsAwarded,
            currentValue: c.currentValue, note: c.note
        )
    }

    private func mapForest(_ f: Forest) -> ThriveWoodBackup.ForestDTO {
        .init(id: f.id, name: f.name, spentPoints: f.spentPoints, createdAt: f.createdAt)
    }

    private func mapTree(_ t: TreeEntity) -> ThriveWoodBackup.TreeDTO {
        .init(
            id: t.id, forestID: t.forest?.id ?? UUID(),
            species: t.speciesRaw, gridX: t.gridX, gridY: t.gridY,
            growthPoints: t.growthPoints, plantedAt: t.plantedAt,
            nickname: t.nickname
        )
    }

    private func mapExercise(_ e: Exercise) -> ThriveWoodBackup.ExerciseDTO {
        .init(
            id: e.id, name: e.name, details: e.details,
            category: e.categoryRaw, trackingType: e.trackingTypeRaw,
            primaryMuscleGroups: e.primaryMuscleGroupsRaw,
            secondaryMuscleGroups: e.secondaryMuscleGroupsRaw,
            iconSystemName: e.iconSystemName,
            isBuiltIn: e.isBuiltIn, createdAt: e.createdAt
        )
    }

    private func mapWorkout(_ w: Workout) -> ThriveWoodBackup.WorkoutDTO {
        .init(
            id: w.id, name: w.name, details: w.details,
            color: w.colorRaw,
            estimatedDurationMinutes: w.estimatedDurationMinutes,
            sortOrder: w.sortOrder,
            createdAt: w.createdAt, archivedAt: w.archivedAt
        )
    }

    private func mapWorkoutExercise(_ we: WorkoutExercise, workoutID: UUID) -> ThriveWoodBackup.WorkoutExerciseDTO? {
        guard let exID = we.exercise?.id else { return nil }
        return .init(
            id: we.id, workoutID: workoutID, exerciseID: exID,
            order: we.order, targetSets: we.targetSets,
            targetReps: we.targetReps, targetWeight: we.targetWeight,
            targetDurationSeconds: we.targetDurationSeconds,
            targetDistanceMeters: we.targetDistanceMeters,
            restSeconds: we.restSeconds, notes: we.notes
        )
    }

    private func mapSession(_ s: WorkoutSession) -> ThriveWoodBackup.SessionDTO {
        .init(
            id: s.id, workoutID: s.workout?.id,
            startedAt: s.startedAt, endedAt: s.endedAt,
            perceivedExertion: s.perceivedExertion,
            notes: s.notes, weightUnit: s.weightUnitRaw
        )
    }

    private func mapSetEntry(_ s: SetEntry, sessionID: UUID) -> ThriveWoodBackup.SetEntryDTO? {
        guard let exID = s.exercise?.id else { return nil }
        return .init(
            id: s.id, sessionID: sessionID, exerciseID: exID,
            order: s.order, reps: s.reps, weight: s.weight,
            durationSeconds: s.durationSeconds,
            distanceMeters: s.distanceMeters,
            isWarmup: s.isWarmup, isCompleted: s.isCompleted,
            completedAt: s.completedAt
        )
    }
    
    private func mapSupplement(_ s: Supplement) -> ThriveWoodBackup.SupplementDTO {
        .init(
            id: s.id, name: s.name, dosage: s.dosage, details: s.details, iconSystemName: s.iconSystemName, colorRaw: s.colorRaw, frequencyRaw: s.frequencyRaw, activeWeekdays: s.activeWeekdays, timesPerDay: s.timesPerDay, reminderTimes: s.reminderTimes, sortOrder: s.sortOrder, createdAt: s.createdAt, archivedAt: s.archivedAt
        )
    }
    
    private func mapSupplementEntry(_ e: SupplementEntry) -> ThriveWoodBackup.SupplementEntryDTO {
        return .init(id: e.id, supplementID: e.supplement!.id, day: e.day, doseNumber: e.doseNumber, takenAt: e.takenAt, skipped: e.skipped)
    }

    // MARK: - Import Logic

    private func importProfile(_ dto: ThriveWoodBackup.ProfileDTO) throws {
        let profile = try env.profileRepo.currentProfile()
        if profile.displayName.isEmpty { profile.displayName = dto.displayName }
        profile.dailyPointGoal = dto.dailyPointGoal
        profile.appearanceRaw = dto.appearance
        profile.accentThemeRaw = dto.accentTheme
        profile.preferredWeightUnitRaw = dto.preferredWeightUnit
        profile.weekStartsOnRaw = dto.weekStartsOn
        profile.quietHoursEnabled = dto.quietHoursEnabled
        profile.quietHoursStart = dto.quietHoursStart
        profile.quietHoursEnd = dto.quietHoursEnd
        profile.defaultRestSeconds = dto.defaultRestSeconds
        profile.enableNotifications = dto.enableNotifications
        profile.enableHapticFeedback = dto.enableHapticFeedback
        if profile.onboardingCompletedAt == nil {
            profile.onboardingCompletedAt = dto.onboardingCompletedAt
        }
        try env.profileRepo.update(profile)
    }

    /// Gibt ein Mapping von Export-UUID → importierter Exercise zurück.
    private func importExercises(_ dtos: [ThriveWoodBackup.ExerciseDTO]) throws -> [UUID: Exercise] {
        let existing = try env.exerciseRepo.fetchAll()
        let existingByName = Dictionary(grouping: existing) { $0.name }
        var map: [UUID: Exercise] = [:]

        // Built-ins via Name matchen
        for e in existing { map[e.id] = e }

        for dto in dtos {
            if let match = existingByName[dto.name]?.first {
                map[dto.id] = match
                continue
            }
            let exercise = Exercise(
                id: dto.id, name: dto.name, details: dto.details,
                category: ExerciseCategory(rawValue: dto.category) ?? .strength,
                trackingType: ExerciseTrackingType(rawValue: dto.trackingType) ?? .repsWeight,
                primaryMuscleGroups: dto.primaryMuscleGroups.compactMap(MuscleGroup.init(rawValue:)),
                secondaryMuscleGroups: dto.secondaryMuscleGroups.compactMap(MuscleGroup.init(rawValue:)),
                iconSystemName: dto.iconSystemName,
                isBuiltIn: false, createdAt: dto.createdAt
            )
            try env.exerciseRepo.create(exercise)
            map[dto.id] = exercise
        }
        return map
    }

    private func importHabits(_ dtos: [ThriveWoodBackup.HabitDTO]) throws -> [UUID: Habit] {
        let existing = Set((try? env.habitRepo.fetchAll(includeArchived: true))?.map(\.id) ?? [])
        var map: [UUID: Habit] = [:]

        for dto in dtos {
            if existing.contains(dto.id) {
                if let h = try env.habitRepo.fetch(id: dto.id) { map[dto.id] = h }
                continue
            }
            let habit = Habit(
                id: dto.id, title: dto.title, details: dto.details,
                iconSystemName: dto.iconSystemName,
                color: HabitColor(rawValue: dto.color) ?? .green,
                points: HabitPoints(rawValue: dto.points) ?? .low,
                frequency: HabitFrequency(rawValue: dto.frequency) ?? .daily,
                activeWeekdays: dto.activeWeekdays.compactMap(Weekday.init(rawValue:)),
                reminderTime: dto.reminderTime,
                sortOrder: dto.sortOrder, createdAt: dto.createdAt,
                archivedAt: dto.archivedAt,
                trackingMode: HabitTrackingMode(rawValue: dto.trackingMode) ?? .simple,
                targetValue: dto.targetValue,
                incrementValue: dto.incrementValue,
                unitLabel: dto.unitLabel
            )
            try env.habitRepo.create(habit)
            map[dto.id] = habit
        }
        return map
    }

    private func importCompletions(
        _ dtos: [ThriveWoodBackup.CompletionDTO],
        habitMap: [UUID: Habit]
    ) throws -> Int {
        var count = 0
        for dto in dtos {
            guard let habit = habitMap[dto.habitID] else { continue }
            if try env.completionRepo.completion(for: habit, on: dto.day) != nil { continue }
            let c = HabitCompletion(
                id: dto.id, habit: habit, day: dto.day,
                completedAt: dto.completedAt,
                pointsAwarded: dto.pointsAwarded,
                currentValue: dto.currentValue
            )
            c.note = dto.note
            try env.completionRepo.add(c)
            count += 1
        }
        return count
    }

    private func importForest(
        _ dto: ThriveWoodBackup.ForestDTO,
        trees: [ThriveWoodBackup.TreeDTO]
    ) throws -> Int {
        let forest = try env.forestRepo.currentForest()
        forest.spentPoints = max(forest.spentPoints, dto.spentPoints)
        try env.forestRepo.update(forest)

        let existingTrees = try env.treeRepo.fetchAll(in: forest)
        let existingPositions = Set(existingTrees.map { "\($0.gridX)-\($0.gridY)" })

        var count = 0
        for t in trees {
            let pos = "\(t.gridX)-\(t.gridY)"
            if existingPositions.contains(pos) { continue }
            let tree = TreeEntity(
                id: t.id,
                species: TreeSpecies(rawValue: t.species) ?? .oak,
                gridX: t.gridX, gridY: t.gridY,
                growthPoints: t.growthPoints,
                plantedAt: t.plantedAt,
                nickname: t.nickname,
                forest: forest
            )
            try env.treeRepo.add(tree)
            count += 1
        }
        return count
    }

    private func importWorkouts(
        _ workoutDTOs: [ThriveWoodBackup.WorkoutDTO],
        _ slotDTOs: [ThriveWoodBackup.WorkoutExerciseDTO],
        exerciseMap: [UUID: Exercise]
    ) throws -> [UUID: Workout] {
        let existing = Set((try? env.workoutRepo.fetchAll(includeArchived: true))?.map(\.id) ?? [])
        let slotsByWorkout = Dictionary(grouping: slotDTOs) { $0.workoutID }
        var map: [UUID: Workout] = [:]

        for dto in workoutDTOs {
            if existing.contains(dto.id) {
                if let w = try env.workoutRepo.fetch(id: dto.id) { map[dto.id] = w }
                continue
            }
            let workout = Workout(
                id: dto.id, name: dto.name, details: dto.details,
                color: HabitColor(rawValue: dto.color) ?? .blue,
                estimatedDurationMinutes: dto.estimatedDurationMinutes,
                sortOrder: dto.sortOrder,
                createdAt: dto.createdAt, archivedAt: dto.archivedAt
            )
            try env.workoutRepo.create(workout)

            for slotDTO in (slotsByWorkout[dto.id] ?? []).sorted(by: { $0.order < $1.order }) {
                guard let exercise = exerciseMap[slotDTO.exerciseID] else { continue }
                let slot = WorkoutExercise(
                    id: slotDTO.id, order: slotDTO.order,
                    exercise: exercise, workout: workout,
                    targetSets: slotDTO.targetSets,
                    targetReps: slotDTO.targetReps,
                    targetWeight: slotDTO.targetWeight,
                    targetDurationSeconds: slotDTO.targetDurationSeconds,
                    targetDistanceMeters: slotDTO.targetDistanceMeters,
                    restSeconds: slotDTO.restSeconds,
                    notes: slotDTO.notes
                )
                workout.exercises.append(slot)
            }
            try env.workoutRepo.update(workout)
            map[dto.id] = workout
        }
        return map
    }

    private func importSessions(
        _ sessionDTOs: [ThriveWoodBackup.SessionDTO],
        _ setDTOs: [ThriveWoodBackup.SetEntryDTO],
        workoutMap: [UUID: Workout],
        exerciseMap: [UUID: Exercise]
    ) throws -> Int {
        let existing = Set((try? env.sessionRepo.fetchAll())?.map(\.id) ?? [])
        let setsBySession = Dictionary(grouping: setDTOs) { $0.sessionID }
        var count = 0

        for dto in sessionDTOs {
            if existing.contains(dto.id) { continue }
            let workout = dto.workoutID.flatMap { workoutMap[$0] }
            let session = WorkoutSession(
                id: dto.id, workout: workout,
                startedAt: dto.startedAt, endedAt: dto.endedAt,
                perceivedExertion: dto.perceivedExertion,
                notes: dto.notes,
                weightUnit: WeightUnit(rawValue: dto.weightUnit) ?? .kilograms
            )
            try env.sessionRepo.create(session)

            for setDTO in (setsBySession[dto.id] ?? []).sorted(by: { $0.order < $1.order }) {
                guard let exercise = exerciseMap[setDTO.exerciseID] else { continue }
                let entry = SetEntry(
                    id: setDTO.id, order: setDTO.order,
                    exercise: exercise, session: session,
                    reps: setDTO.reps, weight: setDTO.weight,
                    durationSeconds: setDTO.durationSeconds,
                    distanceMeters: setDTO.distanceMeters,
                    isWarmup: setDTO.isWarmup,
                    isCompleted: setDTO.isCompleted,
                    completedAt: setDTO.completedAt
                )
                session.sets.append(entry)
            }
            try env.sessionRepo.update(session)
            count += 1
        }
        return count
    }
    
    private func importSupplements(_ dtos: [ThriveWoodBackup.SupplementDTO]) throws -> [UUID: Supplement] {
        let existing = Set((try? env.supplementRepo.fetchAll(includeArchived: true))?.map(\.id) ?? [])
        var map: [UUID: Supplement] = [:]
        
        for dto in dtos {
            if existing.contains(dto.id) {
                if let s = try env.supplementRepo.fetch(id: dto.id) { map[dto.id] = s }
                continue
            }
            let supplement = Supplement(
                id: dto.id, name: dto.name, dosage: dto.dosage, details: dto.details, iconSystemName: dto.iconSystemName, color: HabitColor(rawValue: dto.colorRaw)!, frequency: HabitFrequency(rawValue: dto.frequencyRaw)!, activeWeekdays: dto.activeWeekdays.compactMap(Weekday.init(rawValue:)), timesPerDay: dto.timesPerDay, reminderTimes: dto.reminderTimes, sortOrder: dto.sortOrder, createdAt: dto.createdAt, archivedAt: dto.archivedAt
            )
            try env.supplementRepo.create(supplement)
            map[dto.id] = supplement
        }
        return map
    }
    
    private func importSupplementEntries(_ dtos: [ThriveWoodBackup.SupplementEntryDTO], supplementMap: [UUID: Supplement]) throws -> Int {
        var count = 0
        for dto in dtos {
            guard let supplement = supplementMap[dto.supplementID] else { continue }
            if try env.supplementEntryRepo.entry(for: supplement, on: dto.day, dose: dto.doseNumber) != nil { continue }
            let entry = SupplementEntry(
                id: dto.id, supplement: supplement, day: dto.day,
                doseNumber: dto.doseNumber, takenAt: dto.takenAt,
                skipped: dto.skipped
            )
            try env.supplementEntryRepo.add(entry)
            count += 1
        }
        return count
    }

}

// MARK: - Errors

enum BackupError: LocalizedError {
    case unsupportedVersion(Int)
    case corruptedData
    case exportFailed(Error)
    case importFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            "Backup-Version \(v) wird von dieser App-Version nicht unterstützt. Bitte aktualisiere die App."
        case .corruptedData:
            "Die Backup-Datei ist beschädigt oder ungültig."
        case .exportFailed(let e):
            "Export fehlgeschlagen: \(e.localizedDescription)"
        case .importFailed(let e):
            "Import fehlgeschlagen: \(e.localizedDescription)"
        }
    }
}
