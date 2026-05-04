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
            HStack(spacing: Theme.Spacing.l) {
                StatBlock(icon: "leaf.fill", tint: .accentColor,
                          value: "\(available)", label: "Verfügbar")
                Divider().frame(height: 36)
                StatBlock(icon: "tree.fill", tint: .brown,
                          value: "\(treeCount)", label: "Bäume")
                Divider().frame(height: 36)
                StatBlock(icon: "sparkles", tint: .orange,
                          value: "\(total)", label: "Gesamt")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Bewachsung")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(coverage * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.accentColor.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [.accentColor, .mint],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * coverage)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coverage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private struct StatBlock: View {
        let icon: String; let tint: Color; let value: String; let label: String
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(.headline)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
