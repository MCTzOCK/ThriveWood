//
//  MuscleRecoveryService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//

import Foundation
import SwiftData

@MainActor
final class MuscleRecoveryService {
    private let sessionRepo: WorkoutSessionRepository

    init(sessionRepo: WorkoutSessionRepository) {
        self.sessionRepo = sessionRepo
    }

    func calculateRecovery() throws -> [MuscleRecoveryData] {
        let profile = ActivityProfile.current
        let sessions = try sessionRepo.fetchAll()
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let recentSessions = sessions.filter { $0.startedAt >= sevenDaysAgo }
        let completedSets = recentSessions.flatMap { $0.sets.filter { $0.isCompleted } }

        var weeklyVolumePerMuscle: [MuscleGroup: Double] = [:]
        var lastWorkedPerMuscle: [MuscleGroup: Date] = [:]
        var dailyVolumePerMuscle: [MuscleGroup: [Date: Double]] = [:]

        for set in completedSets {
            guard let exercise = set.exercise else { continue }
            let volume = normalizedVolume(for: set)
            let completedDate = set.completedAt ?? set.session?.startedAt ?? now
            let day = calendar.startOfDay(for: completedDate)

            for muscle in exercise.primaryMuscleGroups {
                weeklyVolumePerMuscle[muscle, default: 0] += volume
                if lastWorkedPerMuscle[muscle] == nil || completedDate > lastWorkedPerMuscle[muscle]! {
                    lastWorkedPerMuscle[muscle] = completedDate
                }
                if dailyVolumePerMuscle[muscle] == nil { dailyVolumePerMuscle[muscle] = [:] }
                dailyVolumePerMuscle[muscle]![day, default: 0] += volume
            }

            for muscle in exercise.secondaryMuscleGroups {
                weeklyVolumePerMuscle[muscle, default: 0] += volume * 0.5
                if lastWorkedPerMuscle[muscle] == nil || completedDate > lastWorkedPerMuscle[muscle]! {
                    lastWorkedPerMuscle[muscle] = completedDate
                }
                if dailyVolumePerMuscle[muscle] == nil { dailyVolumePerMuscle[muscle] = [:] }
                dailyVolumePerMuscle[muscle]![day, default: 0] += volume * 0.5
            }
        }

        let consecutiveDaysPerMuscle = calculateConsecutiveDays(dailyVolumePerMuscle: dailyVolumePerMuscle, calendar: calendar, now: now)

        return MuscleGroup.allCases
            .filter { $0.showInDiagram }
            .map { muscle in
                let volume = weeklyVolumePerMuscle[muscle] ?? 0
                let lastWorked = lastWorkedPerMuscle[muscle]
                let daysSince = lastWorked.map { calendar.dateComponents([.day], from: $0, to: now).day ?? 0 }
                let consecutiveDays = consecutiveDaysPerMuscle[muscle] ?? 0

                let analysis = analyzeRecovery(
                    weeklyVolume: volume,
                    daysSinceLastWorked: daysSince,
                    consecutiveDays: consecutiveDays,
                    dailyVolumePerMuscle: dailyVolumePerMuscle[muscle] ?? [:],
                    profile: profile
                )

                return MuscleRecoveryData(
                    muscleGroup: muscle,
                    weeklyVolume: volume,
                    daysSinceLastWorked: daysSince,
                    consecutiveTrainingDays: consecutiveDays,
                    state: analysis.state,
                    restReason: analysis.reason,
                    recommendedRestDays: analysis.restDays
                )
            }
    }

    private struct RecoveryAnalysis {
        let state: MuscleRecoveryState
        let reason: MuscleRestReason
        let restDays: Int
    }

    private let maxRestDays = 3

    private func analyzeRecovery(
        weeklyVolume: Double,
        daysSinceLastWorked: Int?,
        consecutiveDays: Int,
        dailyVolumePerMuscle: [Date: Double],
        profile: ActivityProfile
    ) -> RecoveryAnalysis {
        if weeklyVolume == 0 {
            return RecoveryAnalysis(state: .recovered, reason: .none, restDays: 0)
        }

        if weeklyVolume > profile.maxWeeklyVolumePerMuscle {
            let ratio = weeklyVolume / profile.maxWeeklyVolumePerMuscle
            let restDays = min(maxRestDays, max(1, Int(ratio)))
            return RecoveryAnalysis(state: .needsRest, reason: .weeklyOverload, restDays: restDays)
        }

        if weeklyVolume > profile.warningWeeklyVolumePerMuscle {
            let restDays = weeklyVolume > profile.maxWeeklyVolumePerMuscle * 0.9 ? 2 : 1
            return RecoveryAnalysis(state: .warning, reason: .nearLimit, restDays: min(restDays, maxRestDays))
        }

        if let daysSince = daysSinceLastWorked {
            let requiredDays = Int(profile.recoveryHours / 24.0)
            if daysSince < requiredDays && weeklyVolume >= profile.minVolumeForRecoveryCheck {
                let deficit = requiredDays - daysSince
                return RecoveryAnalysis(state: .needsRest, reason: .insufficientRecovery, restDays: min(maxRestDays, max(1, deficit)))
            }
        }

        if consecutiveDays > profile.maxConsecutiveDays && weeklyVolume >= profile.minVolumeForRecoveryCheck {
            let excess = consecutiveDays - profile.maxConsecutiveDays
            return RecoveryAnalysis(state: .needsRest, reason: .consecutiveOverload, restDays: min(maxRestDays, max(1, excess)))
        }

        let maxDaily = dailyVolumePerMuscle.values.max() ?? 0
        if maxDaily > profile.maxDailyVolumePerMuscle {
            return RecoveryAnalysis(state: .needsRest, reason: .dailyOverload, restDays: 1)
        }

        return RecoveryAnalysis(state: .recovered, reason: .none, restDays: 0)
    }

    private func calculateConsecutiveDays(
        dailyVolumePerMuscle: [MuscleGroup: [Date: Double]],
        calendar: Calendar,
        now: Date
    ) -> [MuscleGroup: Int] {
        var result: [MuscleGroup: Int] = [:]

        for (muscle, dayVolumes) in dailyVolumePerMuscle {
            let trainingDays = dayVolumes.keys.filter { $0 <= now }.sorted(by: >)
            guard !trainingDays.isEmpty else {
                result[muscle] = 0
                continue
            }

            var consecutive = 0
            var currentDay = calendar.startOfDay(for: now)

            while true {
                if dayVolumes[currentDay] != nil && dayVolumes[currentDay]! > 0 {
                    consecutive += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                    currentDay = prev
                } else {
                    break
                }
            }

            result[muscle] = consecutive
        }

        return result
    }

    private func normalizedVolume(for set: SetEntry) -> Double {
        guard let type = set.exercise?.trackingType else { return 0 }
        switch type {
        case .repsWeight:
            return (set.weight ?? 0) * Double(set.reps ?? 0)
        case .reps:
            return Double(set.reps ?? 0) * 60.0
        case .duration:
            return Double(set.durationSeconds ?? 0) * 0.5
        case .distanceDuration:
            return (set.distanceMeters ?? 0) * 0.05
        }
    }
}