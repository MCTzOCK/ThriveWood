//
//  AchievementService.swift
//  ThriveWood
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AchievementService {
    private let repo: AchievementRepository
    private let habitService: HabitService
    private let scoringService: ScoringService
    private let forestService: ForestService
    private let sessionRepo: WorkoutSessionRepository
    private let muscleRankingService: MuscleRankingService

    private(set) var unlockedIds: Set<String> = []
    private(set) var notificationQueue: [AchievementDefinition] = []

    init(
        repo: AchievementRepository,
        habitService: HabitService,
        scoringService: ScoringService,
        forestService: ForestService,
        sessionRepo: WorkoutSessionRepository,
        muscleRankingService: MuscleRankingService
    ) {
        self.repo = repo
        self.habitService = habitService
        self.scoringService = scoringService
        self.forestService = forestService
        self.sessionRepo = sessionRepo
        self.muscleRankingService = muscleRankingService
    }

    func loadUnlocked() {
        unlockedIds = Set((try? repo.fetchAll().map(\.definitionRaw)) ?? [])
    }

    func checkAll(silent: Bool = false) {
        loadUnlocked()
        for def in AchievementDefinition.allCases {
            if !unlockedIds.contains(def.rawValue) && isConditionMet(def) {
                unlock(def, silent: silent)
            }
        }
    }

    func checkHabits() { checkCategory(.habit) }
    func checkWorkouts() { checkCategory(.workout) }
    func checkForest() { checkCategory(.forest) }
    func checkMuscle() { checkCategory(.muscle) }

    var currentNotification: AchievementDefinition? {
        notificationQueue.first
    }

    func dismissNotification() {
        guard !notificationQueue.isEmpty else { return }
        notificationQueue.removeFirst()
    }

    func isUnlocked(_ def: AchievementDefinition) -> Bool {
        unlockedIds.contains(def.rawValue)
    }

    func unlockedRecords() -> [AchievementRecord] {
        (try? repo.fetchAll()) ?? []
    }

    func unlockedCount() -> Int { unlockedIds.count }
    func totalCount() -> Int { AchievementDefinition.allCases.count }

    func progress(for def: AchievementDefinition) -> (current: Int, target: Int) {
        let target = def.targetValue
        let current = currentValue(for: def)
        return (min(current, target), target)
    }

    func achievements(for category: AchievementCategory) -> [AchievementDefinition] {
        AchievementDefinition.allCases.filter { $0.category == category }
    }

    // MARK: - Private

    private func checkCategory(_ category: AchievementCategory, silent: Bool = false) {
        for def in AchievementDefinition.allCases.filter({ $0.category == category }) {
            if !unlockedIds.contains(def.rawValue) && isConditionMet(def) {
                unlock(def, silent: silent)
            }
        }
    }

    private func unlock(_ def: AchievementDefinition, silent: Bool = false) {
        let record = AchievementRecord(definition: def)
        try? repo.add(record)
        unlockedIds.insert(def.rawValue)
        if !silent {
            notificationQueue.append(def)
            Haptics.success()
        }
    }

    private func isConditionMet(_ def: AchievementDefinition) -> Bool {
        currentValue(for: def) >= def.targetValue
    }

    private func currentValue(for def: AchievementDefinition) -> Int {
        switch def {
        case .firstHabit:
            return ((try? habitService.activeHabits()) ?? []).isEmpty ? 0 : 1
        case .habitStreak7, .habitStreak30, .habitStreak100:
            return maxStreak()
        case .totalPoints100, .totalPoints500, .totalPoints1000:
            return (try? scoringService.totalEarned()) ?? 0
        case .firstWorkout, .workouts10, .workouts50, .workouts100:
            return completedSessionsCount()
        case .firstTree, .trees5, .trees15:
            return treeCount()
        case .treeAncient, .treesAncient2:
            return ancientTreeCount()
        case .muscleBronze:
            return musclesAtOrAbove(rank: .bronze)
        case .muscleGold10:
            return musclesAtOrAbove(rank: .gold)
        case .musclePlatinum:
            return musclesAtOrAbove(rank: .platinum)
        }
    }

    private func maxStreak() -> Int {
        guard let habits = try? habitService.activeHabits() else { return 0 }
        return habits.compactMap { try? habitService.longestStreak(for: $0) }.max() ?? 0
    }

    private func completedSessionsCount() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        return sessions.filter { $0.endedAt != nil }.count
    }

    private func treeCount() -> Int {
        ((try? forestService.trees()) ?? []).count
    }

    private func ancientTreeCount() -> Int {
        ((try? forestService.trees()) ?? []).filter { $0.stage == .ancient }.count
    }

    private func musclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        return rankings.filter { $0.rank >= rank }.count
    }
}