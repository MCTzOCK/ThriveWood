//
//  SummaryGrid.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct SummaryGrid: View {
    let summary: AnalyticsSummary

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryTile(
                icon: "leaf.fill", tint: .green,
                value: "\(summary.totalPoints)", label: "Punkte gesamt"
            )
            SummaryTile(
                icon: "checkmark.circle.fill", tint: .blue,
                value: "\(summary.totalCompletions)", label: "Abhakungen"
            )
            SummaryTile(
                icon: "calendar", tint: .orange,
                value: "\(summary.activeDays)", label: "Aktive Tage"
            )
            SummaryTile(
                icon: "chart.line.uptrend.xyaxis", tint: .purple,
                value: String(format: "%.1f", summary.averagePointsPerActiveDay),
                label: "Ø pro Tag"
            )
        }
    }

    private struct SummaryTile: View {
        let icon: String; let tint: Color; let value: String; let label: String
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .padding(8)
                    .background(Circle().fill(tint.opacity(0.15)))
                Text(value).font(.title2.bold()).contentTransition(.numericText())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.m)
            .cardStyle()
        }
    }
}
