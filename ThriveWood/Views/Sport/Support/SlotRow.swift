//
//  SlotRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI


struct SlotRow: View {
    @Bindable var slot: WorkoutExercise

    private var type: ExerciseTrackingType {
        slot.exercise?.trackingType ?? .repsWeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: slot.exercise?.iconSystemName ?? "dumbbell.fill")
                    .foregroundStyle(.tint)
                Text(slot.exercise?.name ?? "Unbekannt")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(type.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                    .foregroundStyle(.tint)
            }
            Spacer()

            Stepper("Sätze: \(slot.targetSets)", value: $slot.targetSets, in: 1...20)
                .font(.caption)

            HStack(spacing: Theme.Spacing.m) {
                if type.showsReps {
                    field(label: "Reps", value: Binding(
                        get: { Double(slot.targetReps ?? 0) },
                        set: { slot.targetReps = Int($0) == 0 ? nil : Int($0) }),
                          decimal: false, width: 60)
                }
                if type.showsWeight {
                    field(label: "kg", value: Binding(
                        get: { slot.targetWeight ?? 0 },
                        set: { slot.targetWeight = $0 == 0 ? nil : $0 }),
                          decimal: true, width: 70)
                }
                if type.showsDistance {
                    field(label: "km", value: Binding(
                        get: { (slot.targetDistanceMeters ?? 0) / 1000 },
                        set: { slot.targetDistanceMeters = $0 == 0 ? nil : $0 * 1000 }),
                          decimal: true, width: 70)
                }
                if type.showsDuration {
                    field(label: "Sek.", value: Binding(
                        get: { Double(slot.targetDurationSeconds ?? 0) },
                        set: { slot.targetDurationSeconds = Int($0) == 0 ? nil : Int($0) }),
                          decimal: false, width: 70)
                }
            }

            HStack {
                Text("Pause").font(.caption).foregroundStyle(.secondary)
                Text("\(slot.restSeconds)s").font(.caption.monospacedDigit())
                Stepper("", value: $slot.restSeconds, in: 0...600, step: 15).labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func field(label: String, value: Binding<Double>, decimal: Bool, width: CGFloat) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField("0", value: value, format: .number.precision(.fractionLength(decimal ? 0...2 : 0...0)))
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: width)
        }
    }
}
