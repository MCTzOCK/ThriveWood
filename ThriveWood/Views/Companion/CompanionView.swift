//
//  CompanionView.swift
//  ThriveWood
//
//  Detail-Ansicht des „Thrive Companion": großes animiertes Wesen, Energie,
//  Evolution, Umbenennen, Companion wechseln. Observiert CompanionService
//  direkt → alle Änderungen sofort live.
//

import SwiftUI

struct CompanionView: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var switchingCompanion = false

    private var service: CompanionService { env.companionService }

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            hero
            energyCard
            evolutionCard
            actionsCard
            if service.decayPaused { decayPausedHint }
            Spacer(minLength: theme.spacing.lg)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.md)
        .animation(theme.motion.snappy, value: service.energy)
        .animation(theme.motion.snappy, value: service.stage)
        .animation(theme.motion.snappy, value: service.revision)
        .bentoSheet(isPresented: $switchingCompanion, title: Text("Companion wechseln"), detents: [.medium, .large]) {
            CompanionPicker(onChosen: { switchingCompanion = false })
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: theme.spacing.sm) {
            CompanionCreature(
                species: service.species.kitType,
                stage: service.stage.kitType,
                mood: service.mood.kitType,
                size: 132
            )
            .padding(.top, theme.spacing.sm)

            VStack(spacing: 2) {
                Text(service.name)
                    .font(.system(size: 24, weight: .bold))
                Text("\(service.species.label) · \(service.stage.label)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(.secondary)
                Text("\(service.mood.emoji) \(service.mood.label)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(moodColor)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Energie

    private var energyCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    BentoText(verbatim: "Energie", style: .headline)
                    Spacer()
                    Text("\(Int(service.energy)) / 100")
                        .font(Theme.Typography.mono.weight(.semibold))
                        .foregroundStyle(moodColor)
                        .contentTransition(.numericText())
                }
                BentoProgressBar(progress: service.energy / 100, tone: moodTone, height: 12)
                BentoText(
                    verbatim: "Steigt durch erledigte Habits, Workouts und dein Tagesziel. Sinkt bei mehrtägiger Inaktivität.",
                    style: .caption,
                    color: .secondary
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Evolution

    private var evolutionCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    BentoText(verbatim: "Entwicklung", style: .headline)
                    Spacer()
                    BentoBadge(Text("\(service.activeDaysTotal)"), tone: .accent, systemImage: "calendar.badge.checkmark")
                }

                HStack(spacing: theme.spacing.xs) {
                    ForEach(CompanionStage.allCases, id: \.rawValue) { stage in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(stage.rawValue <= service.stage.rawValue
                                          ? speciesColor.opacity(0.18)
                                          : Color.gray.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: stageIcon(stage))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(stage.rawValue <= service.stage.rawValue
                                                     ? speciesColor
                                                     : Color.secondary.opacity(0.5))
                            }
                            Text(stage.label)
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(stage.rawValue <= service.stage.rawValue ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                BentoProgressBar(progress: nextStageProgress, tone: .accent, height: 6)
                BentoText(verbatim: nextStageLabel, style: .caption, color: .secondary)
            }
        }
    }

    // MARK: - Aktionen

    private var actionsCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(spacing: theme.spacing.sm) {
                if editingName {
                    HStack(spacing: theme.spacing.xs) {
                        BentoTextField(text: $nameDraft, prompt: Text("Name"))
                        BentoButton(Text("OK"), variant: .primary, size: .small) {
                            service.rename(nameDraft)
                            editingName = false
                        }
                    }
                } else {
                    BentoButton(Text("Umbenennen"), systemImage: "pencil", variant: .secondary, expands: true) {
                        nameDraft = service.name
                        editingName = true
                    }
                }

                BentoButton(Text("Companion wechseln"), systemImage: "arrow.triangle.2.circlepath", variant: .secondary, expands: true) {
                    switchingCompanion = true
                }

                BentoButton(
                    Text(service.decayPaused ? "Energie-Verfall deaktiviert" : "Energie-Verfall pausieren"),
                    systemImage: service.decayPaused ? "play.circle" : "pause.circle",
                    variant: .ghost,
                    expands: true
                ) {
                    service.setDecayPaused(!service.decayPaused)
                }
            }
        }
    }

    private var decayPausedHint: some View {
        BentoCallout(
            kind: .warning,
            title: Text("Verfall pausiert"),
            message: Text("Dein Companion verliert keine Energie bei Inaktivität. Aktiviere den Verfall wieder, um die volle Bindung zu spüren.")
        )
    }

    // MARK: - Helper

    private var speciesColor: Color {
        switch service.species {
        case .fox:  return .orange
        case .owl:  return .indigo
        case .bear: return .brown
        case .wolf: return .gray
        case .deer: return .pink
        }
    }

    private var moodColor: Color {
        switch service.mood {
        case .vibrant:  return .green
        case .content:  return .accentColor
        case .tired:    return .orange
        case .critical: return .red
        }
    }

    private var moodTone: BentoTone {
        switch service.mood {
        case .vibrant:  return .success
        case .content:  return .accent
        case .tired:    return .warning
        case .critical: return .danger
        }
    }

    private var nextStageProgress: Double {
        guard let next = service.stage.nextThreshold else { return 1 }
        let thresholds = CompanionStage.thresholds
        guard let idx = thresholds.firstIndex(of: next) else { return 1 }
        let current = idx > 0 ? thresholds[idx - 1] : 0
        let span = next - current
        guard span > 0 else { return 1 }
        return min(1, Double(service.activeDaysTotal - current) / Double(span))
    }

    private var nextStageLabel: String {
        guard let next = service.stage.nextThreshold else { return "Maximale Stufe erreicht" }
        return "Nächste Stufe in \(max(0, next - service.activeDaysTotal)) aktiven Tagen"
    }

    private func stageIcon(_ stage: CompanionStage) -> String {
        switch stage {
        case .seedling:    return "leaf.fill"
        case .juvenile:    return "sprout"
        case .adult:       return service.species.symbol
        case .enlightened: return "sparkles"
        }
    }
}

