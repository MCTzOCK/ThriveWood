//
//  WellnessView.swift
//  ThriveWood
//

import SwiftUI

struct WellnessView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var entries: [WellnessEntry] = []
    @State private var todayEntry: WellnessEntry?
    @State private var summary: WellnessService.WellnessSummary?
    @State private var insights: [WellnessService.CorrelationInsight] = []
    @State private var showingEditor = false
    @State private var selectedRange = 0

    var body: some View {
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

    private func avgValue(for metric: WellnessMetric, in summary: WellnessService.WellnessSummary) -> Double {
        switch metric {
        case .mood: summary.avgMood
        case .energy: summary.avgEnergy
        case .sleep: summary.avgSleep
        case .stress: summary.avgStress
        }
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

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Erkenntnisse")
                    .font(.headline)
            }
            ForEach(insights) { insight in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(colorFromString(insight.color).opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: insight.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(colorFromString(insight.color))
                    }
                    Text(insight.detail)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte Einträge")
                .font(.headline)
            if entries.isEmpty {
                Text("Noch keine Einträge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(Array(entries.prefix(10))) { entry in
                    HStack(spacing: 12) {
                        Text(entry.moodEmoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date, format: .dateTime.day().month().year())
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 8) {
                                Label("\(entry.mood)", systemImage: "face.smiling")
                                Label("\(entry.energy)", systemImage: "bolt.fill")
                                Label("\(entry.sleepQuality)", systemImage: "bed.double.fill")
                                Label("\(entry.stress)", systemImage: "brain.head.profile")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.1f", entry.wellnessScore))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(.tint)
                        Button {
                            deleteEntry(entry)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.6))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
        }
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
