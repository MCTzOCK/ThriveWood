//
//  WorkoutService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import WidgetKit

@MainActor
@Observable
final class WorkoutService {
    private let workouts: any WorkoutRepository
    private let sessions: any WorkoutSessionRepository
    private let exercises: any ExerciseRepository
    private let profileRepo: any UserProfileRepository
    private let env: AppEnvironment
    private let healthService = HealthKitService.shared
    
    /// Aktive Session wird live im State gehalten – Views können direkt binden.
    private(set) var activeSession: WorkoutSession?

    /// Per-Exercise Memoizing innerhalb einer aktiven Session. Verhindert, dass
    /// `getTopSet`/`getRecentWorkingStats` bei jedem Aufruf die komplette Session-
    /// Historie neu fetchen (sie wurden zuvor inline im Body und pro recache pro
    /// Exercise aufgerufen — Hauptursache des Session-Screen-Lags).
    private var topSetCache: [UUID: SetEntry] = [:]
    private var workingStatsCache: [UUID: ExerciseWorkingStats] = [:]
    
    init(
        workouts: any WorkoutRepository,
        sessions: any WorkoutSessionRepository,
        exercises: any ExerciseRepository,
        profile: any UserProfileRepository,
        env: AppEnvironment
    ) {
        self.workouts = workouts
        self.sessions = sessions
        self.exercises = exercises
        self.activeSession = try? sessions.activeSession()
        self.profileRepo = profile
        self.env = env
    }
    
    // MARK: Plan
    
    func allWorkouts() throws -> [Workout] { try workouts.fetchAll(includeArchived: false) }
    func allExercises() throws -> [Exercise] { try exercises.fetchAll() }
    
    func addExercise(_ exercise: Exercise, to workout: Workout,
                     targetSets: Int = 3, targetReps: Int? = 10,
                     targetWeight: Double? = nil, restSeconds: Int = 90) throws {
        let order = workout.exercises.count
        let slot = WorkoutExercise(
            order: order, exercise: exercise, workout: workout,
            targetSets: targetSets, targetReps: targetReps,
            targetWeight: targetWeight, restSeconds: restSeconds
        )
        workout.exercises.append(slot)
        try workouts.update(workout)
    }
    
    func removeExercise(_ slot: WorkoutExercise, from workout: Workout) throws {
        workout.exercises.removeAll { $0.id == slot.id }
        for (i, e) in workout.exercises.enumerated() { e.order = i }
        try workouts.update(workout)
    }
    
    func reorderExercises(_ slots: [WorkoutExercise], in workout: Workout) throws {
        for (i, slot) in slots.enumerated() { slot.order = i }
        try workouts.update(workout)
    }
    
    // MARK: Session Lifecycle
    
    @discardableResult
    func startSession(for workout: Workout? = nil,
                      weightUnit: WeightUnit = .kilograms) throws -> WorkoutSession {
        if let existing = try sessions.activeSession() {
            throw ServiceError.sessionAlreadyActive
        }
        // Caches leeren — eine neue Session kann neue PRs liefern; alte gecachte
        // Top-Sets/Working-Stats sind potenziell veraltet.
        topSetCache.removeAll()
        workingStatsCache.removeAll()
        // Einheit aus Profil lesen
        let unit: WeightUnit = (try? profileRepo.currentProfile().preferredWeightUnit) ?? .kilograms
        let session = WorkoutSession(workout: workout, startedAt: .now, weightUnit: unit)
        try sessions.create(session)
        
        // Prefill Sets aus dem Workout-Plan
        if let workout {
            var globalOrder = 0
            for slot in workout.exercises.sorted(by: { $0.order < $1.order }) {
                guard let exercise = slot.exercise else { continue }
                for _ in 0..<slot.targetSets {
                    let set = SetEntry(
                        order: globalOrder,
                        exercise: exercise,
                        session: session,
                        reps: slot.targetReps,
                        weight: slot.targetWeight,
                        durationSeconds: slot.targetDurationSeconds
                    )
                    session.sets.append(set)
                    globalOrder += 1
                }
            }
            try sessions.update(session)
        }
        
        self.activeSession = session
        
        let totalSets = session.workout?.exercises.reduce(0) { $0 + $1.targetSets } ?? 0
        
        env.workoutLiveActivity.start(
            workoutName: session.workout?.name ?? "Freies Training",
            workoutIcon: "dumbbell.fill",
            firstExercise: session.workout?.exercises.first?.exercise?.name ?? "Übung",
            totalExercises: session.workout?.exercises.count ?? 0,
            totalSets: totalSets
        )
        
        return session
    }
    
