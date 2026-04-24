//
//  AnalyticsViewModel.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import Foundation
import SwiftUI

@MainActor
@Observable
final class AnalyticsViewModel {
    private let env: AppEnvironment

    // UI-State
    var range: AnalyticsRange = .month
    var isLoading: Bool = false

    // Daten
    var summary: AnalyticsSummary?
    var dailySamples: [DailyPointSample] = []
    var weekdayDistribution: [WeekdayDistribution] = []
    var habitPerformances: [HabitPerformance] = []
    var selectedHabitID: UUID?
    var heatmap: [HabitHeatmapCell] = []
    var workoutVolume: [WorkoutVolumeSample] = []

    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    var selectedHabit: HabitPerformance? {
        guard let id = selectedHabitID else { return habitPerformances.first }
        return habitPerformances.first { $0.habitID == id } ?? habitPerformances.first
    }

    var dailyGoal: Int {
        (try? env.profileRepo.currentProfile().dailyPointGoal) ?? 5
    }

    // MARK: - Load

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            let r = range.dateRange()
            let habits = try env.habitService.activeHabits()

            summary = try env.analyticsService.summary(in: r)
            dailySamples = try env.analyticsService.dailyPoints(in: r)
            weekdayDistribution = try env.analyticsService.weekdayDistribution(in: r)
            habitPerformances = try env.analyticsService.performance(
                for: habits, in: r, using: env.habitService
            ).sorted { $0.completionRate > $1.completionRate }

            workoutVolume = try env.analyticsService.workoutVolume(in: r)

            if selectedHabitID == nil { selectedHabitID = habitPerformances.first?.habitID }
            loadHeatmap()
        } catch { errors.show(error) }
    }

    func loadHeatmap() {
        guard let habitID = selectedHabitID,
              let habit = try? env.habitRepo.fetch(id: habitID) else {
            heatmap = []
            return
        }
        heatmap = (try? env.analyticsService.heatmap(for: habit, lastDays: 90)) ?? []
    }

    func selectHabit(_ id: UUID) {
        selectedHabitID = id
        loadHeatmap()
    }
}
