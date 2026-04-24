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

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TreeSpecies.allCases) { species in
                        SpeciesCard(
                            species: species,
                            cost: vm.cost(for: species),
                            unlocked: vm.isUnlocked(species),
                            affordable: vm.availablePoints >= vm.cost(for: species)
                        ) {
                            guard vm.isUnlocked(species) else { return }
                            vm.plant(species)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Baum pflanzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    private struct SpeciesCard: View {
        let species: TreeSpecies
        let cost: Int
        let unlocked: Bool
        let affordable: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: Theme.Spacing.s) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.m)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        TreeShapeView(species: species, stage: .mature)
                            .padding(12)
                        if !unlocked {
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(.ultraThinMaterial)
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 120)

                    Text(species.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if unlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                            Text("\(cost)")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(affordable ? .green : .red)
                    } else {
                        Text("Ab \(species.unlockThreshold) Punkten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                            unlocked && affordable ? Color.green.opacity(0.4) : .clear,
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
