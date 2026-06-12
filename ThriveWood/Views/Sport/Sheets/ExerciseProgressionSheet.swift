//
//  ExerciseProgressionSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 27.05.26.
//

import SwiftUI
import Charts

struct ExerciseProgressionSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let topSet: SetEntry

    @State private var progression: [(date: Date, value: Double, reps: Int?)] = []

    private var trackingLabel: String {
        switch exercise.trackingType {
        case .repsWeight: return "Gewicht (kg)"
        case .reps: return "Wiederholungen"
        case .duration: return "Dauer (s)"
        case .distanceDuration: return "Distanz (km)"
        }
    }

    private var valueLabel: String {
        switch exercise.trackingType {
        case .repsWeight: return "\(Int(topSet.weight ?? 0)) kg"
        case .reps: return "\(topSet.reps ?? 0) Reps"
        case .duration:
            let s = topSet.durationSeconds ?? 0
            return s >= 60 ? "\(s / 60):\(String(format: "%02d", s % 60)) min" : "\(s) s"
        case .distanceDuration:
            let km = (topSet.distanceMeters ?? 0) / 1000
            return String(format: "%.2f km", km)
        }
    }

    private var showReps: Bool {
        exercise.trackingType == .repsWeight
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    prHeader
                    if progression.count >= 2 {
                        chartCard
                    } else if progression.isEmpty {
                        emptyProgression
                    }
                    historyList
                }
                .padding(Theme.Spacing.l)
            }
            .background(Color.groupedBackground)
            .navigationTitle(exercise.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .onAppear { load() }
    }

    private var prHeader: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundStyle(.orange)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.orange.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktueller PR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(valueLabel)
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                if showReps, let reps = topSet.reps {
                    Text("\(reps) Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let date = progression.last?.date {
                    Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Progression")
                .font(.headline)

            Chart(Array(progression.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value(trackingLabel, chartValue(point.value))
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value(trackingLabel, chartValue(point.value))
                )
                .foregroundStyle(.orange.gradient.opacity(0.15))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Datum", point.date),
                    y: .value(trackingLabel, chartValue(point.value))
                )
                .foregroundStyle(.orange)
                .symbolSize(40)

                if showReps, let reps = point.reps {
                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value(trackingLabel, chartValue(point.value))
                    )
                    .foregroundStyle(.orange.gradient.opacity(0.8))
                    .annotation(position: .top, spacing: 2) {
                        Text("\(reps)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .stride(by: strideBy)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.month(.abbreviated).year(.twoDigits)))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(yAxisLabel(d))
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private var strideBy: Calendar.Component {
        progression.count > 24 ? .year : .month
    }

    private func chartValue(_ raw: Double) -> Double {
        switch exercise.trackingType {
        case .distanceDuration: return raw / 1000
        default: return raw
        }
    }

    private func yAxisLabel(_ d: Double) -> String {
        switch exercise.trackingType {
        case .repsWeight: return "\(Int(d))"
        case .reps: return "\(Int(d))"
        case .duration:
            let m = Int(d) / 60
            return m > 0 ? "\(m)m" : "\(Int(d))s"
        case .distanceDuration: return String(format: "%.1f", d)
        }
    }

    private var emptyProgression: some View {
        VStack(spacing: Theme.Spacing.s) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Noch keine Progression")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("PR-Verlauf")
                .font(.headline)

            if progression.isEmpty {
                Text("Keine Einträge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(progression.enumerated()), id: \.offset) { index, entry in
                    HStack {
                        Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.subheadline)
                        Spacer()
                        Text(formattedValue(entry.value))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(index == progression.count - 1 ? .orange : .primary)
                        
                        if showReps, let reps = entry.reps {
                            Text("× \(reps)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if index == progression.count - 1 {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 6)

                    if index < progression.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private func formattedValue(_ value: Double) -> String {
        switch exercise.trackingType {
        case .repsWeight: return "\(Int(value)) kg"
        case .reps: return "\(Int(value))"
        case .duration:
            let s = Int(value)
            return s >= 60 ? "\(s / 60):\(String(format: "%02d", s % 60)) min" : "\(s) s"
        case .distanceDuration:
            return String(format: "%.2f km", value / 1000)
        }
    }

    private func load() {
        progression = env.workoutService.getProgression(for: exercise)
    }
}
