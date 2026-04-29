//
//  EntitlementService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 29.04.26.
//
import SwiftUI
import Foundation
import StoreKit


@MainActor
@Observable
final class EntitlementService {
    private let store: StoreService
    private let habitRepo: any HabitRepository
    private let workoutRepo: any WorkoutRepository

    init(store: StoreService, habitRepo: any HabitRepository, workoutRepo: any WorkoutRepository) {
        self.store = store
        self.habitRepo = habitRepo
        self.workoutRepo = workoutRepo
    }

    var isPro: Bool { store.isProUser }

    // MARK: - Limits

    static let freeHabitLimit = 3
    static let freeWorkoutLimit = 2
    static let freeSpecies: Set<TreeSpecies> = [.oak]

    var canCreateHabit: Bool {
        guard !isPro else { return true }
        let count = (try? habitRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeHabitLimit
    }

    var canCreateWorkout: Bool {
        guard !isPro else { return true }
        let count = (try? workoutRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeWorkoutLimit
    }

    func canPlant(species: TreeSpecies) -> Bool {
        isPro || Self.freeSpecies.contains(species)
    }

    var canAccessFullAnalytics: Bool { isPro }
    var canExportData: Bool { isPro }
    var canUseThemes: Bool { isPro }
    var canUseQuietHours: Bool { isPro }
    var canUseCustomIcons: Bool { isPro }

    /// Wie viele Habits der User noch erstellen kann (0 = Limit erreicht).
    var remainingFreeHabits: Int {
        guard !isPro else { return .max }
        let count = (try? habitRepo.fetchAll(includeArchived: false).count) ?? 0
        return max(0, Self.freeHabitLimit - count)
    }
}
