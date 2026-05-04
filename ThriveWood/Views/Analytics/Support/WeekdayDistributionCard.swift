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

    /// Deutsche Kurzform – immer eindeutig.
    private static let germanSymbols: [Int: String] = [
        1: "So", 2: "Mo", 3: "Di",
        4: "Mi", 5: "Do", 6: "Fr", 7: "Sa"
    ]

    /// Sortiert nach dem in den Settings gewählten Wochenbeginn.
    private var orderedData: [WeekdayDistribution] {
        let firstWeekday = Calendar.app.firstWeekday
        return data.sorted { lhs, rhs in
            let a = (lhs.weekday - firstWeekday + 7) % 7
            let b = (rhs.weekday - firstWeekday + 7) % 7
            return a < b
        }
    }

    /// Position 0…6 für jeden Tag in der gewählten Reihenfolge.
    private var indexedData: [(index: Int, item: WeekdayDistribution)] {
        orderedData.enumerated().map { ($0.offset, $0.element) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wochentage").font(.headline)
                Text("Wann du am produktivsten bist")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Chart(indexedData, id: \.index) { entry in
                BarMark(
                    x: .value("Tag", entry.index),
                    y: .value("Punkte", entry.item.points),
                    width: .fixed(20)        // ← breitere Bars
                )
                .foregroundStyle(
                    entry.item.points == maxPoints && entry.item.points > 0
                    ? Color.accentColor
                    : Color.accentColor.opacity(0.45)
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
                    if entry.item.points > 0 {
                        Text("\(entry.item.points)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // Domain inkl. halber Bar-Breite Padding links/rechts → nichts wird abgeschnitten
            .chartXScale(domain: -0.5...6.5)
            .chartXAxis {
                AxisMarks(values: Array(0...6)) { value in
                    AxisValueLabel {
                        if let idx = value.as(Int.self),
                           idx < indexedData.count {
                            Text(Self.germanSymbols[indexedData[idx].item.weekday] ?? "")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
