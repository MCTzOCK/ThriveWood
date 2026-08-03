//
//  WorkoutEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI

struct WorkoutEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let workout: Workout?

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var color: HabitColor = .blue
    @State private var duration: Int = 45
    @State private var slots: [WorkoutExercise] = []
    @State private var showingLibrary = false
    @State private var errors = ErrorState()
    @State private var workoutRef: Workout?

    private var isEditing: Bool { workout != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                detailsCard
                exercisesCard

                if isEditing {
                    BentoButton(
                        Text("Workout archivieren"),
                        systemImage: "archivebox",
                        variant: .destructive,
                        expands: true
                    ) {
                        guard let workout else { return }
                        do { try env.workoutRepo.archive(workout); dismiss() }
                        catch { errors.show(error) }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text(isEditing ? "Speichern" : "Erstellen"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                save()
            }
            .disabled(!isValid)
        }
        .bentoSheet(
            isPresented: $showingLibrary,
            title: Text("Übungen"),
            detents: [.large]
        ) {
            ExerciseLibraryView(onSelect: { exercise in
                addExercise(exercise)
            }, asSheet: false, onlyFor: nil)
        }
        .errorAlert(errors)
        .onAppear(perform: hydrate)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(
                    title: Text("Details"),
                    subtitle: Text(isEditing ? "Workout bearbeiten" : "Neues Workout")
                )

                BentoTextField(
                    label: Text("Name"),
                    text: $name,
                    prompt: Text("Workout-Name"),
                    leadingSystemImage: "textformat",
                    required: true,
                    maximumLength: 60
                )

                BentoTextArea(
                    label: Text("Notiz (optional)"),
                    text: $details,
                    prompt: Text("Notiz"),
                    maximumLength: 280,
                    minimumHeight: 90
                )

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText(verbatim: "Farbe", style: .caption, color: .secondary)
                    ColorGrid(selection: $color)
                }

                BentoStepper(
                    Text("Dauer"),
                    value: $duration,
                    in: 5...240,
                    step: 5
                ) {
                    Text(verbatim: "\($0) min")
                }

                if let w = workout {
                    if let url = PDFService.shared.createPDF(for: w) {
                        BentoButton(
                            Text("PDF teilen"),
                            systemImage: "square.and.arrow.up",
                            variant: .secondary,
                            expands: true
                        ) {}
                        .overlay {
                            ShareLink(item: url) {
                                Color.clear
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Exercises Card

    private var exercisesCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(
                    title: Text("Übungen"),
                    subtitle: Text("\(slots.count) hinzugefügt")
                )

                if slots.isEmpty {
                    BentoEmptyState(
                        systemImage: "figure.strengthtraining.traditional",
                        title: Text("Noch keine Übungen"),
                        message: Text("Füge Übungen aus der Bibliothek hinzu.")
                    )
                    .padding(.vertical, Theme.Spacing.s)
                } else {
                    VStack(spacing: Theme.Spacing.s) {
                        ForEach(slots.sorted(by: { $0.order < $1.order })) { slot in
                            SlotRow(slot: slot) {
                                toggleSuperset(for: slot)
                            }
                        }
                        .onDelete(perform: deleteSlots)
                        .onMove(perform: moveSlots)
                    }
                }

                BentoButton(
                    Text("Übung hinzufügen"),
                    systemImage: "plus.circle.fill",
                    variant: .tonal(.accent),
                    expands: true
                ) {
                    showingLibrary = true
                }
            }
        }
    }

    // MARK: - Actions

    private func hydrate() {
        if let workout {
            name = workout.name
            details = workout.details
            color = workout.color
            duration = workout.estimatedDurationMinutes
            slots = workout.exercises
            workoutRef = workout
        } else {
            let w = Workout(name: "", color: color)
            workoutRef = w
        }
    }

    private func addExercise(_ exercise: Exercise) {
        guard let w = workoutRef else { return }
        let defaultRest = (try? env.profileRepo.currentProfile().defaultRestSeconds) ?? 90
        let slot = WorkoutExercise(
            order: slots.count, exercise: exercise, workout: w,
            restSeconds: defaultRest
        )
        slots.append(slot)
    }

    private func deleteSlots(at offsets: IndexSet) {
        let sorted = slots.sorted { $0.order < $1.order }
        for i in offsets { slots.removeAll { $0.id == sorted[i].id } }
        for (i, s) in slots.sorted(by: { $0.order < $1.order }).enumerated() { s.order = i }
    }

    private func moveSlots(from source: IndexSet, to destination: Int) {
        var sorted = slots.sorted { $0.order < $1.order }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, s) in sorted.enumerated() { s.order = i }
        slots = sorted
    }

    private func toggleSuperset(for slot: WorkoutExercise) {
        if slot.supersetGroup == nil {
            let maxGroup = slots.compactMap(\.supersetGroup).max() ?? 0
            slot.supersetGroup = maxGroup + 1
        } else {
            slot.supersetGroup = nil
        }
    }

    private func save() {
        do {
            if let workout {
                workout.name = name
                workout.details = details
                workout.color = color
                workout.estimatedDurationMinutes = duration
                workout.exercises = slots
                try env.workoutRepo.update(workout)
            } else {
                let new = Workout(
                    name: name.trimmingCharacters(in: .whitespaces),
                    details: details,
                    color: color,
                    estimatedDurationMinutes: duration,
                    sortOrder: Int.max
                )
                try env.workoutRepo.create(new)
                for slot in slots {
                    slot.workout = new
                    new.exercises.append(slot)
                }
                try env.workoutRepo.update(new)
            }
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
    }
}
