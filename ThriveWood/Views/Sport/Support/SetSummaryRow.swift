//
//  SetSummaryRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct SetSummaryRow: View {
    let index: Int
    let set: SetEntry
    let type: ExerciseTrackingType

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28)

            HStack(spacing: 6) {
                if set.isWarmup {
                    Text("WU")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundStyle(.orange)
                }
                Text(set.summaryText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(set.isCompleted ? .primary : .secondary)
            }

            Spacer()

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.callout)
                .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.5))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, 8)
    }
}
