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
    @State private var elapsedNow: Date = .now
    @State private var showingFinish = false
    @State private var showingCancel = false
    @State private var notes: String = ""
    @State private var rpe: Int = 7
    @State private var errors = ErrorState()
    private let elapsedTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Gruppiert die Sets nach Exercise in der Reihenfolge des Workout-Plans.
    private var groupedSets: [(Exercise, [SetEntry])] {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }) ?? []
        var result: [(Exercise, [SetEntry])] = []
        if !plan.isEmpty {
            for slot in plan {
                guard let ex = slot.exercise else { continue }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                result.append((ex, sets))
            }
        } else {
            // Freies Training: nach Exercise-Name sortieren.
            let unique = Set(session.sets.compactMap { $0.exercise })
            for ex in unique.sorted(by: { $0.name < $1.name }) {
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                result.append((ex, sets))
            }
        }
        return result
    }

    private var elapsed: String {
        let s = Int(elapsedNow.timeIntervalSince(session.startedAt))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        header
                        ForEach(groupedSets, id: \.0.id) { exercise, sets in
                            ExerciseBlock(
                                exercise: exercise,
                                sets: sets,
                                unit: session.weightUnit,
                                onAddSet: { addSet(for: exercise) },
                                onComplete: { toggleComplete($0, for: exercise) },
                                onDelete: { deleteSet($0) }
                            )
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                        AddExerciseButton { addExercise() }
                            .padding(.horizontal, Theme.Spacing.l)

                        Color.clear.frame(height: 120) // Abstand für Rest-Timer
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
                    Button("Abbrechen", role: .destructive) { showingCancel = true }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .principal) {
                    Text(elapsed)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.blue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { showingFinish = true }
                        .fontWeight(.semibold)
                }
            }
            .onReceive(elapsedTimer) { elapsedNow = $0 }
            .sheet(isPresented: $showingFinish) {
                FinishSessionSheet(rpe: $rpe, notes: $notes) {
                    finish()
                }
                .presentationDetents([.medium])
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
        }
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: Theme.Spacing.l) {
            StatTile(value: "\(session.sets.filter(\.isCompleted).count)",
                     label: "Sätze", tint: .green)
            StatTile(value: "\(Int(totalVolume))",
                     label: "Volumen (\(session.weightUnit.rawValue))", tint: .blue)
            StatTile(value: "\(groupedSets.count)",
                     label: "Übungen", tint: .orange)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var totalVolume: Double {
        session.sets.filter { $0.isCompleted }.reduce(0) { $0 + $1.volumeValue }
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

    // MARK: Actions

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
        // Für freies Training öffnen wir die Library separat (hier: kleine Abkürzung).
        // In Produktion als Sheet wie beim Editor.
    }

    private func toggleComplete(_ set: SetEntry, for exercise: Exercise) {
        let wasCompleted = set.isCompleted
        set.isCompleted.toggle()
        set.completedAt = set.isCompleted ? .now : nil
        try? env.sessionRepo.update(session)

        if !wasCompleted {
            Haptics.success()
            // Rest-Timer: suche passenden Slot im Plan
            let restSec = session.workout?.exercises
                .first(where: { $0.exercise?.id == exercise.id })?.restSeconds
                ?? (try? env.profileRepo.currentProfile().defaultRestSeconds)
                ?? 90
            if restSec > 0 { rest.start(seconds: restSec) }
        } else {
            Haptics.impact(.light)
        }
    }

    private func deleteSet(_ set: SetEntry) {
        session.sets.removeAll { $0.id == set.id }
        try? env.sessionRepo.update(session)
    }

    private func finish() {
        do {
            try env.workoutService.finishSession(perceivedExertion: rpe, notes: notes)
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
    }
}


struct AddExerciseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Übung hinzufügen")
            }
            .font(.headline)
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }
}
