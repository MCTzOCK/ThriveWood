//
//  RecoveryMuscleRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//

import SwiftUI

struct RecoveryMuscleRow: View {
    let data: MuscleRecoveryData
    let isSelected: Bool
    let onTap: () -> Void

    private var stateColor: Color {
        switch data.state {
        case .recovered: .green
        case .warning: .orange
        case .needsRest: .red
        }
    }

    private var stateLabel: String {
        switch data.state {
        case .recovered: "Erholt"
        case .warning: "Nah am Limit"
        case .needsRest: "Pause nötig"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(stateColor.gradient)
                        .frame(width: 40, height: 40)

                    Image(systemName: data.stateIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.muscleGroup.label)
                        .font(.subheadline.weight(.medium))
                    Text(stateLabel)
                        .font(.caption)
                        .foregroundStyle(stateColor)
                }

                Spacer()

                Text(formatVolume(data.weeklyVolume))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? stateColor.opacity(0.1) : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }
}