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
            let volume = normalizedVolume(for: set)

            // Primäre Muskeln (voller Credit)
            for muscle in exercise.primaryMuscleGroups {
                setsPerMuscle[muscle, default: 0] += 1
                volumePerMuscle[muscle, default: 0] += volume

                if let completed = set.completedAt {
                    if lastWorkedPerMuscle[muscle] == nil || completed > lastWorkedPerMuscle[muscle]! {
                        lastWorkedPerMuscle[muscle] = completed
                    }
                }
            }

            // Sekundäre Muskeln (halber Credit fürs Volumen, volle Sets)
            for muscle in exercise.secondaryMuscleGroups {
                setsPerMuscle[muscle, default: 0] += 1
                volumePerMuscle[muscle, default: 0] += volume * 0.5

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
    func overallRank(includeUntrained: Bool = true) throws -> MuscleRank {
        let rankings = try calculateRankings()
        let relevantRankings = includeUntrained 
            ? rankings 
            : rankings.filter { $0.totalVolume > 0 }
        guard !relevantRankings.isEmpty else { return .untrained }
        let avgVol = relevantRankings.map { r in Int(r.totalVolume) }.reduce(0, +) / relevantRankings.count
        return MuscleRank.fromVolume(avgVol)
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

    // MARK: - Normalized Volume

    /// Berechnet ein normalisiertes Volumen für verschiedene Exercise-Typen.
    /// Macht unterschiedliche Einheiten (kg, Reps, Sekunden, Meter) vergleichbar.
    private func normalizedVolume(for set: SetEntry) -> Double {
        guard let type = set.exercise?.trackingType else { return 0 }

        switch type {
        case .repsWeight:
            let totalReps = Double(set.reps ?? 0)
            let assisted = Double(min(set.assistedReps ?? 0, set.reps ?? 0))
            let cleanReps = totalReps - assisted
            return (set.weight ?? 0) * (cleanReps + assisted * 0.6)

        case .reps:
            return Double(set.reps ?? 0) * 60.0

        case .duration:
            return Double(set.durationSeconds ?? 0) * 0.5

        case .distanceDuration:
            return (set.distanceMeters ?? 0) * 0.05
        }
    }
}

