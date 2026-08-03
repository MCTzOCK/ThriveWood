//
//  RankLegendSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//


import SwiftUI

struct RankLegendSheet: View {
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                // Header
                VStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow.gradient)

                    Text("Rang-System")
                        .font(.title.bold())

                    Text("Sammle Volumen und steige im Rang auf!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                // Ranks Grid
                VStack(spacing: Theme.Spacing.m) {
                    ForEach(MuscleRank.allCases, id: \.self) { rank in
                        RankLegendRow(rank: rank)
                    }
                }

                // Info
                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Label("So funktioniert's", systemImage: "questionmark.circle.fill")
                            .font(.headline)

                        Text("Dein Rang basiert auf der Gesamtzahl des absolvierten Volumen pro Muskelgruppe. Primäre Muskeln zählen voll, sekundäre Muskeln werden ebenfalls gewertet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Trainiere regelmäßig alle Muskelgruppen für einen ausgewogenen Körper und höhere Ränge!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct RankLegendRow: View {
    let rank: MuscleRank

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(rank.gradient)
                    .frame(width: 50, height: 50)
                    .shadow(color: rank.glowColor.opacity(0.4), radius: 6)

                Image(systemName: rank.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rank.label)
                    .font(.headline)
                    .foregroundStyle(rank.primaryColor)

                Text("Ab \(rank.minVolume) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Visual indicator
            HStack(spacing: 2) {
                ForEach(0..<min(rank.rawValue + 1, 5), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(rank.gradient)
                        .frame(width: 4, height: 16 + CGFloat(i) * 3)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
