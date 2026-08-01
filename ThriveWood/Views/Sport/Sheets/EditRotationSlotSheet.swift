//
//  EditRotationSlotSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

/// Editor für einen einzelnen Rotations-Slot (A, B, C ...).
struct EditRotationSlotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    let day: TrainingsPlanDay
    let plan: TrainingsPlan

    @State private var label = ""
    @State private var selectedWorkoutID: UUID?
    @State private var availableWorkouts: [Workout] = []

    var body: some View {
        Form {
            Section {
                HStack {
                    ZStack {
                        Circle()
                            .fill(planColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Text(slotLetter)
                            .font(.headline)
                            .foregroundStyle(planColor)
                    }
                    Text(slotTitle)
                        .font(.headline)
                }
            }

            Section {
                TextField("Label (z.B. A, Push, Oberkörper)", text: $label)
            } header: {
                Text("Bezeichnung")
            }

            Section {
                Picker("Workout", selection: $selectedWorkoutID) {
                    Text("Kein Workout").tag(nil as UUID?)
                    ForEach(availableWorkouts) { workout in
                        Text(workout.name).tag(workout.id)
                    }
                }
            } header: {
                Text("Workout auswählen")
            }

            if day.workout == nil {
                Section {
                    Button("Slot löschen", role: .destructive) {
                        deleteSlot()
                    }
                }
            }
        }
        .navigationTitle("Slot \(slotLetter)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }
            }
        }
        .task { await load() }
        .onAppear {
            label = day.label
            selectedWorkoutID = day.workout?.id
        }
    }

    private var planColor: Color {
        Color(hex: plan.color) ?? .blue
    }

    private var slotLetter: String {
        let idx = plan.rotationSequence.firstIndex { $0.id == day.id } ?? 0
        return String(Character(UnicodeScalar(65 + idx)!))
    }

    private var slotTitle: String {
        label.isEmpty ? "Slot \(slotLetter)" : label
    }

    private func load() async {
        do {
            availableWorkouts = try env.workoutService.allWorkouts()
        } catch {
            print("Load error: \(error)")
        }
    }

    private func save() {
        do {
            let chosen = availableWorkouts.first { $0.id == selectedWorkoutID }
            try env.trainingsPlanService.updateRotationSlot(
                day,
                in: plan,
                label: label.trimmingCharacters(in: .whitespaces),
                workout: chosen
            )
            Haptics.success()
            dismiss()
        } catch {
            print("Save slot error: \(error)")
        }
    }

    private func deleteSlot() {
        do {
            try env.trainingsPlanService.removeRotationSlot(day, from: plan)
            Haptics.success()
            dismiss()
        } catch {
            print("Delete slot error: \(error)")
        }
    }
}
