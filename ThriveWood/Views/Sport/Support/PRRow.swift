//
//  PRRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 19.05.26.
//
import SwiftUI

struct PRRow: View {
    let exercise: Exercise
    let topSet: SetEntry

    var body: some View {
        BentoCard(style: .outlined, padding: .md) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "trophy.fill")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(.orange)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(exercise.trackingType.label)
                        if let date = topSet.completedAt {
                            Text("·")
                            Text(date, format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(topSet.summaryText)
                    .font(Theme.Typography.mono)
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
            }
        }
    }
}
