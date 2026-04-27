//
//  ForestStatsHeader.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct ForestStatsHeader: View {
    let available: Int
    let total: Int
    let coverage: Double
    let treeCount: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.l) {
                StatBlock(icon: "leaf.fill", tint: .green,
                          value: "\(available)", label: "Verfügbar")
                Divider().frame(height: 36)
                StatBlock(icon: "tree.fill", tint: .brown,
                          value: "\(treeCount)", label: "Bäume")
                Divider().frame(height: 36)
                StatBlock(icon: "sparkles", tint: .orange,
                          value: "\(total)", label: "Gesamt")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Bewachsung")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(coverage * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.green.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [.green, .mint],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * coverage)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coverage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private struct StatBlock: View {
        let icon: String; let tint: Color; let value: String; let label: String
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(.headline)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ForestGridView: View {
    @Bindable var vm: ForestViewModel

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<vm.gridHeight, id: \.self) { y in
                HStack(spacing: 6) {
                    ForEach(0..<vm.gridWidth, id: \.self) { x in
                        ForestCell(
                            tree: vm.tree(at: x, y: y),
                            isWatering: vm.tree(at: x, y: y).map { vm.wateringTreeID == $0.id } ?? false
                        )
                        .onTapGesture { vm.tapCell(x: x, y: y) }
                    }
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.brown,
                            Color.brown.opacity(0.8),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

struct ForestCell: View {
    let tree: TreeEntity?
    let isWatering: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .aspectRatio(1, contentMode: .fit)

            if let tree {
                TreeShapeView(species: tree.species, stage: tree.stage, animate: isWatering)
                    .padding(4)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
    }
}

struct HintCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("So wächst dein Wald")
                    .font(.subheadline.weight(.semibold))
                Text("Tippe auf ein leeres Feld, um einen Baum zu pflanzen. Gieße Bäume, damit sie zum Setzling, Jungbaum und schließlich zum Giganten heranwachsen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
