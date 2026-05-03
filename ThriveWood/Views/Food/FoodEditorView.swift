//
//  FoodEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct FoodEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let food: Food?
    let onSave: (Food) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var barcode = ""
    @State private var category: FoodCategory = .other
    @State private var servingSize: Double = 100
    @State private var servingUnit = "g"

    // Nährwerte pro 100g
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0
    @State private var sugar: Double = 0

    @State private var isSaving = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Name", text: $name)
                    TextField("Marke (optional)", text: $brand)
                    TextField("Barcode (optional)", text: $barcode)
                        .keyboardType(.numberPad)
                    Picker("Kategorie", selection: $category) {
                        ForEach(FoodCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section("Portionsgröße") {
                    HStack {
                        TextField("Menge", value: $servingSize, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Picker("Einheit", selection: $servingUnit) {
                            Text("g").tag("g")
                            Text("ml").tag("ml")
                            Text("Stück").tag("Stück")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Nährwerte pro 100g") {
                    NutrientField(label: "Kalorien", value: $calories, unit: "kcal")
                    NutrientField(label: "Protein", value: $protein, unit: "g")
                    NutrientField(label: "Kohlenhydrate", value: $carbs, unit: "g")
                    NutrientField(label: "Fett", value: $fat, unit: "g")
                    NutrientField(label: "Ballaststoffe", value: $fiber, unit: "g")
                    NutrientField(label: "Zucker", value: $sugar, unit: "g")
                }

                // Makro-Verteilung Preview
                if calories > 0 {
                    Section("Makro-Verteilung") {
                        macroDistribution
                    }
                }
            }
            .navigationTitle(food == nil ? "Lebensmittel erstellen" : "Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                }
            }
            .onAppear { hydrate() }
        }
    }

    private var macroDistribution: some View {
        let proteinCals = protein * 4
        let carbsCals = carbs * 4
        let fatCals = fat * 9
        let total = proteinCals + carbsCals + fatCals

        return GeometryReader { geo in
            HStack(spacing: 2) {
                if total > 0 {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * (proteinCals / total))
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geo.size.width * (carbsCals / total))
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: geo.size.width * (fatCals / total))
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 12)
    }

    private func hydrate() {
        guard let food else { return }
        name = food.name
        brand = food.brand ?? ""
        barcode = food.barcode ?? ""
        category = food.category
        servingSize = food.defaultServingSize
        servingUnit = food.servingUnit
        calories = food.caloriesPer100g
        protein = food.proteinPer100g
        carbs = food.carbsPer100g
        fat = food.fatPer100g
        fiber = food.fiberPer100g
        sugar = food.sugarPer100g
    }

    private func save() {
        isSaving = true
        defer { isSaving = false }

        let newFood = Food(
            id: food?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.isEmpty ? nil : brand,
            barcode: barcode.isEmpty ? nil : barcode,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: fiber,
            sugarPer100g: sugar,
            defaultServingSize: servingSize,
            servingUnit: servingUnit,
            category: category,
            isUserCreated: true
        )

        do {
            try env.nutritionService.saveFood(newFood)
            Haptics.success()
            onSave(newFood)
            dismiss()
        } catch {
            Haptics.warning()
        }
    }
}

struct NutrientField: View {
    let label: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}
