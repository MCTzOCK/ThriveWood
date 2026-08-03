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
        BentoCard(tone: .green, style: .elevated, padding: .lg, radius: .large) {
            VStack(spacing: Theme.Spacing.m) {
                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "available",
                        title: Text("Verfügbar"),
                        value: Text(verbatim: "\(available)"),
                        detail: Text("Punkte")
                    ),
                    BentoStatValue(
                        id: "trees",
                        title: Text("Bäume"),
                        value: Text(verbatim: "\(treeCount)"),
                        detail: Text("gepflanzt")
                    ),
                    BentoStatValue(
                        id: "total",
                        title: Text("Gesamt"),
                        value: Text(verbatim: "\(total)"),
                        detail: Text("verdient")
                    )
                ])

                BentoDivider()

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        BentoText(verbatim: "Bewachsung", style: .caption, color: .secondary)
                        Spacer()
                        Text(verbatim: "\(Int(coverage * 100))%")
                            .bentoTextStyle(.bodyStrong, color: .accentColor)
                    }
                    BentoProgressBar(
                        progress: coverage,
                        tone: .green,
                        height: 10
                    )
                }
            }
        }
    }
}
