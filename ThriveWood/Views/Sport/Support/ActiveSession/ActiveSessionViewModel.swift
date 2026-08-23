//
//  ActiveSessionViewModel.swift
//  ThriveWood
//
//  Performantes ViewModel für ActiveSessionViewV3. Hält die gruppierten
//  Übungen/Sätze, berechnet Empfehlungen pro Übung EINMAL pro Mutation
//  (nicht inline im body) und debounced den SwiftData-Save, sodass
//  Hinzufügen/Entfernen/Moven von Sätzen nicht mehr laggt.
//

import SwiftUI

@MainActor
@Observable
final class ActiveSessionViewModel {
    private let env: AppEnvironment
    let session: WorkoutSession
    let rest: RestTimer

    // Gruppierte Ansicht der Session-Sätze, geordnet nach Workout-Plan.
    struct Group: Identifiable {
        let id: UUID                  // exercise.id
        let exercise: Exercise
        var sets: [SetEntry]
        var recommendation: SetRecommendation?
        var topSetSummary: String?
    }

    var groups: [Group] = []

    // Live-Statistiken (für Header/StatStrip).
    var completedCount: Int = 0
    var totalVolume: Double = 0
    var exerciseCount: Int = 0

    let errors = ErrorState()

    /// Aktuell laufender Debounce-Task für den context.save().
    private var saveTask: Task<Void, Never>?

    init(env: AppEnvironment, session: WorkoutSession, rest: RestTimer) {
        self.env = env
        self.session = session
        self.rest = rest
    }

    // MARK: - Derived

    var totalSets: Int { session.sets.count }

