//
//  CompanionCard.swift
//  ThriveWood
//
//  Kompakte Companion-Karte für den Home-Screen. Tap → CompanionView.
//  Observiert CompanionService direkt → Energie-Änderungen erscheinen live.
//

import SwiftUI

struct CompanionCard: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(AppEnvironment.self) private var env
    @State private var showingDetail = false

    private var service: CompanionService { env.companionService }

    var body: some View {
        Button {
            Haptics.selection()
            showingDetail = true
        } label: {
            BentoCard(tone: tone(for: service.species), style: .elevated, padding: .lg, radius: .extraLarge) {
                HStack(spacing: theme.spacing.lg) {
                    CompanionCreature(
                        species: service.species.kitType,
                        stage: service.stage.kitType,
                        mood: service.mood.kitType,
                        size: 64,
                        accessory: service.equippedAccessory?.asset.kitType
                    )

                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        HStack(spacing: theme.spacing.xxs) {
                            Text(service.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(theme.colors.onAccent)
                            Text(service.mood.emoji)
                        }

                        Text("\(service.stage.label) · \(service.mood.label)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(theme.colors.onAccent.opacity(0.8))

                        // Energie-Bar
                        BentoProgressBar(
                            progress: service.energy / 100,
                            tone: .neutral,
                            height: 8
                        )
                        .tint(theme.colors.onAccent)
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.colors.onAccent.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
        .bentoSheet(isPresented: $showingDetail, title: Text("Companion"), detents: [.large]) {
            CompanionView()
        }
    }

    private func tone(for species: CompanionSpecies) -> BentoTone {
        switch species {
        case .fox:        return .warning
        case .owl:        return .info
        case .bear:       return .neutral
        case .wolf:       return .neutral
        case .deer:       return .pink
        case .highlandCow:return .warning
        }
    }
}
