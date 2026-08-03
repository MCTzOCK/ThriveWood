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

    var tone: BentoTone {
        switch self {
        case .weight: return .blue
        case .bodyFat: return .warning
        case .neck: return .info
        case .shoulders: return .accent
        case .chest: return .green
        case .biceps: return .warning
        case .forearms: return .info
        case .waist: return .pink
        case .hip: return .pink
        case .thighs: return .blue
        case .calves: return .info
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
    @Environment(\.bentoTheme) private var theme
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
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("FORTSCHRITT"),
                title: Text("Körper"),
                subtitle: Text(entries.isEmpty ? "Noch keine Einträge" : "\(entries.count) Einträge")
            ) {
                if entries.contains(where: { !$0.photoPaths.isEmpty }) {
                    BentoIconButton(
                        systemImage: "photo.on.rectangle.angled",
                        accessibilityLabel: Text("Galerie"),
                        variant: .secondary
                    ) {
                        showingGallery = true
                    }
                }
                BentoIconButton(
                    systemImage: "plus",
                    accessibilityLabel: Text("Neuer Eintrag"),
                    variant: .primary
                ) {
                    showingAddSheet = true
                }
            }

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

            Spacer(minLength: theme.spacing.xxl)
        }
        .bentoSheet(
            isPresented: $showingAddSheet,
            title: Text("Neuer Eintrag"),
            detents: [.large]
        ) {
            BodyProgressEntryEditor(env: env, existingEntry: nil) {
                loadEntries()
                showingAddSheet = false
            }
        }
        .bentoSheet(
            isPresented: Binding(
                get: { editingEntry != nil },
                set: { if !$0 { editingEntry = nil } }
            ),
            title: Text("Eintrag bearbeiten"),
            detents: [.large]
        ) {
            if let entry = editingEntry {
                BodyProgressEntryEditor(env: env, existingEntry: entry) {
                    loadEntries()
                    editingEntry = nil
                }
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
        .task { loadEntries() }
        .onChange(of: selectedZone) { _, newZone in
            if let zone = newZone {
                withAnimation(theme.motion.snappy) {
                    chartMetric = zone.chartMetric
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        BentoCard(tone: .accent, style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.colors.onAccent)
                    .symbolEffect(.bounce, value: true)

                VStack(spacing: theme.spacing.xs) {
                    BentoText("Noch keine Einträge", style: .title3, color: theme.colors.onAccent)
                    BentoText(
                        "Erstelle deinen ersten Eintrag, um deinen Fortschritt zu verfolgen.",
                        style: .body,
                        color: theme.colors.onAccent.opacity(0.85)
                    )
                    .multilineTextAlignment(.center)
                }

                BentoButton(
                    Text("Ersten Eintrag erstellen"),
                    systemImage: "plus.circle.fill",
                    variant: .secondary,
                    expands: true
                ) {
                    showingAddSheet = true
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, theme.spacing.xl)
    }

    // MARK: - Body Map Card

    private var bodyMapCard: some View {
        let latest = entries.first!

        return BentoCard(style: .outlined, padding: .lg, radius: .large) {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        BentoText(
                            verbatim: latest.date.formatted(.dateTime.day().month(.abbreviated)),
                            style: .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                        BentoText("Aktueller Stand", style: .headline)
                    }
                    Spacer()
                    if let w = latest.weightKg {
                        BentoBadge(
                            Text(verbatim: String(format: "%.1f %@", w, latest.weightUnitRaw == "kg" ? "kg" : "lbs")),
                            tone: .blue,
                            systemImage: "scalemass.fill"
                        )
                    }
                    if let bf = latest.bodyFatPercentage {
                        BentoBadge(
                            Text(verbatim: String(format: "%.1f%%", bf)),
                            tone: .warning
                        )
                    }
                }

                BodyMeasurementMapView(entry: latest, selectedZone: $selectedZone, showFront: $showFront)

                if let zone = selectedZone {
                    BentoDivider()
                    zoneDetailRow(for: zone, entry: latest)
                }
            }
        }
    }

    private func zoneDetailRow(for zone: MeasurementZone, entry: BodyProgressEntry) -> some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.colors.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: zoneIcon(for: zone))
                    .font(.callout)
                    .foregroundStyle(theme.colors.accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                BentoText(verbatim: zone.label, style: .bodyStrong)
                if let val = zoneValueText(for: zone, entry: entry) {
                    BentoText(verbatim: val, style: .callout, color: theme.colors.onSurfaceMuted)
                }
            }
            Spacer()
        }
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

        return BentoSection(
            title: Text("\(chartMetric.rawValue)verlauf"),
            subtitle: Text("\(data.count) Messungen")
        ) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Metric chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(ChartMetric.allCases, id: \.self) { metric in
                                BentoChip(
                                    Text(verbatim: metric.rawValue),
                                    systemImage: metric.icon,
                                    tone: metric.tone,
                                    isSelected: chartMetric == metric
                                ) {
                                    Haptics.selection()
                                    withAnimation(theme.motion.snappy) {
                                        chartMetric = metric
                                    }
                                }
                            }
                        }
                    }

                    if data.count >= 2 {
                        Chart {
                            ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                                AreaMark(x: .value("Datum", point.date), y: .value(chartMetric.rawValue, point.value))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(
                                        colors: [theme.colors.accent.opacity(0.3), theme.colors.accent.opacity(0.05)],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                LineMark(x: .value("Datum", point.date), y: .value(chartMetric.rawValue, point.value))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(theme.colors.accent)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            }
                        }
                        .chartYAxis { AxisMarks(position: .leading) { AxisGridLine().foregroundStyle(theme.colors.outlineSubtle); AxisValueLabel() } }
                        .chartXAxis { AxisMarks(values: .stride(by: data.count > 60 ? .month : data.count > 14 ? .weekOfYear : .day)) { AxisGridLine().foregroundStyle(theme.colors.outlineSubtle.opacity(0.5)); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                        .frame(height: 180)
                    }
                }
            }
        }
    }

    // MARK: - Gallery Button

    private var galleryButton: some View {
        Button { showingGallery = true } label: {
            BentoCard(style: .outlined, padding: .lg, radius: .large) {
                HStack(spacing: theme.spacing.md) {
                    ZStack {
                        Circle()
                            .fill(theme.colors.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(theme.colors.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        BentoText("Fotogalerie", style: .bodyStrong)
                        BentoText("Alle Fortschrittsfotos chronologisch", style: .caption, color: theme.colors.onSurfaceMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Timeline

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            BentoSectionHeader(title: Text("Verlauf"), subtitle: Text("\(entries.count) Einträge"))

            VStack(spacing: theme.spacing.sm) {
                ForEach(entries) { entry in
                    Button { selectedEntry = entry } label: {
                        entryRow(entry)
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }

    private func entryRow(_ entry: BodyProgressEntry) -> some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                VStack(spacing: 2) {
                    Text(verbatim: entry.date.formatted(.dateTime.day()))
                        .font(Theme.Typography.title3.bold().monospacedDigit())
                    BentoText(
                        verbatim: entry.date.formatted(.dateTime.month(.abbreviated)),
                        style: .caption,
                        color: theme.colors.onSurfaceMuted
                    )
                }
                .frame(width: 44)

                Rectangle()
                    .fill(theme.colors.accent.opacity(0.3))
                    .frame(width: 2, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: theme.spacing.xs) {
                        if let w = entry.weightKg {
                            BentoText(verbatim: String(format: "%.1f %@", w, entry.weightUnitRaw), style: .bodyStrong)
                        }
                        if let bf = entry.bodyFatPercentage {
                            BentoBadge(Text(verbatim: String(format: "%.1f%%", bf)), tone: .warning)
                        }
                        if let waist = entry.waistCm {
                            let u = entry.measurementUnitRaw == "in" ? "in" : "cm"
                            BentoText(verbatim: String(format: "%.0f %@", waist, u), style: .caption, color: theme.colors.onSurfaceMuted)
                        }
                    }
                    HStack(spacing: theme.spacing.xs) {
                        if !entry.photoPaths.isEmpty {
                            Image(systemName: "photo.fill").font(.caption2).foregroundStyle(theme.colors.accent)
                        }
                        if !entry.notes.isEmpty {
                            Image(systemName: "note.text").font(.caption2).foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                        if entry.onPump {
                            BentoBadge(Text("Pump"), tone: .danger)
                        }
                        if let e = entry.energyLevel {
                            BentoBadge(Text(verbatim: String(repeating: "⚡️", count: e)), tone: .warning)
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
        }
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
