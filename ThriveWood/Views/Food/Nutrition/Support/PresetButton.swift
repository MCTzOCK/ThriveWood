//
//  PresetButton.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct PresetButton: View {
    let label: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let onTap: (Double, Double, Double, Double) -> Void

    var body: some View {
        Button {
            onTap(calories, protein, carbs, fat)
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
