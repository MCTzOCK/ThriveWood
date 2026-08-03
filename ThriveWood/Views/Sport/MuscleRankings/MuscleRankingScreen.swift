//
//  MuscleRankingScreen.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MuscleRankingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme

    @State private var rankings: [MuscleRankingData] = []
    @State private var recoveryData: [MuscleRecoveryData] = []
    @State private var dashboard: MuscleRecoveryService.RecoveryDashboard?
    @State private var showFront = true
    @State private var selectedMuscle: MuscleGroup?
    @State private var overallRank: MuscleRank = .untrained
    @State private var overallProgress: Double = 0
    @State private var overallVolume: Double = 0
    @State private var showLegend = false
    @State private var progressAnimated = false
    @State private var glowPhase: CGFloat = 0
    @State private var shimmerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var flipAngle: Double = 0
    @State private var isFlipped: Bool = false
    @State private var mapMode: MapMode = .ranking
    @AppStorage("includeUntrainedMuscles") private var includeUntrainedMuscles: Bool = true

    enum MapMode: String, CaseIterable, Identifiable {
        case ranking = "ranking"
        case recovery = "recovery"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .ranking: "Ranking"
            case .recovery: "Pause"
            }
        }
        var icon: String {
            switch self {
            case .ranking: "trophy.fill"
            case .recovery: "bed.double.fill"
            }
        }
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: theme.spacing.lg) {
                BentoPageHeader(
                    eyebrow: Text("MUSKELN"),
                    title: Text(mapMode == .ranking ? "Muskel-Ranking" : "Erholung"),
                    subtitle: Text(mapMode == .ranking
                                   ? "Volumen-basierte Ränge pro Muskelgruppe"
                                   : "Wissenschaftliche Pausen-Empfehlung")
                ) {
                    BentoIconButton(
                        systemImage: "info.circle",
                        accessibilityLabel: Text("Legende"),
                        variant: .secondary
                    ) {
                        showLegend = true
                    }
                }

                BentoCard(style: .outlined, padding: .md, radius: .large) {
                    BentoSegmentedPicker(options: MapMode.allCases, selection: $mapMode) { mode in
                        Text(verbatim: mode.label)
                    }
                }
                .onChange(of: mapMode) { _, _ in
                    withAnimation(theme.motion.snappy) {
                        selectedMuscle = nil
                    }
                }

                if mapMode == .ranking {
                    overallRankHeader
                } else {
                    recoveryOverviewHeader
                    if let dashboard {
                        recoveryDashboardCard(dashboard)
                    }
                }

                diagramSection

                if let selected = selectedMuscle {
                    if mapMode == .ranking,
                       let data = rankings.first(where: { $0.muscleGroup == selected }) {
                        SelectedMuscleCard(data: data) {
                            withAnimation(theme.motion.snappy) { selectedMuscle = nil }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if mapMode == .recovery,
                              let rd = recoveryData.first(where: { $0.muscleGroup == selected }) {
                        RecoveryMuscleCard(data: rd) {
                            withAnimation(theme.motion.snappy) { selectedMuscle = nil }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if mapMode == .ranking {
                    muscleListSection
                } else {
                    recoveryListSection
                }

                Spacer(minLength: theme.spacing.xxl)
            }
        }
        .bentoSheet(
            isPresented: $showLegend,
            title: Text("Legende"),
            detents: [.medium, .large]
        ) {
            if mapMode == .ranking {
                RankLegendSheet()
            } else {
                RecoveryLegendSheet()
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: includeUntrainedMuscles) { _, _ in Task { await load() } }
    }

    // MARK: - Overall Rank Header

    private var overallRankHeader: some View {
        BentoCard(style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: theme.spacing.lg) {
                rankCoin

                VStack(spacing: theme.spacing.xs) {
                    BentoText(verbatim: "Gesamt-Rang", style: .callout, color: theme.colors.onSurfaceMuted)
                    Text(overallRank.label)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(overallRank.gradient)
                }

                if overallRank != .legend, let next = MuscleRank(rawValue: overallRank.rawValue + 1) {
                    HStack(spacing: theme.spacing.sm) {
                        BentoBadge(
                            Text("\(Int(overallProgress * 100))%"),
                            tone: .accent
                        )
                        Image(systemName: "arrow.right")
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        BentoBadge(
                            Text(verbatim: next.label),
                            tone: .neutral
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var rankCoin: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(overallRank.primaryColor.opacity(0.15), lineWidth: 20)
                .frame(width: 140, height: 140)
                .blur(radius: 8)
                .scaleEffect(1 + glowPhase * 0.1)

            // Progress ring background
            Circle()
                .stroke(theme.colors.outlineSubtle, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: progressAnimated ? overallProgress : 0)
                .stroke(
                    overallRank.gradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .shadow(color: overallRank.primaryColor, radius: 4)

            // Rotating shimmer arc
            Circle()
                .trim(from: 0, to: 0.15)
                .stroke(
                    .white.opacity(0.6),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(shimmerRotation))
                .mask(
                    Circle()
                        .trim(from: 0, to: progressAnimated ? overallProgress : 0)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                )

            // Inner glow
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(overallRank.primaryColor.opacity(0.3 - Double(i) * 0.08))
                    .frame(width: CGFloat(100 - i * 10), height: CGFloat(100 - i * 10))
                    .blur(radius: CGFloat(15 - i * 3))
                    .scaleEffect(pulseScale)
            }

            // Flippable coin
            coinFaces
                .rotation3DEffect(.degrees(flipAngle), axis: (0, 1, 0))
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        flipAngle = isFlipped ? 0 : 180
                        isFlipped.toggle()
                    }
                    Haptics.impact(.medium)
                }
        }
        .frame(height: 160)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerRotation = 360
            }
        }
    }

    private var coinFaces: some View {
        ZStack {
            // Front (rank icon)
            Circle()
                .fill(overallRank.gradient)
                .frame(width: 90, height: 90)
                .shadow(color: overallRank.primaryColor, radius: 20)
                .shadow(color: overallRank.primaryColor.opacity(0.5), radius: 40)
                .scaleEffect(pulseScale)
                .overlay(
                    Image(systemName: overallRank.icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                )
                .opacity(flipAngle < 90 ? 1 : 0)

            // Back (progress details)
            Circle()
                .fill(overallRank.gradient)
                .frame(width: 90, height: 90)
                .shadow(color: overallRank.primaryColor, radius: 20)
                .overlay(
                    VStack(spacing: 2) {
                        if let next = MuscleRank(rawValue: overallRank.rawValue + 1) {
                            Text(formatVolume(overallVolume))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(verbatim: "/")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(formatVolume(Double(next.minVolume)))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                            Text(verbatim: "kg")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        } else {
                            Text(verbatim: "∞")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                )
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                .opacity(flipAngle >= 90 ? 1 : 0)
        }
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return "\(Int(v))"
    }

    // MARK: - Diagram Section

    private var diagramSection: some View {
        BentoCard(style: .outlined, padding: .lg, radius: .large) {
            VStack(spacing: theme.spacing.md) {
                BentoSectionHeader(
                    title: Text("Anatomie"),
                    subtitle: Text(showFront ? "Vorderseite" : "Rückseite")
                )

                // Front/Back Toggle
                HStack(spacing: 0) {
                    ForEach([true, false], id: \.self) { isFront in
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                showFront = isFront
                                selectedMuscle = nil
                            }
                        } label: {
                            Text(isFront ? "Vorne" : "Hinten")
                                .font(Theme.Typography.subheadline.weight(.medium))
                                .foregroundStyle(showFront == isFront ? .white : theme.colors.onSurfaceMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    showFront == isFront
                                    ? AnyShapeStyle(theme.colors.accent)
                                    : AnyShapeStyle(Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(theme.colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous))

                // Muscle Map (UNTOUCHED)
                AnatomicMuscleMapView(
                    rankings: rankings,
                    recoveryData: mapMode == .recovery ? recoveryData : nil,
                    selectedMuscle: $selectedMuscle,
                    showFront: $showFront
                )

                if selectedMuscle == nil {
                    BentoBadge(
                        Text(mapMode == .ranking ? "Tippe auf einen Muskel" : "Rote Muskeln brauchen Pause"),
                        tone: mapMode == .ranking ? .info : .warning,
                        systemImage: mapMode == .ranking ? "hand.tap.fill" : "exclamationmark.triangle.fill"
                    )
                }
            }
        }
    }

    // MARK: - Muscle List

    private var muscleListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            BentoSectionHeader(
                title: Text("Alle Muskelgruppen"),
                subtitle: Text("\(rankings.filter { $0.muscleGroup.showInList }.count) Gruppen")
            )

            LazyVStack(spacing: theme.spacing.sm) {
                ForEach(rankings.filter { $0.muscleGroup.showInList }.sorted(by: { $0.totalVolume > $1.totalVolume })) { data in
                    MuscleRankRow(data: data, isSelected: selectedMuscle == data.muscleGroup) {
                        withAnimation(.spring(response: 0.35)) {
                            selectedMuscle = data.muscleGroup
                            showFront = data.muscleGroup.bodyPosition.isFront
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recovery Dashboard Card

    private func recoveryDashboardCard(_ dash: MuscleRecoveryService.RecoveryDashboard) -> some View {
        BentoCard(style: .elevated, padding: .lg, radius: .large) {
            VStack(spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.lg) {
                    VStack(spacing: theme.spacing.xs) {
                        ZStack {
                            Circle()
                                .stroke(theme.colors.outlineSubtle, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                            Circle()
                                .trim(from: 0, to: progressAnimated ? dash.readinessScore / 100 : 0)
                                .stroke(
                                    readinessColor(dash.readinessScore),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 0) {
                                Text(verbatim: "\(Int(dash.readinessScore))")
                                    .font(.title.bold().monospacedDigit())
                                Text(verbatim: "%")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(readinessColor(dash.readinessScore))
                        }
                        BentoText(verbatim: "Bereitschaft", style: .caption, color: theme.colors.onSurfaceMuted)
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: dash.recommendedFocusIcon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.colors.accent)
                            BentoText(verbatim: "Heute trainieren?", style: .caption, color: theme.colors.onSurfaceMuted)
                        }
                        Text(dash.recommendedFocus)
                            .font(Theme.Typography.subheadline.weight(.bold))
                            .foregroundStyle(theme.colors.onSurface)
                        BentoText(
                            verbatim: "\(dash.recoveredMuscles.count) Muskeln erholt · \(dash.needsRestMuscles.count) brauchen Pause",
                            style: .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                    Spacer()
                }

                BentoDivider()

                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "acwr",
                        title: Text("ACWR"),
                        value: Text(verbatim: String(format: "%.2f", dash.acwr)),
                        detail: Text(acwrLabel(dash.acwr))
                    ),
                    BentoStatValue(
                        id: "sessions",
                        title: Text("Sessions 7T"),
                        value: Text(verbatim: "\(dash.sessionCount7d)"),
                        detail: Text("\(dash.sessionCount28d) in 28T")
                    ),
                    BentoStatValue(
                        id: "vol",
                        title: Text("Volumen 7T"),
                        value: Text(verbatim: formatVolume(dash.totalWeeklyVolume)),
                        detail: Text("Ø \(formatVolume(dash.avgWeeklyVolume))/Muskel")
                    )
                ])
            }
        }
    }

    private func readinessColor(_ score: Double) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }

    private func acwrColor(_ ratio: Double) -> Color {
        if ratio < 0.8 { return .blue }
        if ratio <= 1.3 { return .green }
        if ratio <= 1.5 { return .orange }
        return .red
    }

    private func acwrLabel(_ ratio: Double) -> String {
        if ratio < 0.8 { return "Unterlast" }
        if ratio <= 1.3 { return "Optimal" }
        if ratio <= 1.5 { return "Grenzwert" }
        return "Überlast"
    }

    // MARK: - Recovery Overview Header

    private var recoveryOverviewHeader: some View {
        let musclesNeedingRest = recoveryData.filter { $0.needsRest }
        let musclesWarning = recoveryData.filter { $0.isWarning }
        let profile = ActivityProfile.current

        let headerColor: Color = musclesNeedingRest.isEmpty ? (musclesWarning.isEmpty ? .green : .orange) : .red
        let headerIcon = musclesNeedingRest.isEmpty ? (musclesWarning.isEmpty ? "checkmark.circle.fill" : "exclamationmark.circle.fill") : "exclamationmark.triangle.fill"
        let headerText: String = {
            if !musclesNeedingRest.isEmpty {
                return "\(musclesNeedingRest.count) Muskeln brauchen Pause"
            }
            if !musclesWarning.isEmpty {
                return "\(musclesWarning.count) Muskeln nah am Limit"
            }
            return "Alle Muskeln erholt"
        }()
        let headerCount: String = {
            if !musclesNeedingRest.isEmpty { return "\(musclesNeedingRest.count)" }
            if !musclesWarning.isEmpty { return "\(musclesWarning.count)" }
            return "✓"
        }()

        return BentoCard(style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: theme.spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(headerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 100, height: 100)

                    VStack(spacing: 4) {
                        Image(systemName: headerIcon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(headerColor)
                        Text(verbatim: headerCount)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(headerColor)
                    }
                }
                .frame(height: 120)

                BentoText(verbatim: headerText, style: .headline)

                HStack(spacing: 4) {
                    Image(systemName: profile.icon)
                        .font(.caption)
                    BentoText(verbatim: "Profil: \(profile.label)", style: .caption, color: theme.colors.onSurfaceMuted)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Recovery List

    private var recoveryListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            BentoSectionHeader(
                title: Text("Erholungsstatus"),
                subtitle: Text("\(recoveryData.filter { $0.muscleGroup.showInList }.count) Gruppen")
            )

            LazyVStack(spacing: theme.spacing.sm) {
                let sortedRecovery = recoveryData
                    .filter { $0.muscleGroup.showInList }
                    .sorted { lhs, rhs in
                        if lhs.needsRest != rhs.needsRest { return lhs.needsRest }
                        if lhs.isWarning != rhs.isWarning { return lhs.isWarning }
                        return lhs.weeklyVolume > rhs.weeklyVolume
                    }

                ForEach(sortedRecovery) { data in
                    RecoveryMuscleRow(data: data, isSelected: selectedMuscle == data.muscleGroup) {
                        withAnimation(.spring(response: 0.35)) {
                            selectedMuscle = data.muscleGroup
                            showFront = data.muscleGroup.bodyPosition.isFront
                        }
                    }
                }
            }
        }
    }

    // MARK: - Load

    private func load() async {
        progressAnimated = false
        do {
            rankings = try env.muscleRankingService.calculateRankings()
            recoveryData = try env.muscleRecoveryService.calculateRecovery()
            dashboard = try env.muscleRecoveryService.recoveryDashboard()
            let relevantRankings = includeUntrainedMuscles
                ? rankings
                : rankings.filter { $0.totalVolume > 0 }
            overallRank = try env.muscleRankingService.overallRank(
                includeUntrained: includeUntrainedMuscles
            )
            let totalVolume = relevantRankings.map { $0.totalVolume }.reduce(0, +)
            let avgVolume = relevantRankings.isEmpty ? 0 : totalVolume / Double(relevantRankings.count)
            overallVolume = avgVolume
            overallProgress = overallRank.progressToNext(currentVolume: Int(avgVolume))
        } catch {}
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            progressAnimated = true
        }
    }
}
