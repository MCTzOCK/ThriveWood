//
//  AnalyticsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme
    @State private var vm: AnalyticsViewModel?
    @State private var showingPaywall = false
    @State private var selectedWorkoutMetric: WorkoutMetric = .volume
    @State private var dailySteps: [(date: Date, steps: Double)] = []
    @State private var totalSteps: Double = 0
    @State private var selectedTrendDate: Date?

    var body: some View {
        NavigationStack {
            Group {
                if let vm { content(vm: vm) }
                else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.colors.background)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if vm == nil { vm = AnalyticsViewModel(env: env) }
            vm?.load()
            await loadSteps()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: AnalyticsViewModel) -> some View {
        @Bindable var vm = vm

        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("Statistiken"),
                title: Text("Analyse")
            )

            BentoCard(style: .outlined, padding: .xs, radius: .large) {
                BentoSegmentedPicker(options: AnalyticsRange.allCases, selection: $vm.range) { range in
                    Text(range.rawValue)
                }
            }
            .onChange(of: vm.range) { _, newRange in
                if newRange != .week && !env.entitlements.canAccessFullAnalytics {
                    vm.range = .week
                    showingPaywall = true
                }
                vm.load()
                Task { await loadSteps() }
            }

            if let summary = vm.summary {
                summaryGrid(summary: summary, samples: vm.dailySamples)
            }

            pointsTrendSection(samples: vm.dailySamples, goal: vm.dailyGoal)

            weekdayDistributionSection(data: vm.weekdayDistribution)

            if !vm.habitPerformances.isEmpty {
                habitLeaderboardSection(performances: vm.habitPerformances)

                heatmapSection(
                    performances: vm.habitPerformances,
                    selectedHabitID: vm.selectedHabitID,
                    heatmap: vm.heatmap,
                    onSelect: vm.selectHabit
                )
            }

            if let totals = vm.workoutTotals,
               !vm.workoutMetrics.isEmpty,
               totals.totalSessions > 0 {
                workoutSection(samples: vm.workoutMetrics, totals: totals)
            }

            if env.healthService.isAuthorized {
                stepsSection
            }

            Spacer(minLength: theme.spacing.xxl)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .refreshable {
            vm.load()
            await loadSteps()
        }
        .errorAlert(vm.errors)
    }

    // MARK: - Summary Grid

    private func summaryGrid(summary: AnalyticsSummary, samples: [DailyPointSample]) -> some View {
        BentoAdaptiveGrid(minimumItemWidth: 155) {
            BentoMetricTile(
                title: Text("Punkte gesamt"),
                value: Text("\(summary.totalPoints)"),
                systemImage: "leaf.fill",
                tone: .green,
                trendValues: samples.map { Double($0.points) }
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
                title: Text("\u{00D8} pro Tag"),
                value: Text(String(format: "%.1f", summary.averagePointsPerActiveDay)),
                systemImage: "chart.line.uptrend.xyaxis",
                tone: .info
            )
        }
    }

    // MARK: - Points Trend

    private func pointsTrendSection(samples: [DailyPointSample], goal: Int) -> some View {
        BentoSection(title: Text("Punkte-Trend"), subtitle: Text("T\u{00E4}gliche Punkte im Zeitraum")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    if let best = samples.max(by: { $0.points < $1.points }), best.points > 0 {
                        HStack(spacing: theme.spacing.xs) {
                            BentoBadge(
                                Text("Best: \(best.points)"),
                                tone: .success,
                                systemImage: "star.fill"
                            )
                            Text(best.date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(theme.colors.onSurfaceMuted)
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

                        if let selected = trendSelectedSample(in: samples) {
                            RuleMark(x: .value("Auswahl", selected.date, unit: .day))
                                .foregroundStyle(theme.colors.onSurface.opacity(0.2))
                            PointMark(
                                x: .value("Tag", selected.date, unit: .day),
                                y: .value("Punkte", selected.points)
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
                        AxisMarks(values: .stride(by: trendXStride(count: samples.count))) { _ in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .chartXSelection(value: $selectedTrendDate)
                    .frame(height: 200)
                }
            }
        }
    }

    private func trendSelectedSample(in samples: [DailyPointSample]) -> DailyPointSample? {
        guard let selectedTrendDate else { return nil }
        return samples.min(by: {
            abs($0.date.timeIntervalSince(selectedTrendDate)) < abs($1.date.timeIntervalSince(selectedTrendDate))
        })
    }

    private func trendXStride(count: Int) -> Calendar.Component {
        switch count {
        case 0...14: .day
        case 15...60: .weekOfYear
        default: .month
        }
    }

    // MARK: - Weekday Distribution

    private func weekdayDistributionSection(data: [WeekdayDistribution]) -> some View {
        BentoSection(title: Text("Wochentage"), subtitle: Text("Wann du am produktivsten bist")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                let ordered = orderedWeekdays(from: data)
                let maxPoints = max(1, data.map(\.points).max() ?? 1)

                Chart(Array(ordered.enumerated()), id: \.offset) { idx, entry in
                    BarMark(
                        x: .value("Tag", idx),
                        y: .value("Punkte", entry.points),
                        width: .fixed(22)
                    )
                    .foregroundStyle(
                        entry.points == maxPoints && entry.points > 0
                        ? theme.colors.accent
                        : theme.colors.accent.opacity(0.4)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 6,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 6
                        )
                    )
                    .annotation(position: .top, alignment: .center) {
                        if entry.points > 0 {
                            Text("\(entry.points)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                }
                .chartXScale(domain: -0.5...6.5)
                .chartXAxis {
                    AxisMarks(values: Array(0...6)) { value in
                        AxisValueLabel {
                            if let i = value.as(Int.self), i < ordered.count {
                                Text(Self.germanWeekdaySymbols[ordered[i].weekday] ?? "")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.colors.onSurfaceMuted)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                        AxisValueLabel()
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private static let germanWeekdaySymbols: [Int: String] = [
        1: "So", 2: "Mo", 3: "Di",
        4: "Mi", 5: "Do", 6: "Fr", 7: "Sa"
    ]

    private func orderedWeekdays(from data: [WeekdayDistribution]) -> [WeekdayDistribution] {
        let firstWeekday = Calendar.app.firstWeekday
        return data.sorted { lhs, rhs in
            let a = (lhs.weekday - firstWeekday + 7) % 7
            let b = (rhs.weekday - firstWeekday + 7) % 7
            return a < b
        }
    }

    // MARK: - Habit Leaderboard

    private func habitLeaderboardSection(performances: [HabitPerformance]) -> some View {
        BentoSection(title: Text("Top Habits"), subtitle: Text("Sortiert nach Erf\u{00FC}llungsgrad")) {
            VStack(spacing: theme.spacing.xs) {
                ForEach(Array(performances.prefix(5).enumerated()), id: \.element.id) { idx, p in
                    habitLeaderboardRow(rank: idx + 1, performance: p)
                }
            }
        }
    }

    @ViewBuilder
    private func habitLeaderboardRow(rank: Int, performance: HabitPerformance) -> some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                        .fill(performance.color.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: performance.iconSystemName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    HStack(spacing: theme.spacing.xxs) {
                        Text("#\(rank)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Text(performance.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(performance.color.color.opacity(0.15))
                            Capsule()
                                .fill(performance.color.color)
                                .frame(width: geo.size.width * performance.completionRate)
                        }
                    }
                    .frame(height: 6)
                }

                VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                    Text("\(Int(performance.completionRate * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(performance.color.color)
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(performance.currentStreak)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                }
                .frame(minWidth: 50, alignment: .trailing)
            }
        }
    }

    // MARK: - Heatmap

    private func heatmapSection(
        performances: [HabitPerformance],
        selectedHabitID: UUID?,
        heatmap: [HabitHeatmapCell],
        onSelect: @escaping (UUID) -> Void
    ) -> some View {
        BentoSection(title: Text("Aktivit\u{00E4}t"), subtitle: Text("90 Tage Verlauf")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(performances) { p in
                                Button {
                                    Haptics.selection()
                                    onSelect(p.habitID)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: p.iconSystemName)
                                            .font(.caption.weight(.semibold))
                                        Text(p.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, theme.spacing.sm)
                                    .padding(.vertical, theme.spacing.xxs)
                                    .background(
                                        Capsule().fill(
                                            p.habitID == selectedHabitID
                                            ? p.color.color
                                            : p.color.color.opacity(0.12)
                                        )
                                    )
                                    .foregroundStyle(
                                        p.habitID == selectedHabitID
                                        ? .white
                                        : p.color.color
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    heatmapGrid(heatmap: heatmap)
                    heatmapLegend
                }
            }
        }
    }

    private func heatmapGrid(heatmap: [HabitHeatmapCell]) -> some View {
        let columns = heatmapColumns(from: heatmap)
        let cellSize: CGFloat = 14
        let spacing: CGFloat = 3

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { row in
                            heatmapCell(column[safe: row] ?? nil, size: cellSize)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func heatmapColumns(from heatmap: [HabitHeatmapCell]) -> [[HabitHeatmapCell?]] {
        guard let first = heatmap.first else { return [] }
        let cal = Calendar.app
        let weekday = cal.component(.weekday, from: first.date)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        var cells: [HabitHeatmapCell?] = Array(repeating: nil, count: offset)
        cells.append(contentsOf: heatmap.map { Optional($0) })
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map {
            Array(cells[$0..<min($0 + 7, cells.count)])
        }
    }

    private func heatmapCell(_ cell: HabitHeatmapCell?, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(heatmapColor(for: cell))
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        theme.colors.accent.opacity(cell == nil ? 0 : 0.04),
                        lineWidth: 1
                    )
            )
    }

    private func heatmapColor(for cell: HabitHeatmapCell?) -> Color {
        guard let cell, cell.points > 0 else {
            return theme.colors.onSurface.opacity(0.08)
        }
        let intensity: Double = switch cell.points {
        case 1: 0.25
        case 2: 0.45
        case 3: 0.65
        case 4...5: 0.8
        default: 1.0
        }
        return theme.colors.accent.opacity(intensity)
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("Weniger")
                .font(.caption2)
                .foregroundStyle(theme.colors.onSurfaceMuted)
            ForEach([0.12, 0.25, 0.45, 0.65, 0.85, 1.0], id: \.self) { op in
                RoundedRectangle(cornerRadius: 3)
                    .fill(op <= 0.12
                          ? theme.colors.onSurface.opacity(0.08)
                          : theme.colors.accent.opacity(op))
                    .frame(width: 12, height: 12)
            }
            Text("Mehr")
                .font(.caption2)
                .foregroundStyle(theme.colors.onSurfaceMuted)
            Spacer()
        }
    }

    // MARK: - Workout Stats

    private func workoutSection(samples: [WorkoutMetricsSample], totals: WorkoutTotals) -> some View {
        let availableMetrics = workoutAvailableMetrics(from: totals)

        return BentoSection(
            title: Text("Training"),
            subtitle: Text("\(totals.totalSessions) Einheit\(totals.totalSessions == 1 ? "" : "en")")
        ) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text(workoutTotalText(for: selectedWorkoutMetric, in: totals))
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(selectedWorkoutMetric.color)
                            Text(selectedWorkoutMetric.label)
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
                                        selectedWorkoutMetric = metric
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
                                            selectedWorkoutMetric == metric
                                            ? metric.color
                                            : metric.color.opacity(0.12)
                                        )
                                    )
                                    .foregroundStyle(
                                        selectedWorkoutMetric == metric
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
                            y: .value(
                                selectedWorkoutMetric.label,
                                workoutValue(for: selectedWorkoutMetric, in: sample)
                            ),
                            width: .ratio(0.7)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    selectedWorkoutMetric.color,
                                    selectedWorkoutMetric.color.opacity(0.55)
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
                                    Text(workoutFormat(v, for: selectedWorkoutMetric))
                                        .font(.caption2)
                                        .foregroundStyle(theme.colors.onSurfaceMuted)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: workoutXStride(count: samples.count))) { _ in
                            AxisGridLine().foregroundStyle(theme.colors.outlineSubtle)
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .frame(height: 170)
                    .animation(theme.motion.snappy, value: selectedWorkoutMetric)

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
                                Text(workoutTotalText(for: metric, in: totals))
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
                if !availableMetrics.contains(selectedWorkoutMetric) {
                    selectedWorkoutMetric = availableMetrics.first ?? .volume
                }
            }
        }
    }

    private func workoutAvailableMetrics(from totals: WorkoutTotals) -> [WorkoutMetric] {
        var result: [WorkoutMetric] = []
        if totals.hasStrength { result.append(.volume) }
        if totals.hasReps     { result.append(.reps) }
        if totals.hasDuration { result.append(.duration) }
        if totals.hasDistance { result.append(.distance) }
        return result
    }

    private func workoutValue(for metric: WorkoutMetric, in sample: WorkoutMetricsSample) -> Double {
        switch metric {
        case .volume:   sample.volumeKg
        case .reps:     Double(sample.totalReps)
        case .duration: Double(sample.durationSeconds) / 60
        case .distance: sample.distanceMeters / 1000
        }
    }

    private func workoutTotalText(for metric: WorkoutMetric, in totals: WorkoutTotals) -> String {
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

    private func workoutFormat(_ v: Double, for metric: WorkoutMetric) -> String {
        switch metric {
        case .volume:   "\(Int(v))"
        case .reps:     "\(Int(v))"
        case .duration: "\(Int(v))"
        case .distance: String(format: "%.1f", v)
        }
    }

    private func workoutXStride(count: Int) -> Calendar.Component {
        switch count {
        case 0...14: .day
        case 15...60: .weekOfYear
        default: .month
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
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
    }

    private func loadSteps() async {
        guard env.healthService.isAuthorized, let vm else { return }
        let range = vm.range.dateRange()
        dailySteps = (try? await env.healthService.fetchDailySteps(in: range)) ?? []
        totalSteps = (try? await env.healthService.fetchSteps(in: range)) ?? 0
    }

    // MARK: - Old Body

    var oldBody: some View {
        NavigationStack {
            Group {
                if let vm { legacyContent(vm: vm) }
                else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if vm == nil { vm = AnalyticsViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func legacyContent(vm: AnalyticsViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                premiumHeader

                RangePicker(range: $vm.range)
                    .onChange(of: vm.range) { _, newRange in
                        if newRange != .week && !env.entitlements.canAccessFullAnalytics {
                            vm.range = .week
                            showingPaywall = true
                        }
                        vm.load()
                    }

                if let summary = vm.summary {
                    SummaryGrid(summary: summary)
                }

                PointsTrendCard(samples: vm.dailySamples, goal: vm.dailyGoal)

                WeekdayDistributionCard(data: vm.weekdayDistribution)

                if !vm.habitPerformances.isEmpty {
                    HabitLeaderboardCard(performances: vm.habitPerformances)

                    HeatmapCard(
                        performances: vm.habitPerformances,
                        selectedHabitID: vm.selectedHabitID,
                        heatmap: vm.heatmap,
                        onSelect: vm.selectHabit
                    )
                }

                if let totals = vm.workoutTotals,
                   !vm.workoutMetrics.isEmpty,
                   totals.totalSessions > 0 {
                    WorkoutStatsCard(samples: vm.workoutMetrics, totals: totals)
                }

                if env.healthService.isAuthorized {
                    StepsCard(range: vm.range.dateRange())
                }
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
    }

    private var premiumHeader: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Statistiken")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text("Analyse")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}

// MARK: - Extensions

extension WorkoutMetric {
    var bentoTone: BentoTone {
        switch self {
        case .volume:   .blue
        case .reps:     .pink
        case .duration: .warning
        case .distance: .info
        }
    }
}

extension HabitColor {
    var bentoTone: BentoTone {
        switch self {
        case .green, .mint:  .green
        case .teal:          .info
        case .blue, .indigo: .blue
        case .purple, .pink: .pink
        case .red:           .danger
        case .orange:        .warning
        case .yellow:        .yellow
        case .brown, .gray:  .neutral
        }
    }
}
