//
//  ForestStatsHeader.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI

struct ForestStatsHeader: View {
    let available: Int
    let total: Int
    let coverage: Double
    let treeCount: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: 0) {
                StatBlock(icon: "leaf.fill", tint: .accentColor,
                          value: "\(available)", label: "Verfügbar")
                VerticalDivider()
                StatBlock(icon: "tree.fill", tint: .brown,
                          value: "\(treeCount)", label: "Bäume")
                VerticalDivider()
                StatBlock(icon: "sparkles", tint: .orange,
                          value: "\(total)", label: "Gesamt")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Bewachsung")
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(coverage * 100))%")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.accentColor.opacity(0.15))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * coverage)
                            .animation(Theme.Animation.spring, value: coverage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private struct StatBlock: View {
        let icon: String
        let tint: Color
        let value: String
        let label: String

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Theme.Typography.body)
                    .foregroundStyle(tint)
                Text(value)
                    .font(Theme.Typography.headline.monospacedDigit())
                Text(label)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct VerticalDivider: View {
        var body: some View {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 0.5, height: 40)
        }
    }
}
