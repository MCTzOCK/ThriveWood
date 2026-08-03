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
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .outlined, padding: .lg) {
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

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Bezeichnung"))
                        TextField("Label (z.B. A, Push, Oberkörper)", text: $label)
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Workout auswählen"))
                        Picker("Workout", selection: $selectedWorkoutID) {
                            Text("Kein Workout").tag(nil as UUID?)
                            ForEach(availableWorkouts) { workout in
                                Text(workout.name).tag(workout.id)
                            }
                        }
                    }
                }

                if day.workout == nil {
                    BentoButton(
                        Text("Slot löschen"),
                        systemImage: "trash",
                        variant: .destructive,
                        expands: true
                    ) {
                        deleteSlot()
                    }
                }
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                save()
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
