//
//  NutritionService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import Foundation
import SwiftData
import WidgetKit
import Combine

@MainActor
@Observable
final class NutritionService: ObservableObject {
    private let foodRepo: FoodRepository
    private let entryRepo: FoodEntryRepository
    private let profileRepo: UserProfileRepository
    private let templateRepo: MealTemplateRepository


    var lastUpdate: Date = .now
    
    init(
        foodRepo: FoodRepository,
        entryRepo: FoodEntryRepository,
        profileRepo: UserProfileRepository,
        templateRepo: MealTemplateRepository
    ) {
        self.foodRepo = foodRepo
        self.entryRepo = entryRepo
        self.profileRepo = profileRepo
        self.templateRepo = templateRepo
    }

    // MARK: - Food Management

    func searchLocal(query: String) throws -> [Food] {
        try foodRepo.search(query: query)
    }

    func searchOnline(query: String) async throws -> [Food] {
        try await OpenFoodFactsService.shared.search(query: query)
    }

    func fetchByBarcode(_ barcode: String) async throws -> Food? {
        // Erst lokal suchen
        if let local = try foodRepo.fetch(barcode: barcode) {
            return local
        }
        // Dann online
        return try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode)
    }

    func saveFood(_ food: Food) throws {
        if (try? foodRepo.fetch(id: food.id)) != nil {
            try foodRepo.update(food)
        } else {
            try foodRepo.create(food)
        }
        ThriveWoodUnio.scheduleExport()
    }

    func toggleFavorite(_ food: Food) throws {
        food.isFavorite.toggle()
        try foodRepo.update(food)
        ThriveWoodUnio.scheduleExport()
    }

    func recentFoods(limit: Int = 10) throws -> [Food] {
        try foodRepo.recentFoods(limit: limit)
    }

    func favoriteFoods() throws -> [Food] {
        try foodRepo.favoriteFoods()
    }

    // MARK: - Food Logging

    func logFood(
        _ food: Food,
        amount: Double,
        mealType: MealType,
        date: Date = .now,
        note: String? = nil
    ) throws {
        // Falls es ein Online-Food ist, erst lokal speichern
        if (try? foodRepo.fetch(id: food.id)) == nil {
            try foodRepo.create(food)
        }

        try foodRepo.incrementUsage(food)

        let entry = FoodEntry(
            food: food,
            day: date,
            mealType: mealType,
            servingAmount: amount,
            note: note
        )
        try entryRepo.add(entry)

        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
        ThriveWoodUnio.scheduleExport()
    }

    func deleteEntry(_ entry: FoodEntry) throws {
        try entryRepo.delete(entry)
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
        ThriveWoodUnio.scheduleExport()
    }

    func updateEntry(_ entry: FoodEntry) throws {
        try entryRepo.update(entry)
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
        ThriveWoodUnio.scheduleExport()
    }

    // MARK: - Nutrition Calculation

    func todayEntries() throws -> [FoodEntry] {
        try entryRepo.entries(on: .now)
    }

    func entries(on date: Date) throws -> [FoodEntry] {
        try entryRepo.entries(on: date)
    }

    func entriesGroupedByMeal(on date: Date) throws -> [MealType: [FoodEntry]] {
        let entries = try entryRepo.entries(on: date)
        return Dictionary(grouping: entries, by: \.mealType)
    }

    func totalNutrition(on date: Date) throws -> NutritionValues {
        let entries = try entryRepo.entries(on: date)
        return entries.reduce(.zero) { $0 + $1.nutrition }
    }

    func nutritionByMeal(on date: Date) throws -> [MealType: NutritionValues] {
        let grouped = try entriesGroupedByMeal(on: date)
        var result: [MealType: NutritionValues] = [:]
        for (meal, entries) in grouped {
            result[meal] = entries.reduce(.zero) { $0 + $1.nutrition }
        }
        return result
    }

    func goals() throws -> NutritionGoals {
        let profile = try profileRepo.currentProfile()
        return profile.nutritionGoals ?? .default
    }

    func updateGoals(_ goals: NutritionGoals) throws {
        let profile = try profileRepo.currentProfile()
        profile.nutritionGoals = goals
        try profileRepo.update(profile)
    }

    // MARK: - Weekly Stats

    func weeklyNutrition() throws -> [(date: Date, nutrition: NutritionValues)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var result: [(Date, NutritionValues)] = []

        for i in (0..<7).reversed() {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let nutrition = try totalNutrition(on: date)
            result.append((date, nutrition))
        }
        return result
    }

    func averageNutrition(days: Int = 7) throws -> NutritionValues {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var totals: [NutritionValues] = []

        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            totals.append(try totalNutrition(on: date))
        }

        guard !totals.isEmpty else { return .zero }
        let sum = totals.reduce(.zero, +)
        let count = Double(totals.count)

        return NutritionValues(
            calories: sum.calories / count,
            protein: sum.protein / count,
            carbs: sum.carbs / count,
            fat: sum.fat / count,
            fiber: sum.fiber / count,
            sugar: sum.sugar / count,
            sodium: sum.sodium / count
        )
    }
    
    // MARK: - Meal Templates

    func allTemplates() throws -> [MealTemplate] {
        try templateRepo.fetchAll()
    }

    func createTemplate(_ template: MealTemplate) throws {
        try templateRepo.create(template)
        lastUpdate = .now
        ThriveWoodUnio.scheduleExport()
    }

    func updateTemplate(_ template: MealTemplate) throws {
        try templateRepo.update(template)
        lastUpdate = .now
        ThriveWoodUnio.scheduleExport()
    }

    func deleteTemplate(_ template: MealTemplate) throws {
        try templateRepo.delete(template)
        lastUpdate = .now
        ThriveWoodUnio.scheduleExport()
    }

    /// Loggt alle Items eines Templates als einzelne FoodEntries
    func logMealTemplate(
        _ template: MealTemplate,
        mealType: MealType,
        date: Date = .now,
        portionMultiplier: Double = 1.0
    ) throws {
        for item in template.items.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            guard let food = item.food else { continue }
            
            let entry = FoodEntry(
                food: food,
                day: date,
                mealType: mealType,
                servingAmount: item.servingAmount * portionMultiplier,
                note: "aus \(template.name)"
            )
            try entryRepo.add(entry)
        }
        
        try templateRepo.incrementUsage(template)
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
        ThriveWoodUnio.scheduleExport()
    }

    func updateTemplate(_ template: MealTemplate, with newItems: [MealTemplateItem]) throws {
        // Alte Items entfernen
        for item in template.items {
            try templateRepo.deleteItem(item)
        }
        template.items.removeAll()
        
        // Neue Items hinzufügen
        for item in newItems {
            item.template = template
            template.items.append(item)
        }
        
        try templateRepo.update(template)
        lastUpdate = .now
        ThriveWoodUnio.scheduleExport()
    }
    
    /// Erstellt ein Template aus bestehenden Entries
    func createTemplateFromEntries(
        name: String,
        entries: [FoodEntry],
        icon: String = "fork.knife",
        color: HabitColor = .orange
    ) throws -> MealTemplate {
        let template = MealTemplate(
            name: name,
            iconSystemName: icon,
            color: color
        )
        
        for (index, entry) in entries.enumerated() {
            guard let food = entry.food else { continue }
            let item = MealTemplateItem(
                food: food,
                servingAmount: entry.servingAmount,
                sortOrder: index
            )
            item.template = template
            template.items.append(item)
        }
        
        try templateRepo.create(template)
        lastUpdate = .now
        ThriveWoodUnio.scheduleExport()
        return template
    }

}
