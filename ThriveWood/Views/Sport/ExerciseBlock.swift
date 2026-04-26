//
//  ExerciseBlock.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct ExerciseBlock: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let onAddSet: () -> Void
    let onComplete: (SetEntry) -> Void
    let onDelete: (SetEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: exercise.iconSystemName)
                    .foregroundStyle(.blue)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
                Text(exercise.name).font(.headline)
                Spacer()
                Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Header
            HStack {
                Text("#").frame(width: 24, alignment: .leading)
                Text("kg" == unit.rawValue ? "kg" : "lb").frame(width: 70, alignment: .center)
                Text("Reps").frame(width: 70, alignment: .center)
                Spacer()
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)

            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                SetRow(index: idx + 1, set_: set, unit: unit, onComplete: { onComplete(set) })
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { onDelete(set) } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }

            Button(action: onAddSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Satz hinzufügen")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.s)
                        .fill(Color.blue.opacity(0.10))
                )
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}

struct SetRow: View {
    let index: Int
    @Bindable var set_: SetEntry
    let unit: WeightUnit
    let onComplete: () -> Void

    private var type: ExerciseTrackingType {
        set_.exercise?.trackingType ?? .repsWeight
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            indexBadge
            inputs
            Spacer(minLength: 0)
            completeButton
        }
        .animation(.snappy, value: set_.isCompleted)
    }

    private var indexBadge: some View {
        Text("\(index)")
            .font(.callout.weight(.bold).monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 24, alignment: .leading)
    }

    @ViewBuilder
    private var inputs: some View {
        switch type {
        case .repsWeight:
            numberField(
                value: Binding(
                    get: { set_.weight ?? 0 },
                    set: { set_.weight = $0 == 0 ? nil : $0 }),
                placeholder: "0", suffix: unit.rawValue,
                width: 80, decimal: true)
            numberField(
                value: Binding(
                    get: { Double(set_.reps ?? 0) },
                    set: { set_.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps",
                width: 80, decimal: false)

        case .reps:
            numberField(
                value: Binding(
                    get: { Double(set_.reps ?? 0) },
                    set: { set_.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps",
                width: 110, decimal: false)

        case .duration:
            durationField(
                seconds: Binding(
                    get: { set_.durationSeconds ?? 0 },
                    set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))

        case .distanceDuration:
            numberField(
                value: Binding(
                    get: { (set_.distanceMeters ?? 0) / 1000 },
                    set: { set_.distanceMeters = $0 == 0 ? nil : $0 * 1000 }),
                placeholder: "0,00", suffix: "km",
                width: 90, decimal: true)
            durationField(
                seconds: Binding(
                    get: { set_.durationSeconds ?? 0 },
                    set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
        }
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            Image(systemName: set_.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set_.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Field Helpers

    private func numberField(
        value: Binding<Double>,
        placeholder: String,
        suffix: String,
        width: CGFloat,
        decimal: Bool
    ) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, value: value, format: .number.precision(.fractionLength(decimal ? 0...2 : 0...0)))
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
            Text(suffix).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .frame(width: width)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
    }

    private func durationField(seconds: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            TextField("0", value: Binding(
                get: { seconds.wrappedValue / 60 },
                set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 36)
            Text(":").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
            TextField("00", value: Binding(
                get: { seconds.wrappedValue % 60 },
                set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 36)
            Text("min").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
    }
}
