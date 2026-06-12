//
//  BodyProgressView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI
import Charts
import LocalAuthentication

enum ChartMetric: String, CaseIterable {
    case weight = "Gewicht"
    case bodyFat = "KFA"
    case waist = "Taille"
    case chest = "Brust"
    case hip = "Hüfte"
    case shoulder = "Schultern"

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .bodyFat: return "chart.pie.fill"
        case .waist: return "ruler"
        case .chest: return "figure.strengthtraining.traditional"
        case .hip: return "figure.stand"
        case .shoulder: return "arrow.up.and.down.text.horizontal"
        }
    }

    var tint: Color {
        switch self {
        case .weight: return .blue
        case .bodyFat: return .orange
        case .waist: return .purple
        case .chest: return .green
        case .hip: return .teal
        case .shoulder: return .indigo
        }
    }

    var unit: String { self == .weight ? "" : "cm" }

    func value(for entry: BodyProgressEntry) -> Double? {
        switch self {
        case .weight: return entry.weightKg
        case .bodyFat: return entry.bodyFatPercentage
        case .waist: return entry.waistCm
        case .chest: return entry.chestCm
        case .hip: return entry.hipCm
        case .shoulder: return entry.shoulderCm
        }
    }

    func displayValue(for entry: BodyProgressEntry) -> String? {
        guard let v = value(for: entry) else { return nil }
        switch self {
        case .weight: return String(format: "%.1f %@", v, entry.weightUnitRaw)
        case .bodyFat: return String(format: "%.1f%%", v)
        default: return String(format: "%.1f cm", v)
        }
    }

    static func availableMetrics(for entry: BodyProgressEntry) -> [ChartMetric] {
        ChartMetric.allCases.filter { $0.value(for: entry) != nil }
    }
}

