//
//  WorkoutStatsCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 27.04.26.
//

import SwiftUI
import Charts

struct WorkoutStatsCard: View {
    let samples: [WorkoutMetricsSample]
    let totals: WorkoutTotals

    @State private var selected: WorkoutMetric = .volume
    @Environment(\.bentoTheme) private var theme

    private var availableMetrics: [WorkoutMetric] {
        var result: [WorkoutMetric] = []
        if totals.hasStrength { result.append(.volume) }
        if totals.hasReps     { result.append(.reps) }
        if totals.hasDuration { result.append(.duration) }
        if totals.hasDistance { result.append(.distance) }
        return result
    }

    private func value(for metric: WorkoutMetric, in sample: WorkoutMetricsSample) -> Double {
        switch metric {
        case .volume:   sample.volumeKg
        case .reps:     Double(sample.totalReps)
        case .duration: Double(sample.durationSeconds) / 60
        case .distance: sample.distanceMeters / 1000
        }
    }

    private func totalText(for metric: WorkoutMetric) -> String {
        switch metric {
        case .volume:
            return "\(Int(totals.totalVolumeKg)) kg"
        case .reps:
            return "\(totals.totalReps)"
        case .duration:
            let m = totals.totalDurationSeconds / 60
            let h = m / 60
            return h > 0 ? "\(h)h \(m % 60)min" : "\(m) min"
        case .distance:
            return String(format: "%.1f km", totals.totalDistanceMeters / 1000)
        }
    }

    var body: some View {
        if availableMetrics.isEmpty {
            EmptyView()
        } else {
            content
        }
    }

    private var content: some View {
        BentoSection(
            title: Text("Training"),
            subtitle: Text("\(totals.totalSessions) Einheit\(totals.totalSessions == 1 ? "" : "en")")
        ) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text(totalText(for: selected))
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(selected.color)
                            Text(selected.label)
                                .font(.caption)
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                        Spacer()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(availableMetrics) { metric in
                                Button {
                                    Haptics.selection()
                                    withAnimation(theme.motion.snappy) {
                                        selected = metric
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: metric.icon)
                                            .font(.caption.weight(.bold))
                                        Text(metric.label)
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, theme.spacing.sm)
                                    .padding(.vertical, theme.spacing.xxs)
                                    .background(
                                        Capsule().fill(
                                            selected == metric
                                            ? metric.color
                                            : metric.color.opacity(0.12)
                                        )
                                    )
                                    .foregroundStyle(
                                        selected == metric
                                        ? .white
                                        : metric.color
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Chart(samples) { sample in
                        BarMark(
                            x: .value("Tag", sample.date, unit: .day),
                            y: .value(selected.label, value(for: selected, in: sample)),
                            width: .ratio(0.7)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    selected.color,
                                    selected.color.opacity(0.55)
                                ],
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
                        AxisMarks(position: .leading) { value in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(format(v, for: selected))
                                        .font(.caption2)
                                        .foregroundStyle(theme.colors.onSurfaceMuted)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: xAxisStride)) { _ in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .frame(height: 170)
                    .animation(theme.motion.snappy, value: selected)

                    BentoDivider()

                    HStack(spacing: 0) {
                        ForEach(Array(availableMetrics.enumerated()), id: \.element) { idx, metric in
                            if idx > 0 {
                                BentoDivider(orientation: .vertical)
                                    .frame(height: 32)
                            }
                            VStack(spacing: theme.spacing.xxs) {
                                Image(systemName: metric.icon)
                                    .font(.caption)
                                    .foregroundStyle(metric.color)
                                Text(totalText(for: metric))
                                    .font(.caption.weight(.bold).monospacedDigit())
                                Text(metric.label)
                                    .font(.caption2)
                                    .foregroundStyle(theme.colors.onSurfaceMuted)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .onAppear {
                if !availableMetrics.contains(selected) {
                    selected = availableMetrics.first ?? .volume
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

    private func format(_ v: Double, for metric: WorkoutMetric) -> String {
        switch metric {
        case .volume:   "\(Int(v))"
        case .reps:     "\(Int(v))"
        case .duration: "\(Int(v))"
        case .distance: String(format: "%.1f", v)
        }
    }
}