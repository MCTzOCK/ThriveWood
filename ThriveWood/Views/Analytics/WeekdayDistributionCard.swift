//
//  WeekdayDistributionCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI
import Charts

struct WeekdayDistributionCard: View {
    let data: [WeekdayDistribution]

    private var maxPoints: Int {
        max(1, data.map(\.points).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wochentage").font(.headline)
                Text("Wann du am produktivsten bist")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Chart(data) { d in
                BarMark(
                    x: .value("Tag", d.shortLabel),
                    y: .value("Punkte", d.points)
                )
                .foregroundStyle(
                    d.points == maxPoints && d.points > 0
                    ? Color.green
                    : Color.green.opacity(0.45)
                )
                .cornerRadius(6)
                .annotation(position: .top, alignment: .center) {
                    if d.points > 0 {
                        Text("\(d.points)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .frame(height: 180)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
