//
//  WorkoutMetric.swift
//  ThriveWood
//
//  Created by Ben Siebert on 27.04.26.
//


import SwiftUI
import Charts

enum WorkoutMetric: String, CaseIterable, Identifiable {
    case volume, reps, duration, distance
    var id: String { rawValue }

    var label: String {
        switch self {
        case .volume:   "Volumen"
        case .reps:     "Reps"
        case .duration: "Zeit"
        case .distance: "Distanz"
        }
    }

    var unit: String {
        switch self {
        case .volume: "kg"
        case .reps: ""
        case .duration: "min"
        case .distance: "km"
        }
    }

    var color: Color {
        switch self {
        case .volume:   .blue
        case .reps:     .purple
        case .duration: .pink
        case .distance: .teal
        }
    }

    var icon: String {
        switch self {
        case .volume:   "scalemass.fill"
        case .reps:     "number"
        case .duration: "timer"
        case .distance: "location.fill"
        }
    }
}

struct WorkoutStatsCard: View {
    let samples: [WorkoutMetricsSample]
    let totals: WorkoutTotals

    @State private var selected: WorkoutMetric = .volume

    /// Nur die Metriken zeigen, für die es auch Daten gibt.
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
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            header
            metricChips
            chart
            footer
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .onAppear {
            // Wähle die erste verfügbare Metrik, falls die aktuelle nichts hergibt
            if !availableMetrics.contains(selected) {
                selected = availableMetrics.first ?? .volume
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Training").font(.headline)
                Text("\(totals.totalSessions) Einheit\(totals.totalSessions == 1 ? "" : "en") im Zeitraum")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(totalText(for: selected))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(selected.color)
                Text(selected.label)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Chips

    private var metricChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableMetrics) { metric in
                    Button {
                        Haptics.selection()
                        withAnimation(.snappy) { selected = metric }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: metric.icon).font(.caption.weight(.bold))
                            Text(metric.label).font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(
                                selected == metric
                                ? metric.color
                                : metric.color.opacity(0.15)
                            )
                        )
                        .foregroundStyle(selected == metric ? .white : metric.color)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Chart

    private var chart: some View {
        Chart(samples) { sample in
            BarMark(
                x: .value("Tag", sample.date, unit: .day),
                y: .value(selected.label, value(for: selected, in: sample)),
                width: .ratio(0.7)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selected.color, selected.color.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
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
                AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(format(v, for: selected))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStride)) { _ in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.10))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(height: 170)
        .animation(.snappy, value: selected)
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

    // MARK: Footer (Mini-KPIs)

    private var footer: some View {
        HStack(spacing: 0) {
            ForEach(Array(availableMetrics.enumerated()), id: \.element) { idx, metric in
                if idx > 0 { Divider().frame(height: 28) }
                MiniKPI(
                    icon: metric.icon,
                    value: totalText(for: metric),
                    label: metric.label,
                    tint: metric.color
                )
            }
        }
        .padding(.top, Theme.Spacing.s)
    }

    private struct MiniKPI: View {
        let icon: String; let value: String; let label: String; let tint: Color
        var body: some View {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.caption).foregroundStyle(tint)
                Text(value).font(.caption.weight(.bold).monospacedDigit())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
