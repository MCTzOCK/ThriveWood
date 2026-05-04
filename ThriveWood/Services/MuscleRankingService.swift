//
//  MuscleRankingService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import Foundation
import SwiftData

@MainActor
final class MuscleRankingService {
    private let sessionRepo: WorkoutSessionRepository

    init(sessionRepo: WorkoutSessionRepository) {
        self.sessionRepo = sessionRepo
    }

    /// Berechnet Rankings für alle Muskelgruppen
    func calculateRankings() throws -> [MuscleRankingData] {
        let sessions = try sessionRepo.fetchAll()
        let completedSets = sessions.flatMap { $0.sets.filter { $0.isCompleted } }

        var setsPerMuscle: [MuscleGroup: Int] = [:]
        var volumePerMuscle: [MuscleGroup: Double] = [:]
        var lastWorkedPerMuscle: [MuscleGroup: Date] = [:]

        for set in completedSets {
            guard let exercise = set.exercise else { continue }

            // Primäre Muskeln (voller Credit)
            for muscle in exercise.primaryMuscleGroups {
                setsPerMuscle[muscle, default: 0] += 1
                volumePerMuscle[muscle, default: 0] += (set.weight ?? 0) * Double(set.reps ?? 0)

                if let completed = set.completedAt {
                    if lastWorkedPerMuscle[muscle] == nil || completed > lastWorkedPerMuscle[muscle]! {
                        lastWorkedPerMuscle[muscle] = completed
                    }
                }
            }

            // Sekundäre Muskeln (halber Credit fürs Volumen, volle Sets)
            for muscle in exercise.secondaryMuscleGroups {
                setsPerMuscle[muscle, default: 0] += 1
                volumePerMuscle[muscle, default: 0] += (set.weight ?? 0) * Double(set.reps ?? 0) * 0.5

                if let completed = set.completedAt {
                    if lastWorkedPerMuscle[muscle] == nil || completed > lastWorkedPerMuscle[muscle]! {
                        lastWorkedPerMuscle[muscle] = completed
                    }
                }
            }
        }

        let rankingArray = MuscleGroup.allCases
            .filter { $0.showInDiagram }
            .map { muscle in
                MuscleRankingData(
                    muscleGroup: muscle,
                    totalSets: setsPerMuscle[muscle] ?? 0,
                    totalVolume: volumePerMuscle[muscle] ?? 0,
                    lastWorked: lastWorkedPerMuscle[muscle]
                )
            }
        return rankingArray.sorted { lhs, rhs in
            if lhs.rank != rhs.rank {
                return lhs.rank > rhs.rank
            }
            return lhs.totalSets > rhs.totalSets
        }
    }

    /// Gesamtrang basierend auf Durchschnitt aller Muskeln
    func overallRank() throws -> MuscleRank {
        let rankings = try calculateRankings()
        guard !rankings.isEmpty else { return .untrained }
        let avgSets = rankings.map(\.totalSets).reduce(0, +) / rankings.count
        return MuscleRank.fromSets(avgSets)
    }

    /// Top N schwächste Muskelgruppen
    func weakestMuscles(limit: Int = 3) throws -> [MuscleRankingData] {
        let rankings = try calculateRankings()
        return Array(rankings.sorted { $0.totalSets < $1.totalSets }.prefix(limit))
    }

    /// Top N stärkste Muskelgruppen
    func strongestMuscles(limit: Int = 3) throws -> [MuscleRankingData] {
        Array(try calculateRankings().prefix(limit))
    }

    /// Fortschritt über Zeit für einen bestimmten Muskel
    func progressHistory(for muscle: MuscleGroup, days: Int = 30) throws -> [(date: Date, sets: Int)] {
        let sessions = try sessionRepo.fetchAll()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now

        var dailySets: [Date: Int] = [:]

        for session in sessions {
            let sessionDate = session.startedAt
            guard sessionDate >= startDate else { continue }
            let day = calendar.startOfDay(for: sessionDate)

            let muscleSets = session.sets.filter { set in
                guard set.isCompleted, let exercise = set.exercise else { return false }
                return exercise.primaryMuscleGroups.contains(muscle) ||
                       exercise.secondaryMuscleGroups.contains(muscle)
            }.count

            dailySets[day, default: 0] += muscleSets
        }

        return dailySets
            .map { (date: $0.key, sets: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

