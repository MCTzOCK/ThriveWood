//
//  FoodDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import Foundation
import SwiftData

@Model
final class Food {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var barcode: String?

    // Nährwerte pro 100g
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double
    var sugarPer100g: Double
    var sodiumPer100g: Double // mg

    // Standard-Portionsgröße
    var defaultServingSize: Double // in Gramm
    var servingUnit: String // "g", "ml", "Stück", etc.

    var categoryRaw: String
    var isUserCreated: Bool
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.food)
    var entries: [FoodEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double = 0,
        sugarPer100g: Double = 0,
        sodiumPer100g: Double = 0,
        defaultServingSize: Double = 100,
        servingUnit: String = "g",
        category: FoodCategory = .other,
        isUserCreated: Bool = false,
        isFavorite: Bool = false,
        usageCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumPer100g = sodiumPer100g
        self.defaultServingSize = defaultServingSize
        self.servingUnit = servingUnit
        self.categoryRaw = category.rawValue
        self.isUserCreated = isUserCreated
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.createdAt = createdAt
    }

    var category: FoodCategory {
        get { FoodCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var displayName: String {
        if let brand, !brand.isEmpty { return "\(name) (\(brand))" }
        return name
    }

    // Nährwerte für beliebige Grammzahl
    func nutrition(for grams: Double) -> NutritionValues {
        let factor = grams / 100.0
        return NutritionValues(
            calories: caloriesPer100g * factor,
            protein: proteinPer100g * factor,
            carbs: carbsPer100g * factor,
            fat: fatPer100g * factor,
            fiber: fiberPer100g * factor,
            sugar: sugarPer100g * factor,
            sodium: sodiumPer100g * factor
        )
    }
}

@Model
final class FoodEntry {
    @Attribute(.unique) var id: UUID
    var day: Date
    var mealTypeRaw: String
    var servingAmount: Double // in Gramm
    var loggedAt: Date
    var note: String?

    var food: Food?

    init(
        id: UUID = UUID(),
        food: Food,
        day: Date = .now,
        mealType: MealType = .lunch,
        servingAmount: Double,
        loggedAt: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.food = food
        self.day = Calendar.current.startOfDay(for: day)
        self.mealTypeRaw = mealType.rawValue
        self.servingAmount = servingAmount
        self.loggedAt = loggedAt
        self.note = note
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .lunch }
        set { mealTypeRaw = newValue.rawValue }
    }

    var nutrition: NutritionValues {
        food?.nutrition(for: servingAmount) ?? .zero
    }
}

@Model
final class Supplement {
    @Attribute(.unique) var id: UUID
    var name: String
    var dosage: String // "500mg", "1 Kapsel", etc.
    var details: String
    var iconSystemName: String
    var colorRaw: String

    // Frequenz
    var frequencyRaw: String // daily, custom
    var activeWeekdays: [Int]
    var timesPerDay: Int
    var reminderTimes: [Date]

    var sortOrder: Int
    var createdAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SupplementEntry.supplement)
    var entries: [SupplementEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        details: String = "",
        iconSystemName: String = "pills.fill",
        color: HabitColor = .blue,
        frequency: HabitFrequency = .daily,
        activeWeekdays: [Weekday] = Weekday.allCases,
        timesPerDay: Int = 1,
        reminderTimes: [Date] = [],
        sortOrder: Int = 0,
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.details = details
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.frequencyRaw = frequency.rawValue
        self.activeWeekdays = activeWeekdays.map(\.rawValue)
        self.timesPerDay = timesPerDay
        self.reminderTimes = reminderTimes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }
    var isArchived: Bool { archivedAt != nil }
}

@Model
final class SupplementEntry {
    @Attribute(.unique) var id: UUID
    var day: Date
    var doseNumber: Int // 1. Einnahme, 2. Einnahme, etc.
    var takenAt: Date
    var skipped: Bool

    var supplement: Supplement?

    init(
        id: UUID = UUID(),
        supplement: Supplement,
        day: Date = .now,
        doseNumber: Int = 1,
        takenAt: Date = .now,
        skipped: Bool = false
    ) {
        self.id = id
        self.supplement = supplement
        self.day = Calendar.current.startOfDay(for: day)
        self.doseNumber = doseNumber
        self.takenAt = takenAt
        self.skipped = skipped
    }
}
