//
//  SetRecommendationService.swift
//  ThriveWood
//

import Foundation
import FoundationModels

struct SetRecommendation: Identifiable {
    let id = UUID()
    let recommendedWeight: Double
    let recommendedReps: Int
    let confidence: Confidence
    let reason: Reason
    let aiMotivation: String?

    enum Confidence: Int, CaseIterable {
        case high = 3, medium = 2, low = 1

        var label: String {
            switch self {
            case .high: "Hohe Sicherheit"
            case .medium: "Mittlere Sicherheit"
            case .low: "Niedrige Sicherheit"
            }
        }

        var color: String {
            switch self {
            case .high: "green"
            case .medium: "orange"
            case .low: "red"
            }
        }
    }

    enum Reason {
        case prAttempt
        case progressiveOverload
        case rankPush
        case muscleRecovered
        case firstTime

        var label: String {
            switch self {
            case .prAttempt: "PR Versuch"
            case .progressiveOverload: "Progressiver Overload"
            case .rankPush: "Rank Push"
            case .muscleRecovered: "Muskulär erholt"
            case .firstTime: "Erster Satz"
            }
        }

        var icon: String {
            switch self {
            case .prAttempt: "trophy.fill"
            case .progressiveOverload: "chart.line.uptrend.xyaxis"
            case .rankPush: "shield.fill"
            case .muscleRecovered: "heart.fill"
            case .firstTime: "star.fill"
            }
        }
    }
}

@MainActor
@Observable
final class SetRecommendationService {
    private let workoutService: WorkoutService
    private let rankingService: MuscleRankingService
    private let recoveryService: MuscleRecoveryService
    private let aiService: AIService

    private var cachedRankings: [MuscleRankingData]?
    private var cachedRecovery: [MuscleRecoveryData]?

    init(
        workoutService: WorkoutService,
        rankingService: MuscleRankingService,
        recoveryService: MuscleRecoveryService,
        aiService: AIService
    ) {
        self.workoutService = workoutService
        self.rankingService = rankingService
        self.recoveryService = recoveryService
        self.aiService = aiService
    }

    func recommend(
        for exercise: Exercise,
        currentSets: [SetEntry],
        weightUnit: WeightUnit
    ) -> SetRecommendation? {
        guard exercise.trackingType == .repsWeight else { return nil }

        let completedSets = currentSets.filter { $0.isCompleted && !$0.isWarmup }
        let pr = workoutService.getTopSet(for: exercise)
        let prWeight = pr?.weight ?? 0
        let prReps = pr?.reps ?? 0
        let nextSetIndex = completedSets.count

        let workingStats = workoutService.getRecentWorkingStats(for: exercise)

        refreshCacheIfNeeded()

        let primaryMuscles = exercise.primaryMuscleGroups
        let muscleRanks = primaryMuscles.compactMap { muscle -> MuscleRank? in
            cachedRankings?.first { $0.muscleGroup == muscle }?.rank
        }
        let avgRank: MuscleRank? = muscleRanks.isEmpty ? nil : MuscleRank(rawValue: muscleRanks.reduce(0) { $0 + $1.rawValue } / muscleRanks.count)

        let primaryRecovery = primaryMuscles.compactMap { muscle -> MuscleRecoveryState? in
            cachedRecovery?.first { $0.muscleGroup == muscle }?.state
        }
        let isRecovered = primaryRecovery.allSatisfy { $0 == .recovered } && !primaryRecovery.isEmpty
        let needsRest = primaryRecovery.contains(.needsRest)

        var rec: SetRecommendation

        if nextSetIndex == 0 {
            rec = firstSetRecommendation(
                prWeight: prWeight,
                prReps: prReps,
                workingStats: workingStats,
                avgRank: avgRank,
                isRecovered: isRecovered,
                needsRest: needsRest,
                weightUnit: weightUnit
            )
        } else {
            guard let lastCompleted = completedSets.last,
                  let lastWeight = lastCompleted.weight,
                  let lastReps = lastCompleted.reps else {
                return nil
            }
            rec = subsequentSetRecommendation(
                lastWeight: lastWeight,
                lastReps: lastReps,
                prWeight: prWeight,
                workingStats: workingStats,
                setIndex: nextSetIndex,
                totalSets: currentSets.count,
                avgRank: avgRank,
                isRecovered: isRecovered,
                needsRest: needsRest,
                weightUnit: weightUnit
            )
        }

        if rec.recommendedWeight > prWeight && prWeight > 0 {
            rec = SetRecommendation(
                recommendedWeight: rec.recommendedWeight,
                recommendedReps: rec.recommendedReps,
                confidence: .high,
                reason: .prAttempt,
                aiMotivation: nil
            )
        }

        return rec
    }

