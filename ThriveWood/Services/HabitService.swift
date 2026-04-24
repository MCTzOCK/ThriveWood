//
//  HabitService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

@MainActor
@Observable
final class HabitService {
    private let habits: any HabitRepository
    private let completions: any HabitCompletionRepository

    init(habits: any HabitRepository, completions: any HabitCompletionRepository) {
        self.habits = habits
        self.completions = completions
    }

    // MARK: Abhaken

    /// Toggle: legt eine Completion an oder entfernt sie. Gibt die resultierende Punktdifferenz zurück.
    @discardableResult
    func toggle(_ habit: Habit, on day: Date = .now) throws -> Int {
        let normalizedDay = Calendar.app.startOfDay(day)
        if let existing = try completions.completion(for: habit, on: normalizedDay) {
            let delta = -existing.pointsAwarded
            try completions.delete(existing)
            return delta
        } else {
            let c = HabitCompletion(habit: habit, day: normalizedDay)
            try completions.add(c)
            return c.pointsAwarded
        }
    }

    func isCompleted(_ habit: Habit, on day: Date = .now) throws -> Bool {
        try completions.completion(for: habit, on: day) != nil
    }

    // MARK: Abfragen

    func activeHabits() throws -> [Habit] {
        try habits.fetchAll(includeArchived: false)
    }

    func habitsDue(on day: Date = .now) throws -> [Habit] {
        let weekday = Calendar.app.component(.weekday, from: day)
        return try activeHabits().filter { habit in
            switch habit.frequency {
            case .daily: true
            case .weekly: habit.activeWeekdays.contains(weekday)
            case .custom: habit.activeWeekdays.contains(weekday)
            }
        }
    }

    // MARK: Punkte

    func pointsEarned(on day: Date = .now) throws -> Int {
        let start = Calendar.app.startOfDay(day)
        return try completions.completions(in: start...start)
            .reduce(0) { $0 + $1.pointsAwarded }
    }

    func pointsEarned(in range: ClosedRange<Date>) throws -> Int {
        try completions.completions(in: range)
            .reduce(0) { $0 + $1.pointsAwarded }
    }

    func totalPointsEarned() throws -> Int {
        try completions.allCompletions().reduce(0) { $0 + $1.pointsAwarded }
    }

    // MARK: Streaks

    func currentStreak(for habit: Habit, asOf day: Date = .now) throws -> Int {
        let end = Calendar.app.startOfDay(day)
        let start = Calendar.app.date(byAdding: .day, value: -365, to: end) ?? end
        let all = try completions.completions(for: habit, in: start...end)
        let days = Set(all.map { Calendar.app.startOfDay($0.day) })

        var streak = 0
        var cursor = end
        while days.contains(cursor) {
            streak += 1
            guard let prev = Calendar.app.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    func longestStreak(for habit: Habit) throws -> Int {
        let all = try completions.completions(
            for: habit,
            in: Date.distantPast...Date.distantFuture
        )
        let days = all.map { Calendar.app.startOfDay($0.day) }.sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1, current = 1
        for i in 1..<days.count {
            let diff = Calendar.app.daysBetween(days[i - 1], days[i])
            if diff == 1 { current += 1; longest = max(longest, current) }
            else if diff > 1 { current = 1 }
        }
        return longest
    }

    // MARK: Completion-Rate

    /// 0...1 für gegebenen Zeitraum (nur Tage zählen, an denen der Habit fällig war).
    func completionRate(for habit: Habit, in range: ClosedRange<Date>) throws -> Double {
        let comps = try completions.completions(for: habit, in: range)
        let completedDays = Set(comps.map { Calendar.app.startOfDay($0.day) })

        var dueDays = 0
        var cursor = Calendar.app.startOfDay(range.lowerBound)
        let end = Calendar.app.startOfDay(range.upperBound)
        while cursor <= end {
            let weekday = Calendar.app.component(.weekday, from: cursor)
            let isDue: Bool = switch habit.frequency {
                case .daily: true
                case .weekly, .custom: habit.activeWeekdays.contains(weekday)
            }
            if isDue { dueDays += 1 }
            guard let next = Calendar.app.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        guard dueDays > 0 else { return 0 }
        return Double(completedDays.count) / Double(dueDays)
    }
}
