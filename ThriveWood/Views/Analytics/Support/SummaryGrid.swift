//
//  SummaryGrid.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct SummaryGrid: View {
    let summary: AnalyticsSummary

    var body: some View {
        BentoAdaptiveGrid(minimumItemWidth: 155) {
            BentoMetricTile(
                title: Text("Punkte gesamt"),
                value: Text("\(summary.totalPoints)"),
                systemImage: "leaf.fill",
                tone: .green
            )
            BentoMetricTile(
                title: Text("Abhakungen"),
                value: Text("\(summary.totalCompletions)"),
                systemImage: "checkmark.circle.fill",
                tone: .blue
            )
            BentoMetricTile(
                title: Text("Aktive Tage"),
                value: Text("\(summary.activeDays)"),
                systemImage: "calendar",
                tone: .warning
            )
            BentoMetricTile(
                title: Text("Ø pro Tag"),
                value: Text(String(format: "%.1f", summary.averagePointsPerActiveDay)),
                systemImage: "chart.line.uptrend.xyaxis",
                tone: .info
            )
        }
    }
}