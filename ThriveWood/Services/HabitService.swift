//
//  HabitService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class HabitService {
    private let habits: any HabitRepository
    private let completions: any HabitCompletionRepository

    /// Optionaler Hook, der nach jeder positiven Habit-Aktion (Toggle an /
    /// Increment, das Punkte bringt) mit der Punktedifferenz aufgerufen wird.
    /// Wird für den „Thrive Companion" genutzt (Energie-Boost). Default `nil`
    /// → kein Verhaltenswechsel für alle Bestands-Call-Sites.
    var onHabitCompleted: ((Int) -> Void)?

    init(habits: any HabitRepository, completions: any HabitCompletionRepository) {
        self.habits = habits
        self.completions = completions
    }

    // MARK: - Einfache Habits (Toggle)

    @discardableResult
    func toggle(_ habit: Habit, on day: Date = .now) throws -> Int {
        guard habit.trackingMode == .simple else {
            return try increment(habit, on: day)
        }
        let normalizedDay = Calendar.app.startOfDay(day)
        if let existing = try completions.completion(for: habit, on: normalizedDay) {
            let delta = -existing.pointsAwarded
            try completions.delete(existing)
            ThriveWoodUnio.scheduleExport()
            WidgetCenter.shared.reloadAllTimelines()
            return delta
        } else {
            let c = HabitCompletion(habit: habit, day: normalizedDay)
            try completions.add(c)
            ThriveWoodUnio.scheduleExport()
            onHabitCompleted?(c.pointsAwarded)
            return c.pointsAwarded
        }
    }

    // MARK: - Messbare Habits (Increment / Decrement / Set)

    /// Erhöht den Fortschritt um `incrementValue`. Gibt die Punktedifferenz zurück.
    @discardableResult
    func increment(_ habit: Habit, by amount: Double? = nil, on day: Date = .now) throws -> Int {
        let step = amount ?? habit.incrementValue
        WidgetCenter.shared.reloadAllTimelines()
        return try adjustValue(habit, delta: step, on: day)
    }

    /// Verringert den Fortschritt um `incrementValue`. Gibt die Punktedifferenz zurück.
    @discardableResult
    func decrement(_ habit: Habit, by amount: Double? = nil, on day: Date = .now) throws -> Int {
        let step = amount ?? habit.incrementValue
        WidgetCenter.shared.reloadAllTimelines()
        return try adjustValue(habit, delta: -step, on: day)
    }

    /// Setzt den Fortschritt auf einen exakten Wert.
    @discardableResult
    func setValue(_ habit: Habit, value: Double, on day: Date = .now) throws -> Int {
        let normalizedDay = Calendar.app.startOfDay(day)
        let completion = try ensureCompletion(for: habit, on: normalizedDay)
        let oldPoints = completion.pointsAwarded
        completion.currentValue = max(0, min(value, habit.targetValue * 1.5))
        completion.completedAt = .now
        completion.recalculatePoints()
        try completions.add(completion)
        ThriveWoodUnio.scheduleExport()
        return completion.pointsAwarded - oldPoints
    }

    private func adjustValue(_ habit: Habit, delta: Double, on day: Date) throws -> Int {
        let normalizedDay = Calendar.app.startOfDay(day)
        let completion = try ensureCompletion(for: habit, on: normalizedDay)
        let oldPoints = completion.pointsAwarded
        let newValue = completion.currentValue + delta

        if newValue <= 0 && delta < 0 {
            // Letzter Schritt rückgängig → Completion löschen
            let diff = -oldPoints
            try completions.delete(completion)
            ThriveWoodUnio.scheduleExport()
            return diff
        }

        completion.currentValue = max(0, newValue)
        completion.completedAt = .now
        completion.recalculatePoints()
        try completions.add(completion)
        ThriveWoodUnio.scheduleExport()
        let delta = completion.pointsAwarded - oldPoints
        if delta > 0 { onHabitCompleted?(delta) }
        return delta
    }

    /// Gibt die vorhandene Completion zurück oder erstellt eine neue mit currentValue = 0.
    private func ensureCompletion(for habit: Habit, on day: Date) throws -> HabitCompletion {
        if let existing = try completions.completion(for: habit, on: day) {
            return existing
        }
        let new = HabitCompletion(habit: habit, day: day, currentValue: 0)
        return new
    }

    // MARK: - Status-Abfragen

    func isCompleted(_ habit: Habit, on day: Date = .now) throws -> Bool {
        guard let c = try completions.completion(for: habit, on: day) else { return false }
        return c.isComplete
    }

    func currentProgress(_ habit: Habit, on day: Date = .now) throws -> (value: Double, target: Double, progress: Double) {
        let target = habit.targetValue
        guard let c = try completions.completion(for: habit, on: day) else {
            return (0, target, 0)
        }
        return (c.currentValue, target, c.progress)
    }

    // MARK: - Bestehende Methoden (unverändert)

    func activeHabits() throws -> [Habit] {
        try habits.fetchAll(includeArchived: false)
    }

    func habitsDue(on day: Date = .now) throws -> [Habit] {
        let weekday = Calendar.app.component(.weekday, from: day)
        return try activeHabits().filter { habit in
            switch habit.frequency {
            case .daily: true
            case .weekly, .custom: habit.activeWeekdays.contains(weekday)
            }
        }
    }

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

    func currentStreak(for habit: Habit, asOf day: Date = .now) throws -> Int {
        let end = Calendar.app.startOfDay(day)
        let start = Calendar.app.date(byAdding: .day, value: -365, to: end) ?? end
        let all = try completions.completions(for: habit, in: start...end)
        // Nur vollständig abgeschlossene Tage zählen für den Streak
        let completedDays = Set(all.filter(\.isComplete).map { Calendar.app.startOfDay($0.day) })

        var streak = 0
        var cursor = end
        while completedDays.contains(cursor) {
            streak += 1
            guard let prev = Calendar.app.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    func longestStreak(for habit: Habit) throws -> Int {
        let all = try completions.completions(for: habit, in: Date.distantPast...Date.distantFuture)
        let days = all.filter(\.isComplete)
            .map { Calendar.app.startOfDay($0.day) }.sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1, current = 1
        for i in 1..<days.count {
            let diff = Calendar.app.daysBetween(days[i - 1], days[i])
            if diff == 1 { current += 1; longest = max(longest, current) }
            else if diff > 1 { current = 1 }
        }
        return longest
    }

    func completionRate(for habit: Habit, in range: ClosedRange<Date>) throws -> Double {
        let comps = try completions.completions(for: habit, in: range)
        let completedDays = Set(comps.filter(\.isComplete).map { Calendar.app.startOfDay($0.day) })

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
