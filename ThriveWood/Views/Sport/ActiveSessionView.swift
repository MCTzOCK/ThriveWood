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
    @State private var showingGymMap = false
    @State private var showingGymPicker = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        header
                        ForEach(cachedGroups, id: \.0.id) { exercise, sets in
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
                                onStartTracker: { set in startTracker(for: set, exercise: exercise) }
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
                    HStack(spacing: Theme.Spacing.s) {
                        if !gyms.isEmpty {
                            Menu {
                                ForEach(gyms) { g in
                                    Button {
                                        selectedGym = g
                                        Haptics.selection()
                                        showingGymMap = true
                                    } label: {
                                        Label(g.name, systemImage: g.iconSystemName)
                                    }
                                }
                            } label: {
                                Image(systemName: "map.fill")
                            }
                        }
                        Button("Fertig") { showingFinish = true }
                            .fontWeight(.semibold)
                    }
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
            .sheet(isPresented: $showingGymMap) {
                if let gym = selectedGym {
                    GymMapNavigatorView(
                        gym: gym,
                        currentExerciseID: currentIncompleteExerciseID,
                        nextExerciseID: nextIncompleteExerciseID
                    )
                }
            }
        }
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
        let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }) ?? []
        var result: [(Exercise, [SetEntry])] = []
        for slot in plan {
            guard let ex = slot.exercise else { continue }
            let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
            if sets.count > 0 {
                result.append((ex, sets))
            }
        }
        let unique = Set(session.sets.compactMap { $0.exercise })
        for ex in unique.sorted(by: { $0.name < $1.name }) {
            let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
            if sets.count > 0 && !plan.contains(where: { $0.exercise?.id == ex.id }) {
                result.append((ex, sets))
            }
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
