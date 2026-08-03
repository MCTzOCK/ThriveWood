//
//  ActiveSessionViewV3.swift
//  ThriveWood
//
//  Vollständiger BentoUI-Rewrite der aktiven Workout-Session. Identischer
//  Funktionsumfang wie V2, aber performant: Empfehlungen werden im
//  ActiveSessionViewModel pro Mutation berechnet (nicht inline im body),
//  context.save() ist debounced, getTopSet/getRecentWorkingStats sind im
//  WorkoutService memoisiert.
//

import SwiftUI

struct ActiveSessionViewV3: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    @Bindable var session: WorkoutSession

    @State private var vm: ActiveSessionViewModel?
    @State private var rest = RestTimer()
    @State private var exerciseTracker = ExerciseTrackerService()
    @State private var trackingSetEntry: SetEntry?
    @State private var trackingExercise: Exercise?
    @State private var currentExercise: Exercise?
    @State private var showingFinish = false
    @State private var showingCancel = false
    @State private var showingAddSheet = false
    @State private var showingPlayMode = false
    @State private var notes: String = ""
    @State private var rpe: Int = 7
    @State private var quickCompleteSet: SetEntry?
    @State private var quickCompleteExercise: Exercise?

    private var workoutColor: Color { session.workout?.color.color ?? .blue }

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .transition(.opacity)
            } else {
                BentoScreen(scrolls: false) {
                    BentoSpinner(size: 36)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
            }
        }
        .task {
            if vm == nil {
                let model = ActiveSessionViewModel(env: env, session: session, rest: rest)
                vm = model
                model.load()
            } else {
                vm?.load()
            }
        }
        .onAppear { restoreTrackerIfNeeded() }
        .onDisappear {
            vm?.flushSave()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: ActiveSessionViewModel) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: theme.spacing.md) {
                header
                heroCard(vm: vm)
                statStrip(vm: vm)

                if vm.groups.isEmpty {
                    BentoEmptyState(
                        systemImage: "dumbbell",
                        title: Text("Keine Übungen"),
                        message: Text("Füge eine Übung hinzu, um zu starten."),
                        actionTitle: Text("Übung hinzufügen"),
                        action: { showingAddSheet = true }
                    )
                    .padding(.top, theme.spacing.xl)
                } else {
                    exerciseList(vm: vm)
                    addExerciseButton
                }

                Spacer(minLength: rest.isRunning ? 100 : 120)
            }
        }
        .overlay(alignment: .bottom) {
            bottomOverlay(vm: vm)
        }
        .bentoSheet(isPresented: $showingFinish, title: Text("Abschließen"), detents: [.large]) {
            finishSheet(vm: vm)
        }
        .bentoSheet(isPresented: $showingAddSheet, title: Text("Übung"), detents: [.large]) {
            ExerciseLibraryView(onSelect: { ex in vm.addSet(for: ex) }, asSheet: true, onlyFor: nil)
        }
        .bentoSheet(
            isPresented: Binding(get: { currentExercise != nil }, set: { if !$0 { currentExercise = nil } }),
            title: Text("Übung"),
            detents: [.large]
        ) {
            if let ex = currentExercise { ExerciseDetailsSheet(exercise: ex) }
        }
        .bentoDialog(
            isPresented: $showingCancel,
            systemImage: "exclamationmark.triangle.fill",
            title: Text("Workout abbrechen?"),
            message: Text("Alle Sätze gehen verloren."),
            actions: [
                BentoDialogAction(title: Text("Ja, abbrechen"), variant: .destructive, role: .destructive) {
                    vm.cancel()
                    dismiss()
                },
                BentoDialogAction(title: Text("Weiter"), role: .cancel) {}
            ]
        )
        .errorAlert(vm.errors)
        .fullScreenCover(item: $trackingExercise) { ex in
            ExerciseTrackerView(tracker: exerciseTracker, exercise: ex) { seconds, distance in
                trackerCompleted(vm: vm, seconds: seconds, distance: distance)
            }
        }
        .fullScreenCover(isPresented: $showingPlayMode) {
            PlayModeViewV3(
                vm: vm,
                rest: rest,
                accentColor: workoutColor,
                onClose: { showingPlayMode = false }
            )
        }
        .fullScreenCover(item: $quickCompleteSet) { set in
            QuickCompleteViewV3(
                set: set,
                exercise: quickCompleteExercise,
                unit: session.weightUnit,
                accentColor: workoutColor,
                onConfirm: { reps, weight, durationSeconds, distanceMeters in
                    set.reps = reps
                    set.weight = weight
                    set.durationSeconds = durationSeconds
                    set.distanceMeters = distanceMeters
                    vm.toggleComplete(set)
                    quickCompleteSet = nil
                    quickCompleteExercise = nil
                },
                onCancel: {
                    quickCompleteSet = nil
                    quickCompleteExercise = nil
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: theme.spacing.sm) {
            BentoIconButton(
                systemImage: "xmark",
                accessibilityLabel: Text("Schließen"),
                variant: .secondary,
                size: .small
            ) {
                showingCancel = true
            }
            ElapsedTimer(sessionStartedAt: session.startedAt)
                .frame(maxWidth: .infinity)
            BentoIconButton(
                systemImage: "play.fill",
                accessibilityLabel: Text("Play-Modus"),
                variant: .secondary,
                size: .small
            ) {
                showingPlayMode = true
            }
            BentoButton(
                Text("Fertig"),
                variant: .primary,
                size: .small
            ) {
                showingFinish = true
            }
        }
        .padding(.top, theme.spacing.sm)
    }

    // MARK: - Hero Card

    private func heroCard(vm: ActiveSessionViewModel) -> some View {
        BentoCard(background: workoutColor, foreground: .white, style: .flat, padding: .lg, radius: .extraLarge) {
            HStack(spacing: theme.spacing.lg) {
                BentoProgressRing(
                    progress: vm.sessionProgress,
                    tone: .neutral,
                    size: 64,
                    lineWidth: 7,
                    label: Text(verbatim: "\(Int(vm.sessionProgress * 100))%")
                )
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(verbatim: session.workout?.name ?? "Freies Training")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: theme.spacing.xxs) {
                        Text(verbatim: "\(vm.completedCount)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                        Text(verbatim: "/ \(vm.totalSets) Sätzen")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Stat Strip

    private func statStrip(vm: ActiveSessionViewModel) -> some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: 0) {
                statTile(icon: "checkmark.circle.fill", tint: theme.colors.success, value: vm.completedCount, label: "Erledigt")
                Divider().frame(height: 32)
                statTile(icon: "scalemass.fill", tint: workoutColor,
                         valueText: volumeText(vm.totalVolume), label: "Volumen")
                Divider().frame(height: 32)
                statTile(icon: "dumbbell.fill", tint: .orange, value: vm.exerciseCount, label: "Übungen")
            }
        }
    }

    @ViewBuilder
    private func statTile(icon: String, tint: Color, value: Int? = nil, valueText: String? = nil, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(tint)
            if let value {
                Text(verbatim: "\(value)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.colors.onSurface)
                    .contentTransition(.numericText(value: Double(value)))
            } else if let valueText {
                Text(verbatim: valueText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.colors.onSurface)
            }
            Text(verbatim: label)
                .font(.caption2)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func volumeText(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1ft", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    // MARK: - Exercise List

    private func exerciseList(vm: ActiveSessionViewModel) -> some View {
        LazyVStack(spacing: theme.spacing.md) {
            ForEach(Array(vm.groups.enumerated()), id: \.element.id) { index, group in
                ExerciseCardV3(
                    exercise: group.exercise,
                    sets: group.sets,
                    unit: session.weightUnit,
                    topSetSummary: group.topSetSummary,
                    accentColor: workoutColor,
                    recommendation: group.recommendation,
                    aiService: env.aiService,
                    onAddSet: { vm.addSet(for: group.exercise) },
                    onDuplicate: { vm.duplicateLastSet(for: group.exercise) },
                    onComplete: { set in vm.toggleComplete(set) },
                    onDelete: { set in vm.deleteSet(set) },
                    onShowDetails: { currentExercise = group.exercise },
                    onStartTracker: { set in startTracker(for: set, exercise: group.exercise) },
                    onMoveUp: index > 0 ? { vm.moveExercise(at: index, to: index - 1) } : nil,
                    onMoveDown: index < vm.groups.count - 1 ? { vm.moveExercise(at: index, to: index + 1) } : nil,
                    onRemove: { vm.removeExercise(group.exercise) },
                    onApplyRecommendation: group.recommendation != nil
                        ? { vm.applyRecommendation(for: group.exercise, recommendation: group.recommendation) }
                        : nil
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : theme.motion.snappy, value: vm.groups.map(\.id))
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        BentoButton(
            Text("Übung hinzufügen"),
            systemImage: "plus",
            variant: .secondary,
            expands: true
        ) {
            showingAddSheet = true
        }
    }

    // MARK: - Bottom Overlay (Rest + Next Set)

    @ViewBuilder
    private func bottomOverlay(vm: ActiveSessionViewModel) -> some View {
        VStack(spacing: theme.spacing.xs) {
            if rest.isRunning {
                RestTimerBar(rest: rest)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if let next = vm.nextIncomplete {
                nextSetBar(vm: vm, set: next.set, exercise: next.exercise)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.bottom, theme.spacing.sm)
        .animation(reduceMotion ? nil : theme.motion.snappy, value: rest.isRunning)
    }

    private func nextSetBar(vm: ActiveSessionViewModel, set: SetEntry, exercise: Exercise) -> some View {
        Button {
            quickCompleteSet = set
            quickCompleteExercise = exercise
        } label: {
            HStack(spacing: theme.spacing.sm) {
                ZStack {
                    Circle()
                        .fill(workoutColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: exercise.iconSystemName)
                        .font(.subheadline)
                        .foregroundStyle(workoutColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.colors.onSurface)
                        .lineLimit(1)
                    Text(verbatim: "Satz \(set.order + 1) · schnell abhaken")
                        .font(.caption)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                    .fill(theme.colors.surface)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Finish Sheet

    @ViewBuilder
    private func finishSheet(vm: ActiveSessionViewModel) -> some View {
        FinishSessionSheet(
            rpe: $rpe,
            notes: $notes,
            overloadSuggestions: vm.computeOverloadSuggestions(),
            onConfirm: {
                vm.finish(perceivedExertion: rpe, notes: notes)
                dismiss()
            }
        )
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

    private func trackerCompleted(vm: ActiveSessionViewModel, seconds: Int, distance: Double?) {
        guard let set = trackingSetEntry else { return }
        set.durationSeconds = seconds
        if let distance { set.distanceMeters = distance }
        vm.toggleComplete(set)
        exerciseTracker.stop()
        trackingSetEntry = nil
        trackingExercise = nil
    }
}
