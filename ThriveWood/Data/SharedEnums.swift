//
//  SharedEnums.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

enum HabitPoints: Int, Codable, CaseIterable, Identifiable {
    case low = 1, medium = 2, high = 3
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .low: "Leicht (1 Punkt)"
        case .medium: "Mittel (2 Punkte)"
        case .high: "Schwer (3 Punkte)"
        }
    }
}

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily, weekly, custom
    var id: String { rawValue }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 2, tuesday, wednesday, thursday, friday, saturday, sunday = 1
    var id: Int { rawValue }
}

enum HabitColor: String, Codable, CaseIterable, Identifiable {
    case green, mint, teal, blue, indigo, purple, pink, red, orange, yellow, brown, gray
    var id: String { rawValue }
}

enum TreeSpecies: String, Codable, CaseIterable, Identifiable {
    case oak, pine, birch, maple, willow, cherry, sequoia, bonsai
    var id: String { rawValue }
    /// Mindestpunkte, um diese Spezies zu pflanzen.
    var unlockThreshold: Int {
        switch self {
        case .oak: 0
        case .pine: 25
        case .birch: 60
        case .maple: 120
        case .willow: 220
        case .cherry: 400
        case .sequoia: 750
        case .bonsai: 1200
        }
    }
}

enum TreeGrowthStage: Int, Codable, CaseIterable {
    case seed = 0, sprout = 1, sapling = 2, young = 3, mature = 4, ancient = 5

    static func stage(forTreePoints points: Int) -> TreeGrowthStage {
        switch points {
        case ..<5: .seed
        case ..<15: .sprout
        case ..<35: .sapling
        case ..<70: .young
        case ..<150: .mature
        default: .ancient
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, forearms, core,
         quads, hamstrings, glutes, calves, fullBody, cardio
    var id: String { rawValue }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, mobility, stretching, plyometrics, balance
    var id: String { rawValue }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kilograms = "kg", pounds = "lb"
    var id: String { rawValue }
}
