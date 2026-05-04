//
//  HabitLeaderboardCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct HabitLeaderboardCard: View {
    let performances: [HabitPerformance]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Top Habits").font(.headline)
                Text("Sortiert nach Erfüllungsgrad")
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(performances.prefix(5).enumerated()), id: \.element.id) { idx, p in
                    HabitPerformanceRow(rank: idx + 1, performance: p)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
