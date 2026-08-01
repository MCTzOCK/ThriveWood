//
//  SportViewV2Model.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SportViewV2Model {
    private let env: AppEnvironment

    var workouts: [Workout] = []
    var recentSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession? { env.workoutService.activeSession }
    var activePlan: TrainingsPlan?
    var todaysPlannedWorkout: Workout?
    var nextPlannedWorkout: (weekday: TPWeekday, workout: Workout)?
    var recoveryDashboard: MuscleRecoveryService.RecoveryDashboard?
    var todaysWellness: WellnessEntry?
    var weekSessions: [WorkoutSession] = []

    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    func load() {
        do {
            workouts = try env.workoutService.allWorkouts()
            let range = Calendar.app.date(byAdding: .day, value: -30, to: .now)! ... Date.now
            recentSessions = try env.sessionRepo.sessions(in: range)
                .filter { $0.endedAt != nil }
                .sorted { $0.startedAt > $1.startedAt }

            activePlan = try? env.trainingsPlanService.fetchActive()
            todaysPlannedWorkout = try? env.trainingsPlanService.todaysWorkout()
            nextPlannedWorkout = try? env.trainingsPlanService.nextWorkout()
            recoveryDashboard = try? env.muscleRecoveryService.recoveryDashboard()
            todaysWellness = try? env.wellnessService.entryForDay(.now)

            let cal = Calendar.app
            let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            let weekEnd = cal.dateInterval(of: .weekOfYear, for: .now)?.end ?? .now
            weekSessions = (try? env.sessionRepo.sessions(in: weekStart...weekEnd))?
                .filter { $0.endedAt != nil }
                .sorted { $0.startedAt < $1.startedAt } ?? []
        } catch {
            errors.show(error)
        }
    }

    func startSession(for workout: Workout?) -> WorkoutSession? {
        do {
            let session = try env.workoutService.startSession(for: workout)
            Haptics.success()
            return session
        } catch {
            Haptics.warning()
            errors.show(error)
            return nil
        }
    }

    func delete(_ workout: Workout) {
        do {
            try env.workoutService.archiveWorkout(workout)
            withAnimation { workouts.removeAll { $0.id == workout.id } }
        } catch { errors.show(error) }
    }

    // MARK: - Week Helpers

    private let calendar = Calendar.app

    var weekDays: [Date] {
        let today = calendar.startOfDay()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    func plannedWorkout(for date: Date) -> Workout? {
        guard let plan = activePlan else { return nil }
        let weekday = TPWeekday.from(date: date)
        return plan.workout(for: weekday)
    }

    func isRestDay(_ date: Date) -> Bool {
        guard let plan = activePlan else { return false }
        let weekday = TPWeekday.from(date: date)
        guard let day = plan.days.first(where: { $0.weekday == weekday }) else { return false }
        return day.isRestDay
    }

    func sessionCompleted(on date: Date) -> Bool {
        weekSessions.contains { calendar.isDate($0.startedAt, inSameDayAs: date) }
    }

    /// Wurde das übergebene Workout heute bereits absolviert?
    func didCompleteToday(_ workout: Workout?) -> Bool {
        guard let workout else { return false }
        return recentSessions.contains {
            calendar.isDate($0.startedAt, inSameDayAs: .now)
                && $0.workout?.id == workout.id
        }
    }

    /// Heutiges geplantes Workout bereits erledigt?
    var todayWorkoutCompleted: Bool { didCompleteToday(todaysPlannedWorkout) }

    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: .now)
    }

    // MARK: - Week Stats

    var weeklySessionCount: Int { weekSessions.count }

    var weeklyVolume: Double {
        weekSessions.flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0) { $0 + $1.volumeValue }
    }

    var weeklyDurationMinutes: Int {
        weekSessions.compactMap(\.durationSeconds).reduce(0, +) / 60
    }

    var lastSession: WorkoutSession? { recentSessions.first }

    var readinessLabel: String {
        guard let dash = recoveryDashboard else { return "–" }
        if dash.readinessScore >= 70 { return "Hoch" }
        if dash.readinessScore >= 40 { return "Normal" }
        return "Niedrig"
    }

    var readinessColor: Color {
        guard let dash = recoveryDashboard else { return .secondary }
        if dash.readinessScore >= 70 { return .green }
        if dash.readinessScore >= 40 { return .orange }
        return .red
    }

    var todayIsRestDay: Bool {
        guard let plan = activePlan else { return false }
        let weekday = TPWeekday.today
        return plan.days.first { $0.weekday == weekday }?.isRestDay == true
    }
}

// MARK: - TPWeekday Date Helper

extension TPWeekday {
    static func from(date: Date) -> TPWeekday {
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: date)
        let adjusted = weekdayInt == 1 ? 7 : weekdayInt - 1
        return TPWeekday(rawValue: adjusted) ?? .monday
    }
}