    func generateAIMotivation(for recommendation: SetRecommendation, exerciseName: String) async -> String? {
        guard aiService.isAvailable() else { return nil }

        let prompt = """
        Du bist ein motivierender Personal Trainer. Gib eine kurze, maximal 2 Sätze lange motivierende Aussage auf Deutsch für den nächsten Satz der Übung "\(exerciseName)". Die Empfehlung ist \(String(format: "%.1f", recommendation.recommendedWeight)) kg × \(recommendation.recommendedReps) Reps. Grund: \(recommendation.reason.label). Sei direkt, aggressiv motivierend und push den Nutzer an sein Limit. Keine Emojis.
        """

        do {
            let session = LanguageModelSession(model: SystemLanguageModel.default)
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private func firstSetRecommendation(
        prWeight: Double,
        prReps: Int,
        workingStats: WorkoutService.ExerciseWorkingStats?,
        avgRank: MuscleRank?,
        isRecovered: Bool,
        needsRest: Bool,
        weightUnit: WeightUnit
    ) -> SetRecommendation {
        if prWeight == 0 {
            return SetRecommendation(
                recommendedWeight: weightUnit == .kilograms ? 20 : 45,
                recommendedReps: 10,
                confidence: .low,
                reason: .firstTime,
                aiMotivation: nil
            )
        }

        let baseWeight: Double
        let baseReps: Int

        if let stats = workingStats, stats.recentSessionCount >= 2 {
            baseWeight = stats.avgWeight
            baseReps = stats.avgReps
        } else {
            baseWeight = prWeight
            baseReps = prReps
        }

        if needsRest {
            return SetRecommendation(
                recommendedWeight: roundToBar(baseWeight * 0.90, unit: weightUnit),
                recommendedReps: baseReps,
                confidence: .low,
                reason: .progressiveOverload,
                aiMotivation: nil
            )
        }

        let rankValue = avgRank?.rawValue ?? 0
        let recWeight: Double
        let recReps: Int
        let reason: SetRecommendation.Reason
        let confidence: SetRecommendation.Confidence

        if isRecovered && rankValue >= MuscleRank.gold.rawValue {
            let bump = smallJump(for: baseWeight, unit: weightUnit)
            recWeight = roundToBar(baseWeight + bump, unit: weightUnit)
            recReps = baseReps
            reason = .rankPush
            confidence = .high
        } else if isRecovered && rankValue >= MuscleRank.silver.rawValue {
            recWeight = roundToBar(baseWeight, unit: weightUnit)
            recReps = baseReps
            reason = .muscleRecovered
            confidence = .high
        } else if isRecovered {
            recWeight = roundToBar(baseWeight, unit: weightUnit)
            recReps = baseReps
            reason = .muscleRecovered
            confidence = .medium
        } else {
            recWeight = roundToBar(baseWeight * 0.95, unit: weightUnit)
            recReps = baseReps
            reason = .progressiveOverload
            confidence = .medium
        }

        return SetRecommendation(
            recommendedWeight: recWeight,
            recommendedReps: recReps,
            confidence: confidence,
            reason: reason,
            aiMotivation: nil
        )
    }

    private func subsequentSetRecommendation(
        lastWeight: Double,
        lastReps: Int,
        prWeight: Double,
        workingStats: WorkoutService.ExerciseWorkingStats?,
        setIndex: Int,
        totalSets: Int,
        avgRank: MuscleRank?,
        isRecovered: Bool,
        needsRest: Bool,
        weightUnit: WeightUnit
    ) -> SetRecommendation {
        if needsRest {
            return SetRecommendation(
                recommendedWeight: roundToBar(lastWeight, unit: weightUnit),
                recommendedReps: lastReps,
                confidence: .low,
                reason: .progressiveOverload,
                aiMotivation: nil
            )
        }

        let rankValue = avgRank?.rawValue ?? 0
        let isLastSet = setIndex >= totalSets - 1
        let isSecondToLast = setIndex >= totalSets - 2

        let typicalWeight = workingStats?.avgWeight ?? lastWeight
        let typicalReps = workingStats?.avgReps ?? lastReps

        var recWeight: Double
        var recReps: Int
        var reason: SetRecommendation.Reason
        var confidence: SetRecommendation.Confidence

        if isLastSet && rankValue >= MuscleRank.gold.rawValue && isRecovered {
            let bump = jumpSize(for: prWeight, unit: weightUnit)
            recWeight = roundToBar(prWeight + bump, unit: weightUnit)
            recReps = max(1, typicalReps - 4)
            reason = .rankPush
            confidence = .high
        } else if isLastSet && rankValue >= MuscleRank.silver.rawValue && isRecovered {
            let bump = smallJump(for: lastWeight, unit: weightUnit)
            recWeight = roundToBar(lastWeight + bump, unit: weightUnit)
            recReps = typicalReps
            reason = .rankPush
            confidence = .medium
        } else if isSecondToLast && rankValue >= MuscleRank.bronze.rawValue && isRecovered {
            let bump = smallJump(for: lastWeight, unit: weightUnit)
            recWeight = roundToBar(lastWeight + bump, unit: weightUnit)
            recReps = typicalReps
            reason = .rankPush
            confidence = .medium
        } else if isRecovered {
            let bump = smallJump(for: lastWeight, unit: weightUnit)
            recWeight = roundToBar(lastWeight + bump, unit: weightUnit)
            recReps = typicalReps
            reason = .muscleRecovered
            confidence = .medium
        } else {
            let bump = smallJump(for: lastWeight, unit: weightUnit)
            recWeight = roundToBar(lastWeight + bump, unit: weightUnit)
            recReps = typicalReps
            reason = .progressiveOverload
            confidence = .low
        }

        return SetRecommendation(
            recommendedWeight: max(recWeight, roundToBar(2.5, unit: weightUnit)),
            recommendedReps: max(1, recReps),
            confidence: confidence,
            reason: reason,
            aiMotivation: nil
        )
    }

    private func roundToBar(_ weight: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms:
            let step: Double = weight >= 20 ? 2.5 : (weight >= 10 ? 1.25 : 0.5)
            return (weight / step).rounded() * step
        case .pounds:
            let step: Double = weight >= 45 ? 5 : (weight >= 25 ? 2.5 : 1.25)
            return (weight / step).rounded() * step
        }
    }

    private func jumpSize(for prWeight: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms:
            if prWeight < 40 { return 2.5 }
            if prWeight < 80 { return 5 }
            if prWeight < 140 { return 7.5 }
            return 10
        case .pounds:
            if prWeight < 90 { return 5 }
            if prWeight < 180 { return 10 }
            if prWeight < 315 { return 15 }
            return 20
        }
    }

    private func smallJump(for currentWeight: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms:
            if currentWeight < 20 { return 1.25 }
            if currentWeight < 60 { return 2.5 }
            return 2.5
        case .pounds:
            if currentWeight < 45 { return 2.5 }
            if currentWeight < 135 { return 5 }
            return 5
        }
    }

    private func refreshCacheIfNeeded() {
        if cachedRankings == nil {
            cachedRankings = try? rankingService.calculateRankings()
        }
        if cachedRecovery == nil {
            cachedRecovery = try? recoveryService.calculateRecovery()
        }
    }
}
