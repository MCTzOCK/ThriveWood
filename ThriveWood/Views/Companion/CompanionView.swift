//
//  CompanionView.swift
//  ThriveWood
//
//  Detail-Ansicht des „Thrive Companion": großes Wesen, Energie, Evolution,
//  Umbenennen, Companion wechseln. Wird als bentoSheet präsentiert.
//

import SwiftUI

struct CompanionView: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CompanionViewModel

    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var switchingCompanion = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            hero
            energyCard
            evolutionCard
            actionsCard
            if vm.decayPaused { decayPausedHint }
            Spacer(minLength: theme.spacing.lg)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.md)
        .animation(theme.motion.snappy, value: vm.energy)
        .animation(theme.motion.snappy, value: vm.stage)
        .bentoSheet(isPresented: $switchingCompanion, title: Text("Companion wechseln"), detents: [.medium, .large]) {
            CompanionPicker(vm: vm)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: theme.spacing.sm) {
            ZStack {
                Circle()
                    .fill(speciesColor.opacity(0.15))
                    .frame(width: 132, height: 132)
                Image(systemName: vm.species.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(speciesColor)
                    .symbolEffect(.bounce, value: vm.energy)
                    .symbolEffect(.pulse, options: .repeating, isActive: vm.mood == .critical)
            }

            VStack(spacing: 2) {
                Text(vm.name)
                    .font(.system(size: 24, weight: .bold))
                Text("\(vm.species.label) · \(vm.stage.label)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(.secondary)
                Text("\(vm.mood.emoji) \(vm.mood.label)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(moodColor)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, theme.spacing.sm)
    }

    // MARK: - Energie

    private var energyCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    BentoText(verbatim: "Energie", style: .headline)
                    Spacer()
                    Text("\(Int(vm.energy)) / 100")
                        .font(Theme.Typography.mono.weight(.semibold))
                        .foregroundStyle(moodColor)
                        .contentTransition(.numericText())
                }
                BentoProgressBar(progress: vm.energy / 100, tone: moodTone, height: 12)
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
                    BentoBadge(Text("\(vm.activeDaysTotal)"), tone: .accent, systemImage: "calendar.badge.checkmark")
                }

                HStack(spacing: theme.spacing.xs) {
                    ForEach(CompanionStage.allCases, id: \.rawValue) { stage in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(stage.rawValue <= vm.stage.rawValue
                                          ? speciesColor.opacity(0.18)
                                          : Color.gray.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: stageIcon(stage))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(stage.rawValue <= vm.stage.rawValue
                                                     ? speciesColor
                                                     : Color.secondary.opacity(0.5))
                            }
                            Text(stage.label)
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(stage.rawValue <= vm.stage.rawValue ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                BentoProgressBar(progress: vm.nextStageProgress, tone: .accent, height: 6)
                BentoText(verbatim: vm.nextStageLabel, style: .caption, color: .secondary)
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
                            vm.rename(nameDraft)
                            editingName = false
                        }
                    }
                } else {
                    BentoButton(Text("Umbenennen"), systemImage: "pencil", variant: .secondary, expands: true) {
                        nameDraft = vm.name
                        editingName = true
                    }
                }

                BentoButton(Text("Companion wechseln"), systemImage: "arrow.triangle.2.circlepath", variant: .secondary, expands: true) {
                    switchingCompanion = true
                }

                BentoButton(
                    Text(vm.decayPaused ? "Energie-Verfall deaktiviert" : "Energie-Verfall pausieren"),
                    systemImage: vm.decayPaused ? "play.circle" : "pause.circle",
                    variant: .ghost,
                    expands: true
                ) {
                    vm.toggleDecayPaused()
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
        switch vm.species {
        case .fox:  return .orange
        case .owl:  return .indigo
        case .bear: return .brown
        case .wolf: return .gray
        case .deer: return .pink
        }
    }

    private var moodColor: Color {
        switch vm.mood {
        case .vibrant:  return .green
        case .content:  return .accentColor
        case .tired:    return .orange
        case .critical: return .red
        }
    }

    private var moodTone: BentoTone {
        switch vm.mood {
        case .vibrant:  return .success
        case .content:  return .accent
        case .tired:    return .warning
        case .critical: return .danger
        }
    }

    private func stageIcon(_ stage: CompanionStage) -> String {
        switch stage {
        case .seedling:    return "leaf.fill"
        case .juvenile:    return "sprout"
        case .adult:       return vm.species.symbol
        case .enlightened: return "sparkles"
        }
    }
}

// MARK: - Companion Picker (innerhalb des Sheets)

struct CompanionPicker: View {
    @Environment(\.bentoTheme) private var theme
    @Bindable var vm: CompanionViewModel
    @State private var selectedSpecies: CompanionSpecies = .fox
    @State private var nameDraft = ""

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: theme.spacing.sm)], spacing: theme.spacing.sm) {
                ForEach(CompanionSpecies.allCases) { species in
                    speciesTile(species)
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            BentoTextField(text: $nameDraft, prompt: Text("Name (optional)"))
                .padding(.horizontal, theme.spacing.lg)

            BentoButton(Text("Companion wählen"), systemImage: "checkmark.circle.fill", variant: .primary, expands: true) {
                vm.choose(species: selectedSpecies, name: nameDraft)
                nameDraft = ""
            }
            .padding(.horizontal, theme.spacing.lg)

            Spacer(minLength: theme.spacing.lg)
        }
        .padding(.vertical, theme.spacing.md)
        .onAppear {
            selectedSpecies = vm.species
            nameDraft = vm.name
        }
    }

    private func speciesTile(_ species: CompanionSpecies) -> some View {
        Button {
            Haptics.selection()
            withAnimation(theme.motion.snappy) { selectedSpecies = species }
        } label: {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    Circle()
                        .fill(selectedSpecies == species
                              ? color(for: species).opacity(0.2)
                              : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: species.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(selectedSpecies == species ? color(for: species) : .secondary)
                }
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
