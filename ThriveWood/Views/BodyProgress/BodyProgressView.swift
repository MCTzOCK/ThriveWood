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
    case neck = "Nacken"
    case shoulders = "Schultern"
    case chest = "Brust"
    case biceps = "Oberarm"
    case forearms = "Unterarm"
    case waist = "Taille"
    case hip = "Hüfte"
    case thighs = "Oberschenkel"
    case calves = "Wade"

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .bodyFat: return "chart.pie.fill"
        case .neck: return "person.bust"
        case .shoulders: return "arrow.up.and.down.text.horizontal"
        case .chest: return "figure.strengthtraining.traditional"
        case .biceps: return "figure.arm"
        case .forearms: return "hand.raised"
        case .waist: return "ruler"
        case .hip: return "figure.stand"
        case .thighs: return "figure.walk"
        case .calves: return "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .weight: return .blue
        case .bodyFat: return .orange
        case .neck: return .mint
        case .shoulders: return .indigo
        case .chest: return .green
        case .biceps: return .orange
        case .forearms: return .teal
        case .waist: return .purple
        case .hip: return .pink
        case .thighs: return .blue
        case .calves: return .cyan
        }
    }

    var unit: String { self == .weight ? "" : "cm" }

    func value(for entry: BodyProgressEntry) -> Double? {
        switch self {
        case .weight: return entry.weightKg
        case .bodyFat: return entry.bodyFatPercentage
        case .neck: return entry.neckCm
        case .shoulders: return entry.shoulderCm
        case .chest: return entry.chestCm
        case .biceps: return entry.leftBicepCm ?? entry.rightBicepCm
        case .forearms: return entry.leftForearmCm ?? entry.rightForearmCm
        case .waist: return entry.waistCm
        case .hip: return entry.hipCm
        case .thighs: return entry.leftThighCm ?? entry.rightThighCm
        case .calves: return entry.leftCalfCm ?? entry.rightCalfCm
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
    @State private var selectedZone: MeasurementZone?
    @State private var showFront: Bool = true
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
                        bodyMapCard
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
        .onChange(of: selectedZone) { _, newZone in
            if let zone = newZone {
                withAnimation(.easeInOut(duration: 0.25)) {
                    chartMetric = zone.chartMetric
                }
            }
        }
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

    // MARK: - Body Map Card

    private var bodyMapCard: some View {
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
                if let w = latest.weightKg {
                    Text(String(format: "%.1f %@", w, latest.weightUnitRaw == "kg" ? "kg" : "lbs"))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.blue)
                }
                if let bf = latest.bodyFatPercentage {
                    Text(String(format: "%.1f%%", bf))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }
            }

            BodyMeasurementMapView(entry: latest, selectedZone: $selectedZone, showFront: $showFront)

            if let zone = selectedZone {
                zoneDetailRow(for: zone, entry: latest)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func zoneDetailRow(for zone: MeasurementZone, entry: BodyProgressEntry) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: zoneIcon(for: zone))
                .font(.callout)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(zone.label)
                    .font(.subheadline.weight(.semibold))
                if let val = zoneValueText(for: zone, entry: entry) {
                    Text(val)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func zoneIcon(for zone: MeasurementZone) -> String {
        switch zone {
        case .neck: return "person.bust"
        case .shoulders: return "arrow.up.and.down.text.horizontal"
        case .chest: return "figure.strengthtraining.traditional"
        case .biceps: return "figure.arm"
        case .forearms: return "hand.raised"
        case .waist: return "ruler"
        case .hip: return "figure.stand"
        case .thighs: return "figure.walk"
        case .calves: return "figure.run"
        }
    }

    private func zoneValueText(for zone: MeasurementZone, entry: BodyProgressEntry) -> String? {
        switch zone {
        case .neck:
            if let v = entry.neckCm { return String(format: "%.1f cm", v) }
        case .shoulders:
            if let v = entry.shoulderCm { return String(format: "%.1f cm", v) }
        case .chest:
            if let v = entry.chestCm { return String(format: "%.1f cm", v) }
        case .biceps:
            if let l = entry.leftBicepCm, let r = entry.rightBicepCm { return String(format: "L: %.1f / R: %.1f cm", l, r) }
            if let v = entry.leftBicepCm ?? entry.rightBicepCm { return String(format: "%.1f cm", v) }
        case .forearms:
            if let l = entry.leftForearmCm, let r = entry.rightForearmCm { return String(format: "L: %.1f / R: %.1f cm", l, r) }
            if let v = entry.leftForearmCm ?? entry.rightForearmCm { return String(format: "%.1f cm", v) }
        case .waist:
            if let v = entry.waistCm { return String(format: "%.1f cm", v) }
        case .hip:
            if let v = entry.hipCm { return String(format: "%.1f cm", v) }
        case .thighs:
            if let l = entry.leftThighCm, let r = entry.rightThighCm { return String(format: "L: %.1f / R: %.1f cm", l, r) }
            if let v = entry.leftThighCm ?? entry.rightThighCm { return String(format: "%.1f cm", v) }
        case .calves:
            if let l = entry.leftCalfCm, let r = entry.rightCalfCm { return String(format: "L: %.1f / R: %.1f cm", l, r) }
            if let v = entry.leftCalfCm ?? entry.rightCalfCm { return String(format: "%.1f cm", v) }
        }
        return nil
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
