//
//  HintCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct HintCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(Theme.Typography.body)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("So wächst dein Wald")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                Text("Tippe auf ein leeres Feld, um einen Baum zu pflanzen. Gieße Bäume, damit sie zum Setzling, Jungbaum und schließlich zum Giganten heranwachsen.")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