    func finishSession(perceivedExertion: Int? = nil, notes: String = "") throws {
        guard let session = activeSession else { throw ServiceError.noActiveSession }
        session.endedAt = .now
        session.perceivedExertion = perceivedExertion
        session.notes = notes
        try sessions.update(session)

        // Session-Statistiken haben sich geändert (neue PRs möglich) → Caches leeren.
        topSetCache.removeAll()
        workingStatsCache.removeAll()
        
        let savedSession = session
        
        Task {
            try? await healthService.save(session: savedSession)
        }
        
        self.activeSession = nil
        WidgetCenter.shared.reloadAllTimelines()
        
        let completedSets = session.sets.filter(\.isCompleted).count
        let totalSets = session.workout?.exercises.reduce(0) { $0 + $1.targetSets } ?? 0
        let elapsed = Int(Date().timeIntervalSince(session.startedAt))
        
        env.workoutLiveActivity.endWithSummary(
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsed
        )

        env.trainingsPlanService.handleSessionFinished()
        env.companionService.feedWorkout()
    }
    
    func cancelSession() throws {
        guard let session = activeSession else { throw ServiceError.noActiveSession }
        try sessions.delete(session)
        self.activeSession = nil
        topSetCache.removeAll()
        workingStatsCache.removeAll()
    }
    
    // MARK: Set Logging
    
    @discardableResult
    func logSet(exercise: Exercise, reps: Int?, weight: Double?,
                durationSeconds: Int? = nil, isWarmup: Bool = false) throws -> SetEntry {
        guard let session = activeSession else { throw ServiceError.noActiveSession }
        let nextOrder = (session.sets.filter { $0.exercise?.id == exercise.id }
            .map(\.order).max() ?? -1) + 1
        let set = SetEntry(
            order: nextOrder, exercise: exercise, session: session,
            reps: reps, weight: weight, durationSeconds: durationSeconds,
            isWarmup: isWarmup, isCompleted: true, completedAt: .now
        )
        session.sets.append(set)
        try sessions.update(session)
        return set
    }
    
    func markSet(_ set: SetEntry, completed: Bool) throws {
        set.isCompleted = completed
        set.completedAt = completed ? .now : nil
        try sessions.update(set.session ?? WorkoutSession())
    }
    
    func archiveWorkout(_ workout: Workout) throws { try workouts.archive(workout) }
    
    func getTopSet(for exercise: Exercise) -> SetEntry? {
        if let cached = topSetCache[exercise.id] {
            return cached
        }
        let allSessions = (try? sessions.fetchAll()) ?? []
        let relevant = allSessions
            .flatMap(\.sets)
            .filter { $0.exercise?.id == exercise.id && $0.isCompleted && !$0.isWarmup }

        let result: SetEntry = relevant.max(by: { setIsLess($0, $1, for: exercise) }) ?? SetEntry(
            order: 0, exercise: exercise,
            reps: 0, weight: 0, durationSeconds: 0, distanceMeters: 0
        )
        topSetCache[exercise.id] = result
        return result
    }
    
    func getTopSetBefore(exercise: Exercise, date: Date) -> SetEntry? {
        let allSessions = (try? sessions.fetchAll()) ?? []
        let relevantSets = allSessions
            .filter { ($0.endedAt ?? $0.startedAt) < date }
            .flatMap(\.sets)
            .filter { $0.exercise?.id == exercise.id && $0.isCompleted && !$0.isWarmup }
        
        return relevantSets.max(by: { setIsLess($0, $1, for: exercise) })
    }
    
    func getNewPRs(in session: WorkoutSession) -> [(exercise: Exercise, newPR: SetEntry, previousPR: SetEntry)] {
        let sessionSets = session.sets.filter { $0.isCompleted && !$0.isWarmup }
        let grouped = Dictionary(grouping: sessionSets) { $0.exercise?.id ?? UUID() }
        var results: [(exercise: Exercise, newPR: SetEntry, previousPR: SetEntry)] = []
        
        for (_, sets) in grouped {
            guard let exercise = sets.first?.exercise else { continue }
            guard let sessionBest = sets.max(by: { setIsLess($0, $1, for: exercise) }) else { continue }
            guard let previousBest = getTopSetBefore(exercise: exercise, date: session.startedAt) else { continue }
            if setIsLess(previousBest, sessionBest, for: exercise) {
                results.append((exercise, sessionBest, previousBest))
            }
        }
        
        return results.sorted { $0.exercise.name.localizedStandardCompare($1.exercise.name) == .orderedAscending }
    }
    
