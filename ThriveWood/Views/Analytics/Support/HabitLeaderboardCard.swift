//
//  HabitLeaderboardCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI

struct HabitLeaderboardCard: View {
    let performances: [HabitPerformance]
    @Environment(\.bentoTheme) private var theme

    var body: some View {
        BentoSection(title: Text("Top Habits"), subtitle: Text("Sortiert nach Erfüllungsgrad")) {
            VStack(spacing: theme.spacing.xs) {
                ForEach(Array(performances.prefix(5).enumerated()), id: \.element.id) { idx, p in
                    HabitPerformanceRow(rank: idx + 1, performance: p)
                }
            }
        }
    }
}