    var sessionProgress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedCount) / Double(totalSets)
    }

    /// Nächster unvollständiger Satz (für die Next-Set-Bar) + zugehörige Übung.
    var nextIncomplete: (set: SetEntry, exercise: Exercise)? {
        let ordered = session.sets.sorted { $0.order < $1.order }
        guard let set = ordered.first(where: { !$0.isCompleted }),
              let exercise = set.exercise else { return nil }
        return (set, exercise)
    }

    // MARK: - Load / Refresh

    func load() {
        rebuildGroups()
        recomputeStats()
    }

    /// Vollständiger Neuaufbau der Gruppen + Empfehlungen. Nur beim ersten
    /// Laden und nach Strukturänderungen (Übung hinzugefügt/entfernt/moved).
    func rebuildGroups() {
        let raw = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        let workoutOrder: [UUID: Int] = {
            guard let workout = session.workout else { return [:] }
            return Dictionary(uniqueKeysWithValues: workout.exercises.compactMap { slot -> (UUID, Int)? in
                guard let ex = slot.exercise else { return nil }
                return (ex.id, slot.order)
            })
        }()
        let orderedKeys = raw.keys.sorted { id1, id2 in
            let min1 = raw[id1]?.map(\.order).min() ?? 0
            let min2 = raw[id2]?.map(\.order).min() ?? 0
            if min1 != min2 { return min1 < min2 }
            return (workoutOrder[id1] ?? Int.max) < (workoutOrder[id2] ?? Int.max)
        }

        var result: [Group] = []
        for id in orderedKeys {
            guard let sets = raw[id], !sets.isEmpty, let ex = sets.first?.exercise else { continue }
            let sorted = sets.sorted { $0.order < $1.order }
            let topSet = env.workoutService.getTopSet(for: ex)
            let topSummary: String? = {
                guard let topSet, topSet.volumeValue > 0 else { return nil }
                return topSet.summaryText
            }()
            let recommendation: SetRecommendation? = (ex.trackingType == .repsWeight)
                ? env.setRecommendationService.recommend(for: ex, currentSets: sorted, weightUnit: session.weightUnit)
                : nil
            result.append(Group(id: id, exercise: ex, sets: sorted, recommendation: recommendation, topSetSummary: topSummary))
        }
        groups = result
    }

    func recomputeStats() {
        completedCount = session.sets.filter(\.isCompleted).count
        totalVolume = session.sets
            .filter { $0.isCompleted && $0.exercise?.trackingType == .repsWeight }
            .reduce(0) { $0 + $1.volumeValue }
        exerciseCount = Set(session.sets.compactMap { $0.exercise?.id }).count
    }

    // MARK: - Mutations

    func addSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        let last = existing.max(by: { $0.order < $1.order })
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(order: newOrder, exercise: exercise, session: session,
                           reps: last?.reps, weight: last?.weight,
                           durationSeconds: last?.durationSeconds,
                           distanceMeters: last?.distanceMeters)
        session.sets.append(set)
        scheduleSave()
        Haptics.selection()
        // Neue Übung? refreshGroup findet sie sonst nicht (kein bestehender
        // Gruppen-Eintrag) → vollständiger Neuaufbau, sonst targeted refresh.
        if groups.contains(where: { $0.id == exercise.id }) {
            refreshGroup(for: exercise.id)
        } else {
            rebuildGroups()
        }
        recomputeStats()
    }

    func duplicateLastSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        guard let last = existing.max(by: { $0.order < $1.order }) else {
            addSet(for: exercise); return
        }
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(order: newOrder, exercise: exercise, session: session,
                           reps: last.reps, weight: last.weight,
                           durationSeconds: last.durationSeconds,
                           distanceMeters: last.distanceMeters,
                           assistedReps: last.assistedReps)
        session.sets.append(set)
        scheduleSave()
        Haptics.selection()
        refreshGroup(for: exercise.id)
        recomputeStats()
    }

    func toggleComplete(_ set: SetEntry) {
        let wasCompleted = set.isCompleted
        set.isCompleted.toggle()
        set.completedAt = set.isCompleted ? .now : nil
        scheduleSave()

        if !wasCompleted {
            Haptics.success()
            let restSec = session.workout?.exercises
                .first(where: { $0.exercise?.id == set.exercise?.id })?.restSeconds
                ?? (try? env.profileRepo.currentProfile().defaultRestSeconds)
                ?? 90
            if restSec > 0 { rest.start(seconds: restSec) }
        } else {
            Haptics.impact(.light)
        }

        updateLiveActivity(forCompleted: set, becameCompleted: !wasCompleted)
        recomputeStats()
        if let exID = set.exercise?.id { refreshGroup(for: exID) }
    }

    func deleteSet(_ set: SetEntry) {
        guard let exID = set.exercise?.id else { return }
        session.sets.removeAll { $0.id == set.id }
        scheduleSave()
        Haptics.impact(.light)
        refreshGroup(for: exID)
        recomputeStats()
    }

    func removeExercise(_ exercise: Exercise) {
        let toRemove = session.sets.filter { $0.exercise?.id == exercise.id }
        for set in toRemove { session.sets.removeAll { $0.id == set.id } }
        scheduleSave()
        Haptics.impact(.light)
        rebuildGroups()
        recomputeStats()
    }

    /// Tauscht die Position zweier Übungen (Nach-oben/Nach-unten).
    func moveExercise(at from: Int, to: Int) {
        guard from >= 0, to >= 0, from < groups.count, to < groups.count else { return }
        var ordered = groups.map(\.exercise)
        ordered.swapAt(from, to)
        var baseOrder = 0
        for exercise in ordered {
            let sets = session.sets.filter { $0.exercise?.id == exercise.id }.sorted { $0.order < $1.order }
            for (i, set) in sets.enumerated() { set.order = baseOrder + i }
            baseOrder += max(sets.count, 1)
        }
        scheduleSave()
        rebuildGroups()
        Haptics.selection()
    }

    // MARK: - Session Lifecycle

    func finish(perceivedExertion: Int, notes: String) {
        do {
            flushSave()
            try env.workoutService.finishSession(perceivedExertion: perceivedExertion, notes: notes)
            Haptics.success()
            env.achievementService.checkWorkouts()
            env.achievementService.checkMuscle()
        } catch { errors.show(error) }
    }

    func cancel() {
        do {
            try env.workoutService.cancelSession()
        } catch { errors.show(error) }
    }

    func flushSave() {
        saveTask?.cancel()
        saveTask = nil
        try? env.sessionRepo.update(session)
    }

    /// Wendet eine Empfehlung auf den nächsten unvollständigen Satz einer Übung an.
    func applyRecommendation(for exercise: Exercise, recommendation: SetRecommendation?) {
        guard let rec = recommendation else { return }
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        guard let nextSet = existing.first(where: { !$0.isCompleted }) ?? existing.max(by: { $0.order < $1.order }) else { return }
        nextSet.weight = rec.recommendedWeight
        nextSet.reps = rec.recommendedReps
        scheduleSave()
        Haptics.success()
        refreshGroup(for: exercise.id)
    }

    /// Progressive-Overload-Vorschläge fürs Finish-Sheet.
    func computeOverloadSuggestions() -> [FinishSessionSheet.OverloadSuggestion] {
        var suggestions: [FinishSessionSheet.OverloadSuggestion] = []
        for group in groups {
            guard group.exercise.trackingType == .repsWeight else { continue }
            let completedSets = group.sets.filter { $0.isCompleted && !$0.isWarmup }
            guard let bestSet = completedSets.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }) else { continue }
            guard let bestWeight = bestSet.weight, let bestReps = bestSet.reps, bestWeight > 0 else { continue }

            let stats = env.workoutService.getRecentWorkingStats(for: group.exercise)
            let avgWeight = stats?.avgWeight ?? bestWeight
            let avgReps = stats?.avgReps ?? bestReps

            let shouldIncrease = bestWeight >= avgWeight
            guard shouldIncrease else { continue }

            let bump: Double = bestWeight < 20 ? 1.25 : (bestWeight < 60 ? 2.5 : 5.0)
            let suggestedWeight = bestWeight + bump
            let suggestedReps = avgReps

            let increasePercent = ((suggestedWeight - avgWeight) / avgWeight) * 100

            suggestions.append(FinishSessionSheet.OverloadSuggestion(
                exerciseName: group.exercise.name,
                exerciseIcon: group.exercise.iconSystemName,
                lastWeight: bestWeight,
                lastReps: bestReps,
                suggestedWeight: suggestedWeight,
                suggestedReps: suggestedReps,
                increasePercent: increasePercent
            ))
        }
        return Array(suggestions.prefix(5))
    }

    // MARK: - Internals

    /// Aktualisiert eine einzelne Gruppe nach einer Satz-Mutation, ohne die
    /// Empfehlungen aller Übungen neu zu berechnen.
    private func refreshGroup(for exerciseID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == exerciseID }),
              let exercise = groups[index].exercise as Exercise? else { return }
        let sets = session.sets.filter { $0.exercise?.id == exerciseID }.sorted { $0.order < $1.order }
        // Empfehlung nur neu berechnen, wenn sich die Anzahl abgeschlossener
        // Sätze geändert hat (Empfehlung hängt vom nextSetIndex ab).
        let prevCompleted = groups[index].sets.filter(\.isCompleted).count
        let newCompleted = sets.filter(\.isCompleted).count
        var recommendation = groups[index].recommendation
        if exercise.trackingType == .repsWeight, prevCompleted != newCompleted {
            recommendation = env.setRecommendationService.recommend(for: exercise, currentSets: sets, weightUnit: session.weightUnit)
        }
        groups[index] = Group(id: exerciseID, exercise: exercise, sets: sets,
                              recommendation: recommendation,
                              topSetSummary: groups[index].topSetSummary)
    }

    private func updateLiveActivity(forCompleted set: SetEntry, becameCompleted: Bool) {
        let cs = session.sets.filter(\.isCompleted).count
        let ts = session.workout?.exercises.reduce(0) { $0 + $1.targetSets } ?? 0
        let ei = session.workout?.exercises.firstIndex(where: { $0.exercise?.id == set.exercise?.id }) ?? 0
        let elapsed = Int(Date().timeIntervalSince(session.startedAt))
        let setInfo: String? = {
            guard let weight = set.weight, let reps = set.reps else { return nil }
            return "\(Int(weight))kg × \(reps)"
        }()
        env.workoutLiveActivity.update(
            currentExercise: set.exercise?.name ?? "",
            exerciseIndex: ei,
            totalExercises: session.workout?.exercises.count ?? 0,
            completedSets: cs,
            totalSets: ts,
            elapsedSeconds: elapsed,
            lastSetInfo: setInfo
        )
    }

    /// Debounced Save: mutiert das Modell sofort (UI reagiert via @Observable),
    /// persistiert aber erst nach einer kurzen Ruhepause, um wiederholte
    /// context.save()-Aufrufe zu bündeln.
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.flushSave()
        }
    }
}
