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

struct HabitPerformanceRow: View {
    let rank: Int
    let performance: HabitPerformance

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(performance.color.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: performance.iconSystemName)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("#\(rank)").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(performance.title).font(.subheadline.weight(.semibold))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(performance.color.color.opacity(0.15))
                        Capsule()
                            .fill(performance.color.color)
                            .frame(width: geo.size.width * performance.completionRate)
                    }
                }
                .frame(height: 6)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(performance.completionRate * 100))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(performance.color.color)
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                    Text("\(performance.currentStreak)").font(.caption2)
                }
            }
            .frame(minWidth: 50, alignment: .trailing)
        }
    }
}
