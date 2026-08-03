//
//  SportInsightsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 15.07.26.
//

import SwiftUI
import Charts

struct SportInsightsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showingAll1RM = false
    @State private var showingAllOverload = false
    @State private var showingAllTopExercises = false

    private var allSessions: [WorkoutSession] {
        (try? env.sessionRepo.fetchAll()) ?? []
    }

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.endedAt != nil }.sorted { $0.startedAt > $1.startedAt }
    }

    private var allCompletedSets: [SetEntry] {
        completedSessions.flatMap { $0.sets }.filter { $0.isCompleted }
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            if completedSessions.isEmpty {
                BentoEmptyState(
                    systemImage: "chart.bar.xaxis",
                    title: Text("Noch keine Daten"),
                    message: Text("Schließe ein paar Workouts ab, um detaillierte Insights zu sehen.")
                )
                .padding(.top, Theme.Spacing.xxl)
            } else {
                VStack(spacing: Theme.Spacing.l) {
                    BentoPageHeader(
                        eyebrow: Text("ANALYSEN"),
                        title: Text("Sport Insights"),
                        subtitle: Text("\(completedSessions.count) Sessions analysiert")
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.m)

                    quickStatsRow
                    gymStatsRow
                    trainingTimeCard
                    rpeDistributionCard
                    workoutBreakdownCard
                    avgDurationCard
                    muscleGroupBalanceCard
                    topExercisesCard
                    volumeTrendCard
                    weekdayFrequencyCard
                    estimated1RMCard
                    progressiveOverloadCard
                    consistencyCard
                    activityLevelCard
                }
                .padding(.bottom, 120)
            }
        }
        .bentoSheet(isPresented: $showingAll1RM, title: Text("Geschätztes 1RM"), detents: [.large]) {
            AllExercisesList(title: "Geschätztes 1RM — Alle Übungen") {
                computeEstimated1RM(limit: 999)
            }
        }
        .bentoSheet(isPresented: $showingAllOverload, title: Text("Progressive Overload"), detents: [.large]) {
            AllOverloadList(title: "Progressive Overload — Alle Übungen") {
                computeProgressiveOverload()
            }
        }
        .bentoSheet(isPresented: $showingAllTopExercises, title: Text("Top Übungen"), detents: [.large]) {
            AllTopExercisesList(title: "Top Übungen — Alle") {
                computeTopExercises(limit: 999)
            }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        let totalVolume = allCompletedSets.reduce(0.0) { $0 + $1.volumeValue }
        let totalSets = allCompletedSets.count
        let avgPerWeek = computeAvgPerWeek()
        let currentStreak = computeStreak()

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.s), GridItem(.flexible(), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
            QuickStatTile(icon: "scalemass.fill", value: formatVolume(totalVolume), label: "Gesamtvolumen", color: .blue)
            QuickStatTile(icon: "flame.fill", value: "\(currentStreak)", label: "Tage Streak", color: .orange)
            QuickStatTile(icon: "chart.bar.fill", value: "\(avgPerWeek)", label: "Ø / Woche", color: .green)
            QuickStatTile(icon: "sum", value: "\(totalSets)", label: "Sätze gesamt", color: .purple)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Gym Stats Row
  
    private var gymStatsRow: some View {
        let gymDays = Set(completedSessions.map { Calendar.current.startOfDay(for: $0.startedAt) }).count
        let totalMinutes = completedSessions.compactMap(\.durationSeconds).reduce(0, +) / 60
        let totalReps = allCompletedSets.compactMap(\.reps).reduce(0, +)

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.s), GridItem(.flexible(), spacing: Theme.Spacing.s), GridItem(.flexible(), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
            QuickStatTile(icon: "calendar.badge.checkmark", value: "\(gymDays)", label: "Tage im Gym", color: .green)
            QuickStatTile(icon: "timer", value: formatDuration(totalMinutes), label: "Gesamtzeit", color: .blue)
            QuickStatTile(icon: "arrow.triangle.2.circlepath", value: formatReps(totalReps), label: "Reps gesamt", color: .orange)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Training Times

    private var trainingTimeCard: some View {
        let hourBuckets = computeHourBuckets()
        let maxCount = hourBuckets.map(\.count).max() ?? 1
        let peakHour = hourBuckets.max(by: { $0.count < $1.count })

        return InsightCard(title: "Trainingszeiten", icon: "clock.fill") {
            if let peak = peakHour, peak.count > 0 {
                PillBadge(text: "Peak: \(peak.label)h", icon: "flame.fill", color: .orange)
            }

            Chart(hourBuckets) { bucket in
                BarMark(
                    x: .value("Stunde", bucket.hour),
                    y: .value("Sessions", bucket.count)
                )
                .foregroundStyle(bucket.count == maxCount && maxCount > 0 ? Color.orange : Color.accentColor.opacity(0.6))
                .cornerRadius(3)
            }
            .chartXScale(domain: 5...23)
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis {
                AxisMarks(values: [6, 9, 12, 15, 18, 21]) { value in
                    AxisValueLabel("\(value.as(Int.self) ?? 0)")
                }
            }
            .frame(height: 160)

            if let peak = peakHour, peak.count > 0 {
                Text("Du trainierst am häufigsten um \(peak.label) Uhr (\(peak.count)x).")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - RPE Distribution

    private var rpeDistributionCard: some View {
        let rpeData = computeRPEDistribution()
        let avgRPE = computeAvgRPE()
        let mostCommon = rpeData.max(by: { $0.count < $1.count })

        return InsightCard(title: "Anstrengung (RPE)", icon: "gauge.with.dots.needle.67percent") {
            if !rpeData.isEmpty {
                PillBadge(text: String(format: "Ø %.1f", avgRPE), icon: "chart.line.uptrend.xyaxis", color: .red)
            }

            if rpeData.isEmpty {
                Text("Noch keine RPE-Werte erfasst.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(rpeData) { item in
                    BarMark(
                        x: .value("RPE", item.rpe),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(
                        item.rpe <= 3 ? Color.green :
                        item.rpe <= 6 ? Color.yellow :
                        item.rpe <= 8 ? Color.orange : Color.red
                    )
                    .cornerRadius(4)
                }
                .chartXScale(domain: 1...10)
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: Array(1...10)) { value in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.1))
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)

                if let mc = mostCommon, mc.count > 0 {
                    Text("Meist trainierst du mit RPE \(mc.rpe) (\(mc.count)x).")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Workout Breakdown

    private var workoutBreakdownCard: some View {
        let grouped = Dictionary(grouping: completedSessions) { $0.workout?.name ?? "Freies Training" }
        let sorted = grouped.sorted { $0.value.count > $1.value.count }

        return InsightCard(title: "Workout-Verteilung", icon: "chart.pie.fill") {
            ForEach(sorted, id: \.key) { name, list in
                let total = completedSessions.count
                let fraction = total > 0 ? Double(list.count) / Double(total) : 0

                HStack(spacing: Theme.Spacing.m) {
                    Text(name)
                        .font(Theme.Typography.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(list.count)")
                        .font(Theme.Typography.mono)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: fraction)
                    .tint(Color.accentColor)
                    .frame(height: 6)
            }
        }
    }

    // MARK: - Avg Duration per Workout

    private var avgDurationCard: some View {
        let grouped = Dictionary(grouping: completedSessions) { $0.workout?.name ?? "Freies Training" }
        let avgData = grouped.map { (name, list) in
            (name: name, avgMinutes: list.compactMap(\.durationSeconds).map { $0 / 60 }.reduce(0, +) / max(list.count, 1))
        }.sorted { $0.avgMinutes > $1.avgMinutes }

        return InsightCard(title: "Ø Dauer pro Workout", icon: "timer") {
            ForEach(avgData, id: \.name) { item in
                HStack {
                    Text(item.name)
                        .font(Theme.Typography.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.avgMinutes) min")
                        .font(Theme.Typography.mono)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Muscle Group Balance

    private var muscleGroupBalanceCard: some View {
        let muscleData = computeMuscleGroupVolume()

        return InsightCard(title: "Muskelpunkte-Bilanz", icon: "figure.strengthtraining.traditional") {
            if muscleData.isEmpty {
                Text("Noch keine Daten.").font(Theme.Typography.caption).foregroundStyle(.secondary)
            } else {
                Chart(muscleData) { item in
                    BarMark(
                        x: .value("Volumen", item.volume),
                        y: .value("Muskel", item.label)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(formatVolume(item.volume))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis { AxisMarks(position: .bottom) }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel(value.as(String.self) ?? "")
                            .font(Theme.Typography.caption2)
                    }
                }
                .frame(height: CGFloat(muscleData.count) * 36 + 20)
            }
        }
    }

    // MARK: - Top Exercises by Volume

    private var topExercisesCard: some View {
        let topExercises = computeTopExercises(limit: 8)

        return Button {
            showingAllTopExercises = true
        } label: {
            InsightCard(title: "Top Übungen nach Volumen", icon: "trophy.fill") {
                if topExercises.isEmpty {
                    Text("Noch keine Daten.").font(Theme.Typography.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(topExercises, id: \.name) { item in
                        HStack(spacing: Theme.Spacing.m) {
                            Text("#\(item.rank)")
                                .font(Theme.Typography.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                                .frame(width: 24)

                            Text(item.name)
                                .font(Theme.Typography.subheadline)
                                .lineLimit(1)

                            Spacer()

                            Text(formatVolume(item.volume))
                                .font(Theme.Typography.mono)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if computeTopExercises(limit: 999).count > 8 {
                        HStack {
                            Spacer()
                            Text("Alle anzeigen (\(computeTopExercises(limit: 999).count))")
                                .font(Theme.Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Volume Trend

    private var volumeTrendCard: some View {
        let last12 = Array(completedSessions.prefix(12)).reversed()
        let volumeData = last12.map { s in
            (date: s.startedAt, volume: s.sets.filter(\.isCompleted).reduce(0.0) { $0 + $1.volumeValue })
        }

        return InsightCard(title: "Volumen-Trend", icon: "chart.line.uptrend.xyaxis") {
            if volumeData.count >= 2 {
                Chart(volumeData, id: \.date) { date, volume in
                    AreaMark(
                        x: .value("Datum", date),
                        y: .value("Volumen", volume)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )

                    LineMark(
                        x: .value("Datum", date),
                        y: .value("Volumen", volume)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 180)
            } else {
                Text("Mindestens 2 Sessions nötig.").font(Theme.Typography.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weekday Frequency

    private var weekdayFrequencyCard: some View {
        let weekdayData = computeWeekdayFrequency()
        let mostFrequent = weekdayData.max(by: { $0.count < $1.count })

        return InsightCard(title: "Wochentag-Verteilung", icon: "calendar") {
            Chart(weekdayData) { item in
                BarMark(
                    x: .value("Tag", item.shortLabel),
                    y: .value("Sessions", item.count)
                )
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis { AxisMarks() }
            .frame(height: 160)

            if let mf = mostFrequent, mf.count > 0 {
                Text("Am liebsten trainierst du \(mf.label) (\(mf.count)x).")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Estimated 1RM

    private var estimated1RMCard: some View {
        let e1rmData = computeEstimated1RM(limit: 6)

        return Button {
            showingAll1RM = true
        } label: {
            InsightCard(title: "Geschätztes 1RM", icon: "dumbbell.fill") {
                if e1rmData.isEmpty {
                    Text("Noch keine Sätze mit Gewicht erfasst.").font(Theme.Typography.caption).foregroundStyle(.secondary)
                } else {
                    Text("Das 1-Repetition-Maximum (1RM) ist das Gewicht, das du theoretisch genau einmal bewegen kannst. Geschätzt nach der Epley-Formel aus deinem schwersten Satz.")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, Theme.Spacing.s)

                    ForEach(e1rmData, id: \.name) { item in
                        HStack {
                            Text(item.name)
                                .font(Theme.Typography.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.e1rm.clean) kg")
                                .font(Theme.Typography.mono)
                                .foregroundStyle(.primary)
                            Text("(\(item.weight.clean) × \(item.reps))")
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if computeEstimated1RM(limit: 999).count > 6 {
                        HStack {
                            Spacer()
                            Text("Alle anzeigen (\(computeEstimated1RM(limit: 999).count))")
                                .font(Theme.Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Progressive Overload

    private var progressiveOverloadCard: some View {
        let overload = computeProgressiveOverload()

        return Button {
            showingAllOverload = true
        } label: {
            InsightCard(title: "Progressive Overload", icon: "arrow.up.right.circle.fill") {
                if overload.isEmpty {
                    Text("Noch nicht genug Daten für Vergleich.").font(Theme.Typography.caption).foregroundStyle(.secondary)
                } else {
                    Text("Vergleicht das Ø-Volumen pro Satz der ersten Hälfte deiner Sessions mit der zweiten. Positiv = du hast dich gesteigert.")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, Theme.Spacing.s)

                    ForEach(overload.prefix(8), id: \.name) { item in
                        HStack(spacing: Theme.Spacing.m) {
                            Text(item.name)
                                .font(Theme.Typography.subheadline)
                                .lineLimit(1)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(item.trend == .up ? "↑" : item.trend == .down ? "↓" : "→")
                                    .foregroundStyle(item.trend == .up ? .green : item.trend == .down ? .red : .secondary)
                                Text("\(item.pctChange >= 0 ? "+" : "")\(Int(item.pctChange))%")
                                    .font(Theme.Typography.mono)
                                    .foregroundStyle(item.trend == .up ? .green : item.trend == .down ? .red : .secondary)
                            }
                        }
                    }

                    if overload.count > 8 {
                        HStack {
                            Spacer()
                            Text("Alle anzeigen (\(overload.count))")
                                .font(Theme.Typography.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Consistency

    private var consistencyCard: some View {
        let consistency = computeConsistency()
        let activeWeeks = computeActiveWeeks()
        let totalWeeks = computeTotalWeeks()

        return InsightCard(title: "Konsistenz", icon: "checkmark.seal.fill") {
            VStack(spacing: Theme.Spacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(consistency * 100))%")
                            .font(Theme.Typography.title2.weight(.bold))
                        Text("aktive Wochen")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(activeWeeks)/\(totalWeeks)")
                            .font(Theme.Typography.mono)
                        Text("Wochen aktiv")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: consistency)
                    .tint(consistency >= 0.7 ? .green : consistency >= 0.4 ? .orange : .red)
                    .frame(height: 8)
            }
        }
    }

    // MARK: - Activity Level Summary

    private var activityLevelCard: some View {
        let level = computeActivityLevel()
        let totalVolume = allCompletedSets.filter { $0.exercise?.trackingType == .repsWeight }.reduce(0.0) { $0 + $1.volumeValue }
        let gymDays = Set(completedSessions.map { Calendar.current.startOfDay(for: $0.startedAt) }).count
        let avgRPE = computeAvgRPE()
        let consistency = computeConsistency()

        return InsightCard(title: "Trainingsstand", icon: "figure.run.circle.fill") {
            VStack(spacing: Theme.Spacing.l) {
                HStack(spacing: Theme.Spacing.l) {
                    ZStack {
                        Circle()
                            .fill(level.color.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: level.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(level.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(level.label)
                            .font(Theme.Typography.title2.weight(.bold))
                        Text(level.description)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                PremiumDivider()

                VStack(spacing: Theme.Spacing.s) {
                    summaryRow(label: "Gesamtvolumen (Kraft)", value: formatVolume(totalVolume) + " kg")
                    summaryRow(label: "Trainingstage", value: "\(gymDays)")
                    if avgRPE > 0 {
                        summaryRow(label: "Ø Anstrengung", value: String(format: "%.1f RPE", avgRPE))
                    }
                    summaryRow(label: "Konsistenz", value: "\(Int(consistency * 100))%")
                    summaryRow(label: "Sessions gesamt", value: "\(completedSessions.count)")
                }
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.footnote.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private struct ActivityLevel {
        let label: String
        let description: String
        let icon: String
        let color: Color
    }

    private func computeActivityLevel() -> ActivityLevel {
        let sessions = completedSessions.count
        let consistency = computeConsistency()
        let gymDays = Set(completedSessions.map { Calendar.current.startOfDay(for: $0.startedAt) }).count

        if sessions == 0 {
            return ActivityLevel(label: "Einsteiger", description: "Noch keine abgeschlossenen Sessions. Zeit für das erste Workout!", icon: "leaf.fill", color: .green)
        }

        if sessions < 10 || gymDays < 8 {
            return ActivityLevel(label: "Einsteiger", description: "Du machst deine ersten Schritte. Bleib dran – Konsistenz ist alles!", icon: "sprout.fill", color: .green)
        }

        if sessions < 50 || consistency < 0.5 {
            return ActivityLevel(label: "Fortgeschritten", description: "Du baust eine solide Basis auf. Trainiere regelmäßig für mehr Insights.", icon: "flame.fill", color: .orange)
        }

        if sessions < 150 || consistency < 0.7 {
            return ActivityLevel(label: "Erfahren", description: "Deine Trainingsroutine ist etabliert. Fein-tune deine Progression!", icon: "bolt.fill", color: .yellow)
        }

        return ActivityLevel(label: "Athlet", description: "Du trainierst extrem konsequent. Respekt für deine Disziplin!", icon: "trophy.fill", color: .purple)
    }

    // MARK: - Computation Helpers

    private struct HourBucket: Identifiable {
        let hour: Int
        let count: Int
        var id: Int { hour }
        var label: String { hour == 0 ? "0" : "\(hour)" }
    }

    private func computeHourBuckets() -> [HourBucket] {
        var counts = [Int: Int]()
        for s in completedSessions {
            let hour = Calendar.current.component(.hour, from: s.startedAt)
            counts[hour, default: 0] += 1
        }
        return (0...23).map { HourBucket(hour: $0, count: counts[$0] ?? 0) }
    }

    private struct RPEDatum: Identifiable {
        let rpe: Int
        let count: Int
        var id: Int { rpe }
    }

    private func computeRPEDistribution() -> [RPEDatum] {
        var counts = [Int: Int]()
        for s in completedSessions {
            if let rpe = s.perceivedExertion {
                counts[rpe, default: 0] += 1
            }
        }
        return (1...10).map { RPEDatum(rpe: $0, count: counts[$0] ?? 0) }
    }

    private func computeAvgRPE() -> Double {
        let rpes = completedSessions.compactMap(\.perceivedExertion)
        guard !rpes.isEmpty else { return 0 }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }

    private struct MuscleVolume: Identifiable {
        let label: String
        let volume: Double
        let color: Color
        var id: String { label }
    }

    private func computeMuscleGroupVolume() -> [MuscleVolume] {
        var volumes = [String: Double]()
        let colors: [String: Color] = [
            "Push": .red, "Pull": .blue, "Beine": .green, "Core": .orange, "Cardio": .purple, "Ganzkörper": .gray
        ]

        for set in allCompletedSets {
            guard let ex = set.exercise else { continue }
            let category = categorizeMuscleGroup(ex.primaryMuscleGroups)
            volumes[category, default: 0] += set.volumeValue
        }

        return volumes.sorted { $0.value > $1.value }.map { (k, v) in
            MuscleVolume(label: k, volume: v, color: colors[k] ?? .accentColor)
        }
    }

    private func categorizeMuscleGroup(_ groups: [MuscleGroup]) -> String {
        let push: Set<MuscleGroup> = [.chest, .upperChest, .shoulders, .frontDelts, .sideDelts, .triceps]
        let pull: Set<MuscleGroup> = [.lats, .upperBack, .midBack, .biceps, .forearms, .rearDelts, .rhomboids, .traps]
        let legs: Set<MuscleGroup> = [.quads, .hamstrings, .glutes, .calves, .adductors, .abductors]
        let core: Set<MuscleGroup> = [.core, .obliques, .serratus]

        let set = Set(groups)
        if !set.isDisjoint(with: push) { return "Push" }
        if !set.isDisjoint(with: pull) { return "Pull" }
        if !set.isDisjoint(with: legs) { return "Beine" }
        if !set.isDisjoint(with: core) { return "Core" }
        if set.contains(.cardio) { return "Cardio" }
        return "Ganzkörper"
    }

    private func computeTopExercises(limit: Int) -> [TopExercise] {
        var volumes = [String: Double]()
        for set in allCompletedSets {
            guard let ex = set.exercise, ex.trackingType == .repsWeight else { continue }
            volumes[ex.name, default: 0] += set.volumeValue
        }
        return volumes.sorted { $0.value > $1.value }.prefix(limit).enumerated().map { (i, kv) in
            TopExercise(rank: i + 1, name: kv.key, volume: kv.value)
        }
    }

    private func computeEstimated1RM(limit: Int) -> [E1RM] {
        var bestPerExercise: [String: (weight: Double, reps: Int, e1rm: Double)] = [:]

        for set in allCompletedSets {
            guard let ex = set.exercise,
                  ex.trackingType == .repsWeight,
                  let w = set.weight, w > 0,
                  let r = set.reps, r > 0 else { continue }

            let e1rm = w * (1 + Double(r) / 30)
            if e1rm > (bestPerExercise[ex.name]?.e1rm ?? 0) {
                bestPerExercise[ex.name] = (w, r, e1rm)
            }
        }

        return bestPerExercise
            .sorted { $0.value.e1rm > $1.value.e1rm }
            .prefix(limit)
            .map { E1RM(name: $0.key, weight: $0.value.weight, reps: $0.value.reps, e1rm: $0.value.e1rm) }
    }

    private func computeProgressiveOverload() -> [OverloadItem] {
        let weightedSets = allCompletedSets.filter { $0.exercise?.trackingType == .repsWeight }
        let grouped = Dictionary(grouping: weightedSets) { $0.exercise?.name ?? "Unbekannt" }
        var results: [OverloadItem] = []

        for (name, sets) in grouped {
            guard sets.count >= 2 else { continue }
            let sortedSets = sets.sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
            let half = sortedSets.count / 2
            guard half > 0 else { continue }

            let firstHalf = sortedSets.prefix(half).reduce(0.0) { $0 + $1.volumeValue } / Double(half)
            let secondHalf = sortedSets.suffix(half).reduce(0.0) { $0 + $1.volumeValue } / Double(half)

            guard firstHalf > 0 else { continue }
            let pct = ((secondHalf - firstHalf) / firstHalf) * 100

            let trend: OverloadItem.Trend = pct > 2 ? .up : pct < -2 ? .down : .flat
            results.append(OverloadItem(name: name, pctChange: pct, trend: trend))
        }

        return results.sorted { abs($0.pctChange) > abs($1.pctChange) }.map { $0 }
    }

    private struct WeekdayFreq: Identifiable {
        let weekday: Int
        let label: String
        let shortLabel: String
        let count: Int
        var id: Int { weekday }
    }

    private func computeWeekdayFrequency() -> [WeekdayFreq] {
        let cal = Calendar.app
        let labels = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        let fullLabels = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        var counts = [Int: Int]()

        for s in completedSessions {
            let wd = cal.component(.weekday, from: s.startedAt)
            counts[wd, default: 0] += 1
        }

        return (1...7).map { wd in
            WeekdayFreq(
                weekday: wd,
                label: fullLabels[wd - 1],
                shortLabel: labels[wd - 1],
                count: counts[wd] ?? 0
            )
        }
    }

    private func computeStreak() -> Int {
        guard !completedSessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var streak = 0
        var checkDate = today

        let trainingDays = Set(completedSessions.map { cal.startOfDay(for: $0.startedAt) })

        while trainingDays.contains(checkDate) {
            streak += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }

        if streak == 0 {
            checkDate = cal.date(byAdding: .day, value: -1, to: today)!
            while trainingDays.contains(checkDate) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            }
        }

        return streak
    }

    private func computeAvgPerWeek() -> Int {
        guard !completedSessions.isEmpty else { return 0 }
        let cal = Calendar.current
        guard let first = completedSessions.last?.startedAt else { return 0 }
        let weeks = max(1, (cal.dateComponents([.weekOfYear], from: first, to: .now).weekOfYear ?? 1))
        return Int(round(Double(completedSessions.count) / Double(weeks)))
    }

    private func computeConsistency() -> Double {
        let active = computeActiveWeeks()
        let total = computeTotalWeeks()
        guard total > 0 else { return 0 }
        return min(1.0, Double(active) / Double(total))
    }

    private func computeActiveWeeks() -> Int {
        let cal = Calendar.current
        var weeks = Set<String>()
        for s in completedSessions {
            let week = cal.component(.weekOfYear, from: s.startedAt)
            let year = cal.component(.yearForWeekOfYear, from: s.startedAt)
            weeks.insert("\(year)-\(week)")
        }
        return weeks.count
    }

    private func computeTotalWeeks() -> Int {
        guard let oldest = completedSessions.last?.startedAt else { return 0 }
        let cal = Calendar.current
        let components = cal.dateComponents([.weekOfYear], from: cal.startOfDay(for: oldest), to: cal.startOfDay(for: .now))
        let weeks = (components.weekOfYear ?? 0) + 1
        return max(weeks, computeActiveWeeks())
    }

    fileprivate static func formatVolumeStatic(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000 { return String(format: "%.1ft", v / 1000) }
        return String(format: "%.0f", v)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000 { return String(format: "%.1ft", v / 1000) }
        return String(format: "%.0f", v)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        return "\(minutes)m"
    }

    private func formatReps(_ reps: Int) -> String {
        if reps >= 1_000_000 { return String(format: "%.1fM", Double(reps) / 1_000_000) }
        if reps >= 1_000 { return String(format: "%.1fk", Double(reps) / 1_000) }
        return "\(reps)"
    }
}

// MARK: - Data Types

fileprivate struct TopExercise: Identifiable {
    let rank: Int
    let name: String
    let volume: Double
    var id: String { name }
}

fileprivate struct E1RM: Identifiable {
    let name: String
    let weight: Double
    let reps: Int
    let e1rm: Double
    var id: String { name }
}

fileprivate struct OverloadItem: Identifiable {
    let name: String
    let pctChange: Double
    let trend: Trend
    var id: String { name }
    enum Trend { case up, down, flat }
}

// MARK: - Reusable Components

private struct InsightCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text(title)) {
                    Image(systemName: icon)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Color.accentColor)
                }
                content()
            }
            // Verhindert, dass breite Charts (intrinsische Mindestbreite)
            // die Karten- und damit Screen-Breite überschreiten und ein
            // ungewolltes horizontales Scrollen auslösen.
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}

// MARK: - All Top Exercises List

private struct AllTopExercisesList: View {
    let title: String
    let items: [TopExercise]

    init(title: String, items: [TopExercise]) {
        self.title = title
        self.items = items
    }

    init(title: String, provider: () -> [TopExercise]) {
        self.title = title
        self.items = provider()
    }

    var body: some View {
        LazyVStack(spacing: Theme.Spacing.s) {
            if items.isEmpty {
                Text("Keine Daten vorhanden.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.name) { item in
                    HStack(spacing: Theme.Spacing.m) {
                        Text("#\(item.rank)")
                            .font(Theme.Typography.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 28)
                        Text(item.name)
                            .font(Theme.Typography.body)
                            .lineLimit(1)
                        Spacer()
                        Text(SportInsightsView.formatVolumeStatic(item.volume))
                            .font(Theme.Typography.mono)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Theme.Spacing.m)
                    .cardStyle()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xl)
    }
}

private struct QuickStatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        BentoCard(style: .elevated, padding: .md) {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: icon)
                    .font(Theme.Typography.body)
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, value: value)
                Text(value)
                    .font(Theme.Typography.headline.monospacedDigit())
                    .contentTransition(.numericText())
                BentoText(verbatim: label, style: .caption, color: .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - All 1RM List

private struct AllExercisesList: View {
    let title: String
    let items: [E1RM]

    init(title: String, items: [E1RM]) {
        self.title = title
        self.items = items
    }

    init(title: String, provider: () -> [E1RM]) {
        self.title = title
        self.items = provider()
    }

    var body: some View {
        LazyVStack(spacing: Theme.Spacing.s) {
            if items.isEmpty {
                Text("Noch keine Sätze mit Gewicht erfasst.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(Theme.Typography.body)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.e1rm.clean) kg")
                            .font(Theme.Typography.mono)
                            .foregroundStyle(.primary)
                        Text("(\(item.weight.clean) × \(item.reps))")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Theme.Spacing.m)
                    .cardStyle()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xl)
    }
}

// MARK: - All Overload List

private struct AllOverloadList: View {
    let title: String
    let items: [OverloadItem]

    init(title: String, items: [OverloadItem]) {
        self.title = title
        self.items = items
    }

    init(title: String, provider: () -> [OverloadItem]) {
        self.title = title
        self.items = provider()
    }

    var body: some View {
        LazyVStack(spacing: Theme.Spacing.s) {
            if items.isEmpty {
                Text("Noch nicht genug Daten für einen Vergleich.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.name) { item in
                    HStack(spacing: Theme.Spacing.m) {
                        Text(item.name)
                            .font(Theme.Typography.body)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(item.trend == .up ? "↑" : item.trend == .down ? "↓" : "→")
                                .foregroundStyle(item.trend == .up ? .green : item.trend == .down ? .red : .secondary)
                            Text("\(item.pctChange >= 0 ? "+" : "")\(Int(item.pctChange))%")
                                .font(Theme.Typography.mono)
                                .foregroundStyle(item.trend == .up ? .green : item.trend == .down ? .red : .secondary)
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .cardStyle()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xl)
    }
}
