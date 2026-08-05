//
//  CompanionStep.swift
//  ThriveWood
//
//  Onboarding-Schritt: User wählt sein Companion-Wesen und vergibt einen Namen.
//

import SwiftUI

struct CompanionStep: View {
    @Binding var species: CompanionSpecies
    @Binding var name: String
    let accent: AccentTheme
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var appear = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.l) {
                Spacer().frame(height: Theme.Spacing.m)

                // Header
                VStack(spacing: Theme.Spacing.xs) {
                    BentoBadge(Text("DEIN BEGLEITER"), tone: .accent, systemImage: "pawprint.fill")
                    BentoText("Wähle deinen Companion", style: .title1)
                    BentoText(
                        "Er begleitet dich auf deinem Weg. Seine Energie steigt durch erledigte Habits und Workouts — und sinkt, wenn du nachlässig wirst.",
                        style: .callout,
                        color: .secondary
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.l)
                    .fixedSize(horizontal: false, vertical: true)
                }

                // Vorschau
                ZStack {
                    Circle()
                        .fill(color(for: species).opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1 : 0.7)
                    CompanionCreature(
                        species: species.kitType,
                        stage: .seedling,
                        mood: .content,
                        size: 110
                    )
                    .scaleEffect(appear ? 1 : 0.5)
                }
                .padding(.top, Theme.Spacing.s)

                // Arten-Auswahl
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
                    ForEach(CompanionSpecies.allCases) { sp in
                        speciesTile(sp)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)

                // Name
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    BentoText("Name (optional)", style: .caption, color: .secondary)
                    BentoTextField(text: $name, prompt: Text(species.defaultName))
                }
                .padding(.horizontal, Theme.Spacing.l)

                Spacer(minLength: Theme.Spacing.l)

                // Buttons
                VStack(spacing: Theme.Spacing.s) {
                    OnboardingButton(title: "Weiter", accent: accent, icon: "arrow.right", action: onNext)
                    Button("Zurück") { onBack() }
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.bouncy) { appear = true }
        }
    }

    private func speciesTile(_ sp: CompanionSpecies) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.bouncy) { species = sp }
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(species == sp
                              ? color(for: sp).opacity(0.2)
                              : Color.gray.opacity(0.1))
                        .frame(width: 52, height: 52)
                    CompanionCreature(
                        species: sp.kitType,
                        stage: .seedling,
                        mood: .content,
                        size: 44
                    )
                }
                Text(sp.label)
                    .font(Theme.Typography.caption.weight(.medium))
                    .foregroundStyle(species == sp ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(species == sp ? color(for: sp).opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                            .stroke(species == sp ? color(for: sp).opacity(0.4) : Color.gray.opacity(0.15),
                                    lineWidth: species == sp ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func color(for sp: CompanionSpecies) -> Color {
        switch sp {
        case .fox:        return .orange
        case .owl:        return .indigo
        case .bear:       return .brown
        case .wolf:       return .gray
        case .deer:       return .pink
        case .highlandCow:return .brown
        }
    }
}
