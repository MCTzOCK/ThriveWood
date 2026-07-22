//
//  RotationPlanService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import Foundation

@MainActor
@Observable
final class RotationPlanService {
    private let repo: RotationPlanRepository

    init(repo: RotationPlanRepository) {
        self.repo = repo
    }

    // MARK: - Fetch

    func fetchAll() throws -> [RotationTrainingsPlan] {
        try repo.fetchAll()
    }

    func fetchActive() throws -> RotationTrainingsPlan? {
        try repo.fetchActive()
    }

    func fetch(by id: UUID) throws -> RotationTrainingsPlan? {
        try repo.fetch(by: id)
    }

    // MARK: - Create

    func createPlan(
        name: String,
        details: String = "",
        color: String = "#4CAF50",
        workouts: [(workout: Workout?, label: String)] = []
    ) throws -> RotationTrainingsPlan {
        guard !name.isEmpty else {
            throw ServiceError.validationFailed("Name darf nicht leer sein")
        }
        let plan = try repo.create(name: name, details: details, color: color)
        for (workout, label) in workouts {
            try repo.addEntry(workout: workout, label: label, to: plan)
        }
        return plan
    }

    // MARK: - Update

    func updatePlan(_ plan: RotationTrainingsPlan, name: String, details: String, color: String) throws {
        guard !name.isEmpty else {
            throw ServiceError.validationFailed("Name darf nicht leer sein")
        }
        plan.name = name
        plan.details = details
        plan.color = color
        try repo.update(plan)
    }

    func setActivePlan(_ plan: RotationTrainingsPlan) throws {
        try repo.setActive(plan)
    }

    func addWorkout(_ workout: Workout?, label: String, to plan: RotationTrainingsPlan) throws {
        try repo.addEntry(workout: workout, label: label, to: plan)
    }

    func removeEntry(_ entry: RotationPlanEntry, from plan: RotationTrainingsPlan) throws {
        try repo.removeEntry(entry, from: plan)
    }

    func reorderEntries(_ entries: [RotationPlanEntry], in plan: RotationTrainingsPlan) throws {
        try repo.reorderEntries(entries, in: plan)
    }

    // MARK: - Rotation

    /// Schiebt die Rotation weiter. Sollte nach Abschluss einer Session aufgerufen werden.
    func advance(_ plan: RotationTrainingsPlan) throws {
        try repo.advance(plan)
    }

    func reset(_ plan: RotationTrainingsPlan, to index: Int = 0) throws {
        try repo.reset(plan, to: index)
    }

    // MARK: - Delete

    func deletePlan(_ plan: RotationTrainingsPlan) throws {
        try repo.delete(plan)
    }

    // MARK: - Helpers

    /// Das naechste Workout aus dem aktiven Rotationsplan (falls vorhanden).
    func nextWorkoutFromActive() throws -> (plan: RotationTrainingsPlan, workout: Workout?)? {
        guard let plan = try repo.fetchActive() else { return nil }
        return (plan, plan.nextWorkout)
    }

    /// Schreibt automatisch fort, wenn eine Session abgeschlossen wurde.
    /// Wird vom WorkoutService nach finishSession aufgerufen.
    func handleSessionFinished(session: WorkoutSession) {
        guard let plan = try? repo.fetchActive() else { return }
        let _ = try? repo.advance(plan)
    }
}
