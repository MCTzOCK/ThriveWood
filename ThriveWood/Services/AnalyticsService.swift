//
//  AnalyticsService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

struct DailyPointSample: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let points: Int
}

struct HabitHeatmapCell: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let points: Int
    let isCompleted: Bool
}

struct WorkoutVolumeSample: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let totalVolume: Double   // Σ (weight * reps)
    let totalDuration: Int    // Sekunden
}

@MainActor
@Observable
final class AnalyticsService {
    private let completions: any HabitCompletionRepository
    private let sessionsRepo: any WorkoutSessionRepository
    let completionsRepository: HabitCompletionRepository

    init(completions: any HabitCompletionRepository, sessions: any WorkoutSessionRepository) {
        self.completions = completions
        self.sessionsRepo = sessions
        self.completionsRepository = completions
    }

    // MARK: Habits

    func dailyPoints(in range: ClosedRange<Date>) throws -> [DailyPointSample] {
        let comps = try completions.completions(in: range)
        let grouped = Dictionary(grouping: comps) { Calendar.app.startOfDay($0.day) }

        var out: [DailyPointSample] = []
        var cursor = Calendar.app.startOfDay(range.lowerBound)
        let end = Calendar.app.startOfDay(range.upperBound)
        while cursor <= end {
            let pts = grouped[cursor]?.reduce(0) { $0 + $1.pointsAwarded } ?? 0
            out.append(DailyPointSample(date: cursor, points: pts))
            guard let next = Calendar.app.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return out
    }

    func heatmap(for habit: Habit, lastDays: Int = 90) throws -> [HabitHeatmapCell] {
        let end = Calendar.app.startOfDay()
        let start = Calendar.app.date(byAdding: .day, value: -(lastDays - 1), to: end) ?? end
        let comps = try completions.completions(for: habit, in: start...end)
        let byDay = Dictionary(uniqueKeysWithValues: comps.map {
            (Calendar.app.startOfDay($0.day), $0.pointsAwarded)
        })

        var out: [HabitHeatmapCell] = []
        var cursor = start
        while cursor <= end {
            let pts = byDay[cursor] ?? 0
            out.append(HabitHeatmapCell(date: cursor, points: pts, isCompleted: pts > 0))
            guard let next = Calendar.app.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return out
    }

    // MARK: Workouts

    func workoutVolume(in range: ClosedRange<Date>) throws -> [WorkoutVolumeSample] {
        let sessions = try sessionsRepo.sessions(in: range).filter { $0.endedAt != nil }
        let grouped = Dictionary(grouping: sessions) { Calendar.app.startOfDay($0.startedAt) }
        return grouped.keys.sorted().map { day in
            let daySessions = grouped[day] ?? []
            let volume = daySessions.flatMap(\.sets).reduce(0.0) { acc, set in
                // Nur Strength-Sets in die kg-Volumen-Statistik
                guard set.exercise?.trackingType == .repsWeight else { return acc }
                return acc + (set.weight ?? 0) * Double(set.reps ?? 0)
            }
            let duration = daySessions.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return WorkoutVolumeSample(date: day, totalVolume: volume, totalDuration: duration)
        }
    }

    /// Persönlicher Rekord pro Übung (max. Gewicht × Reps).
    func personalRecord(for exercise: Exercise) throws -> (weight: Double, reps: Int)? {
        let sessions = try sessionsRepo.fetchAll()
        let sets = sessions.flatMap(\.sets).filter { $0.exercise?.id == exercise.id && $0.isCompleted }
        return sets
            .compactMap { s -> (Double, Int)? in
                guard let w = s.weight, let r = s.reps else { return nil }
                return (w, r)
            }
            .max { ($0.0 * Double($0.1)) < ($1.0 * Double($1.1)) }
    }
}
