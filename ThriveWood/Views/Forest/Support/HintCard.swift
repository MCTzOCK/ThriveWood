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
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
