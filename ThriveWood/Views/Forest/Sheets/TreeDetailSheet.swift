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
        VStack(spacing: Theme.Spacing.l) {
            // Hero Tree Display
            BentoOverlayTile(minimumHeight: 200, alignment: .center) {
                LinearGradient(
                    colors: [Color.mint.opacity(0.25), Color.green.opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
            } content: {
                TreeShapeView(
                    species: tree.species,
                    stage: tree.stage,
                    animate: vm.wateringTreeID == tree.id
                )
                .padding(Theme.Spacing.l)
            }

            // Title & Stage
            VStack(spacing: Theme.Spacing.xs) {
                BentoText(verbatim: tree.nickname ?? tree.species.displayName, style: .title2)
                BentoText(
                    verbatim: "\(tree.stage.label) • \(tree.growthPoints) Wachstumspunkte",
                    style: .callout,
                    color: .secondary
                )
            }

            GrowthProgressBar(points: tree.growthPoints)

            // Actions
            HStack(spacing: Theme.Spacing.m) {
                BentoButton(
                    Text(verbatim: "Gießen (\(waterCost) P)"),
                    systemImage: "drop.fill",
                    variant: vm.availablePoints >= waterCost ? .primary : .secondary,
                    size: .medium,
                    expands: true
                ) {
                    vm.water(tree, amount: waterAmount)
                }
                .disabled(vm.availablePoints < waterCost || tree.stage == .ancient)

                BentoIconButton(
                    systemImage: "trash",
                    accessibilityLabel: Text("Entfernen"),
                    variant: .tonal(.danger),
                    size: .medium
                ) {
                    showDeleteConfirm = true
                }
            }

            Spacer(minLength: 0)
        }
        .bentoDialog(
            isPresented: $showDeleteConfirm,
            systemImage: "exclamationmark.triangle.fill",
            title: Text("Baum wirklich entfernen?"),
            message: Text("Die investierten Punkte werden nicht erstattet."),
            actions: [
                BentoDialogAction(title: Text("Abbrechen"), role: .cancel) { },
                BentoDialogAction(
                    title: Text("Entfernen"),
                    variant: .destructive,
                    role: .destructive
                ) {
                    vm.remove(tree)
                    dismiss()
                }
            ]
        )
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
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                BentoBadge(Text(verbatim: currentStage.label), tone: .green)
                Spacer()
                if let next = nextThreshold {
                    BentoText(
                        verbatim: "→ \(next - points) bis nächste Stufe",
                        style: .caption,
                        color: .secondary
                    )
                } else {
                    BentoBadge(Text(verbatim: "Maximal! 🎉"), tone: .success, systemImage: "sparkles")
                }
            }
            BentoProgressBar(
                progress: progress,
                tone: .green,
                height: 10
            )
        }
    }
}
