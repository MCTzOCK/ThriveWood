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
    let topSet: SetEntry?
    let onAddSet: () -> Void
    let onComplete: (SetEntry) -> Void
    let onDelete: (SetEntry) -> Void
    let removeExercise: () -> Void
    let showDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: exercise.iconSystemName)
                    .foregroundStyle(.tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))
                Text(exercise.name).font(.headline)
                Spacer()
                Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button(action: showDetails) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                
                Button(action: removeExercise) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            if let topSet, topSet.volumeValue > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                    Text(topSet.summaryText)
                }
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
                .foregroundStyle(.orange)
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
                SetRow(index: idx + 1, set_: set, unit: unit, onComplete: { onComplete(set) }, onDelete: { onDelete(set) })
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
                        .fill(Color.accentColor.opacity(0.10))
                )
                .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}

