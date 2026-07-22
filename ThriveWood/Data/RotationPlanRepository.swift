//
//  RotationPlanRepository.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import Foundation
import SwiftData

@MainActor
final class RotationPlanRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAll() throws -> [RotationTrainingsPlan] {
        let descriptor = FetchDescriptor<RotationTrainingsPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchActive() throws -> RotationTrainingsPlan? {
        var descriptor = FetchDescriptor<RotationTrainingsPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func fetch(by id: UUID) throws -> RotationTrainingsPlan? {
        let descriptor = FetchDescriptor<RotationTrainingsPlan>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Create

    func create(
        name: String,
        details: String = "",
        color: String = "#4CAF50"
    ) throws -> RotationTrainingsPlan {
        let plan = RotationTrainingsPlan(
            name: name,
            details: details,
            color: color
        )
        modelContext.insert(plan)
        try modelContext.save()
        return plan
    }

    // MARK: - Update

    func update(_ plan: RotationTrainingsPlan) throws {
        try modelContext.save()
    }

    func setActive(_ plan: RotationTrainingsPlan) throws {
        let allPlans = try fetchAll()
        for p in allPlans {
            p.isActive = false
        }
        plan.isActive = true
        try modelContext.save()
    }

    func deactivateAll() throws {
        let allPlans = try fetchAll()
        for p in allPlans {
            p.isActive = false
        }
        try modelContext.save()
    }

    // MARK: - Entry Management

    func addEntry(workout: Workout?, label: String, to plan: RotationTrainingsPlan) throws {
        let order = plan.entries.count
        let entry = RotationPlanEntry(order: order, label: label, plan: plan, workout: workout)
        plan.entries.append(entry)
        modelContext.insert(entry)
        try modelContext.save()
    }

    func removeEntry(_ entry: RotationPlanEntry, from plan: RotationTrainingsPlan) throws {
        plan.entries.removeAll { $0.id == entry.id }
        for (i, e) in plan.entries.enumerated() { e.order = i }
        modelContext.delete(entry)
        try modelContext.save()
    }

    func reorderEntries(_ entries: [RotationPlanEntry], in plan: RotationTrainingsPlan) throws {
        for (i, entry) in entries.enumerated() { entry.order = i }
        try modelContext.save()
    }

    // MARK: - Rotation Logic

    /// Schiebt die Rotation weiter: currentWorkoutIndex += 1.
    /// Wenn ein kompletter Durchlauf beendet ist, wird completedRotations inkrementiert.
    func advance(_ plan: RotationTrainingsPlan) throws {
        let count = plan.sequenceCount
        guard count > 0 else { return }
        plan.currentWorkoutIndex += 1
        if plan.currentWorkoutIndex % count == 0 {
            plan.completedRotations += 1
        }
        try modelContext.save()
    }

    /// Setzt die Rotation auf einen bestimmten Index zurueck.
    func reset(_ plan: RotationTrainingsPlan, to index: Int = 0) throws {
        plan.currentWorkoutIndex = max(0, index)
        plan.completedRotations = 0
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(_ plan: RotationTrainingsPlan) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }
}
