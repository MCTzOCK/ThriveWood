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
    private let supplementRepo: any SupplementRepository
    private let gymRepo: any GymRepository

    init(store: StoreService, habitRepo: any HabitRepository, workoutRepo: any WorkoutRepository, supplementRepo: any SupplementRepository, gymRepo: any GymRepository) {
        self.store = store
        self.habitRepo = habitRepo
        self.workoutRepo = workoutRepo
        self.supplementRepo = supplementRepo
        self.gymRepo = gymRepo
    }

    var isPro: Bool { store.isProUser }

    // MARK: - Limits

    static let freeHabitLimit = 3
    static let freeWorkoutLimit = 2
    static let freeSupplementLimit = 2
    static let freeSpecies: Set<TreeSpecies> = [.oak]
    static let freeGymLimit = 1

    var canCreateHabit: Bool {
        guard !isPro else { return true }
        let count = (try? habitRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeHabitLimit
    }
    
    var canCreateSupplement: Bool {
        guard !isPro else { return true }
        let count = (try? supplementRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeSupplementLimit
    }

    var canCreateWorkout: Bool {
        guard !isPro else { return true }
        let count = (try? workoutRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeWorkoutLimit
    }

    var canCreateGym: Bool {
        guard !isPro else { return true }
        let count = (try? gymRepo.fetchAll(includeArchived: false).count) ?? 0
        return count < Self.freeGymLimit
    }

    var canPlaceEquipmentOnMap: Bool { isPro }
    var canUseMapInWorkout: Bool { isPro }

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
