//
//  SummaryGrid.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct SummaryGrid: View {
    let summary: AnalyticsSummary

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.m),
                           GridItem(.flexible(), spacing: Theme.Spacing.m)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
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
        let icon: String
        let tint: Color
        let value: String
        let label: String

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(Theme.Typography.body)
                        .foregroundStyle(tint)
                }
                Text(value)
                    .font(Theme.Typography.title2.weight(.bold))
                    .contentTransition(.numericText())
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Theme.Shadow.card, radius: 8, x: 0, y: 2)
        }
    }
}
