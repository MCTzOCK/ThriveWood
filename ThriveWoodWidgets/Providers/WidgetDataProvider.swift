//
//  WidgetDataProvider.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import Foundation
import SwiftData

@MainActor
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    private let context: ModelContext

    private init() {
        context = ModelContext(SharedModelContainer.shared)
        context.autosaveEnabled = false
    }

    // MARK: - Habits

    func habitsDueToday() -> [Habit] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: .now)
        let all = (try? context.fetch(FetchDescriptor<Habit>(
            predicate: #Predicate { $0.archivedAt == nil }
        ))) ?? []
        return all.filter { h in
            h.frequency == .daily || h.activeWeekdays.contains(weekday)
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func completion(for habitID: UUID, on day: Date) -> HabitCompletion? {
        let start = Calendar.current.startOfDay(for: day)
        let all = (try? context.fetch(FetchDescriptor<HabitCompletion>())) ?? []
        return all.first { $0.habit?.id == habitID && Calendar.current.isDate($0.day, inSameDayAs: start) }
    }

    func isCompleted(_ habit: Habit) -> Bool {
        guard let c = completion(for: habit.id, on: .now) else { return false }
        return c.isComplete
    }

    func todayProgress(_ habit: Habit) -> Double {
        guard let c = completion(for: habit.id, on: .now) else { return 0 }
        return c.progress
    }

    func streak(for habit: Habit) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let comps = (try? context.fetch(FetchDescriptor<HabitCompletion>())) ?? []
        let habitComps = comps.filter { $0.habit?.id == habit.id && $0.isComplete }
        let days = Set(habitComps.map { cal.startOfDay(for: $0.day) })

        var streak = 0
        var cursor = today
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    func todayPoints() -> (earned: Int, goal: Int) {
        let today = Calendar.current.startOfDay(for: .now)
        let comps = (try? context.fetch(FetchDescriptor<HabitCompletion>())) ?? []
        let earned = comps.filter { Calendar.current.isDate($0.day, inSameDayAs: today) }
            .reduce(0) { $0 + $1.pointsAwarded }
        let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first
        let goal = profile?.dailyPointGoal ?? 5
        return (earned, goal)
    }

    // MARK: - Forest

    func forestStats() -> (treeCount: Int, coverage: Double, totalSpecies: Int) {
        let forest = (try? context.fetch(FetchDescriptor<Forest>()))?.first
        let trees = (try? context.fetch(FetchDescriptor<TreeEntity>())) ?? []
        let forestTrees = trees.filter { $0.forest?.id == forest?.id }
        let gridSize = 6 * 8
        let coverage = gridSize > 0 ? Double(forestTrees.count) / Double(gridSize) : 0
        let species = Set(forestTrees.map(\.speciesRaw)).count
        return (forestTrees.count, coverage, species)
    }

    func forestTrees() -> [TreeEntity] {
        let forest = (try? context.fetch(FetchDescriptor<Forest>()))?.first
        let trees = (try? context.fetch(FetchDescriptor<TreeEntity>())) ?? []
        return trees.filter { $0.forest?.id == forest?.id }
    }

    // MARK: - Workouts

    func recentSessions(limit: Int = 3) -> [WorkoutSession] {
        let all = (try? context.fetch(FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))) ?? []
        return Array(all.filter { $0.endedAt != nil }.prefix(limit))
    }

    // MARK: - Scoring

    func availablePoints() -> Int {
        let comps = (try? context.fetch(FetchDescriptor<HabitCompletion>())) ?? []
        let earned = comps.reduce(0) { $0 + $1.pointsAwarded }
        let forest = (try? context.fetch(FetchDescriptor<Forest>()))?.first
        let spent = forest?.spentPoints ?? 0
        return earned - spent
    }
}
