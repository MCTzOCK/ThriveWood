//
//  AccessoryShopView.swift
//  ThriveWood
//
//  Shop für Companion-Accessoires. Zeigt den statischen Katalog mit Vorschau,
//  Coin-Preis, Kaufen-/Ausgerüstet-Status.
//

import SwiftUI

struct AccessoryShopView: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    private var service: CompanionService { env.companionService }

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.s)]

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Coin-Stand.
            HStack {
                Image(systemName: "coin.fill")
                    .foregroundStyle(.yellow)
                BentoText(verbatim: "\(service.coins) Coins", style: .headline)
                Spacer()
                BentoBadge(Text(env.companionSpeechService.isAIAvailable ? "AI an" : "AI aus"),
                           tone: env.companionSpeechService.isAIAvailable ? .success : .neutral)
            }
            .padding(.horizontal, theme.spacing.lg)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: theme.spacing.sm) {
                    ForEach(CompanionStage.allCases, id: \.rawValue) { _ in
                        EmptyView()
                    }
                    ForEach(AccessoryCatalogItem.all) { item in
                        shopTile(item)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xxl)
            }
        }
        .padding(.top, theme.spacing.md)
    }

    @ViewBuilder
    private func shopTile(_ item: AccessoryCatalogItem) -> some View {
        let owned = service.ownedAccessoryIDs.contains(item.rawID)
        let equipped = service.equippedAccessoryID == item.rawID
        let affordable = service.coins >= item.cost

        BentoCard(style: .outlined, padding: .md) {
            VStack(spacing: theme.spacing.xs) {
                // Vorschau: Tier mit Accessoire.
                // Vorschau immer mit Accessoire — auch vor dem Kauf, damit der
                // User sieht, was er kauft. Nicht-besitzte Items werden leicht
                // transparent, um den Besitz-Status zu signalisieren.
                CompanionCreature(
                    species: service.species.kitType,
                    stage: service.stage.kitType,
                    mood: service.mood.kitType,
                    size: 70,
                    accessory: item.asset.kitType
                )
                .opacity(owned ? 1.0 : 0.85)

                Text(item.name).font(Theme.Typography.caption.weight(.semibold))
                    .lineLimit(1)

                if owned {
                    BentoButton(
                        Text(equipped ? "Ablegen" : "Anlegen"),
                        systemImage: equipped ? "checkmark.circle.fill" : "shirt.fill",
                        variant: equipped ? .primary : .secondary,
                        size: .small,
                        expands: true
                    ) {
                        service.equip(rawID: equipped ? nil : item.rawID)
                    }
                } else {
                    BentoButton(
                        Text(verbatim: "\(item.cost)"),
                        systemImage: affordable ? "coin.fill" : "lock.fill",
                        variant: affordable ? .primary : .ghost,
                        size: .small,
                        expands: true
                    ) {
                        let ok = service.buy(item)
                        if ok { Haptics.success() } else { Haptics.warning() }
                    }
                    .disabled(!affordable)
                }
            }
        }
    }
}
