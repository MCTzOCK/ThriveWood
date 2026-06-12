//
//  FoodEntryRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.food?.displayName ?? "Unbekannt")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text("\(Int(entry.servingAmount))g • \(Int(entry.nutrition.calories)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    MacroPill(value: entry.nutrition.protein, label: "P", color: .blue)
                    MacroPill(value: entry.nutrition.carbs, label: "K", color: .green)
                    MacroPill(value: entry.nutrition.fat, label: "F", color: .yellow)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}
