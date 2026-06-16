//
//  ActiveSessionView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI
import Combine

struct ActiveSessionView: View {
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
    @State private var notes: String = ""
    @State private var rpe: Int = 7
    @State private var errors = ErrorState()

    @State private var cachedGroups: [(Exercise, [SetEntry])] = []
    @State private var cachedCompletedCount: Int = 0
    @State private var cachedTotalVolume: Double = 0
    @State private var cachedExerciseCount: Int = 0
    @State private var gyms: [Gym] = []
    @State private var selectedGym: Gym?
    @State private var sessionMode: SessionMode = .classic

    enum SessionMode: String, CaseIterable {
        case classic = "Klassisch"
        case game = "Game"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if sessionMode == .game {
                    gameModeContent
                } else {
                    classicModeContent
                }

                if rest.isRunning { RestTimerBar(rest: rest) }
            }
            .navigationTitle(session.workout?.name ?? "Freies Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen", role: .destructive) { dismiss() }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .principal) {
                    ElapsedTimer(sessionStartedAt: session.startedAt)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { showingFinish = true }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { recache(); restoreTrackerIfNeeded(); resolveGym() }
            .onChange(of: session.sets.count) { _, _ in recache() }
            .onChange(of: completedSignature) { _, _ in recache() }
            .sheet(isPresented: $showingFinish) {
                FinishSessionSheet(rpe: $rpe, notes: $notes) {
                    finish()
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingAddSheet) {
                ExerciseLibraryView(onSelect: { ex in
                    addSet(for: ex)
                }, asSheet: true, onlyFor: nil)
            }
            .sheet(item: $currentExercise) {
                ExerciseDetailsSheet(exercise: $0)
            }
            .confirmationDialog(
                "Workout wirklich abbrechen?",
                isPresented: $showingCancel, titleVisibility: .visible
            ) {
                Button("Ja, abbrechen", role: .destructive) {
                    try? env.workoutService.cancelSession()
                    dismiss()
                }
                Button("Weitertrainieren", role: .cancel) {}
            } message: {
                Text("Alle Sätze dieses Workouts gehen verloren.")
            }
            .errorAlert(errors)
            .fullScreenCover(item: $trackingExercise) { exercise in
                ExerciseTrackerView(
                    tracker: exerciseTracker,
                    exercise: exercise
                ) { seconds, distance in
                    trackerCompleted(seconds: seconds, distance: distance)
                }
            }
        }
    }

    // MARK: - Classic Mode

    private var classicModeContent: some View {
        VStack(spacing: 0) {
            modePicker
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    header
                    ForEach(Array(cachedGroups.enumerated()), id: \.element.0.id) { index, group in
                        let (exercise, sets) = group
                        ExerciseBlock(
                            exercise: exercise,
                            sets: sets,
                            unit: session.weightUnit,
                            topSet: env.workoutService.getTopSet(for: exercise),
                            onAddSet: { addSet(for: exercise) },
                            onComplete: { toggleComplete($0, for: exercise) },
                            onDelete: { deleteSet($0) },
                            removeExercise: {
                                sets.forEach { deleteSet($0) }
                            },
                            showDetails: {
                                withAnimation(.snappy) {
                                    currentExercise = exercise
                                }
                            },
                            onStartTracker: { set in startTracker(for: set, exercise: exercise) },
                            onMoveUp: index > 0 ? { moveExercise(from: index, to: index - 1) } : nil,
                            onMoveDown: index < cachedGroups.count - 1 ? { moveExercise(from: index, to: index + 1) } : nil
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                    AddExerciseButton { addExercise() }
                        .padding(.horizontal, Theme.Spacing.l)

                    Color.clear.frame(height: 120)
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Game Mode

    private var gameModeContent: some View {
        VStack(spacing: 0) {
            modePicker
            if let gym = selectedGym {
                GameMapContent(
                    gym: gym,
                    groups: cachedGroups,
                    onToggleSet: { set, ex in toggleComplete(set, for: ex) },
                    onDeleteSet: { set in deleteSet(set) },
                    onAddSet: { ex in addSet(for: ex) },
                    onAddExercise: { showingAddSheet = true },
                    currentExerciseID: currentIncompleteExerciseID,
                    nextExerciseID: nextIncompleteExerciseID,
                    weightUnit: session.weightUnit
                )
            } else {
                VStack(spacing: Theme.Spacing.l) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Wähle ein Gym für den Game-Modus")
                        .font(.headline)
                    if !gyms.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.m) {
                                ForEach(gyms) { g in
                                    Button {
                                        selectedGym = g
                                        Haptics.selection()
                                    } label: {
                                        HStack(spacing: Theme.Spacing.s) {
                                            Image(systemName: g.iconSystemName)
                                            Text(g.name).font(.subheadline.weight(.semibold))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                    } else {
                        Text("Erstelle zuerst ein Gym unter Mein Gym.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Modus", selection: $sessionMode) {
            ForEach(SessionMode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.l) {
            StatTile(value: "\(cachedCompletedCount)", label: "Sätze", tint: .green)
            StatTile(value: "\(Int(cachedTotalVolume))", label: "Volumen (\(session.weightUnit.rawValue))", tint: .blue)
            StatTile(value: "\(cachedExerciseCount)", label: "Übungen", tint: .orange)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private struct StatTile: View {
        let value: String; let label: String; let tint: Color
        var body: some View {
            VStack(spacing: 4) {
                Text(value).font(.title3.bold().monospacedDigit())
                    .foregroundStyle(tint)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .cardStyle()
        }
    }

    // MARK: Recache

    private var completedSignature: Int {
        session.sets.filter(\.isCompleted).count
    }

    private func recache() {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        let workoutOrder: [UUID: Int] = {
            guard let workout = session.workout else { return [:] }
            return Dictionary(uniqueKeysWithValues: workout.exercises.compactMap { slot -> (UUID, Int)? in
                guard let ex = slot.exercise else { return nil }
                return (ex.id, slot.order)
            })
        }()
        let orderedKeys = groups.keys.sorted { id1, id2 in
            let min1 = groups[id1]?.map(\.order).min() ?? 0
            let min2 = groups[id2]?.map(\.order).min() ?? 0
            if min1 != min2 { return min1 < min2 }
            let w1 = workoutOrder[id1] ?? Int.max
            let w2 = workoutOrder[id2] ?? Int.max
            if w1 != w2 { return w1 < w2 }
            return true
        }
        var result: [(Exercise, [SetEntry])] = []
        for id in orderedKeys {
            guard let sets = groups[id], !sets.isEmpty, let exercise = sets.first?.exercise else { continue }
            result.append((exercise, sets.sorted { $0.order < $1.order }))
        }
        cachedGroups = result
        cachedCompletedCount = session.sets.filter(\.isCompleted).count
        cachedTotalVolume = session.sets.filter { $0.isCompleted && $0.exercise?.trackingType == .repsWeight }.reduce(0) { $0 + $1.volumeValue }
        cachedExerciseCount = result.count
    }

    // MARK: Actions

    private var currentIncompleteExerciseID: UUID? {
        cachedGroups.first(where: { _, sets in sets.contains { !$0.isCompleted } })?.0.id
    }

    private var nextIncompleteExerciseID: UUID? {
        let incomplete = cachedGroups.filter { _, sets in sets.contains { !$0.isCompleted } }
        return incomplete.count > 1 ? incomplete[1].0.id : nil
    }

    private func resolveGym() {
        do { gyms = try env.gymService.allGyms() } catch { errors.show(error) }
        if gyms.count == 1 {
            selectedGym = gyms[0]
        }
    }

    private func addSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        let last = existing.max(by: { $0.order < $1.order })
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(
            order: newOrder, exercise: exercise, session: session,
            reps: last?.reps,
            weight: last?.weight,
            durationSeconds: last?.durationSeconds,
            distanceMeters: last?.distanceMeters
        )
        session.sets.append(set)
        try? env.sessionRepo.update(session)
        Haptics.selection()
    }

    private func addExercise() {
        showingAddSheet = true
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
        
        let completedSets = session.sets.filter(\.isCompleted).count
        let totalSets = session.workout?.exercises.reduce(0) { $0 + $1.targetSets } ?? 0
        let exerciseIndex = session.workout?.exercises.firstIndex(where: { $0.exercise?.id == exercise.id }) ?? 0
        let elapsed = Int(Date().timeIntervalSince(session.startedAt))
        
        let setInfo: String? = {
            guard let weight = set.weight, let reps = set.reps else { return nil }
            return "\(Int(weight))kg × \(reps)"
        }()
        
        env.workoutLiveActivity.update(
            currentExercise: set.exercise?.name ?? "",
            exerciseIndex: exerciseIndex,
            totalExercises: session.workout?.exercises.count ?? 0,
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsed,
            lastSetInfo: setInfo
        )
    }

    private func deleteSet(_ set: SetEntry) {
        session.sets.removeAll { $0.id == set.id }
        try? env.sessionRepo.update(session)
    }

    private func moveExercise(from: Int, to: Int) {
        guard from >= 0, to >= 0, from < cachedGroups.count, to < cachedGroups.count else { return }
        var orderedExercises = cachedGroups.map(\.0)
        orderedExercises.swapAt(from, to)
        var baseOrder = 0
        for exercise in orderedExercises {
            let sets = session.sets.filter { $0.exercise?.id == exercise.id }.sorted { $0.order < $1.order }
            for (i, set) in sets.enumerated() {
                set.order = baseOrder + i
            }
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

    // MARK: Tracker

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
        if let distance {
            set.distanceMeters = distance
        }
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


// MARK: - Game Map Content

struct GameMapContent: View {
    @Environment(AppEnvironment.self) private var env
    let gym: Gym
    let groups: [(Exercise, [SetEntry])]
    let onToggleSet: (SetEntry, Exercise) -> Void
    let onDeleteSet: (SetEntry) -> Void
    let onAddSet: (Exercise) -> Void
    let onAddExercise: () -> Void
    let currentExerciseID: UUID?
    let nextExerciseID: UUID?
    let weightUnit: WeightUnit

    private var workoutEquipment: [GymEquipment] {
        let exerciseIDs = Set(groups.map { $0.0.id })
        return gym.equipment.filter { eq in
            eq.exerciseAssignments.contains { assignment in
                if let exID = assignment.exercise?.id {
                    return exerciseIDs.contains(exID)
                }
                return false
            }
        }
    }

    private var orderedEquipment: [GymEquipment] {
        let exerciseOrder = groups.map { $0.0.id }
        var result: [GymEquipment] = []
        var seen = Set<UUID>()
        for exID in exerciseOrder {
            if let eq = workoutEquipment.first(where: { eq in
                eq.exerciseAssignments.contains { $0.exercise?.id == exID } && !seen.contains(eq.id)
            }) {
                result.append(eq)
                seen.insert(eq.id)
            }
        }
        for eq in workoutEquipment where !seen.contains(eq.id) {
            result.append(eq)
            seen.insert(eq.id)
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GymFloorPlanView(
                    gym: gym,
                    isReadOnly: true,
                    highlightEquipmentID: currentExerciseID.flatMap { id in
                        workoutEquipment.first { eq in
                            eq.exerciseAssignments.contains { $0.exercise?.id == id }
                        }?.id
                    },
                    nextEquipmentID: nextExerciseID.flatMap { id in
                        workoutEquipment.first { eq in
                            eq.exerciseAssignments.contains { $0.exercise?.id == id }
                        }?.id
                    }
                )
                .frame(height: 350)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                .padding(.horizontal, Theme.Spacing.l)

                if !groups.isEmpty {
                    stationList
                } else {
                    emptyGame
                }
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var stationList: some View {
        VStack(spacing: Theme.Spacing.m) {
            ForEach(Array(groups.enumerated()), id: \.element.0.id) { index, group in
                let (exercise, sets) = group
                let isCurrent = exercise.id == currentExerciseID
                let isNext = exercise.id == nextExerciseID
                let completedCount = sets.filter(\.isCompleted).count
                let allDone = completedCount == sets.count

                GameStationCard(
                    index: index + 1,
                    exercise: exercise,
                    sets: sets,
                    isCurrent: isCurrent,
                    isNext: isNext,
                    allDone: allDone,
                    unit: weightUnit,
                    onToggleSet: { set in onToggleSet(set, exercise) },
                    onDeleteSet: onDeleteSet,
                    onAddSet: { onAddSet(exercise) }
                )
                .padding(.horizontal, Theme.Spacing.l)
            }

            Button {
                onAddExercise()
            } label: {
                Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private var emptyGame: some View {
        VStack(spacing: Theme.Spacing.m) {
            Text("Noch keine Übungen")
                .font(.headline)
            Text("Füge Übungen hinzu, um deine Stationen zu sehen.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button {
                onAddExercise()
            } label: {
                Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.xl)
    }
}


// MARK: - Game Station Card

struct GameStationCard: View {
    let index: Int
    let exercise: Exercise
    let sets: [SetEntry]
    let isCurrent: Bool
    let isNext: Bool
    let allDone: Bool
    let unit: WeightUnit
    let onToggleSet: (SetEntry) -> Void
    let onDeleteSet: (SetEntry) -> Void
    let onAddSet: () -> Void

    private var statusIcon: String {
        if allDone { return "checkmark.circle.fill" }
        if isCurrent { return "play.circle.fill" }
        if isNext { return "arrow.right.circle.fill" }
        return "circle"
    }

    private var statusColor: Color {
        if allDone { return .green }
        if isCurrent { return .accentColor }
        if isNext { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 6) {
                        Text("Station \(index)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(statusColor)
                    }
                }
                Spacer()
                if isCurrent {
                    Text("AKTUELL")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor))
                }
            }

            if isCurrent || isNext {
                ForEach(Array(sets.enumerated()), id: \.element.id) { idx, setEntry in
                    GameSetRow(
                        index: idx + 1,
                        setEntry: setEntry,
                        unit: unit,
                        onToggle: { onToggleSet(setEntry) },
                        onDelete: { onDeleteSet(setEntry) }
                    )
                }

                Button {
                    onAddSet()
                } label: {
                    Label("Satz hinzufügen", systemImage: "plus")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.s)
                .strokeBorder(isCurrent ? Color.accentColor : (isNext ? Color.orange : Color.clear), lineWidth: isCurrent || isNext ? 2 : 0)
        )
    }
}


struct GameSetRow: View {
    let index: Int
    @Bindable var setEntry: SetEntry
    let unit: WeightUnit
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var type: ExerciseTrackingType {
        setEntry.exercise?.trackingType ?? .repsWeight
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 18)

            switch type {
            case .repsWeight:
                gameNumberField(
                    value: Binding(get: { setEntry.weight ?? 0 }, set: { setEntry.weight = $0 == 0 ? nil : $0 }),
                    placeholder: "0", suffix: unit.rawValue, decimal: true
                )
                gameNumberField(
                    value: Binding(get: { Double(setEntry.reps ?? 0) }, set: { setEntry.reps = Int($0) == 0 ? nil : Int($0) }),
                    placeholder: "0", suffix: "Wdh", decimal: false
                )
            case .reps:
                gameNumberField(
                    value: Binding(get: { Double(setEntry.reps ?? 0) }, set: { setEntry.reps = Int($0) == 0 ? nil : Int($0) }),
                    placeholder: "0", suffix: "Wdh", decimal: false
                )
            case .duration:
                gameDurationField(
                    seconds: Binding(get: { setEntry.durationSeconds ?? 0 }, set: { setEntry.durationSeconds = $0 == 0 ? nil : $0 })
                )
            case .distanceDuration:
                gameNumberField(
                    value: Binding(get: { (setEntry.distanceMeters ?? 0) / 1000 }, set: { setEntry.distanceMeters = $0 == 0 ? nil : $0 * 1000 }),
                    placeholder: "0", suffix: "km", decimal: true
                )
                gameDurationField(
                    seconds: Binding(get: { setEntry.durationSeconds ?? 0 }, set: { setEntry.durationSeconds = $0 == 0 ? nil : $0 })
                )
            }

            Spacer(minLength: 0)

            Button(action: { Haptics.selection(); onToggle() }) {
                Image(systemName: setEntry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(setEntry.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) { Haptics.impact(.light); onDelete() } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(setEntry.isCompleted ? Color.green.opacity(0.06) : Color(.tertiarySystemFill))
        )
    }

    @ViewBuilder
    private func gameNumberField(
        value: Binding<Double>,
        placeholder: String,
        suffix: String,
        decimal: Bool
    ) -> some View {
        HStack(spacing: 3) {
            if decimal {
                FlexibleNumberField(value: value, placeholder: placeholder, decimal: true)
                    .font(.caption)
            } else {
                TextField(placeholder, value: value, format: .number.precision(.fractionLength(0...0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.caption)
            }
            Text(suffix)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color(.quaternarySystemFill)))
    }

    private func gameDurationField(seconds: Binding<Int>) -> some View {
        HStack(spacing: 2) {
            TextField("0", value: Binding(
                get: { seconds.wrappedValue / 60 },
                set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 28)
                .font(.caption)
            Text(":").font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
            TextField("00", value: Binding(
                get: { seconds.wrappedValue % 60 },
                set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 28)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color(.quaternarySystemFill)))
    }
}
