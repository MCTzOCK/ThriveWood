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
    @Environment(\.bentoTheme) private var theme
    let range: ClosedRange<Date>

    @State private var dailySteps: [(date: Date, steps: Double)] = []
    @State private var totalSteps: Double = 0

    var body: some View {
        BentoSection(title: Text("Schritte"), subtitle: Text("via Apple Health")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text("\(Int(totalSteps))")
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(.pink)
                            Text("gesamt")
                                .font(.caption)
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                        Spacer()
                    }

                    if !dailySteps.isEmpty {
                        Chart(dailySteps, id: \.date) { sample in
                            BarMark(
                                x: .value("Tag", sample.date, unit: .day),
                                y: .value("Schritte", sample.steps),
                                width: .ratio(0.7)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .pink.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 4,
                                    topTrailingRadius: 4
                                )
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                                AxisValueLabel()
                                    .foregroundStyle(theme.colors.onSurfaceMuted)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                                AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .foregroundStyle(theme.colors.onSurfaceMuted)
                            }
                        }
                        .frame(height: 140)
                    } else {
                        BentoEmptyState(
                            systemImage: "figure.walk",
                            title: Text("Keine Daten"),
                            message: Text("Aktiviere Apple Health in den Einstellungen.")
                        )
                        .frame(height: 140)
                    }
                }
            }
        }
        .task { await loadData() }
    }

    private func loadData() async {
        guard env.healthService.isAuthorized else { return }
        dailySteps = (try? await env.healthService.fetchDailySteps(in: range)) ?? []
        totalSteps = (try? await env.healthService.fetchSteps(in: range)) ?? 0
    }
}