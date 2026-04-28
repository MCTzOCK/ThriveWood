//
//  HealthKitService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import Foundation
import HealthKit

@MainActor
@Observable
final class HealthKitService {
    private let store = HKHealthStore()
    
    public static let shared = HealthKitService()
    
    private(set) var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    private(set) var isAuthorized: Bool = false

    // MARK: - Typen, die wir lesen / schreiben wollen

    private var readTypes: Set<HKObjectType> {
        Set([
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKObjectType.workoutType()
        ].compactMap { $0 })
    }

    private var writeTypes: Set<HKSampleType> {
        Set([
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKObjectType.workoutType()
        ].compactMap { $0 })
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            isAuthorized = false
            return false
        }
    }

    // MARK: - Workout speichern

    /// Speichert eine abgeschlossene `WorkoutSession` in Apple Health.
    func save(session: WorkoutSession) async throws {
        guard isAvailable, isAuthorized else { return }
        guard let endedAt = session.endedAt else { return }

        let activityType = mapActivityType(session: session)
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: config,
            device: .local()
        )

        try await builder.beginCollection(at: session.startedAt)

        // Metadaten
        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: true
        ]
        if let name = session.workout?.name {
            metadata[HKMetadataKeyWorkoutBrandName] = "ThriveWood"
            metadata["WorkoutName"] = name
        }
        try await builder.addMetadata(metadata)

        // Samples aus unseren Sets ableiten
        let samples = buildSamples(from: session)
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: endedAt)
        try await builder.finishWorkout()
    }

    // MARK: - Lesen (für Analyse-Tab)

    func fetchSteps(in range: ClosedRange<Date>) async throws -> Double {
        try await fetchSum(type: .stepCount, unit: .count(), in: range)
    }

    func fetchActiveCalories(in range: ClosedRange<Date>) async throws -> Double {
        try await fetchSum(type: .activeEnergyBurned, unit: .kilocalorie(), in: range)
    }

    /// Tagesweise Schritte für Charts.
    func fetchDailySteps(in range: ClosedRange<Date>) async throws -> [(date: Date, steps: Double)] {
        try await fetchDailySum(type: .stepCount, unit: .count(), in: range)
    }

    // MARK: - Mapping

    private func mapActivityType(session: WorkoutSession) -> HKWorkoutActivityType {
        // Wenn wir den Übungstyp kennen, mappen wir passend
        let exercises = session.sets.compactMap { $0.exercise }
        let categories = Set(exercises.map { $0.category })
        let trackingTypes = Set(exercises.map { $0.trackingType })

        if trackingTypes.contains(.distanceDuration) {
            // Prüfe ob es Laufen, Radfahren, etc. ist
            let names = Set(exercises.map { $0.name.lowercased() })
            if names.contains(where: { $0.contains("lauf") || $0.contains("run") }) {
                return .running
            }
            if names.contains(where: { $0.contains("rad") || $0.contains("cycl") }) {
                return .cycling
            }
            if names.contains(where: { $0.contains("schwimm") || $0.contains("swim") }) {
                return .swimming
            }
            if names.contains(where: { $0.contains("ruder") || $0.contains("row") }) {
                return .rowing
            }
            return .running // Default für distanceDuration
        }

        if categories.contains(.cardio) { return .mixedCardio }
        if categories.contains(.mobility) || categories.contains(.stretching) { return .flexibility }
        if categories.contains(.strength) { return .traditionalStrengthTraining }

        return .functionalStrengthTraining
    }

    private func buildSamples(from session: WorkoutSession) -> [HKSample] {
        guard let endedAt = session.endedAt else { return [] }
        var samples: [HKSample] = []

        // Distanz (alle distanceDuration-Sets aufsammeln)
        let totalDistance = session.sets
            .filter { $0.exercise?.trackingType == .distanceDuration && $0.isCompleted }
            .reduce(0.0) { $0 + ($1.distanceMeters ?? 0) }

        if totalDistance > 0 {
            let exercises = session.sets.compactMap { $0.exercise }
            let isCycling = exercises.contains { $0.name.lowercased().contains("rad") || $0.name.lowercased().contains("cycl") }
            let distType: HKQuantityTypeIdentifier = isCycling ? .distanceCycling : .distanceWalkingRunning

            if let type = HKQuantityType.quantityType(forIdentifier: distType) {
                let qty = HKQuantity(unit: .meter(), doubleValue: totalDistance)
                let sample = HKCumulativeQuantitySample(
                    type: type, quantity: qty,
                    start: session.startedAt, end: endedAt
                )
                samples.append(sample)
            }
        }

        // Kalorien schätzen (einfache Heuristik basierend auf Dauer)
        if let durationSec = session.durationSeconds, durationSec > 0 {
            let durationMin = Double(durationSec) / 60
            // Grobe Schätzung: ~6 kcal/min Krafttraining, ~8 kcal/min Cardio
            let exercises = session.sets.compactMap { $0.exercise }
            let isCardioHeavy = exercises.filter { $0.category == .cardio }.count > exercises.count / 2
            let calPerMin: Double = isCardioHeavy ? 8 : 6
            let estimatedCal = durationMin * calPerMin

            if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let qty = HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCal)
                let sample = HKCumulativeQuantitySample(
                    type: type, quantity: qty,
                    start: session.startedAt, end: endedAt
                )
                samples.append(sample)
            }
        }

        return samples
    }

    // MARK: - Generic Fetch Helpers

    private func fetchSum(
        type identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        in range: ClosedRange<Date>
    ) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let predicate = HKQuery.predicateForSamples(
            withStart: range.lowerBound,
            end: range.upperBound,
            options: .strictEndDate
        )
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error { cont.resume(throwing: error); return }
                let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: sum)
            }
            store.execute(query)
        }
    }

    private func fetchDailySum(
        type identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        in range: ClosedRange<Date>
    ) async throws -> [(date: Date, steps: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(
            withStart: range.lowerBound,
            end: range.upperBound,
            options: .strictEndDate
        )
        let interval = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: Calendar.app.startOfDay(range.lowerBound),
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error { cont.resume(throwing: error); return }
                var out: [(Date, Double)] = []
                results?.enumerateStatistics(
                    from: range.lowerBound, to: range.upperBound
                ) { stat, _ in
                    let value = stat.sumQuantity()?.doubleValue(for: unit) ?? 0
                    out.append((stat.startDate, value))
                }
                cont.resume(returning: out)
            }
            store.execute(query)
        }
    }
}
