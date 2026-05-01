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
    private let healthService = HealthKitService.shared
    
    /// Aktive Session wird live im State gehalten – Views können direkt binden.
    private(set) var activeSession: WorkoutSession?
    
    init(
        workouts: any WorkoutRepository,
        sessions: any WorkoutSessionRepository,
        exercises: any ExerciseRepository,
        profile: any UserProfileRepository
    ) {
        self.workouts = workouts
        self.sessions = sessions
        self.exercises = exercises
        self.activeSession = try? sessions.activeSession()
        self.profileRepo = profile
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
        // Einheit aus Profil lesen
        let unit: WeightUnit = (try? profileRepo.currentProfile().preferredWeightUnit) ?? .kilograms
        let session = WorkoutSession(workout: workout, startedAt: .now, weightUnit: unit)
        try sessions.create(session)
        
        // Prefill Sets aus dem Workout-Plan
        if let workout {
            for slot in workout.exercises.sorted(by: { $0.order < $1.order }) {
                guard let exercise = slot.exercise else { continue }
                for i in 0..<slot.targetSets {
                    let set = SetEntry(
                        order: i,
                        exercise: exercise,
                        session: session,
                        reps: slot.targetReps,
                        weight: slot.targetWeight,
                        durationSeconds: slot.targetDurationSeconds
                    )
                    session.sets.append(set)
                }
            }
            try sessions.update(session)
        }
        
        self.activeSession = session
        return session
    }
    
    func finishSession(perceivedExertion: Int? = nil, notes: String = "") throws {
        guard let session = activeSession else { throw ServiceError.noActiveSession }
        session.endedAt = .now
        session.perceivedExertion = perceivedExertion
        session.notes = notes
        try sessions.update(session)
        
        let savedSession = session
        
        Task {
            try? await healthService.save(session: savedSession)
        }
        
        self.activeSession = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func cancelSession() throws {
        guard let session = activeSession else { throw ServiceError.noActiveSession }
        try sessions.delete(session)
        self.activeSession = nil
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
}

private extension ServiceError {
    func withExisting(_: WorkoutSession) -> ServiceError { self }
}
