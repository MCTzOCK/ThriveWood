//
//  StepsCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI
import Charts

struct StepsCard: View {
    @Environment(AppEnvironment.self) private var env
    let range: ClosedRange<Date>

    @State private var dailySteps: [(date: Date, steps: Double)] = []
    @State private var totalSteps: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schritte").font(.headline)
                    Text("via Apple Health")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(totalSteps))")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.pink)
                    Text("gesamt").font(.caption2).foregroundStyle(.secondary)
                }
            }

            if !dailySteps.isEmpty {
                Chart(dailySteps, id: \.date) { sample in
                    BarMark(
                        x: .value("Tag", sample.date, unit: .day),
                        y: .value("Schritte", sample.steps),
                        width: .ratio(0.7)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.pink, .pink.opacity(0.5)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                        AxisValueLabel()
                    }
                }
                .frame(height: 140)
            } else {
                ContentUnavailableView("Keine Daten", systemImage: "figure.walk",
                                        description: Text("Aktiviere Apple Health in den Einstellungen."))
                    .frame(height: 140)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .task { await loadData() }
    }

    private func loadData() async {
        guard env.healthService.isAuthorized else { return }
        dailySteps = (try? await env.healthService.fetchDailySteps(in: range)) ?? []
        totalSteps = (try? await env.healthService.fetchSteps(in: range)) ?? 0
    }
}
