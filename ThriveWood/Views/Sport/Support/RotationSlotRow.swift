//
//  RotationSlotRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

/// Zeile für einen einzelnen Rotations-Slot (A, B, C ...).
struct RotationSlotRow: View {
    let day: TrainingsPlanDay
    let plan: TrainingsPlan
    let onTap: () -> Void

    private var planColor: Color {
        Color(hex: plan.color) ?? .blue
    }

    private var index: Int {
        plan.rotationSequence.firstIndex { $0.id == day.id } ?? 0
    }

    private var letter: String {
        String(Character(UnicodeScalar(65 + index)!))
    }

    private var isCurrent: Bool {
        plan.currentRotationIndex % max(plan.rotationCount, 1) == index
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? planColor.opacity(0.25) : Color(.tertiarySystemFill))
                        .frame(width: 44, height: 44)
                    Text(day.label.isEmpty ? letter : day.label)
                        .font(.headline)
                        .foregroundStyle(isCurrent ? planColor : .primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(slotTitle)
                        .font(Theme.Typography.subheadline.weight(.semibold))

                    if let workout = day.workout {
                        Text(workout.name)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Kein Workout zugewiesen")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if isCurrent {
                    PillBadge(text: "Aktuell", icon: "play.fill", color: planColor)
                }

                Image(systemName: "chevron.right")
                    .font(Theme.Typography.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }

    private var slotTitle: String {
        let base = day.label.isEmpty ? "Slot \(letter)" : day.label
        return base
    }
}
