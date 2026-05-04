//
//  FoodSearchRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct FoodSearchRow: View {
    let food: Food
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("\(Int(food.caloriesPer100g)) kcal / 100g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    MacroPill(value: food.proteinPer100g, label: "P", color: .blue)
                    MacroPill(value: food.carbsPer100g, label: "K", color: .green)
                    MacroPill(value: food.fatPer100g, label: "F", color: .yellow)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
