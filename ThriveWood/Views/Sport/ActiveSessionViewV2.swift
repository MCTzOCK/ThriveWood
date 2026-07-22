//
//  ActiveSessionViewV2.swift
//  ThriveWood
//
//  Created by Ben Siebert on 14.07.26.
//


import SwiftUI

struct ActiveSessionViewV2: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession

    @State private var rest = RestTimer()
    @State private var exerciseTracker = ExerciseTrackerService()
    @State private var trackingSetEntry: SetEntry?
    @State private var trackingExercise: Exercise?
    @State private var currentExercise: Exercise? = nil
    @State private var showingFinish = false
    @State private var showingCancel = false
    @State private var showingAddSheet = false
    @State private var showingPlayMode = false
    @State private var notes: String = ""
    @State private var rpe: Int = 7
    @State private var errors = ErrorState()

    @State private var groups: [(exercise: Exercise, sets: [SetEntry])] = []
    @State private var topSets: [UUID: SetEntry] = [:]
    @State private var completedCount: Int = 0
    @State private var totalVolume: Double = 0
    @State private var exerciseCount: Int = 0

    @State private var quickCompleteSet: SetEntry?
    @State private var quickCompleteExercise: Exercise?

    private var workoutColor: Color { session.workout?.color.color ?? .blue }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    liveStatsCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    ForEach(Array(groups.enumerated()), id: \.element.exercise.id) { index, group in
                        let supersetColor = supersetColorFor(exerciseId: group.exercise.id)
                        let recommendation = group.exercise.trackingType == .repsWeight
                            ? env.setRecommendationService.recommend(for: group.exercise, currentSets: group.sets, weightUnit: session.weightUnit)
                            : nil
                        ExerciseCardV2(
                            exercise: group.exercise,
                            sets: group.sets,
                            unit: session.weightUnit,
                            topSet: topSets[group.exercise.id],
                            accentColor: workoutColor,
                            supersetColor: supersetColor,
                            recommendation: recommendation,
                            aiService: env.aiService,
                            onAddSet: { addSet(for: group.exercise) },
                            onDuplicate: { duplicateLastSet(for: group.exercise) },
                            onComplete: { toggleComplete($0, for: group.exercise) },
                            onDelete: { deleteSet($0) },
                            onShowDetails: { currentExercise = group.exercise },
                            onStartTracker: { set in startTracker(for: set, exercise: group.exercise) },
                            onMoveUp: index > 0 ? { moveExercise(from: index, to: index - 1) } : nil,
                            onMoveDown: index < groups.count - 1 ? { moveExercise(from: index, to: index + 1) } : nil,
                            onRemove: { group.sets.forEach { deleteSet($0) } },
                            onApplyRecommendation: {
                                applyRecommendation(for: group.exercise, recommendation: recommendation)
                            }
                        )
                        .padding(.horizontal, 16)
                    }

                    addExerciseButton
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    Spacer(minLength: rest.isRunning ? 110 : 130)
                }
            }
            .background(backgroundGradient)
            .scrollIndicators(.hidden)
            .navigationTitle(session.workout?.name ?? "Freies Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { sessionToolbar }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    if rest.isRunning { RestTimerBar(rest: rest) }
                    nextSetBar
                }
            }
            .onAppear { recache(); restoreTrackerIfNeeded() }
            .onChange(of: session.sets.count) { _, _ in recache() }
            .onChange(of: completedSignature) { _, _ in recache() }
            .sheet(isPresented: $showingFinish) { finishSheet }
            .sheet(isPresented: $showingAddSheet) { addSheet }
            .sheet(item: $currentExercise) { ex in ExerciseDetailsSheet(exercise: ex) }
            .confirmationDialog("Workout abbrechen?", isPresented: $showingCancel, titleVisibility: .visible) {
                Button("Ja, abbrechen", role: .destructive) {
                    try? env.workoutService.cancelSession()
                    dismiss()
                }
                Button("Weiter", role: .cancel) {}
            } message: { Text("Alle Sätze gehen verloren.") }
            .errorAlert(errors)
            .fullScreenCover(item: $trackingExercise) { ex in trackerCover(ex) }
            .fullScreenCover(isPresented: $showingPlayMode) {
                PlayModeView(
                    session: session,
                    unit: session.weightUnit,
                    accentColor: workoutColor,
                    rest: rest,
                    onComplete: { set, ex in
                        toggleComplete(set, for: ex)
                    },
                    onAddSet: { ex in addSet(for: ex) },
                    onSave: { try? env.sessionRepo.update(session) }
                )
            }
            .fullScreenCover(item: $quickCompleteSet) { set in
                QuickCompleteView(
                    set: set,
                    exercise: quickCompleteExercise ?? groups.first(where: { $0.sets.contains(set) })?.exercise ?? Exercise(name: "?"),
                    unit: session.weightUnit,
                    accentColor: workoutColor,
                    onConfirm: { updatedSet in
                        quickCompleteSet = nil
                        quickCompleteExercise = nil
                        let ex = updatedSet.exercise ?? quickCompleteExercise
                        toggleComplete(updatedSet, for: ex ?? Exercise(name: "?"))
                    },
                    onCancel: {
                        quickCompleteSet = nil
                        quickCompleteExercise = nil
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func exerciseCard(index: Int, group: (exercise: Exercise, sets: [SetEntry])) -> some View {
        ExerciseCardV2(
            exercise: group.exercise,
            sets: group.sets,
            unit: session.weightUnit,
            topSet: topSets[group.exercise.id],
            accentColor: workoutColor,
            onAddSet: { addSet(for: group.exercise) },
            onDuplicate: { duplicateLastSet(for: group.exercise) },
            onComplete: { toggleComplete($0, for: group.exercise) },
            onDelete: { deleteSet($0) },
            onShowDetails: { currentExercise = group.exercise },
            onStartTracker: { set in startTracker(for: set, exercise: group.exercise) },
            onMoveUp: index > 0 ? { moveExercise(from: index, to: index - 1) } : nil,
            onMoveDown: index < groups.count - 1 ? { moveExercise(from: index, to: index + 1) } : nil,
            onRemove: { group.sets.forEach { deleteSet($0) } }
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [workoutColor.opacity(0.06), .clear],
                startPoint: .top, endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Live Stats Card

    private var liveStatsCard: some View {
        HStack(spacing: 0) {
            statTile(icon: "checkmark.circle.fill", value: "\(completedCount)", label: "Sätze", tint: .green)
            Divider().frame(height: 36).padding(.horizontal, 2)
            statTile(icon: "scalemass.fill", value: formatVolume(totalVolume), label: "Volumen", tint: workoutColor)
            Divider().frame(height: 36).padding(.horizontal, 2)
            statTile(icon: "dumbbell.fill", value: "\(exerciseCount)", label: "Übungen", tint: .orange)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }

    private func statTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.caption).foregroundStyle(tint)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText(value: Double(completedCount)))
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Next Set Bar

    private var nextSet: (Exercise, SetEntry, Int)? {
        for group in groups {
            for (i, set) in group.sets.enumerated() where !set.isCompleted {
                return (group.exercise, set, i + 1)
            }
        }
        return nil
    }

    @ViewBuilder
    private var nextSetBar: some View {
        if let next = nextSet {
            Button {
                quickCompleteExercise = next.0
                quickCompleteSet = next.1
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(workoutColor.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: next.0.iconSystemName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(workoutColor)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(next.0.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("Satz \(next.2) · \(next.1.summaryText.isEmpty ? "bereit" : next.1.summaryText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 12, y: -2)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .buttonStyle(BounceButtonStyle())
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Add Exercise

    private var addExerciseButton: some View {
        Button { showingAddSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Übung hinzufügen")
            }
            .font(.headline)
            .foregroundStyle(workoutColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(workoutColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
            )
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var sessionToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button("Workout abbrechen", role: .destructive) { showingCancel = true }
                Button("Schließen (läuft weiter)") { dismiss() }
            } label: {
                Image(systemName: "xmark")
            }
        }
        ToolbarItem(placement: .principal) {
            ElapsedTimer(sessionStartedAt: session.startedAt)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 4) {
                Button { showingPlayMode = true } label: {
                    Image(systemName: "play.fill")
                }
                Button("Fertig") { showingFinish = true }
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Sheets

    private var finishSheet: some View {
        FinishSessionSheet(
            rpe: $rpe,
            notes: $notes,
            overloadSuggestions: computeOverloadSuggestions(),
            onConfirm: { finish() }
        )
        .presentationDetents([.medium, .large])
    }

    private var addSheet: some View {
        ExerciseLibraryView(onSelect: { ex in addSet(for: ex) }, asSheet: true, onlyFor: nil)
    }

    private func trackerCover(_ ex: Exercise) -> some View {
        ExerciseTrackerView(tracker: exerciseTracker, exercise: ex) { seconds, distance in
            trackerCompleted(seconds: seconds, distance: distance)
        }
    }

    // MARK: - Derived

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1f t", v / 1000).replacingOccurrences(of: ".", with: ",") }
        return "\(Int(v))"
    }

    private func supersetColorFor(exerciseId: UUID) -> Color? {
        guard let workout = session.workout else { return nil }
        let slot = workout.exercises.first(where: { $0.exercise?.id == exerciseId })
        guard let group = slot?.supersetGroup else { return nil }
        let colors: [Color] = [.orange, .purple, .teal, .pink, .indigo, .brown]
        return colors[(group - 1) % colors.count]
    }

    private func applyRecommendation(for exercise: Exercise, recommendation: SetRecommendation?) {
        guard let rec = recommendation else { return }
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        guard let nextSet = existing.first(where: { !$0.isCompleted }) ?? existing.max(by: { $0.order < $1.order }) else { return }
        nextSet.weight = rec.recommendedWeight
        nextSet.reps = rec.recommendedReps
        try? env.sessionRepo.update(session)
        recache()
        Haptics.success()
    }

    private func computeOverloadSuggestions() -> [FinishSessionSheet.OverloadSuggestion] {
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

    private var completedSignature: Int { session.sets.filter(\.isCompleted).count }

    // MARK: - Recache

    private func recache() {
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
        var result: [(exercise: Exercise, sets: [SetEntry])] = []
        var ts: [UUID: SetEntry] = [:]
        for id in orderedKeys {
            guard let sets = raw[id], !sets.isEmpty, let ex = sets.first?.exercise else { continue }
            result.append((ex, sets.sorted { $0.order < $1.order }))
            ts[ex.id] = env.workoutService.getTopSet(for: ex)
        }
        groups = result
        topSets = ts
        completedCount = session.sets.filter(\.isCompleted).count
        recomputeVolume()
        exerciseCount = result.count
    }

    private func recomputeVolume() {
        totalVolume = session.sets.filter { $0.isCompleted && $0.exercise?.trackingType == .repsWeight }.reduce(0) { $0 + $1.volumeValue }
    }

    // MARK: - Actions

    private func addSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        let last = existing.max(by: { $0.order < $1.order })
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(order: newOrder, exercise: exercise, session: session,
                            reps: last?.reps, weight: last?.weight,
                            durationSeconds: last?.durationSeconds,
                            distanceMeters: last?.distanceMeters)
        session.sets.append(set)
        try? env.sessionRepo.update(session)
        Haptics.selection()
    }

    private func duplicateLastSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        guard let last = existing.max(by: { $0.order < $1.order }) else { return }
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(order: newOrder, exercise: exercise, session: session,
                            reps: last.reps, weight: last.weight,
                            durationSeconds: last.durationSeconds,
                            distanceMeters: last.distanceMeters,
                            assistedReps: last.assistedReps)
        session.sets.append(set)
        try? env.sessionRepo.update(session)
        Haptics.selection()
    }

    private func toggleComplete(_ set: SetEntry, for exercise: Exercise) {
        let wasCompleted = set.isCompleted
        set.isCompleted.toggle()
        set.completedAt = set.isCompleted ? .now : nil
        try? env.sessionRepo.update(session)

        if !wasCompleted {
            Haptics.success()
            let restSec = session.workout?.exercises
                .first(where: { $0.exercise?.id == exercise.id })?.restSeconds
                ?? (try? env.profileRepo.currentProfile().defaultRestSeconds)
                ?? 90
            if restSec > 0 { rest.start(seconds: restSec) }
        } else {
            Haptics.impact(.light)
        }

        let cs = session.sets.filter(\.isCompleted).count
        let ts = session.workout?.exercises.reduce(0) { $0 + $1.targetSets } ?? 0
        let ei = session.workout?.exercises.firstIndex(where: { $0.exercise?.id == exercise.id }) ?? 0
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

    private func deleteSet(_ set: SetEntry) {
        session.sets.removeAll { $0.id == set.id }
        try? env.sessionRepo.update(session)
        Haptics.impact(.light)
    }

    private func moveExercise(from: Int, to: Int) {
        guard from >= 0, to >= 0, from < groups.count, to < groups.count else { return }
        var ordered = groups.map(\.exercise)
        ordered.swapAt(from, to)
        var baseOrder = 0
        for exercise in ordered {
            let sets = session.sets.filter { $0.exercise?.id == exercise.id }.sorted { $0.order < $1.order }
            for (i, set) in sets.enumerated() { set.order = baseOrder + i }
            baseOrder += max(sets.count, 1)
        }
        try? env.sessionRepo.update(session)
        recache()
        Haptics.selection()
    }

    private func finish() {
        do {
            try env.workoutService.finishSession(perceivedExertion: rpe, notes: notes)
            Haptics.success()
            env.achievementService.checkWorkouts()
            env.achievementService.checkMuscle()
            dismiss()
        } catch { errors.show(error) }
    }

    // MARK: - Tracker

    private func startTracker(for set: SetEntry, exercise: Exercise) {
        trackingSetEntry = set
        trackingExercise = exercise
        let trackingType: ExerciseTrackingType
        switch exercise.trackingType {
        case .duration: trackingType = .duration
        case .distanceDuration: trackingType = .distanceDuration
        default: trackingType = .duration
        }
        exerciseTracker.start(trackingType: trackingType, setEntryId: set.id, sessionId: session.id)
    }

    private func restoreTrackerIfNeeded() {
        guard let state = exerciseTracker.savedState,
              state.sessionId == session.id,
              let setEntry = session.sets.first(where: { $0.id == state.setEntryId }),
              let exercise = setEntry.exercise
        else { return }
        trackingSetEntry = setEntry
        trackingExercise = exercise
        exerciseTracker.restore(from: state)
    }

    private func trackerCompleted(seconds: Int, distance: Double?) {
        guard let set = trackingSetEntry else { return }
        set.durationSeconds = seconds
        if let distance { set.distanceMeters = distance }
        set.isCompleted = true
        set.completedAt = .now
        try? env.sessionRepo.update(session)
        Haptics.success()
        exerciseTracker.stop()
        trackingSetEntry = nil
        trackingExercise = nil
        recache()
    }
}



// MARK: - Exercise Card V2

private struct ExerciseCardV2: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let topSet: SetEntry?
    let accentColor: Color
    var supersetColor: Color? = nil
    var recommendation: SetRecommendation? = nil
    var aiService: AIService? = nil
    let onAddSet: () -> Void
    let onDuplicate: () -> Void
    let onComplete: (SetEntry) -> Void
    let onDelete: (SetEntry) -> Void
    let onShowDetails: () -> Void
    let onStartTracker: (SetEntry) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onRemove: () -> Void
    var onApplyRecommendation: (() -> Void)? = nil

    private var completed: Int { sets.filter(\.isCompleted).count }
    private var allDone: Bool { completed == sets.count && !sets.isEmpty }
    private var progress: Double { sets.isEmpty ? 0 : Double(completed) / Double(sets.count) }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            if let recommendation, let aiService, let onApplyRecommendation {
                SetRecommendationBadge(
                    recommendation: recommendation,
                    unit: unit,
                    exerciseName: exercise.name,
                    aiService: aiService,
                    onApply: onApplyRecommendation
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            if !sets.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                        SetRowV2(
                            index: idx + 1,
                            set_: set,
                            unit: unit,
                            onTap: { onComplete(set) },
                            onDelete: { onDelete(set) },
                            onDuplicate: idx == sets.count - 1 ? onDuplicate : nil,
                            onStartTracker: (exercise.trackingType == .duration || exercise.trackingType == .distanceDuration) && !set.isCompleted
                                ? { onStartTracker(set) } : nil
                        )
                        if idx < sets.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            addActionRow
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        )
        .overlay(alignment: .leading) {
            if let sc = supersetColor {
                RoundedRectangle(cornerRadius: 3)
                    .fill(sc)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accentColor.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: exercise.iconSystemName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .lineLimit(1)
                    if let sc = supersetColor {
                        Image(systemName: "link")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(sc)
                    }
                }
                if let topSet, topSet.volumeValue > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "trophy.fill")
                        Text(topSet.summaryText)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                }
            }
            Spacer()
            progressRing
            Menu {
                Button { onShowDetails() } label: { Label("Details", systemImage: "info.circle") }
                if let onMoveUp { Button { onMoveUp() } label: { Label("Nach oben", systemImage: "arrow.up") } }
                if let onMoveDown { Button { onMoveDown() } label: { Label("Nach unten", systemImage: "arrow.down") } }
                Divider()
                Button("Übung entfernen", role: .destructive) { onRemove() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                .frame(width: 32, height: 32)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(allDone ? Color.green : accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.3), value: progress)
            Text("\(completed)/\(sets.count)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(allDone ? .green : .secondary)
        }
    }

    private var addActionRow: some View {
        HStack(spacing: 8) {
            Button { onAddSet() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                    Text("Satz")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(BounceButtonStyle())

            Button { onDuplicate() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus.square.on.square")
                    Text("Duplikat")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }
}

// MARK: - Set Row V2 (no row-tap, only checkmark button triggers complete)

struct SetRowV2: View {
    let index: Int
    @Bindable var set_: SetEntry
    let unit: WeightUnit
    let onTap: () -> Void
    let onDelete: () -> Void
    var onDuplicate: (() -> Void)? = nil
    var onStartTracker: (() -> Void)? = nil

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var distanceText: String = ""
    @State private var assistedText: String = ""
    @State private var hasSynced: Bool = false
    @State private var showAssisted: Bool = false

    private var type: ExerciseTrackingType { set_.exercise?.trackingType ?? .repsWeight }

    var body: some View {
        HStack(spacing: 10) {
            checkmarkButton
            VStack(alignment: .leading, spacing: 4) {
                inputsRow
                if showAssisted {
                    assistedRow
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            Spacer(minLength: 0)
            trackerButton
            deleteButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(set_.isCompleted ? Color.green.opacity(0.06) : Color.clear)
        .animation(.snappy(duration: 0.25), value: set_.isCompleted)
        .animation(.snappy(duration: 0.25), value: showAssisted)
        .onAppear { syncFromModel() }
        .onChange(of: set_.weight) { _, _ in if !hasSynced { syncFromModel() } }
        .onChange(of: set_.reps) { _, _ in if !hasSynced { syncFromModel() } }
    }

    private func syncFromModel() {
        weightText = set_.weight.map { $0.clean } ?? ""
        repsText = set_.reps.map { String($0) } ?? ""
        distanceText = set_.distanceMeters.map { String(format: "%.2f", $0 / 1000).replacingOccurrences(of: ".", with: ",") } ?? ""
        assistedText = set_.assistedReps.map { String($0) } ?? ""
        showAssisted = (set_.assistedReps ?? 0) > 0
    }

    private var checkmarkButton: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(set_.isCompleted ? Color.green : Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 30, height: 30)
                if set_.isCompleted {
                    Circle().fill(Color.green).frame(width: 30, height: 30)
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(BounceButtonStyle())
    }

    @ViewBuilder
    private var inputsRow: some View {
        HStack(spacing: 8) {
            switch type {
            case .repsWeight:
                labeledField(text: $weightText, label: "Gewicht", suffix: unit.rawValue, keyboard: .decimalPad, width: 60)
                    .onChange(of: weightText) { _, newValue in
                        hasSynced = true
                        if newValue.isEmpty { set_.weight = nil }
                        else if let parsed = Double(newValue.replacingOccurrences(of: ",", with: ".")) { set_.weight = parsed }
                        hasSynced = false
                    }
                labeledField(text: $repsText, label: "Reps", suffix: "Wdh", keyboard: .numberPad, width: 60)
                    .onChange(of: repsText) { _, newValue in
                        hasSynced = true
                        set_.reps = newValue.isEmpty ? nil : Int(newValue)
                        hasSynced = false
                    }
            case .reps:
                labeledField(text: $repsText, label: "Reps", suffix: "Wdh", keyboard: .numberPad, width: 60)
                    .onChange(of: repsText) { _, newValue in
                        hasSynced = true
                        set_.reps = newValue.isEmpty ? nil : Int(newValue)
                        hasSynced = false
                    }
            case .duration:
                durationField(seconds: Binding(get: { set_.durationSeconds ?? 0 }, set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
            case .distanceDuration:
                labeledField(text: $distanceText, label: "Distanz", suffix: "km", keyboard: .decimalPad, width: 60)
                    .onChange(of: distanceText) { _, newValue in
                        hasSynced = true
                        if newValue.isEmpty { set_.distanceMeters = nil }
                        else { set_.distanceMeters = (Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000 }
                        hasSynced = false
                    }
                durationField(seconds: Binding(get: { set_.durationSeconds ?? 0 }, set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
            }

            if type == .repsWeight {
                Button {
                    withAnimation(.snappy) { showAssisted.toggle() }
                    if !showAssisted { set_.assistedReps = nil; assistedText = "" }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAssisted ? "person.2.fill" : "person.2")
                            .font(.caption2.weight(.bold))
                        if !showAssisted {
                            Text("Assist")
                                .font(.caption2.weight(.medium))
                        }
                    }
                    .foregroundStyle(showAssisted ? .orange : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showAssisted ? Color.orange.opacity(0.12) : Color(.tertiarySystemFill))
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var assistedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text("Assisted Reps")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.orange)
            Spacer(minLength: 0)
            TextField("0", text: $assistedText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                .font(.caption.weight(.semibold).monospacedDigit())
                .onChange(of: assistedText) { _, newValue in
                    hasSynced = true
                    set_.assistedReps = newValue.isEmpty ? nil : Int(newValue)
                    hasSynced = false
                }
            Text("Wdh")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }

    @ViewBuilder
    private var trackerButton: some View {
        if let onStartTracker, !set_.isCompleted {
            Button(action: onStartTracker) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(BounceButtonStyle())
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.caption)
                .foregroundStyle(.red.opacity(0.5))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(BounceButtonStyle())
    }

    @ViewBuilder
    private func labeledField(text: Binding<String>, label: String, suffix: String, keyboard: UIKeyboardType, width: CGFloat = 60) -> some View {
        VStack(spacing: 2) {
            TextField("0", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .frame(width: width)
                .font(.subheadline.weight(.semibold).monospacedDigit())
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                if !suffix.isEmpty {
                    Text("· \(suffix)")
                        .font(.system(size: 9))
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    private func durationField(seconds: Binding<Int>) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                TextField("0", value: Binding(
                    get: { seconds.wrappedValue / 60 },
                    set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Text(":").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                TextField("00", value: Binding(
                    get: { seconds.wrappedValue % 60 },
                    set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            Text("Dauer · min")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Quick Complete FullScreen Cover

private struct QuickCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var set: SetEntry
    let exercise: Exercise
    let unit: WeightUnit
    let accentColor: Color
    let onConfirm: (SetEntry) -> Void
    let onCancel: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var durationMinutes: String = ""
    @State private var durationSeconds: String = ""
    @State private var distanceText: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps, durationMin, durationSec, distance }

    private var type: ExerciseTrackingType { exercise.trackingType }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator
                header
                Spacer()
                inputFields
                Spacer()
                actionButtons
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .statusBarHidden(true)
        .onAppear { setupDefaults(); focusedField = firstField }
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: exercise.iconSystemName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            Text(exercise.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Satz eintragen & abschließen")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var inputFields: some View {
        VStack(spacing: 20) {
            switch type {
            case .repsWeight:
                HStack(spacing: 16) {
                    bigInputField(
                        text: $weightText,
                        label: "Gewicht",
                        suffix: unit.rawValue,
                        placeholder: "0",
                        field: .weight
                    )
                    Text("×").font(.title.weight(.bold)).foregroundStyle(.white.opacity(0.4))
                    bigInputField(
                        text: $repsText,
                        label: "Reps",
                        suffix: "Wdh",
                        placeholder: "0",
                        field: .reps
                    )
                }
            case .reps:
                bigInputField(
                    text: $repsText,
                    label: "Reps",
                    suffix: "Wdh",
                    placeholder: "0",
                    field: .reps
                )
                .frame(maxWidth: 240)
            case .duration:
                HStack(spacing: 12) {
                    bigInputField(
                        text: $durationMinutes,
                        label: "Minuten",
                        suffix: "min",
                        placeholder: "0",
                        field: .durationMin
                    )
                    bigInputField(
                        text: $durationSeconds,
                        label: "Sekunden",
                        suffix: "s",
                        placeholder: "0",
                        field: .durationSec
                    )
                }
            case .distanceDuration:
                HStack(spacing: 16) {
                    bigInputField(
                        text: $distanceText,
                        label: "Distanz",
                        suffix: "km",
                        placeholder: "0,00",
                        field: .distance
                    )
                    Text("+").font(.title.weight(.bold)).foregroundStyle(.white.opacity(0.4))
                    HStack(spacing: 12) {
                        bigInputField(
                            text: $durationMinutes,
                            label: "Min",
                            suffix: "",
                            placeholder: "0",
                            field: .durationMin
                        )
                        bigInputField(
                            text: $durationSeconds,
                            label: "Sek",
                            suffix: "",
                            placeholder: "0",
                            field: .durationSec
                        )
                    }
                }
            }
        }
    }

    private func bigInputField(text: Binding<String>, label: String, suffix: String, placeholder: String, field: Field) -> some View {
        VStack(spacing: 8) {
            TextField(placeholder, text: text)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .keyboardType(field == .distance ? .decimalPad : .numberPad)
                .focused($focusedField, equals: field)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
            HStack(spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                if !suffix.isEmpty {
                    Text("· \(suffix)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                applyValues()
                onConfirm(set)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text("Speichern & Abhaken")
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor)
                )
            }
            .buttonStyle(BounceButtonStyle())

            Button {
                onCancel()
            } label: {
                Text("Abbrechen")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 8)
            }
        }
    }

    private var firstField: Field? {
        switch type {
        case .repsWeight: .weight
        case .reps: .reps
        case .duration: .durationMin
        case .distanceDuration: .distance
        }
    }

    private func setupDefaults() {
        if let w = set.weight { weightText = w.clean }
        if let r = set.reps { repsText = String(r) }
        let totalSec = set.durationSeconds ?? 0
        durationMinutes = totalSec > 0 ? String(totalSec / 60) : ""
        durationSeconds = totalSec > 0 ? String(totalSec % 60) : ""
        if let d = set.distanceMeters { distanceText = String(format: "%.2f", d / 1000).replacingOccurrences(of: ".", with: ",") }
    }

    private func applyValues() {
        switch type {
        case .repsWeight:
            set.weight = weightText.isEmpty ? nil : Double(weightText.replacingOccurrences(of: ",", with: "."))
            set.reps = repsText.isEmpty ? nil : Int(repsText)
        case .reps:
            set.reps = repsText.isEmpty ? nil : Int(repsText)
        case .duration:
            let min = Int(durationMinutes) ?? 0
            let sec = Int(durationSeconds) ?? 0
            set.durationSeconds = (min * 60 + sec) == 0 ? nil : (min * 60 + sec)
        case .distanceDuration:
            set.distanceMeters = distanceText.isEmpty ? nil : (Double(distanceText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000
            let dmin = Int(durationMinutes) ?? 0
            let dsec = Int(durationSeconds) ?? 0
            set.durationSeconds = (dmin * 60 + dsec) == 0 ? nil : (dmin * 60 + dsec)
        }
    }
}

// MARK: - Play Mode (custom swipe, inline rest timer, set navigation)

private struct PlayModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    let unit: WeightUnit
    let accentColor: Color
    let rest: RestTimer
    let onComplete: (SetEntry, Exercise) -> Void
    let onAddSet: (Exercise) -> Void
    let onSave: () -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @GestureState private var dragActive: CGFloat = 0
    @State private var cachedGroups: [(exercise: Exercise, sets: [SetEntry])] = []

    private var groups: [(exercise: Exercise, sets: [SetEntry])] {
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
        return orderedKeys.compactMap { id in
            guard let sets = raw[id], !sets.isEmpty, let ex = sets.first?.exercise else { return nil }
            return (ex, sets.sorted { $0.order < $1.order })
        }
    }

    var body: some View {
        let wCount = cachedGroups.count

        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if wCount > 0 {
                    GeometryReader { geo in
                        let cardWidth = geo.size.width
                        let totalOffset = -CGFloat(currentIndex) * cardWidth + dragOffset + dragActive

                        HStack(spacing: 0) {
                            ForEach(Array(cachedGroups.enumerated()), id: \.element.exercise.id) { index, group in
                                ExercisePlayCard(
                                    exercise: group.exercise,
                                    sets: group.sets,
                                    unit: unit,
                                    accentColor: accentColor,
                                    rest: rest,
                                    exerciseIndex: index + 1,
                                    totalExercises: wCount,
                                    canGoBack: index > 0,
                                    canGoForward: index < wCount - 1,
                                    onBack: { goTo(index - 1) },
                                    onForward: { goTo(index + 1) },
                                    onComplete: { set in onComplete(set, group.exercise) },
                                    onAddSet: { onAddSet(group.exercise) }
                                )
                                .frame(width: cardWidth)
                            }
                        }
                        .offset(x: totalOffset)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: currentIndex)
                        .gesture(
                            DragGesture()
                                .updating($dragActive) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold = cardWidth * 0.2
                                    let velocity: CGFloat = 400

                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                                        if value.translation.width < -threshold || value.predictedEndTranslation.width < -velocity {
                                            if currentIndex < wCount - 1 { currentIndex += 1 }
                                        } else if value.translation.width > threshold || value.predictedEndTranslation.width > velocity {
                                            if currentIndex > 0 { currentIndex -= 1 }
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tray").font(.largeTitle).foregroundStyle(.white.opacity(0.3))
                        Text("Keine Übungen").font(.headline).foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .onAppear { cachedGroups = groups }
        .onChange(of: session.sets.count) { _, _ in cachedGroups = groups }
        .onDisappear { onSave() }
    }

    private func goTo(_ index: Int) {
        let clamped = max(0, min(index, groups.count - 1))
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
            currentIndex = clamped
        }
        Haptics.selection()
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "list.bullet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            pageDots
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<groups.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? accentColor : Color.white.opacity(0.2))
                    .frame(width: i == currentIndex ? 24 : 8, height: 4)
                    .animation(.snappy, value: currentIndex)
            }
        }
    }
}

// MARK: - Exercise Play Card (with set navigation + inline rest timer)

private struct ExercisePlayCard: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let accentColor: Color
    let rest: RestTimer
    let exerciseIndex: Int
    let totalExercises: Int
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onComplete: (SetEntry) -> Void
    let onAddSet: () -> Void

    @State private var viewSetIndex: Int = 0
    @State private var restWasRunning: Bool = false

    private var currentSet: SetEntry? {
        guard viewSetIndex < sets.count else { return nil }
        return sets[viewSetIndex]
    }

    private var completed: Int { sets.filter(\.isCompleted).count }
    private var allDone: Bool { completed == sets.count && !sets.isEmpty }
    private var progress: Double { sets.isEmpty ? 0 : Double(completed) / Double(sets.count) }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            Spacer()
            if rest.isRunning {
                inlineRestTimer
            } else if let set = currentSet {
                currentSetView(set)
            } else if allDone {
                doneView
            } else {
                emptyView
            }
            Spacer()
            setNavButtons
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .onAppear { viewSetIndex = sets.firstIndex { !$0.isCompleted } ?? 0 }
        .onChange(of: rest.isRunning) { _, isRunning in
            if restWasRunning && !isRunning {
                advanceToNextSet()
            }
            restWasRunning = isRunning
        }
    }

    private func advanceToNextSet() {
        let nextIncomplete = sets.firstIndex { !$0.isCompleted }
        if let next = nextIncomplete {
            if next != viewSetIndex {
                withAnimation(.snappy) { viewSetIndex = next }
            }
        } else if viewSetIndex < sets.count - 1 {
            withAnimation(.snappy) { viewSetIndex += 1 }
        } else if totalExercises > exerciseIndex {
            onForward()
        }
    }

    private var cardHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: exercise.iconSystemName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            Text(exercise.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Text("\(exerciseIndex) / \(totalExercises)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                if !sets.isEmpty {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("\(completed)/\(sets.count) Sätze")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(allDone ? .green : .white.opacity(0.6))
                }
            }
            if !sets.isEmpty {
                progressBar
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(allDone ? Color.green : accentColor)
                    .frame(width: geo.size.width * progress)
                    .animation(.snappy, value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 40)
    }

    private var inlineRestTimer: some View {
        InlineRestTimerView(rest: rest, accentColor: accentColor, setNumber: viewSetIndex + 1)
    }

    @ViewBuilder
    private func currentSetView(_ set: SetEntry) -> some View {
        VStack(spacing: 28) {
            HStack(spacing: 8) {
                Text("Satz \(viewSetIndex + 1)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                if set.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            PlaySetInputs(setEntry: set, unit: unit)

            if set.isCompleted {
                Button {
                    onComplete(set)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Wieder öffnen")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                Button {
                    onComplete(set)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("Abhaken")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accentColor)
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.green.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.green)
            }
            Text("Übung abgeschlossen")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Button { onAddSet() } label: {
                Label("Satz hinzufügen", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(accentColor.opacity(0.15)))
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.3))
            Text("Keine Sätze")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Button { onAddSet() } label: {
                Label("Satz hinzufügen", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
        }
    }

    private var setNavButtons: some View {
        HStack(spacing: 16) {
            Button {
                if viewSetIndex > 0 {
                    withAnimation(.snappy) { viewSetIndex -= 1 }
                    Haptics.selection()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("Satz \(max(1, viewSetIndex))")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewSetIndex > 0 ? .white : .white.opacity(0.15))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(viewSetIndex > 0 ? Color.white.opacity(0.1) : Color.clear)
                )
            }
            .disabled(viewSetIndex == 0)
            .buttonStyle(BounceButtonStyle())

            Spacer()

            Text("\(viewSetIndex + 1) / \(sets.count)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.4))

            Spacer()

            Button {
                if viewSetIndex < sets.count - 1 {
                    withAnimation(.snappy) { viewSetIndex += 1 }
                    Haptics.selection()
                } else {
                    onForward()
                }
            } label: {
                HStack(spacing: 5) {
                    Text(viewSetIndex < sets.count - 1 ? "Satz \(viewSetIndex + 2)" : "Weiter")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(accentColor.opacity(0.15))
                )
            }
            .buttonStyle(BounceButtonStyle())
        }
    }
}

// MARK: - Inline Rest Timer (isolated, doesn't invalidate parent)

private struct InlineRestTimerView: View {
    @Bindable var rest: RestTimer
    let accentColor: Color
    let setNumber: Int

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 6).frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: rest.progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(rest.formatted)
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Pause")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            HStack(spacing: 12) {
                Button { rest.add(15); Haptics.selection() } label: {
                    Text("+15s")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(BounceButtonStyle())

                Button { rest.stop(); Haptics.impact(.light) } label: {
                    Text("Überspringen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(accentColor.opacity(0.15)))
                }
                .buttonStyle(BounceButtonStyle())
            }
            Text("Satz \(setNumber) · als nächstes")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Play Set Inputs

private struct PlaySetInputs: View {
    @Bindable var setEntry: SetEntry
    let unit: WeightUnit

    @State private var assistedText: String = ""
    @State private var showAssisted: Bool = false

    private var type: ExerciseTrackingType { setEntry.exercise?.trackingType ?? .repsWeight }

    var body: some View {
        switch type {
        case .repsWeight: repsWeightInputs
        case .reps: repsOnlyInputs
        case .duration: durationInputs
        case .distanceDuration: distanceDurationInputs
        }
    }

    @ViewBuilder
    private var repsWeightInputs: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                bigInput(
                    text: Binding(
                        get: { setEntry.weight.map { $0.clean } ?? "" },
                        set: { setEntry.weight = $0.isEmpty ? nil : Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ),
                    label: "Gewicht",
                    suffix: unit.rawValue,
                    keyboard: .decimalPad
                )
                Text("×").font(.title.weight(.bold)).foregroundStyle(.white.opacity(0.3))
                bigInput(
                    text: Binding(
                        get: { setEntry.reps.map { String($0) } ?? "" },
                        set: { setEntry.reps = $0.isEmpty ? nil : Int($0) }
                    ),
                    label: "Reps",
                    suffix: "Wdh",
                    keyboard: .numberPad
                )
            }
            if showAssisted {
                bigInput(
                    text: Binding(
                        get: { assistedText },
                        set: {
                            assistedText = $0
                            setEntry.assistedReps = $0.isEmpty ? nil : Int($0)
                        }
                    ),
                    label: "Assisted Reps",
                    suffix: "Wdh",
                    keyboard: .numberPad
                )
                .frame(maxWidth: 240)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Button {
                withAnimation(.snappy) {
                    showAssisted.toggle()
                    if !showAssisted { setEntry.assistedReps = nil; assistedText = "" }
                }
                Haptics.selection()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: showAssisted ? "person.2.fill" : "person.2")
                    Text(showAssisted ? "Assisted aktiv" : "Assisted Reps")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(showAssisted ? .orange : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(showAssisted ? Color.orange.opacity(0.2) : Color.white.opacity(0.08)))
            }
        }
        .onAppear {
            assistedText = setEntry.assistedReps.map { String($0) } ?? ""
            showAssisted = (setEntry.assistedReps ?? 0) > 0
        }
    }

    private var repsOnlyInputs: some View {
        bigInput(
            text: Binding(
                get: { setEntry.reps.map { String($0) } ?? "" },
                set: { setEntry.reps = $0.isEmpty ? nil : Int($0) }
            ),
            label: "Reps",
            suffix: "Wdh",
            keyboard: .numberPad
        )
        .frame(maxWidth: 260)
    }

    private var durationInputs: some View {
        HStack(spacing: 16) {
            bigInput(
                text: Binding(
                    get: { setEntry.durationSeconds.map { String($0 / 60) } ?? "" },
                    set: {
                        let m = Int($0) ?? 0
                        let s = (setEntry.durationSeconds ?? 0) % 60
                        setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                    }
                ),
                label: "Minuten",
                suffix: "min",
                keyboard: .numberPad
            )
            bigInput(
                text: Binding(
                    get: { setEntry.durationSeconds.map { String($0 % 60) } ?? "" },
                    set: {
                        let s = Int($0) ?? 0
                        let m = (setEntry.durationSeconds ?? 0) / 60
                        setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                    }
                ),
                label: "Sekunden",
                suffix: "s",
                keyboard: .numberPad
            )
        }
    }

    private var distanceDurationInputs: some View {
        VStack(spacing: 20) {
            bigInput(
                text: Binding(
                    get: { setEntry.distanceMeters.map { String(format: "%.2f", $0 / 1000).replacingOccurrences(of: ".", with: ",") } ?? "" },
                    set: { setEntry.distanceMeters = $0.isEmpty ? nil : (Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000 }
                ),
                label: "Distanz",
                suffix: "km",
                keyboard: .decimalPad
            )
            .frame(maxWidth: 260)
            HStack(spacing: 16) {
                bigInput(
                    text: Binding(
                        get: { setEntry.durationSeconds.map { String($0 / 60) } ?? "" },
                        set: {
                            let m = Int($0) ?? 0
                            let s = (setEntry.durationSeconds ?? 0) % 60
                            setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                        }
                    ),
                    label: "Min",
                    suffix: "",
                    keyboard: .numberPad
                )
                bigInput(
                    text: Binding(
                        get: { setEntry.durationSeconds.map { String($0 % 60) } ?? "" },
                        set: {
                            let s = Int($0) ?? 0
                            let m = (setEntry.durationSeconds ?? 0) / 60
                            setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                        }
                    ),
                    label: "Sek",
                    suffix: "",
                    keyboard: .numberPad
                )
            }
        }
    }

    @ViewBuilder
    private func bigInput(text: Binding<String>, label: String, suffix: String, keyboard: UIKeyboardType) -> some View {
        VStack(spacing: 8) {
            TextField("0", text: text)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .keyboardType(keyboard)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
            HStack(spacing: 3) {
                Text(label).font(.caption.weight(.semibold))
                if !suffix.isEmpty { Text("· \(suffix)").font(.caption2).foregroundStyle(.white.opacity(0.5)) }
            }
            .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
