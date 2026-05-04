//
//  NutritionCell.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI


struct NutritionCell: View {
    let value: Double
    let label: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))\(unit)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
