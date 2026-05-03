//
//  FoodLogSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct FoodLogSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let food: Food
    let date: Date
    let mealType: MealType
    let onLogged: () -> Void

    @State private var servingAmount: Double
    @State private var selectedMeal: MealType
    @State private var note: String = ""
    @State private var isSaving = false

    init(food: Food, date: Date, mealType: MealType, onLogged: @escaping () -> Void) {
        self.food = food
        self.date = date
        self.mealType = mealType
        self.onLogged = onLogged
        self._servingAmount = State(initialValue: food.defaultServingSize)
        self._selectedMeal = State(initialValue: mealType)
    }

    private var nutrition: NutritionValues {
        food.nutrition(for: servingAmount)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Food Info
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

                // Menge
                Section("Menge") {
                    HStack {
                        TextField("Menge", value: $servingAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text(food.servingUnit)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Quick-Buttons
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach([50.0, 100.0, 150.0, 200.0], id: \.self) { amount in
                            Button {
                                servingAmount = amount
                            } label: {
                                Text("\(Int(amount))g")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        servingAmount == amount
                                        ? Color.accentColor
                                        : Color(.tertiarySystemFill)
                                    )
                                    .foregroundStyle(servingAmount == amount ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Mahlzeit
                Section("Mahlzeit") {
                    Picker("", selection: $selectedMeal) {
                        ForEach(MealType.allCases) { meal in
                            Label(meal.label, systemImage: meal.icon).tag(meal)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // Nährwerte
                Section("Nährwerte für \(Int(servingAmount))\(food.servingUnit)") {
                    nutritionGrid
                }

                // Notiz
                Section("Notiz (optional)") {
                    TextField("z.B. mit Hafermilch", text: $note)
                }
            }
            .navigationTitle("Hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving || servingAmount <= 0)
                }
            }
        }
    }

    private var nutritionGrid: some View {
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

    private func save() {
        isSaving = true
        do {
            try env.nutritionService.logFood(
                food,
                amount: servingAmount,
                mealType: selectedMeal,
                date: date,
                note: note.isEmpty ? nil : note
            )
            Haptics.success()
            onLogged()
        } catch {
            Haptics.warning()
        }
        isSaving = false
    }
}

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