// MARK: - Companion Picker (innerhalb des Sheets)

struct CompanionPicker: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(AppEnvironment.self) private var env
    let onChosen: () -> Void

    @State private var selectedSpecies: CompanionSpecies = .fox
    @State private var nameDraft = ""

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Live-Vorschau der gewählten Art
            CompanionCreature(
                species: selectedSpecies.kitType,
                stage: .seedling,
                mood: .content,
                size: 96
            )
            .padding(.top, theme.spacing.sm)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: theme.spacing.sm)], spacing: theme.spacing.sm) {
                ForEach(CompanionSpecies.allCases) { species in
                    speciesTile(species)
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            BentoTextField(text: $nameDraft, prompt: Text("Name (optional)"))
                .padding(.horizontal, theme.spacing.lg)

            BentoButton(Text("Companion wählen"), systemImage: "checkmark.circle.fill", variant: .primary, expands: true) {
                do {
                    _ = try env.companionService.choose(species: selectedSpecies, name: nameDraft)
                    nameDraft = ""
                    onChosen()
                } catch { }
            }
            .padding(.horizontal, theme.spacing.lg)

            Spacer(minLength: theme.spacing.lg)
        }
        .padding(.vertical, theme.spacing.md)
        .onAppear {
            selectedSpecies = env.companionService.species
            nameDraft = env.companionService.name
        }
    }

    private func speciesTile(_ species: CompanionSpecies) -> some View {
        Button {
            Haptics.selection()
            withAnimation(theme.motion.snappy) { selectedSpecies = species }
        } label: {
            VStack(spacing: theme.spacing.xs) {
                CompanionCreature(species: species.kitType, stage: .seedling, mood: .content, size: 48)
                Text(species.label)
                    .font(Theme.Typography.caption.weight(.medium))
                    .foregroundStyle(selectedSpecies == species ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                    .fill(selectedSpecies == species
                          ? color(for: species).opacity(0.08)
                          : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                            .stroke(selectedSpecies == species
                                    ? color(for: species).opacity(0.4)
                                    : Color.gray.opacity(0.15),
                                    lineWidth: selectedSpecies == species ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func color(for species: CompanionSpecies) -> Color {
        switch species {
        case .fox:  return .orange
        case .owl:  return .indigo
        case .bear: return .brown
        case .wolf: return .gray
        case .deer: return .pink
        }
    }
}
