//
//  TrainingsPlanService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//


import Foundation

@MainActor
@Observable
final class TrainingsPlanService {
    private let repo: TrainingsPlanRepository
    
    init(repo: TrainingsPlanRepository) {
        self.repo = repo
    }
    
    // MARK: - Fetch
    
    func fetchAll() throws -> [TrainingsPlan] {
        try repo.fetchAll()
    }
    
    func fetchActive() throws -> TrainingsPlan? {
        try repo.fetchActive()
    }
    
    func fetch(by id: UUID) throws -> TrainingsPlan? {
        try repo.fetch(by: id)
    }
    
    // MARK: - Create
    
    func createPlan(name: String, details: String = "", color: String = "#4CAF50") throws -> TrainingsPlan {
        guard !name.isEmpty else {
            throw ServiceError.validationFailed("Name darf nicht leer sein")
        }

        let plan = try repo.create(name: name, details: details, color: color)
        ThriveWoodUnio.scheduleExport()
        return plan
    }

    // MARK: - Update

    func updatePlan(_ plan: TrainingsPlan, name: String, details: String, color: String) throws {
        guard !name.isEmpty else {
            throw ServiceError.validationFailed("Name darf nicht leer sein")
        }

        plan.name = name
        plan.details = details
        plan.color = color
        try repo.update(plan)
        ThriveWoodUnio.scheduleExport()
    }

    func setActivePlan(_ plan: TrainingsPlan) throws {
        try repo.setActive(plan)
        ThriveWoodUnio.scheduleExport()
    }

    func assignWorkout(_ workout: Workout?, to weekday: TPWeekday, in plan: TrainingsPlan) throws {
        try repo.assignWorkout(workout, to: weekday, in: plan)
        ThriveWoodUnio.scheduleExport()
    }

    func toggleRestDay(_ weekday: TPWeekday, in plan: TrainingsPlan) throws {
        guard let day = plan.days.first(where: { $0.weekday == weekday }) else { return }
        try repo.setRestDay(weekday, in: plan, isRest: !day.isRestDay)
        ThriveWoodUnio.scheduleExport()
    }

    func updateDayNotes(_ notes: String, for weekday: TPWeekday, in plan: TrainingsPlan) throws {
        try repo.updateDayNotes(notes, for: weekday, in: plan)
        ThriveWoodUnio.scheduleExport()
    }

    // MARK: - Delete

    func deletePlan(_ plan: TrainingsPlan) throws {
        try repo.delete(plan)
        ThriveWoodUnio.scheduleExport()
    }
    
    // MARK: - Quick Actions
    
    func todaysWorkout() throws -> Workout? {
        try repo.todaysWorkout()
    }
    
    func nextWorkout() throws -> (weekday: TPWeekday, workout: Workout)? {
        try repo.nextWorkout()
    }

    // MARK: - Rotation Management

    func createRotationPlan(
        name: String,
        details: String = "",
        color: String = "#4CAF50",
        workoutCount: Int = 3
    ) throws -> TrainingsPlan {
        guard !name.isEmpty else {
            throw ServiceError.validationFailed("Name darf nicht leer sein")
        }
        let plan = try repo.create(name: name, details: details, color: color)
        plan.planType = .rotation
        try repo.update(plan)

        for i in 0..<max(2, workoutCount) {
            let label = String(Character(UnicodeScalar(65 + i)!))
            try repo.addRotationEntry(workout: nil, label: label, to: plan)
        }
        ThriveWoodUnio.scheduleExport()
        return plan
    }

    func advanceRotation(_ plan: TrainingsPlan) throws {
        try repo.advanceRotation(plan)
        ThriveWoodUnio.scheduleExport()
    }

    func resetRotation(_ plan: TrainingsPlan) throws {
        try repo.resetRotation(plan)
        ThriveWoodUnio.scheduleExport()
    }

    func addRotationWorkout(_ workout: Workout?, label: String, to plan: TrainingsPlan) throws {
        try repo.addRotationEntry(workout: workout, label: label, to: plan)
        ThriveWoodUnio.scheduleExport()
    }

    /// Aktualisiert Label und Workout eines Rotations-Slots.
    func updateRotationSlot(
        _ day: TrainingsPlanDay,
        in plan: TrainingsPlan,
        label: String,
        workout: Workout?
    ) throws {
        day.label = label
        day.workout = workout
        try repo.update(plan)
        ThriveWoodUnio.scheduleExport()
    }

    /// Entfernt einen Rotations-Slot und sortiert die restlichen neu.
    func removeRotationSlot(_ day: TrainingsPlanDay, from plan: TrainingsPlan) throws {
        plan.days.removeAll { $0.id == day.id }
        for (i, d) in plan.rotationSequence.enumerated() { d.rotationOrder = i }
        try repo.removeDay(day, from: plan)
        ThriveWoodUnio.scheduleExport()
    }

    func handleSessionFinished() {
        guard let plan = try? repo.fetchActive(), plan.isRotationPlan else { return }
        try? repo.advanceRotation(plan)
    }
    
    // MARK: - Templates
    
    /// Erstellt einen Push/Pull/Legs Plan
    func createPushPullLegsPlan(
        pushWorkout: Workout,
        pullWorkout: Workout,
        legsWorkout: Workout
    ) throws -> TrainingsPlan {
        let plan = try createPlan(
            name: "Push/Pull/Legs",
            details: "6x pro Woche Split",
            color: "#2196F3"
        )
        
        try assignWorkout(pushWorkout, to: .monday, in: plan)
        try assignWorkout(pullWorkout, to: .tuesday, in: plan)
        try assignWorkout(legsWorkout, to: .wednesday, in: plan)
        try assignWorkout(pushWorkout, to: .thursday, in: plan)
        try assignWorkout(pullWorkout, to: .friday, in: plan)
        try assignWorkout(legsWorkout, to: .saturday, in: plan)
        try repo.setRestDay(.sunday, in: plan, isRest: true)
        
        return plan
    }
    
    /// Erstellt einen Upper/Lower Split
    func createUpperLowerPlan(
        upperWorkout: Workout,
        lowerWorkout: Workout
    ) throws -> TrainingsPlan {
        let plan = try createPlan(
            name: "Upper/Lower Split",
            details: "4x pro Woche",
            color: "#9C27B0"
        )
        
        try assignWorkout(upperWorkout, to: .monday, in: plan)
        try assignWorkout(lowerWorkout, to: .tuesday, in: plan)
        try repo.setRestDay(.wednesday, in: plan, isRest: true)
        try assignWorkout(upperWorkout, to: .thursday, in: plan)
        try assignWorkout(lowerWorkout, to: .friday, in: plan)
        try repo.setRestDay(.saturday, in: plan, isRest: true)
        try repo.setRestDay(.sunday, in: plan, isRest: true)
        
        return plan
    }
}
