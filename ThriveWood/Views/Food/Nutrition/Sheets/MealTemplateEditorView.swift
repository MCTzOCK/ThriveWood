//
//  MealTemplateEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 03.05.26.
//


import SwiftUI

struct MealTemplateEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let template: MealTemplate?
    let initialEntries: [FoodEntry]?

    @State private var name = ""
    @State private var icon = "fork.knife"
    @State private var color: HabitColor = .orange
    @State private var items: [TempItem] = []
    @State private var showAddFood = false
    @State private var isSaving = false

    struct TempItem: Identifiable {
        let id = UUID()
        var food: Food
        var amount: Double
    }

    private let iconOptions = [
        "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
        "carrot.fill", "fish.fill", "leaf.fill", "birthday.cake.fill"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    private var totalNutrition: NutritionValues {
        items.reduce(.zero) { acc, item in
            acc + (item.food.nutrition(for: item.amount))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                itemsSection
                nutritionPreview
            }
            .navigationTitle(template == nil ? "Mahlzeit speichern" : "Mahlzeit bearbeiten")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
            .sheet(isPresented: $showAddFood) {
                FoodSearchView(
                    selectedDate: .now,
                    preselectedMeal: .lunch
                ) { food, amount in
                    items.append(TempItem(food: food, amount: amount))
                }
            }
            .onAppear { hydrate() }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name (z.B. Frühstücks-Bowl)", text: $name)

            // Icon-Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(iconOptions, id: \.self) { iconName in
                        Button {
                            icon = iconName
                        } label: {
                            Image(systemName: iconName)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(icon == iconName ? color.color.opacity(0.2) : Color.tertiaryFill)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(icon == iconName ? color.color : .clear, lineWidth: 2)
                                )
                                .foregroundStyle(icon == iconName ? color.color : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ColorGrid(selection: $color)
        }
    }

    private var itemsSection: some View {
        Section {
            ForEach($items) { $item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.food.displayName)
                            .font(.subheadline)
                        Text("\(Int(item.food.nutrition(for: item.amount).calories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("", value: $item.amount, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indices in
                items.remove(atOffsets: indices)
            }
            .onMove { from, to in
                items.move(fromOffsets: from, toOffset: to)
            }

            Button {
                showAddFood = true
            } label: {
                Label("Zutat hinzufügen", systemImage: "plus")
            }
        } header: {
            HStack {
                Text("Zutaten (\(items.count))")
                Spacer()
                #if os(iOS)
                EditButton()
                    .font(.caption)
                #endif
            }
        }
    }

    private var nutritionPreview: some View {
        Section("Gesamtnährwerte") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.m) {
                NutritionCell(value: totalNutrition.calories, label: "kcal", color: .orange)
                NutritionCell(value: totalNutrition.protein, label: "Protein", unit: "g", color: .blue)
                NutritionCell(value: totalNutrition.carbs, label: "Carbs", unit: "g", color: .green)
                NutritionCell(value: totalNutrition.fat, label: "Fett", unit: "g", color: .yellow)
            }
        }
    }

    // MARK: - Logic

    private func hydrate() {
        if let template {
            name = template.name
            icon = template.iconSystemName
            color = template.color
            items = template.items.compactMap { item in
                guard let food = item.food else { return nil }
                return TempItem(food: food, amount: item.servingAmount)
            }
        } else if let initialEntries {
            items = initialEntries.compactMap { entry in
                guard let food = entry.food else { return nil }
                return TempItem(food: food, amount: entry.servingAmount)
            }
        }
    }

    private func save() {
        isSaving = true
        defer { isSaving = false }

        do {
            if let template {
                // Update bestehende
                template.name = name.trimmingCharacters(in: .whitespaces)
                template.iconSystemName = icon
                template.color = color
                
                // Neue Items erstellen
                let newItems: [MealTemplateItem] = items.enumerated().map { index, item in
                    MealTemplateItem(
                        food: item.food,
                        servingAmount: item.amount,
                        sortOrder: index
                    )
                }
                
                // Service-Methode verwenden
                try env.nutritionService.updateTemplate(template, with: newItems)
            } else {
                // Neu erstellen
                let newTemplate = MealTemplate(
                    name: name.trimmingCharacters(in: .whitespaces),
                    iconSystemName: icon,
                    color: color
                )
                
                for (index, item) in items.enumerated() {
                    let templateItem = MealTemplateItem(
                        food: item.food,
                        servingAmount: item.amount,
                        sortOrder: index
                    )
                    templateItem.template = newTemplate
                    newTemplate.items.append(templateItem)
                }
                
                try env.nutritionService.createTemplate(newTemplate)
            }
            Haptics.success()
            dismiss()
        } catch {
            Haptics.warning()
            print("Save error: \(error)")
        }
    }

}
