//
//  DebugService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 24.04.26.
//

#if DEBUG

import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class DebugService {
    private let env: AppEnvironment
    
    init(env: AppEnvironment) { self.env = env }
    
    // MARK: - Punkte
    
    /// Vergibt Punkte, indem ein "Debug-Habit" automatisch abgehakt wird.
    /// So bleiben alle Analytics/Scoring-Logiken konsistent.
    @discardableResult
    func grantPoints(_ amount: Int, on day: Date = .now) throws -> Int {
        guard amount > 0 else { return 0 }
        let habit = try ensureDebugHabit()
        let normalized = Calendar.app.startOfDay(day)
        
        // Bestehende Debug-Completion an dem Tag finden (oder neu)
        let completion = try env.completionRepo.completion(for: habit, on: normalized)
        ?? {
            let c = HabitCompletion(habit: habit, day: normalized, pointsAwarded: 0)
            try? env.completionRepo.add(c)
            return c
        }()
        
        completion.pointsAwarded += amount
        try env.completionRepo.add(completion)   // save
        return amount
    }
    
    /// Verteilt Punkte zufällig über die letzten `days` Tage.
    func grantPoints(_ total: Int, distributedOverLast days: Int) throws {
        guard days > 0, total > 0 else { return }
        let cal = Calendar.app
        let today = cal.startOfDay()
        var remaining = total
        
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let isLast = offset == days - 1
            let chunk = isLast ? remaining : Int.random(in: 0...(remaining / max(1, days - offset) * 2))
            let capped = min(chunk, remaining)
            if capped > 0 { try grantPoints(capped, on: day) }
            remaining -= capped
            if remaining <= 0 { break }
        }
    }
    
    // MARK: - Seed-Daten
    
    /// Erzeugt eine realistische Beispielwelt: Habits + Completions der letzten 60 Tage.
    func seedSampleData() throws {
        // Habits
        let samples: [(String, String, HabitColor, HabitPoints)] = [
            ("Sport",       "figure.run",         .orange, .high),
            ("Lesen",       "book.fill",          .indigo, .medium),
            ("Meditation",  "brain.head.profile", .purple, .low),
            ("Wasser",      "drop.fill",          .blue,   .low),
            ("Früh aufstehen", "sun.max.fill",    .yellow, .medium)
        ]
        var habits: [Habit] = []
        for (i, s) in samples.enumerated() {
            let h = Habit(
                title: s.0, iconSystemName: s.1, color: s.2,
                points: s.3, sortOrder: i
            )
            try env.habitRepo.create(h)
            habits.append(h)
        }
        
        // Completions – zufällig, aber mit realistischer Streak-Tendenz
        let cal = Calendar.app
        let today = cal.startOfDay()
        for offset in 0..<60 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            for habit in habits {
                if Double.random(in: 0...1) < 0.65 {
                    let c = HabitCompletion(habit: habit, day: day)
                    try env.completionRepo.add(c)
                }
            }
        }
    }
    
    // MARK: - Zeitreise
    
    /// Hakt alle heute fälligen Habits ab (Streak-Booster).
    func completeAllToday() throws {
        for habit in try env.habitService.habitsDue(on: .now) {
            if try !env.habitService.isCompleted(habit) {
                _ = try env.habitService.toggle(habit)
            }
        }
    }
    
    /// Baut eine künstliche Streak von `days` Tagen für einen Habit.
    func buildStreak(for habit: Habit, days: Int) throws {
        let cal = Calendar.app
        let today = cal.startOfDay()
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if try env.completionRepo.completion(for: habit, on: day) == nil {
                let c = HabitCompletion(habit: habit, day: day)
                try env.completionRepo.add(c)
            }
        }
    }
    
    // MARK: - Reset
    
    /// Löscht alle Completions (Punkte-Reset).
    func resetAllCompletions() throws {
        for c in try env.completionRepo.allCompletions() {
            try env.completionRepo.delete(c)
        }
    }
    
    /// Löscht den kompletten Wald.
    func resetForest() throws {
        let forest = try env.forestRepo.currentForest()
        for tree in try env.treeRepo.fetchAll(in: forest) {
            try env.treeRepo.delete(tree)
        }
        forest.spentPoints = 0
        try env.forestRepo.update(forest)
    }
    
    /// Full Wipe – alles außer Built-In-Exercises.
    func wipeEverything() throws {
        try resetAllCompletions()
        try resetForest()
        for h in try env.habitRepo.fetchAll(includeArchived: true) {
            try env.habitRepo.delete(h)
        }
        for w in try env.workoutRepo.fetchAll(includeArchived: true) {
            try env.workoutRepo.delete(w)
        }
        for s in try env.sessionRepo.fetchAll() {
            try env.sessionRepo.delete(s)
        }
    }
    
    // MARK: - Helpers
    
    private static let debugHabitTitle = "🛠 Debug Punkte"
    
    private func ensureDebugHabit() throws -> Habit {
        if let existing = try env.habitRepo.fetchAll(includeArchived: true)
            .first(where: { $0.title == Self.debugHabitTitle }) {
            return existing
        }
        let habit = Habit(
            title: Self.debugHabitTitle,
            iconSystemName: "hammer.fill",
            color: .gray, points: .low,
            sortOrder: Int.max
        )
        habit.archivedAt = .now   // taucht nicht in der Home-Liste auf
        try env.habitRepo.create(habit)
        return habit
    }
    
    func fireTestNotification() async throws {
        guard let habit = try env.habitRepo.fetchAll(includeArchived: false).first else { return }
        guard await env.notificationService.ensureAuthorized() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = habit.title
        content.body = "Test-Reminder ✨"
        content.sound = .default
        content.categoryIdentifier = NotificationService.Category.habitReminder
        content.userInfo = [NotificationService.UserInfoKey.habitID: habit.id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let req = UNNotificationRequest(
            identifier: "debug-\(UUID().uuidString)",
            content: content, trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(req)
    }
    
    func wipeAllSportData() throws {
        try env.workoutRepo.fetchAll(includeArchived: true).forEach { try? env.workoutRepo.delete($0) }
        try env.sessionRepo.fetchAll().forEach { try? env.sessionRepo.delete($0) }
        try env.exerciseRepo.fetchAll().forEach { try? env.exerciseRepo.delete($0) }
    }
}

#endif
