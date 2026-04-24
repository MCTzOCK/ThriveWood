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
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Notiz (optional)", text: $details, axis: .vertical).lineLimit(1...3)
                    ColorGrid(selection: $color)
                    Stepper("Dauer: \(duration) min",
                            value: $duration, in: 5...240, step: 5)
                }

                Section {
                    if slots.isEmpty {
                        Text("Noch keine Übungen").foregroundStyle(.secondary)
                    } else {
                        ForEach(slots.sorted(by: { $0.order < $1.order })) { slot in
                            SlotRow(slot: slot)
                        }
                        .onDelete(perform: deleteSlots)
                        .onMove(perform: moveSlots)
                    }
                    Button {
                        showingLibrary = true
                    } label: {
                        Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Übungen")
                        Spacer()
                        if !slots.isEmpty { EditButton().font(.caption) }
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            guard let workout else { return }
                            do { try env.workoutRepo.archive(workout); dismiss() }
                            catch { errors.show(error) }
                        } label: { Label("Archivieren", systemImage: "archivebox") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Workout bearbeiten" : "Neues Workout")
            .navigationBarTitleDisplayMode(.inline)
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
                ExerciseLibraryView { exercise in
                    addExercise(exercise)
                }
            }
            .errorAlert(errors)
            .onAppear(perform: hydrate)
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
            // temporäres Workout-Objekt, damit wir Slots direkt anhängen können
            let w = Workout(name: "", color: color)
            workoutRef = w
        }
    }

    private func addExercise(_ exercise: Exercise) {
        guard let w = workoutRef else { return }
        let slot = WorkoutExercise(
            order: slots.count, exercise: exercise, workout: w
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

private struct SlotRow: View {
    @Bindable var slot: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: slot.exercise?.iconSystemName ?? "dumbbell.fill")
                    .foregroundStyle(.blue)
                Text(slot.exercise?.name ?? "Unbekannt")
                    .font(.subheadline.weight(.semibold))
            }
            HStack(spacing: Theme.Spacing.m) {
                Stepper("Sätze: \(slot.targetSets)",
                        value: $slot.targetSets, in: 1...20)
                    .font(.caption)
            }
            HStack(spacing: Theme.Spacing.m) {
                HStack {
                    Text("Reps").font(.caption).foregroundStyle(.secondary)
                    TextField("10",
                              value: Binding(
                                get: { slot.targetReps ?? 0 },
                                set: { slot.targetReps = $0 == 0 ? nil : $0 }),
                              format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                HStack {
                    Text("kg").font(.caption).foregroundStyle(.secondary)
                    TextField("0",
                              value: Binding(
                                get: { slot.targetWeight ?? 0 },
                                set: { slot.targetWeight = $0 == 0 ? nil : $0 }),
                              format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
                HStack {
                    Text("Pause").font(.caption).foregroundStyle(.secondary)
                    Text("\(slot.restSeconds)s").font(.caption.monospacedDigit())
                    Stepper("", value: $slot.restSeconds, in: 0...600, step: 15)
                        .labelsHidden()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
