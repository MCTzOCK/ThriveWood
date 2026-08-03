//
//  PointsTrendCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI
import Charts

struct PointsTrendCard: View {
    let samples: [DailyPointSample]
    let goal: Int

    @State private var selectedDate: Date?
    @Environment(\.bentoTheme) private var theme

    private var selectedSample: DailyPointSample? {
        guard let selectedDate else { return nil }
        return samples.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        BentoSection(title: Text("Punkte-Trend"), subtitle: Text("Tägliche Punkte im Zeitraum")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    if let s = selectedSample {
                        HStack(spacing: theme.spacing.xs) {
                            Text(s.date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                            Text("\(s.points) Punkte")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.colors.accent)
                            Spacer()
                        }
                    }

                    Chart {
                        ForEach(samples) { s in
                            AreaMark(
                                x: .value("Tag", s.date, unit: .day),
                                y: .value("Punkte", s.points)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        theme.colors.accent.opacity(0.35),
                                        theme.colors.accent.opacity(0.03)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Tag", s.date, unit: .day),
                                y: .value("Punkte", s.points)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(theme.colors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }

                        if goal > 0 {
                            RuleMark(y: .value("Ziel", goal))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(theme.colors.warning.opacity(0.7))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Ziel \(goal)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(theme.colors.warning)
                                }
                        }

                        if let s = selectedSample {
                            RuleMark(x: .value("Auswahl", s.date, unit: .day))
                                .foregroundStyle(theme.colors.onSurface.opacity(0.2))
                            PointMark(
                                x: .value("Tag", s.date, unit: .day),
                                y: .value("Punkte", s.points)
                            )
                            .foregroundStyle(theme.colors.accent)
                            .symbolSize(120)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel()
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: xAxisStride)) { _ in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .chartXSelection(value: $selectedDate)
                    .frame(height: 200)
                }
            }
        }
    }

    private var xAxisStride: Calendar.Component {
        switch samples.count {
        case 0...14: .day
        case 15...60: .weekOfYear
        default: .month
        }
    }
}