    func getProgression(for exercise: Exercise) -> [(date: Date, value: Double, reps: Int?)] {
        let allSessions = (try? sessions.fetchAll()) ?? []
        let sorted = allSessions
            .filter { $0.endedAt != nil }
            .sorted { ($0.endedAt ?? $0.startedAt) < ($1.endedAt ?? $1.startedAt) }
        
        var bestSoFar: SetEntry? = nil
        var result: [(date: Date, value: Double, reps: Int?)] = []
        
        for session in sorted {
            let sets = session.sets.filter { $0.exercise?.id == exercise.id && $0.isCompleted && !$0.isWarmup }
            guard let sessionBest = sets.max(by: { setIsLess($0, $1, for: exercise) }) else { continue }
            
            if bestSoFar == nil || setIsLess(bestSoFar!, sessionBest, for: exercise) {
                bestSoFar = sessionBest
                let value: Double
                let reps: Int?
                switch exercise.trackingType {
                case .repsWeight:
                    value = sessionBest.weight ?? 0
                    reps = sessionBest.reps
                case .reps:
                    value = Double(sessionBest.reps ?? 0)
                    reps = nil
                case .duration:
                    value = Double(sessionBest.durationSeconds ?? 0)
                    reps = nil
                case .distanceDuration:
                    value = sessionBest.distanceMeters ?? 0
                    reps = nil
                }
                result.append((date: session.endedAt ?? session.startedAt, value: value, reps: reps))
            }
        }
        return result
    }
    
    private func setIsLess(_ lhs: SetEntry, _ rhs: SetEntry, for exercise: Exercise) -> Bool {
        switch exercise.trackingType {
        case .repsWeight:
            let lw = lhs.weight ?? 0, rw = rhs.weight ?? 0
            if lw != rw { return lw < rw }
            return (lhs.reps ?? 0) < (rhs.reps ?? 0)
        case .reps:
            return (lhs.reps ?? 0) < (rhs.reps ?? 0)
        case .duration:
            return (lhs.durationSeconds ?? 0) < (rhs.durationSeconds ?? 0)
        case .distanceDuration:
            let ld = lhs.distanceMeters ?? 0, rd = rhs.distanceMeters ?? 0
            if ld != rd { return ld < rd }
            return (lhs.durationSeconds ?? 0) > (rhs.durationSeconds ?? 0)
        }
    }
    
    func getAllPRs() -> [(exercise: Exercise, topSet: SetEntry)] {
        let allSessions = (try? sessions.fetchAll()) ?? []
        let allSets = allSessions.flatMap(\.sets)
            .filter { $0.isCompleted && !$0.isWarmup && $0.exercise != nil }
        
        let grouped = Dictionary(grouping: allSets) { $0.exercise!.id }
        
        var result: [(exercise: Exercise, topSet: SetEntry)] = []
        for (_, sets) in grouped {
            guard let exercise = sets.first?.exercise else { continue }
            let topSet = sets.max(by: { setIsLess($0, $1, for: exercise) })
            guard let topSet, topSet.volumeValue > 0 else { continue }
            result.append((exercise, topSet))
        }
        
        return result.sorted { $0.exercise.name.localizedStandardCompare($1.exercise.name) == .orderedAscending }
    }

    struct ExerciseWorkingStats {
        let avgWeight: Double
        let avgReps: Int
        let recentSessionCount: Int
    }

    func getRecentWorkingStats(for exercise: Exercise, lastNSessions: Int = 5) -> ExerciseWorkingStats? {
        if let cached = workingStatsCache[exercise.id] {
            return cached
        }
        let allSessions = (try? sessions.fetchAll()) ?? []
        let relevantSessions = allSessions
            .filter { $0.endedAt != nil }
            .filter { session in
                session.sets.contains { $0.exercise?.id == exercise.id && $0.isCompleted && !$0.isWarmup }
            }
            .sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) }

        guard !relevantSessions.isEmpty else { return nil }

        let recentSessions = Array(relevantSessions.prefix(lastNSessions))
        let recentSets = recentSessions.flatMap { session in
            session.sets.filter { $0.exercise?.id == exercise.id && $0.isCompleted && !$0.isWarmup }
        }

        let weights = recentSets.compactMap { $0.weight }
        let reps = recentSets.compactMap { $0.reps }

        guard !weights.isEmpty, !reps.isEmpty else { return nil }

        let avgWeight = weights.reduce(0, +) / Double(weights.count)
        let avgReps = Double(reps.reduce(0, +)) / Double(reps.count)

        let stats = ExerciseWorkingStats(
            avgWeight: avgWeight,
            avgReps: Int(avgReps.rounded()),
            recentSessionCount: recentSessions.count
        )
        workingStatsCache[exercise.id] = stats
        return stats
    }

    // return in minutes
    func getAverageDuration(workout: Workout) -> TimeInterval {
        do {
            let sessions = try? self.sessions.fetchAll()
                .filter { $0.workout?.id == workout.id && $0.endedAt != nil }
                .compactMap(\.durationSeconds)
            guard let sessions, !sessions.isEmpty else { return 0 }
            
            let totalDuration = sessions.reduce(0, +)
            return TimeInterval(totalDuration) / Double(sessions.count) / 60.0
        } catch {
            return TimeInterval(workout.estimatedDurationMinutes)
        }
    }
    
}

private extension ServiceError {
    func withExisting(_: WorkoutSession) -> ServiceError { self }
}
