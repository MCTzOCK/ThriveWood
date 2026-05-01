//
//  DailyHabitsProvider.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import WidgetKit
import AppIntents

// MARK: - Daily Habits Provider

@MainActor
struct DailyHabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyHabitsEntry {
        DailyHabitsEntry(date: .now, habits: [], pointsEarned: 0, pointsGoal: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyHabitsEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyHabitsEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    @MainActor private func makeEntry() -> DailyHabitsEntry {
        let provider = WidgetDataProvider.shared
        let habits = provider.habitsDueToday().map { h in
            (habit: h,
             completed: provider.isCompleted(h),
             progress: provider.todayProgress(h),
             streak: provider.streak(for: h))
        }
        let pts = provider.todayPoints()
        return DailyHabitsEntry(date: .now, habits: habits,
                                pointsEarned: pts.earned, 
                                pointsGoal: pts.goal)
    }
}

// MARK: - Habit Streak Provider (Configurable)

struct HabitStreakProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitStreakEntry {
        HabitStreakEntry(date: .now, habitTitle: "Habit", habitIcon: "leaf.fill",
                         habitColor: "green", streak: 7, completedToday: false, progress: 0)
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitStreakEntry {
        await makeEntry(for: configuration)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitStreakEntry> {
        let entry = await makeEntry(for: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(next))
    }

    @MainActor private func makeEntry(for config: SelectHabitIntent) -> HabitStreakEntry {
        let provider = WidgetDataProvider.shared
        let habits = provider.habitsDueToday()
        let habit = habits.first { $0.id.uuidString == config.habitID } ?? habits.first

        guard let h = habit else {
            return HabitStreakEntry(date: .now, habitTitle: "Kein Habit",
                                   habitIcon: "leaf.fill", habitColor: "green",
                                   streak: 0, completedToday: false, progress: 0)
        }
        return HabitStreakEntry(
            date: .now, habitTitle: h.title, habitIcon: h.iconSystemName,
            habitColor: h.colorRaw, streak: provider.streak(for: h),
            completedToday: provider.isCompleted(h),
            progress: provider.todayProgress(h)
        )
    }
}

// MARK: - Forest Provider
@MainActor
struct ForestProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForestEntry {
        ForestEntry(date: .now, treeCount: 12, coverage: 0.25, species: 3,
                    availablePoints: 8, trees: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ForestEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ForestEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    @MainActor private func makeEntry() -> ForestEntry {
        let p = WidgetDataProvider.shared
        let stats = p.forestStats()
        let trees = p.forestTrees().map {
            (species: $0.speciesRaw, gridX: $0.gridX, gridY: $0.gridY,
             stage: $0.stage.rawValue)
        }
        return ForestEntry(date: .now, treeCount: stats.treeCount,
                           coverage: stats.coverage, species: stats.totalSpecies,
                           availablePoints: p.availablePoints(), trees: trees)
    }
}

// MARK: - Workout Provider

@MainActor
struct WorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(date: .now, sessions: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    @MainActor private func makeEntry() -> WorkoutEntry {
        let sessions = WidgetDataProvider.shared.recentSessions(limit: 5).map { s in
            let vol = s.sets.filter(\.isCompleted).reduce(0.0) {
                $0 + ($1.weight ?? 0) * Double($1.reps ?? 0)
            }
            return (name: s.workout?.name ?? "Freies Training",
                    date: s.startedAt,
                    duration: s.durationSeconds ?? 0,
                    volume: vol)
        }
        return WorkoutEntry(date: .now, sessions: sessions)
    }
}