struct BodyProgressView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var authenticated = false
    @State private var entries: [BodyProgressEntry] = []
    @State private var showingAddSheet = false
    @State private var selectedEntry: BodyProgressEntry?
    @State private var editingEntry: BodyProgressEntry?
    @State private var showingGallery = false
    @State private var chartMetric: ChartMetric = .weight
    @State private var errors = ErrorState()

    var body: some View {
        Group {
            if authenticated {
                content
            } else {
                UnauthenticatedView(onLogin: authenticate)
            }
        }
        .onAppear(perform: authenticate)
    }

    private var content: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        summaryCard
                        if entriesForChart.count >= 2 { chartCard }
                        if entries.contains(where: { !$0.photoPaths.isEmpty }) {
                            galleryButton
                        }
                        timelineList
                    }
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Körper")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Theme.Spacing.s) {
                        if entries.contains(where: { !$0.photoPaths.isEmpty }) {
                            Button { showingGallery = true } label: {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3)
                            }
                        }
                        Button { showingAddSheet = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BodyProgressEntryEditor(env: env, existingEntry: nil) {
                    loadEntries()
                    showingAddSheet = false
                }
            }
            .sheet(item: $editingEntry) { entry in
                BodyProgressEntryEditor(env: env, existingEntry: entry) {
                    loadEntries()
                    editingEntry = nil
                }
            }
            .fullScreenCover(item: $selectedEntry) { entry in
                BodyProgressDetailView(entry: entry, env: env) {
                    loadEntries()
                } onEdit: {
                    editingEntry = entry
                    selectedEntry = nil
                } onDelete: {
                    env.bodyProgressService.deleteEntry(entry)
                    Haptics.selection()
                    selectedEntry = nil
                    loadEntries()
                }
            }
            .fullScreenCover(isPresented: $showingGallery) {
                BodyProgressGalleryView(entries: entries.reversed())
            }
            .errorAlert(errors)
        }
        .task { loadEntries() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer().frame(height: Theme.Spacing.xxl)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Noch keine Einträge")
                .font(.title3.weight(.semibold))
            Text("Erstelle deinen ersten Eintrag, um deinen Fortschritt zu verfolgen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showingAddSheet = true } label: {
                Label("Ersten Eintrag erstellen", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, Theme.Spacing.s)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let latest = entries.first!

        return VStack(spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(latest.date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Aktueller Stand")
                        .font(.headline)
                }
                Spacer()
                if entries.count >= 2, let first = entries.last {
                    if let current = chartMetric.value(for: latest), let previous = chartMetric.value(for: first) {
                        let diff = current - previous
                        Text(diff >= 0 ? "+\(String(format: "%.1f", diff))" : String(format: "%.1f", diff))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(diff <= 0 ? .green : .red)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.s) {
                if let dv = ChartMetric.weight.displayValue(for: latest) {
                    metricTile(metric: .weight, value: dv, isSelected: chartMetric == .weight)
                }
                if let dv = ChartMetric.bodyFat.displayValue(for: latest) {
                    metricTile(metric: .bodyFat, value: dv, isSelected: chartMetric == .bodyFat)
                }
                if let dv = ChartMetric.waist.displayValue(for: latest) {
                    metricTile(metric: .waist, value: dv, isSelected: chartMetric == .waist)
                }
                if let dv = ChartMetric.chest.displayValue(for: latest) {
                    metricTile(metric: .chest, value: dv, isSelected: chartMetric == .chest)
                }
                if let dv = ChartMetric.hip.displayValue(for: latest) {
                    metricTile(metric: .hip, value: dv, isSelected: chartMetric == .hip)
                }
                if let dv = ChartMetric.shoulder.displayValue(for: latest) {
                    metricTile(metric: .shoulder, value: dv, isSelected: chartMetric == .shoulder)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func metricTile(metric: ChartMetric, value: String, isSelected: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                chartMetric = metric
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: metric.icon)
                    .font(.callout)
                    .foregroundStyle(metric.tint)
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                Text(metric.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(isSelected ? metric.tint.opacity(0.18) : metric.tint.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(isSelected ? metric.tint : .clear, lineWidth: isSelected ? 2 : 0))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chart

    private var entriesForChart: [(date: Date, value: Double)] {
        entries.compactMap { entry in
            guard let v = chartMetric.value(for: entry) else { return nil }
            return (entry.date, v)
        }.reversed()
    }

    private var chartCard: some View {
        let data = entriesForChart
        let titleSuffix = chartMetric == .weight ? "verlauf" : "verlauf"

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("\(chartMetric.rawValue)\(titleSuffix)")
                .font(.headline)
                .padding(.horizontal, Theme.Spacing.l)

            if data.count >= 2 {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        AreaMark(x: .value("Datum", point.date), y: .value(chartMetric.rawValue, point.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [chartMetric.tint.opacity(0.3), chartMetric.tint.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Datum", point.date), y: .value(chartMetric.rawValue, point.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(chartMetric.tint)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) { AxisGridLine().foregroundStyle(.secondary.opacity(0.15)); AxisValueLabel() } }
                .chartXAxis { AxisMarks(values: .stride(by: data.count > 60 ? .month : data.count > 14 ? .weekOfYear : .day)) { AxisGridLine().foregroundStyle(.secondary.opacity(0.1)); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                .frame(height: 160)
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
        .padding(.vertical, Theme.Spacing.m)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Gallery Button

    private var galleryButton: some View {
        Button { showingGallery = true } label: {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fotogalerie")
                        .font(.subheadline.weight(.semibold))
                    Text("Alle Fortschrittsfotos chronologisch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.Spacing.l)
            .cardStyle()
            .padding(.horizontal, Theme.Spacing.l)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Verlauf")
                .font(.headline)
                .padding(.horizontal, Theme.Spacing.l)

            ForEach(entries) { entry in
                Button { selectedEntry = entry } label: {
                    entryRow(entry)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func entryRow(_ entry: BodyProgressEntry) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            VStack(spacing: 2) {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.title3.bold().monospacedDigit())
                Text(entry.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: 2, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.s) {
                    if let w = entry.weightKg {
                        Text(String(format: "%.1f %@", w, entry.weightUnitRaw))
                            .font(.subheadline.weight(.semibold))
                    }
                    if let bf = entry.bodyFatPercentage {
                        Text(String(format: "%.1f%%", bf))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    if let waist = entry.waistCm {
                        let u = entry.measurementUnitRaw == "in" ? "in" : "cm"
                        Text(String(format: "%.0f %@", waist, u))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: Theme.Spacing.xs) {
                    if !entry.photoPaths.isEmpty {
                        Image(systemName: "photo.fill").font(.caption2).foregroundStyle(.blue)
                    }
                    if !entry.notes.isEmpty {
                        Image(systemName: "note.text").font(.caption2).foregroundStyle(.secondary)
                    }
                    if entry.onPump {
                        Text("Pump").font(.caption2).fontWeight(.bold).foregroundStyle(.red)
                    }
                    if let e = entry.energyLevel {
                        Text(String(repeating: "⚡️", count: e)).font(.caption2)
                    }
                }
            }

            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Auth

    func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometricsOrCompanion, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometricsOrCompanion, localizedReason: "Entsperre, um auf deine Körperdaten zuzugreifen.") { success, _ in
                if success { DispatchQueue.main.async { authenticated = true } }
            }
        } else {
            authenticated = true
        }
    }

    private func loadEntries() {
        entries = env.bodyProgressService.fetchEntries()
    }
}
