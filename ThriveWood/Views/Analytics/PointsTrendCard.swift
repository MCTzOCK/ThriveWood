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

    private var selectedSample: DailyPointSample? {
        guard let selectedDate else { return nil }
        return samples.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Punkte-Trend").font(.headline)
                    Text("Tägliche Punkte im Zeitraum")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let s = selectedSample {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(s.date.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(s.points) Punkte")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
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
                            colors: [Color.green.opacity(0.4), Color.green.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Tag", s.date, unit: .day),
                        y: .value("Punkte", s.points)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                if goal > 0 {
                    RuleMark(y: .value("Ziel", goal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.orange.opacity(0.7))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Ziel \(goal)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                }

                if let s = selectedSample {
                    RuleMark(x: .value("Auswahl", s.date, unit: .day))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    PointMark(
                        x: .value("Tag", s.date, unit: .day),
                        y: .value("Punkte", s.points)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(100)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { value in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.10))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 200)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private var xAxisStride: Calendar.Component {
        switch samples.count {
        case 0...14: .day
        case 15...60: .weekOfYear
        default: .month
        }
    }
}
