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
        do {
            unlockedIds = Set(try repo.fetchAll().map(\.definitionRaw))
        } catch {
            unlockedIds = []
        }
    }

    func checkAll(silent: Bool = false) {
        do {
            try ensureSchemaReady()
            loadUnlocked()
            for def in AchievementDefinition.allCases {
                if !unlockedIds.contains(def.rawValue) && isConditionMet(def) {
                    unlock(def, silent: silent)
                }
            }
        } catch {
        }
    }

    func checkHabits() { try? checkCategory(.habit) }
    func checkWorkouts() { try? checkCategory(.workout) }
    func checkForest() { try? checkCategory(.forest) }
    func checkMuscle() { try? checkCategory(.muscle) }

    var currentNotification: AchievementDefinition? {
        notificationQueue.first
    }

    func dismissNotification() {
        guard !notificationQueue.isEmpty else { return }
        notificationQueue.removeFirst()
    }

    func triggerTestNotification() {
        guard let def = AchievementDefinition.allCases.randomElement() else { return }
        notificationQueue.append(def)
        Haptics.success()
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

    private func ensureSchemaReady() throws {
        do {
            _ = try repo.fetchAll()
        } catch {
            let placeholder = AchievementRecord(definition: .firstHabit)
            try repo.add(placeholder)
            try repo.delete(placeholder)
        }
    }

    private func checkCategory(_ category: AchievementCategory, silent: Bool = false) throws {
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
        // MARK: Habits
        case .firstHabit:
            return ((try? habitService.activeHabits()) ?? []).count
        case .habitCreator5, .habitCreator10:
            return ((try? habitService.activeHabits()) ?? []).count
        case .firstCompletion:
            return hasAnyCompletion() ? 1 : 0
        case .habitsAllInOneDay5, .habitsAllInOneDay10:
            return habitsCompletedToday()
        case .habitsAllInOneDayAll:
            return allHabitsCompletedToday() ? 1 : 0
        case .streak3, .streak7, .streak14, .streak30, .streak60, .streak100, .streak180, .streak365:
            return maxStreak()
        case .points10, .points50, .points100, .points250, .points500, .points1000, .points2500, .points5000:
            return (try? scoringService.totalEarned()) ?? 0
        case .measurableGoal100:
            return measurableGoalReachedCount()
        case .measurableGoal500, .measurableGoal1000:
            return totalMeasurableCompletions()
        case .pointsSingleDay10, .pointsSingleDay20, .pointsSingleDay30:
            return (try? habitService.pointsEarned(on: .now)) ?? 0

        // MARK: Workouts
        case .firstWorkout, .workouts5, .workouts10, .workouts25, .workouts50, .workouts75, .workouts100, .workouts200:
            return completedSessionsCount()
        case .workoutDuration30, .workoutDuration60, .workoutDuration90:
            return maxWorkoutDurationMinutes()
        case .firstPR:
            return hasAnyPR() ? 1 : 0
        case .prCount5, .prCount15, .prCount30:
            return totalPRCount()
        case .totalVolume1000, .totalVolume10000, .totalVolume50000, .totalVolume100000, .totalVolume250000:
            return totalVolume()
        case .workout3DaysRow, .workout7DaysRow:
            return workoutStreakDays()
        case .firstCardio:
            return hasWorkoutCategory(.cardio) ? 1 : 0
        case .firstStrength:
            return hasWorkoutCategory(.strength) ? 1 : 0
        case .setsCompleted100, .setsCompleted500, .setsCompleted1000:
            return totalCompletedSets()

        // MARK: Forest
        case .firstTree, .trees3, .trees5, .trees10, .trees15, .trees25, .trees40:
            return treeCount()
        case .firstOak, .firstPine, .firstBirch, .firstMaple, .firstWillow, .firstCherry, .firstSequoia, .firstBonsai:
            return hasTreeSpecies(treeSpecies(for: def)) ? 1 : 0
        case .treeGrowthSapling:
            return treesAtOrAboveGrowthStage(.sapling)
        case .treeGrowthYoung:
            return treesAtOrAboveGrowthStage(.young)
        case .treeGrowthMature:
            return treesAtOrAboveGrowthStage(.mature)
        case .treeGrowthAncient:
            return treesAtOrAboveGrowthStage(.ancient)
        case .treesAncient2:
            return ancientTreeCount()
        case .treesAncient5:
            return ancientTreeCount()
        case .forestCoverage25, .forestCoverage50, .forestCoverage75:
            return Int((try? forestService.coverage()) ?? 0) * 100 / 100
        case .pointsSpent50, .pointsSpent200, .pointsSpent500:
            return (try? scoringService.totalSpent()) ?? 0

        // MARK: Muscle
        case .muscleBronze:
            return musclesAtOrAbove(rank: .bronze)
        case .muscleBronze5:
            return musclesAtOrAbove(rank: .bronze)
        case .muscleBronze10:
            return musclesAtOrAbove(rank: .bronze)
        case .muscleSilver:
            return musclesAtOrAbove(rank: .silver)
        case .muscleSilver5:
            return musclesAtOrAbove(rank: .silver)
        case .muscleSilver10:
            return musclesAtOrAbove(rank: .silver)
        case .muscleGold:
            return musclesAtOrAbove(rank: .gold)
        case .muscleGold5:
            return musclesAtOrAbove(rank: .gold)
        case .muscleGold10:
            return musclesAtOrAbove(rank: .gold)
        case .musclePlatinum:
            return musclesAtOrAbove(rank: .platinum)
        case .musclePlatinum3:
            return musclesAtOrAbove(rank: .platinum)
        case .muscleDiamond:
            return musclesAtOrAbove(rank: .diamond)
        case .muscleChampion:
            return musclesAtOrAbove(rank: .champion)
        case .muscleLegend:
            return musclesAtOrAbove(rank: .legend)
        case .muscleUpperBodyBronze:
            return upperBodyMusclesAtOrAbove(rank: .bronze)
        case .muscleLowerBodyBronze:
            return lowerBodyMusclesAtOrAbove(rank: .bronze)
        case .muscleCoreBronze:
            return coreMusclesAtOrAbove(rank: .bronze)
        case .muscleBackBronze:
            return backMusclesAtOrAbove(rank: .bronze)
        case .muscleFirstSet:
            return totalCompletedSets() >= 1 ? 1 : 0
        case .muscleSetsTotal100:
            return totalCompletedSets()
        case .muscleSetsTotal500:
            return totalCompletedSets()
        }
    }

    // MARK: - Data Helpers

    private func hasAnyCompletion() -> Bool {
        (try? habitService.activeHabits())?.contains { (try? habitService.isCompleted($0)) ?? false } ?? false
    }

    private func habitsCompletedToday() -> Int {
        let habits = (try? habitService.activeHabits()) ?? []
        return habits.filter { (try? habitService.isCompleted($0)) ?? false }.count
    }

    private func allHabitsCompletedToday() -> Bool {
        let due = (try? habitService.habitsDue()) ?? []
        guard !due.isEmpty else { return false }
        return due.allSatisfy { (try? habitService.isCompleted($0)) ?? false }
    }

    private func maxStreak() -> Int {
        guard let habits = try? habitService.activeHabits() else { return 0 }
        return habits.compactMap { try? habitService.longestStreak(for: $0) }.max() ?? 0
    }

    private func measurableGoalReachedCount() -> Int {
        let habits = (try? habitService.activeHabits()) ?? []
        var count = 0
        for habit in habits where habit.isMeasurable {
            if let progress = try? habitService.currentProgress(habit), progress.progress >= 1.0 {
                count += 1
            }
        }
        return count
    }

    private func totalMeasurableCompletions() -> Int {
        let habits = (try? habitService.activeHabits()) ?? []
        var total = 0
        for habit in habits where habit.isMeasurable {
            let completions = habit.completions.filter { $0.isComplete }
            total += completions.count
        }
        return total
    }

    private func completedSessionsCount() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        return sessions.filter { $0.endedAt != nil }.count
    }

    private func maxWorkoutDurationMinutes() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        return sessions.compactMap { session in
            guard let end = session.endedAt else { return nil }
            return Int(end.timeIntervalSince(session.startedAt) / 60)
        }.max() ?? 0
    }

    private func hasAnyPR() -> Bool {
        #if os(iOS)
        let workoutService = (UIApplication.shared.connectedScenes.first?.delegate as? any AnyObject)
        #endif
        return totalPRCount() >= 1
    }

    private func totalPRCount() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        var seenExercises: Set<UUID> = []
        var count = 0
        let sorted = sessions.filter { $0.endedAt != nil }.sorted { ($0.startedAt) < ($1.startedAt) }
        for session in sorted {
            let prs = session.sets.filter { $0.isCompleted && !$0.isWarmup && $0.exercise != nil }
            for set in prs {
                guard let exercise = set.exercise else { continue }
                if !seenExercises.contains(exercise.id) && set.volumeValue > 0 {
                    seenExercises.insert(exercise.id)
                    count += 1
                }
            }
        }
        return count
    }

    private func totalVolume() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        let allSets = sessions.flatMap(\.sets).filter(\.isCompleted)
        var total: Double = 0
        for set in allSets {
            guard let type = set.exercise?.trackingType else { continue }
            switch type {
            case .repsWeight: total += (set.weight ?? 0) * Double(set.reps ?? 0)
            case .reps: total += Double(set.reps ?? 0) * 60.0
            case .duration: total += Double(set.durationSeconds ?? 0) * 0.5
            case .distanceDuration: total += (set.distanceMeters ?? 0) * 0.05
            }
        }
        return Int(total)
    }

    private func workoutStreakDays() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        let completedDays = Set(sessions.compactMap { $0.endedAt }.map { Calendar.current.startOfDay(for: $0) })
        guard !completedDays.isEmpty else { return 0 }
        let sorted = completedDays.sorted()
        var streak = 1
        var maxStreak = 1
        for i in 1..<sorted.count {
            let diff = Calendar.current.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { streak += 1; maxStreak = max(maxStreak, streak) }
            else if diff > 1 { streak = 1 }
        }
        let today = Calendar.current.startOfDay(for: .now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        return completedDays.contains(today) || completedDays.contains(yesterday) ? maxStreak : 0
    }

    private func hasWorkoutCategory(_ category: ExerciseCategory) -> Bool {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        return sessions.contains { session in
            session.sets.contains { set in
                set.isCompleted && set.exercise?.category == category
            }
        }
    }

    private func totalCompletedSets() -> Int {
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        return sessions.flatMap(\.sets).filter(\.isCompleted).count
    }

    private func treeCount() -> Int {
        ((try? forestService.trees()) ?? []).count
    }

    private func hasTreeSpecies(_ species: TreeSpecies) -> Bool {
        ((try? forestService.trees()) ?? []).contains { $0.species == species }
    }

    private func treeSpecies(for def: AchievementDefinition) -> TreeSpecies {
        switch def {
        case .firstOak: return .oak
        case .firstPine: return .pine
        case .firstBirch: return .birch
        case .firstMaple: return .maple
        case .firstWillow: return .willow
        case .firstCherry: return .cherry
        case .firstSequoia: return .sequoia
        case .firstBonsai: return .bonsai
        default: return .oak
        }
    }

    private func treesAtOrAboveGrowthStage(_ stage: TreeGrowthStage) -> Int {
        ((try? forestService.trees()) ?? []).filter { $0.stage.rawValue >= stage.rawValue }.count
    }

    private func ancientTreeCount() -> Int {
        ((try? forestService.trees()) ?? []).filter { $0.stage == .ancient }.count
    }

    private func musclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        return rankings.filter { $0.rank >= rank }.count
    }

    private func upperBodyMusclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        let upperCategories: [MuscleCategory] = [.upperFront, .upperBack]
        return rankings.filter { $0.rank >= rank && upperCategories.contains($0.muscleGroup.category) }.count
    }

    private func lowerBodyMusclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        let lowerCategories: [MuscleCategory] = [.lowerFront, .lowerBack]
        return rankings.filter { $0.rank >= rank && lowerCategories.contains($0.muscleGroup.category) }.count
    }

    private func coreMusclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        return rankings.filter { $0.rank >= rank && ($0.muscleGroup == .core || $0.muscleGroup == .obliques) }.count
    }

    private func backMusclesAtOrAbove(rank: MuscleRank) -> Int {
        guard let rankings = try? muscleRankingService.calculateRankings() else { return 0 }
        return rankings.filter { $0.rank >= rank && $0.muscleGroup.category == .upperBack }.count
    }
}