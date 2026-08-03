//
//  HabitPerformanceRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct HabitPerformanceRow: View {
    let rank: Int
    let performance: HabitPerformance
    @Environment(\.bentoTheme) private var theme

    var body: some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                        .fill(performance.color.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: performance.iconSystemName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    HStack(spacing: theme.spacing.xxs) {
                        Text("#\(rank)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Text(performance.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(performance.color.color.opacity(0.15))
                            Capsule()
                                .fill(performance.color.color)
                                .frame(width: geo.size.width * performance.completionRate)
                        }
                    }
                    .frame(height: 6)
                }

                VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                    Text("\(Int(performance.completionRate * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(performance.color.color)
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(performance.currentStreak)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                }
                .frame(minWidth: 50, alignment: .trailing)
            }
        }
    }
}