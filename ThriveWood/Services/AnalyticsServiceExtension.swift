//
//  AnalyticsServiceExtension.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import Foundation

// MARK: - Zusätzliche DTOs

struct HabitPerformance: Identifiable, Hashable {
    var id: UUID { habitID }
    let habitID: UUID
    let title: String
    let iconSystemName: String
    let colorRaw: String
    let completionRate: Double   // 0...1
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let pointsEarned: Int

    var color: HabitColor { HabitColor(rawValue: colorRaw) ?? .green }
}

struct WeekdayDistribution: Identifiable, Hashable {
    var id: Int { weekday }
    let weekday: Int       // 1...7 (So…Sa, Calendar-Standard)
    let shortLabel: String
    let completions: Int
    let points: Int
}

struct AnalyticsSummary {
    let totalPoints: Int
    let totalCompletions: Int
    let activeDays: Int
    let averagePointsPerActiveDay: Double
    let bestDay: DailyPointSample?
}

enum AnalyticsRange: String, CaseIterable, Identifiable {
    case week = "7T"
    case month = "30T"
    case quarter = "90T"
    case year = "1J"

    var id: String { rawValue }
    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        }
    }
    var label: String {
        switch self {
        case .week: "Woche"
        case .month: "Monat"
        case .quarter: "Quartal"
        case .year: "Jahr"
        }
    }

    func dateRange(endingAt end: Date = .now) -> ClosedRange<Date> {
        let cal = Calendar.app
        let endDay = cal.startOfDay(end)
        let start = cal.date(byAdding: .day, value: -(days - 1), to: endDay) ?? endDay
        return start...endDay
    }
}

// MARK: - Service-Erweiterung

extension AnalyticsService {

    func summary(in range: ClosedRange<Date>) throws -> AnalyticsSummary {
        let samples = try dailyPoints(in: range)
        let total = samples.reduce(0) { $0 + $1.points }
        let active = samples.filter { $0.points > 0 }.count
        let completions = try completionsRepository.completions(in: range).count
        let avg = active > 0 ? Double(total) / Double(active) : 0
        let best = samples.max(by: { $0.points < $1.points })
        return AnalyticsSummary(
            totalPoints: total,
            totalCompletions: completions,
            activeDays: active,
            averagePointsPerActiveDay: avg,
            bestDay: best
        )
    }

    func weekdayDistribution(in range: ClosedRange<Date>) throws -> [WeekdayDistribution] {
        let comps = try completionsRepository.completions(in: range)
        let cal = Calendar.app
        let symbols = cal.shortWeekdaySymbols

        var buckets: [Int: (count: Int, points: Int)] = [:]
        for c in comps {
            let wd = cal.component(.weekday, from: c.day)
            let cur = buckets[wd] ?? (0, 0)
            buckets[wd] = (cur.count + 1, cur.points + c.pointsAwarded)
        }
        return (1...7).map { wd in
            let b = buckets[wd] ?? (0, 0)
            return WeekdayDistribution(
                weekday: wd,
                shortLabel: symbols[wd - 1],
                completions: b.count,
                points: b.points
            )
        }
    }

    func performance(
        for habits: [Habit],
        in range: ClosedRange<Date>,
        using habitService: HabitService
    ) throws -> [HabitPerformance] {
        try habits.map { habit in
            let comps = try completionsRepository.completions(for: habit, in: range)
            let rate = try habitService.completionRate(for: habit, in: range)
            let cur = try habitService.currentStreak(for: habit)
            let longest = try habitService.longestStreak(for: habit)
            return HabitPerformance(
                habitID: habit.id,
                title: habit.title,
                iconSystemName: habit.iconSystemName,
                colorRaw: habit.colorRaw,
                completionRate: rate,
                currentStreak: cur,
                longestStreak: longest,
                totalCompletions: comps.count,
                pointsEarned: comps.reduce(0) { $0 + $1.pointsAwarded }
            )
        }
    }
}
