//
//  MealTemplateRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MealTemplateRow: View {
    let template: MealTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s)
                        .fill(template.color.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: template.iconSystemName)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: Theme.Spacing.s) {
                        Text("\((template.items ?? []).count) Zutaten")
                        Text("•")
                        Text("\(Int(template.totalNutrition.calories)) kcal")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(template.color.color)
            }
        }
        .buttonStyle(.plain)
    }
}
