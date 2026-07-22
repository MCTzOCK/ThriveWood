//
//  WellnessService.swift
//  ThriveWood
//

import Foundation
import SwiftData

@MainActor
final class WellnessService {
    private let repo: WellnessRepository
    private let completionRepo: HabitCompletionRepository
    private let sessionRepo: WorkoutSessionRepository

    init(repo: WellnessRepository, completionRepo: HabitCompletionRepository, sessionRepo: WorkoutSessionRepository) {
        self.repo = repo
        self.completionRepo = completionRepo
        self.sessionRepo = sessionRepo
    }

    func save(_ entry: WellnessEntry) throws {
        if try repo.fetchForDay(entry.date) != nil {
            try repo.update(entry)
        } else {
            try repo.add(entry)
        }
    }

    func entryForDay(_ day: Date) throws -> WellnessEntry? {
        try repo.fetchForDay(day)
    }

    func fetchAll() throws -> [WellnessEntry] {
        try repo.fetchAll()
    }

    func delete(_ entry: WellnessEntry) throws {
        try repo.delete(entry)
    }

    struct WellnessSummary {
        let avgMood: Double
        let avgEnergy: Double
        let avgSleep: Double
        let avgStress: Double
        let avgWellnessScore: Double
        let entryCount: Int
    }

    func summary(forDays days: Int) throws -> WellnessSummary {
        let entries = try repo.fetchAll()
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        let recent = entries.filter { $0.date >= cutoff }

        guard !recent.isEmpty else {
            return WellnessSummary(avgMood: 0, avgEnergy: 0, avgSleep: 0, avgStress: 0, avgWellnessScore: 0, entryCount: 0)
        }

        let count = Double(recent.count)
        return WellnessSummary(
            avgMood: recent.map { Double($0.mood) }.reduce(0, +) / count,
            avgEnergy: recent.map { Double($0.energy) }.reduce(0, +) / count,
            avgSleep: recent.map { Double($0.sleepQuality) }.reduce(0, +) / count,
            avgStress: recent.map { Double($0.stress) }.reduce(0, +) / count,
            avgWellnessScore: recent.map(\.wellnessScore).reduce(0, +) / count,
            entryCount: recent.count
        )
    }

    struct CorrelationInsight: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: String
        let color: String
    }

    func correlations() throws -> [CorrelationInsight] {
        let entries = try repo.fetchAll()
        let completions = try completionRepo.allCompletions()
        let sessions = try sessionRepo.fetchAll()
        let calendar = Calendar.current

        var insights: [CorrelationInsight] = []

        let goodSleepDays = Set(entries.filter { $0.sleepQuality >= 4 }.map { calendar.startOfDay(for: $0.date) })
        let badSleepDays = Set(entries.filter { $0.sleepQuality <= 2 }.map { calendar.startOfDay(for: $0.date) })

        if !goodSleepDays.isEmpty && !badSleepDays.isEmpty {
            let goodHabitCompletions = completions.filter { goodSleepDays.contains(calendar.startOfDay(for: $0.day)) }.count
            let badHabitCompletions = completions.filter { badSleepDays.contains(calendar.startOfDay(for: $0.day)) }.count
            let goodRate = Double(goodHabitCompletions) / Double(goodSleepDays.count)
            let badRate = Double(badHabitCompletions) / Double(badSleepDays.count)

            if badRate > 0 {
                let diff = Int(((goodRate / badRate) - 1) * 100)
                if diff > 0 {
                    insights.append(CorrelationInsight(
                        title: "Schlaf & Habits",
                        detail: "An Tagen mit gutem Schlaf schließt du \(diff)% mehr Habits ab.",
                        icon: "bed.double.fill",
                        color: "indigo"
                    ))
                }
            }
        }

        let goodMoodDays = Set(entries.filter { $0.mood >= 4 }.map { calendar.startOfDay(for: $0.date) })
        let badMoodDays = Set(entries.filter { $0.mood <= 2 }.map { calendar.startOfDay(for: $0.date) })

        if !goodMoodDays.isEmpty && !badMoodDays.isEmpty {
            let goodWorkouts = sessions.filter { goodMoodDays.contains(calendar.startOfDay(for: $0.startedAt)) }.count
            let badWorkouts = sessions.filter { badMoodDays.contains(calendar.startOfDay(for: $0.startedAt)) }.count
            let goodRate = Double(goodWorkouts) / Double(goodMoodDays.count)
            let badRate = Double(badWorkouts) / Double(badMoodDays.count)

            if badRate > 0 {
                let diff = Int(((goodRate / badRate) - 1) * 100)
                if diff > 0 {
                    insights.append(CorrelationInsight(
                        title: "Stimmung & Training",
                        detail: "An guten Tagen trainierst du \(diff)% häufiger.",
                        icon: "dumbbell.fill",
                        color: "yellow"
                    ))
                }
            }
        }

        let lowStressDays = Set(entries.filter { $0.stress <= 2 }.map { calendar.startOfDay(for: $0.date) })
        let highStressDays = Set(entries.filter { $0.stress >= 4 }.map { calendar.startOfDay(for: $0.date) })

        if !lowStressDays.isEmpty && !highStressDays.isEmpty {
            let lowCompletions = completions.filter { lowStressDays.contains(calendar.startOfDay(for: $0.day)) }.count
            let highCompletions = completions.filter { highStressDays.contains(calendar.startOfDay(for: $0.day)) }.count
            let lowRate = Double(lowCompletions) / Double(lowStressDays.count)
            let highRate = Double(highCompletions) / Double(highStressDays.count)

            if highRate > 0 {
                let diff = Int(((lowRate / highRate) - 1) * 100)
                if diff > 0 {
                    insights.append(CorrelationInsight(
                        title: "Stress & Produktivität",
                        detail: "An stressfreien Tagen erledigst du \(diff)% mehr Habits.",
                        icon: "brain.head.profile",
                        color: "red"
                    ))
                }
            }
        }

        return insights
    }
}
