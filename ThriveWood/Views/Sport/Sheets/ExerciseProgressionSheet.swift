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
    @Environment(\.bentoTheme) private var theme

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
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("PROGRESSION"),
                title: Text(exercise.name),
                subtitle: Text(trackingLabel)
            )

            prHeroCard

            if progression.count >= 2 {
                chartCard
            } else if progression.isEmpty {
                emptyProgression
            }

            if !progression.isEmpty {
                historyCard
            }

            Spacer(minLength: theme.spacing.xxl)
        }
        .onAppear { load() }
    }

    // MARK: - PR Hero

    private var prHeroCard: some View {
        BentoCard(tone: .warning, style: .elevated, padding: .lg, radius: .extraLarge) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .symbolEffect(.bounce, value: topSet.id)
                }

                VStack(alignment: .leading, spacing: 2) {
                    BentoText(verbatim: "Aktueller PR", style: .caption)
                    BentoText(verbatim: valueLabel, style: .title2)
                    if showReps, let reps = topSet.reps {
                        BentoText(verbatim: "\(reps) Reps", style: .caption)
                    }
                    if let date = progression.last?.date {
                        BentoText(
                            verbatim: date.formatted(.dateTime.day().month(.abbreviated).year()),
                            style: .caption
                        )
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        BentoSection(title: Text("Progression"), subtitle: Text(trackingLabel)) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                Chart(Array(progression.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Datum", point.date, unit: .day),
                        y: .value(trackingLabel, chartValue(point.value))
                    )
                    .foregroundStyle(theme.colors.warning)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    AreaMark(
                        x: .value("Datum", point.date, unit: .day),
                        y: .value(trackingLabel, chartValue(point.value))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.colors.warning.opacity(0.35),
                                theme.colors.warning.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value(trackingLabel, chartValue(point.value))
                    )
                    .foregroundStyle(theme.colors.warning)
                    .symbolSize(45)

                    if showReps, let reps = point.reps {
                        PointMark(
                            x: .value("Datum", point.date),
                            y: .value(trackingLabel, chartValue(point.value))
                        )
                        .annotation(position: .top, spacing: 2) {
                            Text(verbatim: "\(reps)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
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
        }
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

    // MARK: - Empty

    private var emptyProgression: some View {
        BentoCard(style: .outlined, padding: .lg, radius: .large) {
            BentoEmptyState(
                systemImage: "chart.line.uptrend.xyaxis",
                title: Text("Noch keine Progression"),
                message: Text("Sammle weitere Sessions, um hier deinen Verlauf zu sehen.")
            )
        }
    }

    // MARK: - History

    private var historyCard: some View {
        BentoSection(title: Text("PR-Verlauf"), subtitle: Text("\(progression.count) Einträge")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: 0) {
                    ForEach(Array(progression.enumerated()), id: \.offset) { index, entry in
                        let isLatest = index == progression.count - 1
                        BentoTimelineRow(
                            title: Text(formattedValue(entry.value)),
                            detail: Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year())),
                            tone: isLatest ? .warning : .neutral,
                            isLast: isLatest
                        )

                        if !isLatest {
                            BentoDivider()
                                .padding(.leading, 28)
                        }
                    }
                }
            }
        }
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
