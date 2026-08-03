//
//  SpeciesPickerSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct SpeciesPickerSheet: View {
    @Bindable var vm: ForestViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false

    var body: some View {
        BentoAdaptiveGrid(minimumItemWidth: 140) {
            ForEach(TreeSpecies.allCases) { species in
                SpeciesCard(
                    species: species,
                    cost: vm.cost(for: species),
                    unlocked: vm.isUnlocked(species),
                    affordable: vm.availablePoints >= vm.cost(for: species),
                    vm: vm
                ) {
                    if !vm.env.entitlements.canPlant(species: species) {
                        showingPaywall = true
                        return
                    }
                    guard vm.isUnlocked(species) else { return }
                    vm.plant(species)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private struct SpeciesCard: View {
        let species: TreeSpecies
        let cost: Int
        let unlocked: Bool
        let affordable: Bool
        let vm: ForestViewModel
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: Theme.Spacing.s) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.m)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.2), Color.mint.opacity(0.1)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        if vm.env.entitlements.canPlant(species: species) {
                            TreeShapeView(species: species, stage: .mature)
                                .padding(12)
                        } else {
                            TreeShapeView(species: species, stage: .mature)
                                .padding(12)
                                .proBadge()
                        }

                        if !unlocked {
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(.ultraThinMaterial)
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 120)

                    BentoText(verbatim: species.displayName, style: .headline)

                    if unlocked {
                        BentoBadge(
                            Text(verbatim: "\(cost)"),
                            tone: affordable ? .success : .danger,
                            systemImage: "leaf.fill"
                        )
                    } else {
                        BentoText(
                            verbatim: "Ab \(species.unlockThreshold) Punkten",
                            style: .caption,
                            color: .secondary
                        )
                    }
                }
                .padding(Theme.Spacing.m)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .strokeBorder(
                            unlocked && affordable ? Color.accentColor.opacity(0.4) : .clear,
                            lineWidth: 1.5
                        )
                )
                .opacity(unlocked ? 1.0 : 0.75)
            }
            .buttonStyle(.plain)
            .disabled(!unlocked || !affordable)
        }
    }
}
