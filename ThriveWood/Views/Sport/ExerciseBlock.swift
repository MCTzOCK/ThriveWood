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
                SetRow(index: idx + 1, set: set, onComplete: { onComplete(set) })
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
    @Bindable var set: SetEntry
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("\(index)")
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            TextField("0", value: Binding(
                get: { set.weight ?? 0 },
                set: { set.weight = $0 == 0 ? nil : $0 }
            ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))

            TextField("0", value: Binding(
                get: { set.reps ?? 0 },
                set: { set.reps = $0 == 0 ? nil : $0 }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))

            Spacer()

            Button(action: onComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .animation(.snappy, value: set.isCompleted)
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
