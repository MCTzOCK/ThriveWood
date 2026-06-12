//
//  FoodAmountSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct FoodAmountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let food: Food
    let onConfirm: (Double) -> Void
    
    @State private var amount: Double
    
    init(food: Food, onConfirm: @escaping (Double) -> Void) {
        self.food = food
        self.onConfirm = onConfirm
        self._amount = State(initialValue: food.defaultServingSize)
    }
    
    private var nutrition: NutritionValues {
        food.nutrition(for: amount)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(food.displayName)
                            .font(.headline)
                        if let brand = food.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Menge") {
                    HStack {
                        TextField("Menge", value: $amount, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text(food.servingUnit)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    // Quick-Buttons
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach([50.0, 100.0, 150.0, 200.0], id: \.self) { val in
                            Button {
                                amount = val
                            } label: {
                                Text("\(Int(val))g")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        amount == val
                                        ? Color.accentColor
                                        : Color.tertiaryFill
                                    )
                                    .foregroundStyle(amount == val ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Nährwerte für \(Int(amount))\(food.servingUnit)") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Theme.Spacing.m) {
                        NutritionCell(value: nutrition.calories, label: "kcal", color: .orange)
                        NutritionCell(value: nutrition.protein, label: "Protein", unit: "g", color: .blue)
                        NutritionCell(value: nutrition.carbs, label: "Carbs", unit: "g", color: .green)
                        NutritionCell(value: nutrition.fat, label: "Fett", unit: "g", color: .yellow)
                    }
                }
            }
            .navigationTitle("Menge wählen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        onConfirm(amount)
                    }
                    .fontWeight(.semibold)
                    .disabled(amount <= 0)
                }
            }
        }
    }
}
