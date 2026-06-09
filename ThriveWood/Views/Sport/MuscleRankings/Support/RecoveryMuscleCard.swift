//
//  RecoveryMuscleCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//

import SwiftUI

struct RecoveryMuscleCard: View {
    let data: MuscleRecoveryData
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

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
        case .needsRest: "Pause empfohlen"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(stateColor.gradient)
                        .frame(width: 56, height: 56)

                    Image(systemName: data.stateIcon)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(data.muscleGroup.label)
                        .font(.title3.bold())

                    Text(stateLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(stateColor)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            if data.needsRest || data.isWarning {
                VStack(alignment: .leading, spacing: 8) {
                    Label(data.restReasonText, systemImage: "info.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if data.recommendedRestDays > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                            Text("\(data.recommendedRestDays) Tag\(data.recommendedRestDays == 1 ? "" : "e") Pause empfohlen")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(stateColor)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(stateColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 24) {
                StatItem(icon: "scalemass.fill", value: formatVolume(data.weeklyVolume), label: "Volumen / 7d")
                StatItem(icon: "calendar", value: data.daysSinceLastWorked.map { "\($0)d" } ?? "—", label: "Letzte Pause")
                StatItem(icon: "flame.fill", value: "\(data.consecutiveTrainingDays)", label: "Tage direkt")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .shadow(color: stateColor.opacity(0.15), radius: 20)
        )
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }
}