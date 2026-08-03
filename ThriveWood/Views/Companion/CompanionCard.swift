//
//  CompanionCard.swift
//  ThriveWood
//
//  Kompakte Companion-Karte für den Home-Screen. Tap → CompanionView.
//

import SwiftUI

struct CompanionCard: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(AppEnvironment.self) private var env
    @State private var vm: CompanionViewModel?
    @State private var showingDetail = false

    var body: some View {
        Group {
            if let vm {
                card(vm: vm)
            } else {
                BentoCard(style: .elevated, padding: .lg) {
                    HStack { BentoSpinner(size: 24); Spacer() }
                }
            }
        }
        .task {
            if vm == nil { vm = CompanionViewModel(env: env) }
            vm?.load()
        }
        .bentoSheet(isPresented: $showingDetail, title: Text("Companion"), detents: [.large]) {
            if let vm { CompanionView(vm: vm) }
        }
    }

    @ViewBuilder
    private func card(vm: CompanionViewModel) -> some View {
        Button {
            Haptics.selection()
            showingDetail = true
        } label: {
            BentoCard(tone: tone(for: vm.species), style: .elevated, padding: .lg, radius: .extraLarge) {
                HStack(spacing: theme.spacing.lg) {
                    // Wesen-Visual
                    ZStack {
                        Circle()
                            .fill(theme.colors.onAccent.opacity(0.18))
                            .frame(width: 64, height: 64)
                        Image(systemName: vm.species.symbol)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(theme.colors.onAccent)
                            .symbolEffect(.bounce, value: vm.energy)
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        HStack(spacing: theme.spacing.xxs) {
                            Text(vm.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(theme.colors.onAccent)
                            Text(vm.mood.emoji)
                        }

                        Text("\(vm.stage.label) · \(vm.mood.label)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(theme.colors.onAccent.opacity(0.8))

                        // Energie-Bar
                        BentoProgressBar(
                            progress: vm.energy / 100,
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
    }

    private func tone(for species: CompanionSpecies) -> BentoTone {
        switch species {
        case .fox:  return .warning
        case .owl:  return .info
        case .bear: return .neutral
        case .wolf: return .neutral
        case .deer: return .pink
        }
    }
}
