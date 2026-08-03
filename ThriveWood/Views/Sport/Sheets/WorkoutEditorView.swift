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
        NavigationStack {
            BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
                VStack(spacing: Theme.Spacing.l) {
                    BentoPageHeader(
                        eyebrow: Text(isEditing ? "BEARBEITEN" : "NEU"),
                        title: Text(isEditing ? "Workout bearbeiten" : "Neues Workout"),
                        subtitle: Text(isValid ? name : "Gib einen Namen ein")
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)

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
                        .padding(.horizontal, Theme.Spacing.l)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 120)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save)
                        .disabled(!isValid).fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingLibrary) {
                ExerciseLibraryView(onSelect: { exercise in
                    addExercise(exercise)
                }, asSheet: true, onlyFor: nil)
            }
            .errorAlert(errors)
            .onAppear(perform: hydrate)
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Details")) { EmptyView() }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText(verbatim: "Name", style: .caption, color: .secondary)
                    TextField("Workout-Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText(verbatim: "Notiz (optional)", style: .caption, color: .secondary)
                    TextField("Notiz", text: $details, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText(verbatim: "Farbe", style: .caption, color: .secondary)
                    ColorGrid(selection: $color)
                }

                HStack {
                    BentoText(verbatim: "Dauer", style: .caption, color: .secondary)
                    Spacer()
                    Stepper("\(duration) min", value: $duration, in: 5...240, step: 5)
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
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Exercises Card

    private var exercisesCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Übungen (\(slots.count))")) {
                    if !slots.isEmpty {
                        EditButton().font(.caption)
                    }
                }

                if slots.isEmpty {
                    BentoText(
                        verbatim: "Noch keine Übungen hinzugefügt",
                        style: .callout,
                        color: .secondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.m)
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
        .padding(.horizontal, Theme.Spacing.l)
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
