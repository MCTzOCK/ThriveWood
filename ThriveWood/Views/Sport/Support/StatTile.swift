//
//  StatTile.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct StatTile: View {
    let icon: String; let tint: Color; let value: String; let label: String
    var body: some View {
        BentoCard(style: .elevated, padding: .md) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(tint)
                    .padding(8)
                    .background(Circle().fill(tint.opacity(0.15)))
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .contentTransition(.numericText())
                BentoText(verbatim: label, style: .caption, color: .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
