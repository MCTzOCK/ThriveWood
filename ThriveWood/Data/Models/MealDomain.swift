//
//  MealDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 03.05.26.
//


import Foundation
import SwiftData

@Model
final class MealTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconSystemName: String
    var colorRaw: String
    var usageCount: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MealTemplateItem.template)
    var items: [MealTemplateItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconSystemName: String = "fork.knife",
        color: HabitColor = .orange,
        usageCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorRaw = color.rawValue
        self.usageCount = usageCount
        self.createdAt = createdAt
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .orange }
        set { colorRaw = newValue.rawValue }
    }

    var totalNutrition: NutritionValues {
        items.reduce(.zero) { $0 + $1.nutrition }
    }
}

@Model
final class MealTemplateItem {
    @Attribute(.unique) var id: UUID
    var servingAmount: Double
    var sortOrder: Int

    var food: Food?
    var template: MealTemplate?

    init(
        id: UUID = UUID(),
        food: Food,
        servingAmount: Double,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.food = food
        self.servingAmount = servingAmount
        self.sortOrder = sortOrder
    }

    var nutrition: NutritionValues {
        food?.nutrition(for: servingAmount) ?? .zero
    }
}
