//
//  CompanionView.swift
//  ThriveWood
//
//  Haustier-Zentrale: großes streichelbares Tier, Sprechblase (Apple
//  Intelligence + Fallback), 4 Bedürfnis-Balken, Pflege-Aktionen,
//  Reaktionen, Accessoire-Shop. Observiert CompanionService direkt → alles live.
//

import SwiftUI

struct CompanionView: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var switchingCompanion = false
    @State private var showingShop = false
    @State private var reactionTrigger: Int = 0
    @State private var petBounce: Bool = false

    private var service: CompanionService { env.companionService }
    private var speech: CompanionSpeechService { env.companionSpeechService }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.lg) {
                heroWithSpeech
                needsCard
                actionsCard
                accessoriesRow
                settingsCard
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.md)
            .padding(.bottom, theme.spacing.xxl)
        }
        .animation(theme.motion.snappy, value: service.energy)
        .animation(theme.motion.snappy, value: service.bond)
        .animation(theme.motion.snappy, value: service.revision)
        .onAppear { if service.speechBubble == nil { speech.generateNext() } }
        .bentoSheet(isPresented: $switchingCompanion, title: Text("Companion wechseln"), detents: [.medium, .large]) {
            CompanionPicker(onChosen: { switchingCompanion = false })
        }
        .bentoSheet(isPresented: $showingShop, title: Text("Accessoire-Shop"), detents: [.large]) {
            AccessoryShopView()
        }
    }

    // MARK: - Hero + Sprechblase

    private var heroWithSpeech: some View {
        VStack(spacing: theme.spacing.sm) {
            // Sprechblase (tappbar → neue Line).
            if let bubble = service.speechBubble {
                Button {
                    Haptics.selection()
                    speech.generateNext()
                } label: {
                    speechBubble(bubble)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else if speech.isLoading {
                speechBubble("…")
                    .overlay { BentoSpinner(size: 18) }
            }

            // Großes Tier — Tap = streicheln.
            Button {
                let ok = service.pet()
                if ok {
                    Haptics.impact(.soft)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { petBounce.toggle() }
                    reactionTrigger &+= 1
                }
            } label: {
                CompanionCreature(
                    species: service.species.kitType,
                    stage: service.stage.kitType,
                    mood: service.mood.kitType,
                    size: 150,
                    accessory: service.equippedAccessory?.asset.kitType,
                    reaction: service.lastReaction?.kitType,
                    reactionTrigger: reactionTrigger
                )
                .scaleEffect(petBounce ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: petBounce)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(service.name).font(.system(size: 24, weight: .bold))
                Text("\(service.species.label) · \(service.stage.label)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(.secondary)
                Text("\(service.mood.emoji) \(service.mood.label)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(moodColor)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func speechBubble(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.callout)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                    .fill(theme.colors.surface)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            )
            .overlay(alignment: .bottom) {
                SpeechBubbleTail()
                    .fill(theme.colors.surface)
                    .frame(width: 16, height: 10)
                    .offset(y: 9)
            }
            .padding(.horizontal, theme.spacing.xl)
    }

    /// Dreieck für den Sprechblasen-Schwanz (eigener Name, da Triangle schon
    /// im CompanionKit existiert).
    private struct SpeechBubbleTail: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
            return p
        }
    }

    // MARK: - Bedürfnis-Balken

    private var needsCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoText(verbatim: "Bedürfnisse", style: .headline)

                needBar(.hunger, value: service.hunger)
                needBar(.hygiene, value: service.hygiene)
                needBar(.fun, value: service.fun)
                needBar(.bond, value: service.bond)

                BentoDivider()

                needBar(.energy, value: service.energy)
            }
        }
    }

    @ViewBuilder
    private func needBar(_ need: CompanionNeed, value: Double) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            HStack(spacing: theme.spacing.xs) {
                Text(need.emoji)
                BentoText(verbatim: need.label, style: .caption)
                Spacer()
                Text("\(Int(value))")
                    .font(Theme.Typography.mono.weight(.medium))
                    .foregroundStyle(value < 30 ? AnyShapeStyle(Color.red) : AnyShapeStyle(Color.secondary))
                    .contentTransition(.numericText())
            }
            BentoProgressBar(progress: value / 100, tone: needTone(value), height: 7)
        }
    }

    private func needTone(_ value: Double) -> BentoTone {
        if value >= 60 { return .success }
        if value >= 30 { return .warning }
        return .danger
    }

    // MARK: - Pflege-Aktionen

    private var actionsCard: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoText(verbatim: "Pflege", style: .headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                    careButton(.hunger, icon: "fork.knife", label: "Füttern") { service.feed() }
                    careButton(.hygiene, icon: "drop.degreesign", label: "Pflegen") { service.clean() }
                    careButton(.fun, icon: "tennisball.fill", label: "Spielen") { service.play() }
                    careButton(.bond, icon: "hand.draw.fill", label: "Streicheln") { service.pet() }
                }
            }
        }
    }

    @ViewBuilder
    private func careButton(_ need: CompanionNeed, icon: String, label: String, action: @escaping () -> Bool) -> some View {
        let cd = service.cooldownRemaining(for: need)
        let active = cd <= 0
        BentoButton(
            Text(verbatim: label),
            systemImage: icon,
            variant: active ? .secondary : .ghost,
            expands: true
        ) {
            let ok = action()
            if ok { reactionTrigger &+= 1 } else { Haptics.warning() }
        }
        .disabled(!active)
        .overlay(alignment: .bottomTrailing) {
            if cd > 0 {
                Text(verbatim: "\(Int(cd))s")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.colors.surfaceSecondary))
                    .padding(6)
            }
        }
    }

    // MARK: - Accessoires (kurze Reihe)

    private var accessoriesRow: some View {
        BentoCard(style: .elevated, padding: .lg) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    BentoText(verbatim: "Accessoires", style: .headline)
                    BentoText(verbatim: "\(service.ownedAccessoryIDs.count) besessen · \(service.coins) Coins",
                              style: .caption, color: .secondary)
                }
                Spacer()
                BentoButton(Text("Shop"), systemImage: "bag.fill", variant: .secondary, size: .small) {
                    showingShop = true
                }
            }
        }
    }

    // MARK: - Settings (Rename, Companion wechseln, Decay)

    private var settingsCard: some View {
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
                    Text(service.decayPaused ? "Verfall deaktiviert" : "Verfall pausieren"),
                    systemImage: service.decayPaused ? "play.circle" : "pause.circle",
                    variant: .ghost,
                    expands: true
                ) {
                    service.setDecayPaused(!service.decayPaused)
                }

                if service.decayPaused {
                    BentoCallout(
                        kind: .warning,
                        title: Text("Verfall pausiert"),
                        message: Text("Dein Companion verliert keine Bedürfnisse bei Inaktivität.")
                    )
                }
            }
        }
    }

    // MARK: - Helper

    private var moodColor: Color {
        switch service.mood {
        case .vibrant:  return .green
        case .content:  return .accentColor
        case .tired:    return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Companion Picker

struct CompanionPicker: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(AppEnvironment.self) private var env
    let onChosen: () -> Void

    @State private var selectedSpecies: CompanionSpecies = .fox
    @State private var nameDraft = ""

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            CompanionCreature(
                species: selectedSpecies.kitType,
                stage: .seedling,
                mood: .content,
                size: 110
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
                    .fill(selectedSpecies == species ? color(for: species).opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                            .stroke(selectedSpecies == species ? color(for: species).opacity(0.4) : Color.gray.opacity(0.15),
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
