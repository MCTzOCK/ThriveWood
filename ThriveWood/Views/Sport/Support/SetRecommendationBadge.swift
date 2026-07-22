//
//  SetRecommendationBadge.swift
//  ThriveWood
//

import SwiftUI

struct SetRecommendationBadge: View {
    let recommendation: SetRecommendation
    let unit: WeightUnit
    let exerciseName: String
    let aiService: AIService
    let onApply: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: recommendation.reason.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(reasonColor)
                .frame(width: 24, height: 24)
                .background(Circle().fill(reasonColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Empfehlung")
                        .font(.caption.weight(.bold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(recommendation.reason.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("\(String(format: "%.1f", recommendation.recommendedWeight)) \(unit.rawValue) × \(recommendation.recommendedReps) Reps")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }

            Spacer()

            Button {
                Haptics.selection()
                onApply()
            } label: {
                Text("Übernehmen")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(reasonColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(reasonColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var reasonColor: Color {
        switch recommendation.confidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}
