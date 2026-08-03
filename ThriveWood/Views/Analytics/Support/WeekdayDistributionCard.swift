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

    @Environment(\.bentoTheme) private var theme

    private var maxPoints: Int {
        max(1, data.map(\.points).max() ?? 1)
    }

    private static let germanSymbols: [Int: String] = [
        1: "So", 2: "Mo", 3: "Di",
        4: "Mi", 5: "Do", 6: "Fr", 7: "Sa"
    ]

    private var orderedData: [WeekdayDistribution] {
        let firstWeekday = Calendar.app.firstWeekday
        return data.sorted { lhs, rhs in
            let a = (lhs.weekday - firstWeekday + 7) % 7
            let b = (rhs.weekday - firstWeekday + 7) % 7
            return a < b
        }
    }

    var body: some View {
        BentoSection(title: Text("Wochentage"), subtitle: Text("Wann du am produktivsten bist")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                let ordered = orderedData

                Chart(Array(ordered.enumerated()), id: \.offset) { idx, entry in
                    BarMark(
                        x: .value("Tag", idx),
                        y: .value("Punkte", entry.points),
                        width: .fixed(22)
                    )
                    .foregroundStyle(
                        entry.points == maxPoints && entry.points > 0
                        ? theme.colors.accent
                        : theme.colors.accent.opacity(0.4)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 6,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 6
                        )
                    )
                    .annotation(position: .top, alignment: .center) {
                        if entry.points > 0 {
                            Text("\(entry.points)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                }
                .chartXScale(domain: -0.5...6.5)
                .chartXAxis {
                    AxisMarks(values: Array(0...6)) { value in
                        AxisValueLabel {
                            if let i = value.as(Int.self), i < ordered.count {
                                Text(Self.germanSymbols[ordered[i].weekday] ?? "")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.colors.onSurfaceMuted)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                        AxisValueLabel()
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                }
                .frame(height: 200)
            }
        }
    }
}