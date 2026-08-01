//
//  WellnessView.swift
//  ThriveWood
//

import SwiftUI

struct WellnessView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme

    @State private var entries: [WellnessEntry] = []
    @State private var todayEntry: WellnessEntry?
    @State private var summary: WellnessService.WellnessSummary?
    @State private var insights: [WellnessService.CorrelationInsight] = []
    @State private var showingEditor = false
    @State private var selectedRange = 0

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("Tägliche Check-Ins"),
                title: Text("Wellness")
            ) {
                BentoIconButton(
                    systemImage: "plus.circle.fill",
                    accessibilityLabel: Text("Neuer Check-In"),
                    variant: .primary,
                    size: .medium
                ) {
                    showingEditor = true
                }
            }

            if let today = todayEntry {
                todayHero(today)
                todayMetrics(today)
            } else {
                checkInPrompt
            }

            if let summary, summary.entryCount > 0 {
                summarySection(summary)
            }

            if !insights.isEmpty {
                insightsSection
            }

            recentEntriesSection

            Spacer(minLength: theme.spacing.xxl)
        }
        .bentoSheet(
            isPresented: $showingEditor,
            title: Text(todayEntry != nil ? "Check-in bearbeiten" : "Täglicher Check-in"),
            subtitle: Text("Wie fühlst du dich?"),
            detents: [.large]
        ) {
            WellnessCheckInSheetContent(existingEntry: todayEntry) { entry in
                try? env.wellnessService.save(entry)
                load()
            }
        }
        .task { load() }
        .refreshable { load() }
    }

    var oldBody: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let today = todayEntry {
                    todayCard(today)
                } else {
                    checkInButton
                }

                if let summary, summary.entryCount > 0 {
                    summaryCard(summary)
                }

                if !insights.isEmpty {
                    insightsSection
                }

                recentEntriesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Wellness")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEditor = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            WellnessCheckInSheet(existingEntry: todayEntry) { entry in
                try? env.wellnessService.save(entry)
                load()
            }
        }
        .task { load() }
        .refreshable { load() }
    }

    private func load() {
        entries = (try? env.wellnessService.fetchAll()) ?? []
        todayEntry = try? env.wellnessService.entryForDay(.now)
        let days = selectedRange == 0 ? 7 : (selectedRange == 1 ? 30 : 90)
        summary = try? env.wellnessService.summary(forDays: days)
        insights = (try? env.wellnessService.correlations()) ?? []
    }

    private func deleteEntry(_ entry: WellnessEntry) {
        try? env.wellnessService.delete(entry)
        Haptics.impact(.medium)
        load()
    }

    // MARK: - Check-In Prompt

    private var checkInPrompt: some View {
        BentoHeroCard(
            eyebrow: Text("CHECK-IN"),
            title: Text("Wie fühlst du dich?"),
            message: Text("Nimm dir einen Moment Zeit für dein tägliches Wellness-Check-In."),
            tone: .yellow
        ) {
            Image(systemName: "face.smiling")
                .font(.system(size: 56))
                .foregroundStyle(theme.colors.onTile)
                .symbolEffect(.bounce, value: true)
        } actions: {
            BentoButton(
                Text("Jetzt check-in"),
                systemImage: "plus.circle.fill",
                variant: .primary,
                expands: true
            ) {
                showingEditor = true
            }
        }
    }

    private var checkInButton: some View {
        Button { showingEditor = true } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.yellow.opacity(0.12)).frame(width: 56, height: 56)
                    Image(systemName: "face.smiling")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
                Text("Wie fühlst du dich heute?")
                    .font(.headline)
                Text("Täglicher Check-in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Today Hero

    private func todayHero(_ entry: WellnessEntry) -> some View {
        BentoCard(
            background: nil,
            foreground: nil,
            style: .elevated,
            padding: .lg,
            radius: .extraLarge
        ) {
            HStack(spacing: theme.spacing.lg) {
                BentoGauge(
                    value: entry.wellnessScore,
                    in: 0...5,
                    title: Text("Score"),
                    valueLabel: Text(String(format: "%.1f", entry.wellnessScore)),
                    tone: .accent,
                    size: 110
                )

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(entry.moodEmoji)
                        .font(.system(size: 36))
                    BentoText("Heute", style: .caption)
                    BentoText(
                        Text(String(format: "%.1f / 5.0", entry.wellnessScore)),
                        style: .title3
                    )
                }

                Spacer(minLength: 0)

                BentoIconButton(
                    systemImage: "pencil",
                    accessibilityLabel: Text("Bearbeiten"),
                    variant: .secondary,
                    size: .small
                ) {
                    showingEditor = true
                }
            }
        }
    }

    // MARK: - Today Metrics

    private func todayMetrics(_ entry: WellnessEntry) -> some View {
        BentoAdaptiveGrid(minimumItemWidth: 150) {
            ForEach(WellnessMetric.allCases) { metric in
                let value = metricValue(metric, from: entry)
                BentoMetricTile(
                    title: Text(metric.label),
                    value: Text("\(value)"),
                    unit: Text("/ 5"),
                    systemImage: metric.icon,
                    tone: metric.bentoTone
                )
            }
        }
    }

    // MARK: - Summary

    private func summarySection(_ summary: WellnessService.WellnessSummary) -> some View {
        BentoSection(
            title: Text("Übersicht"),
            subtitle: Text("\(summary.entryCount) Einträge")
        ) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoSegmentedPicker(options: [0, 1, 2], selection: $selectedRange) { range in
                        Text(range == 0 ? "7 Tage" : (range == 1 ? "30 Tage" : "90 Tage"))
                    }
                    .onChange(of: selectedRange) { _, _ in load() }

                    BentoBarChart(
                        data: WellnessMetric.allCases.map { metric in
                            BentoBarDatum(
                                id: metric.rawValue,
                                label: metric.label,
                                value: avgValue(for: metric, in: summary)
                            )
                        },
                        tone: .accent,
                        height: 140
                    )

                    HStack(spacing: theme.spacing.xs) {
                        ForEach(WellnessMetric.allCases) { metric in
                            let avg = avgValue(for: metric, in: summary)
                            BentoBadge(
                                Text(String(format: "%.1f", avg)),
                                tone: metric.bentoTone,
                                systemImage: metric.icon
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        BentoSection(title: Text("Erkenntnisse")) {
            VStack(spacing: theme.spacing.xs) {
                ForEach(insights) { insight in
                    let kind = calloutKind(from: insight.color)
                    BentoCallout(
                        kind: kind,
                        title: Text(insight.title),
                        message: Text(insight.detail)
                    )
                }
            }
        }
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        BentoSection(
            title: Text("Letzte Einträge"),
            subtitle: nil
        ) {
            if entries.isEmpty {
                BentoEmptyState(
                    systemImage: "calendar.badge.exclamationmark",
                    title: Text("Noch keine Einträge"),
                    message: Text("Starte mit deinem ersten Check-In.")
                )
            } else {
                VStack(spacing: theme.spacing.xs) {
                    ForEach(Array(entries.prefix(10))) { entry in
                        recentEntryCard(entry)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func recentEntryCard(_ entry: WellnessEntry) -> some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                Text(entry.moodEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    BentoText(
                        "\(entry.date.formatted(.dateTime.day().month().year()))",
                        style: .headline
                    )
                    HStack(spacing: theme.spacing.xs) {
                        ForEach(WellnessMetric.allCases) { metric in
                            let value = metricValue(metric, from: entry)
                            HStack(spacing: 2) {
                                Text(metric.emoji(for: value))
                                    .font(.caption2)
                                Text("\(value)")
                                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                                    .foregroundStyle(metric.color)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                    Text(String(format: "%.1f", entry.wellnessScore))
                        .font(.system(size: 18, weight: .heavy).monospacedDigit())
                        .foregroundStyle(theme.colors.accent)
                    BentoIconButton(
                        systemImage: "trash",
                        accessibilityLabel: Text("Löschen"),
                        variant: .ghost,
                        size: .small
                    ) {
                        withAnimation(theme.motion.snappy) { deleteEntry(entry) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func metricValue(_ metric: WellnessMetric, from entry: WellnessEntry) -> Int {
        switch metric {
        case .mood: entry.mood
        case .energy: entry.energy
        case .sleep: entry.sleepQuality
        case .stress: entry.stress
        }
    }

    private func avgValue(for metric: WellnessMetric, in summary: WellnessService.WellnessSummary) -> Double {
        switch metric {
        case .mood: summary.avgMood
        case .energy: summary.avgEnergy
        case .sleep: summary.avgSleep
        case .stress: summary.avgStress
        }
    }

    private func calloutKind(from color: String) -> BentoCalloutKind {
        switch color {
        case "yellow": .warning
        case "orange": .warning
        case "red": .error
        case "green": .success
        default: .info
        }
    }

    // MARK: - Old Helpers (kept for oldBody)

    private func todayCard(_ entry: WellnessEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(entry.moodEmoji)
                    .font(.system(size: 48))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heute")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "Wellness-Score: %.1f", entry.wellnessScore))
                        .font(.title2.bold())
                }
                Spacer()
                Button { showingEditor = true } label: {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                metricBadge(metric: .mood, value: entry.mood)
                metricBadge(metric: .energy, value: entry.energy)
                metricBadge(metric: .sleep, value: entry.sleepQuality)
                metricBadge(metric: .stress, value: entry.stress)
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func metricBadge(metric: WellnessMetric, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(metric.emoji(for: value))
                .font(.title3)
            Text(metric.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text("\(value)/5")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(metric.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(metric.color.opacity(0.08))
        )
    }

    private func summaryCard(_ summary: WellnessService.WellnessSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Übersicht")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedRange) {
                    Text("7T").tag(0)
                    Text("30T").tag(1)
                    Text("90T").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: selectedRange) { _, _ in load() }
            }

            HStack {
                ForEach(WellnessMetric.allCases) { metric in
                    avgMetricBar(metric: metric, value: avgValue(for: metric, in: summary))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func avgMetricBar(metric: WellnessMetric, value: Double) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(metric.color.opacity(0.15))
                    .frame(height: 80)
                RoundedRectangle(cornerRadius: 6)
                    .fill(metric.color)
                    .frame(height: max(4, CGFloat(value / 5.0) * 80))
            }
            Text(metric.emoji(for: Int(value.rounded())))
                .font(.caption)
            Text(String(format: "%.1f", value))
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(metric.color)
            Text(metric.label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func colorFromString(_ name: String) -> Color {
        switch name {
        case "yellow": .yellow
        case "orange": .orange
        case "indigo": .indigo
        case "red": .red
        case "green": .green
        case "blue": .blue
        case "purple": .purple
        default: .accentColor
        }
    }
}

// MARK: - WellnessMetric Extension

extension WellnessMetric {
    var bentoTone: BentoTone {
        switch self {
        case .mood: .yellow
        case .energy: .warning
        case .sleep: .blue
        case .stress: .danger
        }
    }
}

// MARK: - Check-In Sheet Content (for bentoSheet)

struct WellnessCheckInSheetContent: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let existingEntry: WellnessEntry?
    let onSave: (WellnessEntry) -> Void

    @State private var mood: Int = 3
    @State private var energy: Int = 3
    @State private var sleepQuality: Int = 3
    @State private var stress: Int = 3
    @State private var note: String = ""

    private var entry: WellnessEntry {
        let e = existingEntry ?? WellnessEntry(date: .now)
        e.mood = mood
        e.energy = energy
        e.sleepQuality = sleepQuality
        e.stress = stress
        e.note = note
        return e
    }

    private var score: Double {
        let s = Double(mood) + Double(energy) + Double(sleepQuality) + Double(6 - stress)
        return s / 4.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                scoreHero

                BentoSentencePromptCard(
                    eyebrow: Text("CHECK-IN"),
                    prompt: Text("Wie war dein Tag?"),
                    tone: .blue
                ) {
                    BentoSentenceForm(
                        textStyle: .title3,
                        horizontalAlignment: .leading
                    ) {
                        "Ich fühle mich"
                        BentoSentenceGap(
                            id: "mood",
                            tone: .yellow,
                            status: .filled,
                            accessibilityLabel: Text("Stimmung"),
                            action: { cycleValue(&mood) },
                            label: {
                                HStack(spacing: 6) {
                                    Text(WellnessMetric.mood.emoji(for: mood))
                                    Text(verbatim: "\(mood)/5")
                                }
                            }
                        )

                        "mit"

                        BentoSentenceGap(
                            id: "energy",
                            tone: .warning,
                            status: .filled,
                            accessibilityLabel: Text("Energie"),
                            action: { cycleValue(&energy) },
                            label: {
                                HStack(spacing: 6) {
                                    Text(WellnessMetric.energy.emoji(for: energy))
                                    Text(verbatim: "\(energy)/5")
                                }
                            }
                        )

                        "Energie,"

                        BentoSentenceLineBreak()

                        "mein Schlaf war"

                        BentoSentenceGap(
                            id: "sleep",
                            tone: .blue,
                            status: .filled,
                            accessibilityLabel: Text("Schlafqualität"),
                            action: { cycleValue(&sleepQuality) },
                            label: {
                                HStack(spacing: 6) {
                                    Text(WellnessMetric.sleep.emoji(for: sleepQuality))
                                    Text(verbatim: "\(sleepQuality)/5")
                                }
                            }
                        )

                        BentoSentencePunctuation(",")

                        "und ich bin"

                        BentoSentenceGap(
                            id: "stress",
                            tone: .danger,
                            status: .filled,
                            accessibilityLabel: Text("Stresslevel"),
                            action: { cycleValue(&stress) },
                            label: {
                                HStack(spacing: 6) {
                                    Text(WellnessMetric.stress.emoji(for: stress))
                                    Text(verbatim: "\(stress)/5")
                                }
                            }
                        )

                        "gestresst."

                        BentoSentenceLineBreak()

                        "Notiz:"

                        BentoSentenceInlineTextGap(
                            id: "note",
                            text: $note,
                            placeholder: " optional",
                            tone: .info,
                            sizing: .wide,
                            accessibilityLabel: Text("Notiz"),
                            onSubmit: {}
                        )

                        BentoSentencePunctuation(".")
                    }
                }
            }
            .padding(.horizontal, theme.spacing.value(.md))
            .padding(.bottom, theme.spacing.value(.xl))
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark.circle.fill",
                variant: .primary,
                expands: true
            ) {
                onSave(entry)
                Haptics.success()
                dismiss()
            }
            .padding(.horizontal, theme.spacing.value(.md))
            .padding(.vertical, theme.spacing.value(.sm))
            .background(theme.colors.background)
        }
        .onAppear {
            if let e = existingEntry {
                mood = e.mood
                energy = e.energy
                sleepQuality = e.sleepQuality
                stress = e.stress
                note = e.note
            }
        }
    }

    // MARK: - Score Hero

    private var scoreHero: some View {
        BentoCard(
            style: .elevated,
            padding: .lg,
            radius: .extraLarge
        ) {
            HStack(spacing: theme.spacing.lg) {
                Text(WellnessMetric.mood.emoji(for: mood))
                    .font(.system(size: 52))
                    .animation(.snappy, value: mood)

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    BentoText("Live-Score", style: .caption)
                    HStack(alignment: .lastTextBaseline, spacing: theme.spacing.xxs) {
                        Text(String(format: "%.1f", score))
                            .bentoTextStyle(.metric)
                        Text("/ 5.0")
                            .bentoTextStyle(.callout, color: theme.colors.onSurfaceMuted)
                    }
                }
                Spacer(minLength: 0)

                BentoProgressRing(
                    progress: score / 5.0,
                    tone: .accent,
                    size: 64,
                    lineWidth: 8
                )
            }
        }
    }

    // MARK: - Cycle Value

    private func cycleValue(_ value: inout Int) {
        withAnimation(theme.motion.snappy) {
            value = value >= 5 ? 1 : value + 1
        }
        Haptics.selection()
    }
}

// MARK: - Legacy Sheet wrapper (kept for oldBody compatibility)

struct WellnessCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existingEntry: WellnessEntry?
    let onSave: (WellnessEntry) -> Void

    @State private var mood: Int = 3
    @State private var energy: Int = 3
    @State private var sleepQuality: Int = 3
    @State private var stress: Int = 3
    @State private var note: String = ""

    private var entry: WellnessEntry {
        let e = existingEntry ?? WellnessEntry(date: .now)
        e.mood = mood
        e.energy = energy
        e.sleepQuality = sleepQuality
        e.stress = stress
        e.note = note
        return e
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(WellnessMetric.mood.emoji(for: mood))
                        .font(.system(size: 64))
                        .animation(.snappy, value: mood)

                    metricSlider(.mood, value: $mood)
                    metricSlider(.energy, value: $energy)
                    metricSlider(.sleep, value: $sleepQuality)
                    metricSlider(.stress, value: $stress)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notiz", systemImage: "note.text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("Wie war dein Tag?", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(existingEntry != nil ? "Check-in bearbeiten" : "Täglicher Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(entry)
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let e = existingEntry {
                    mood = e.mood
                    energy = e.energy
                    sleepQuality = e.sleepQuality
                    stress = e.stress
                    note = e.note
                }
            }
        }
    }

    private func metricSlider(_ metric: WellnessMetric, value: Binding<Int>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundStyle(metric.color)
                Text(metric.label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(metric.emoji(for: value.wrappedValue))
                    .font(.title3)
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        withAnimation(.snappy) { value.wrappedValue = i }
                        Haptics.selection()
                    } label: {
                        Circle()
                            .fill(i <= value.wrappedValue ? metric.color : Color(.tertiarySystemFill))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("\(i)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(i <= value.wrappedValue ? .white : .secondary)
                            )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
