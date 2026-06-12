//
//  TreeDetailSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct TreeDetailSheet: View {
    let tree: TreeEntity
    @Bindable var vm: ForestViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    private let waterAmount: Int = 5
    private var waterCost: Int { waterAmount * ForestService.wateringCostPerGrowth }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.l) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.l)
                        .fill(
                            LinearGradient(
                                colors: [Color.mint.opacity(0.25), Color.green.opacity(0.15)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    TreeShapeView(
                        species: tree.species,
                        stage: tree.stage,
                        animate: vm.wateringTreeID == tree.id
                    )
                    .padding(Theme.Spacing.l)
                }
                .frame(height: 220)
                .padding(.horizontal, Theme.Spacing.l)

                VStack(spacing: 6) {
                    Text(tree.nickname ?? tree.species.displayName)
                        .font(.title2.bold())
                    Text("\(tree.stage.label) • \(tree.growthPoints) Wachstumspunkte")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GrowthProgressBar(points: tree.growthPoints)
                    .padding(.horizontal, Theme.Spacing.l)

                HStack(spacing: Theme.Spacing.m) {
                    Button {
                        vm.water(tree, amount: waterAmount)
                    } label: {
                        Label("Gießen (\(waterCost) P)", systemImage: "drop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.m)
                            .background(
                                Capsule().fill(
                                    vm.availablePoints >= waterCost
                                    ? Color.accentColor
                                    : Color.gray.opacity(0.4)
                                )
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(vm.availablePoints < waterCost || tree.stage == .ancient)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline)
                            .frame(width: 54, height: 52)
                            .background(Capsule().fill(Color.red.opacity(0.15)))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)

                Spacer(minLength: 0)
            }
            .padding(.vertical, Theme.Spacing.l)
            .navigationTitle("Baum")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Fertig") { dismiss() }
                }
            }
            .confirmationDialog(
                "Baum wirklich entfernen?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Entfernen", role: .destructive) {
                    vm.remove(tree)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Die investierten Punkte werden nicht erstattet.")
            }
        }
    }
}

struct GrowthProgressBar: View {
    let points: Int

    private var currentStage: TreeGrowthStage { .stage(forTreePoints: points) }
    private var nextThreshold: Int? {
        switch currentStage {
        case .seed: 5
        case .sprout: 15
        case .sapling: 35
        case .young: 70
        case .mature: 150
        case .ancient: nil
        }
    }
    private var prevThreshold: Int {
        switch currentStage {
        case .seed: 0
        case .sprout: 5
        case .sapling: 15
        case .young: 35
        case .mature: 70
        case .ancient: 150
        }
    }

    private var progress: Double {
        guard let next = nextThreshold else { return 1 }
        let span = next - prevThreshold
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(points - prevThreshold) / Double(span)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(currentStage.label)
                    .font(.caption.weight(.semibold))
                Spacer()
                if let next = nextThreshold {
                    Text("→ \(next - points) bis nächste Stufe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Maximale Stufe erreicht 🎉")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.accentColor.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [.accentColor, .mint],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
