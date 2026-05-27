//
//  ForestPreviewCard.swift
//  ThriveWood
//

import SwiftUI

struct ForestPreviewCard: View {
    @Environment(AppEnvironment.self) private var env

    @State private var treeCount: Int = 0
    @State private var coverage: Double = 0

    let availablePoints: Int

    var body: some View {
        NavigationLink {
            ForestView()
        } label: {
            HStack(spacing: Theme.Spacing.l) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mein Wald")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(treeCount) Bäume")
                        .font(.headline.bold())
                }

                Spacer(minLength: 0)

                VStack(spacing: 2) {
                    ZStack {
                        ringBackground
                        ringProgress
                        Text("\(Int(coverage * 100))%")
                            .font(.caption2.bold())
                    }
                    .frame(width: 44, height: 44)

                    Text("Bewuchs")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.Spacing.l)
            .cardStyle()
        }
        
        .buttonStyle(.plain)
        .task { loadStats() }
    }

    private var ringBackground: some View {
        Circle()
            .stroke(Color.accentColor.opacity(0.15), lineWidth: 4)
    }

    private var ringProgress: some View {
        Circle()
            .trim(from: 0, to: coverage)
            .stroke(
                LinearGradient(colors: [.accentColor, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coverage)
    }

    private func loadStats() {
        treeCount = (try? env.forestService.trees().count) ?? 0
        coverage = (try? env.forestService.coverage(gridWidth: 6, gridHeight: 8)) ?? 0
    }
}
