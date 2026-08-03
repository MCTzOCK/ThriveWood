//
//  MuscleRankRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MuscleRankRow: View {
    let data: MuscleRankingData
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.bentoTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            BentoCard(
                background: isSelected ? data.rank.primaryColor.opacity(0.1) : nil,
                style: isSelected ? .elevated : .outlined,
                padding: .md
            ) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(data.rank.gradient)
                            .frame(width: 40, height: 40)

                        Image(systemName: data.rank.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        BentoText(verbatim: data.muscleGroup.label, style: .bodyStrong)
                        BentoText(
                            verbatim: data.rank.label,
                            style: .caption,
                            color: data.rank.primaryColor
                        )
                    }

                    Spacer()

                    BentoText(
                        verbatim: "\(Int(data.totalVolume)) kg",
                        style: .bodyStrong,
                        color: theme.colors.onSurfaceMuted
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .animation(.bouncy, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
