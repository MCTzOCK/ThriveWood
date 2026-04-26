//
//  SharedEnums.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftUI

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
    var fullLabel: String {
        switch self {
        case .monday: "Montag"
        case .tuesday: "Dienstag"
        case .wednesday: "Mittwoch"
        case .thursday: "Donnerstag"
        case .friday: "Freitag"
        case .saturday: "Samstag"
        case .sunday: "Sonntag"
        }
    }
    
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
    var id: String {
        switch self {
        case .chest: "Brust"
        case .back: "Rücken"
        case .shoulders: "Schultern"
        case .biceps: "Bizeps"
        case .triceps: "Trizeps"
        case .forearms: "Unterarme"
        case .core: "Core"
        case .quads: "Quadrizeps"
        case .hamstrings: "Hamstrings"
        case .glutes: "Gluteus"
        case .calves: "Waden"
        case .fullBody: "Ganzkörper"
        case .cardio: "Cardio"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, mobility, stretching, plyometrics, balance
    var id: String {
        switch self {
        case .strength: "Kraft"
        case .cardio: "Cardio"
        case .mobility: "Mobilität"
        case .stretching: "Dehnen"
        case .plyometrics: "Plyometrisch"
        case .balance: "Balance"
        }
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kilograms = "kg", pounds = "lb"
    var id: String { rawValue }
}

enum ExerciseTrackingType: String, Codable, CaseIterable, Identifiable {
    /// Klassisches Krafttraining: Reps + Gewicht (z.B. Bankdrücken)
    case repsWeight
    /// Reine Wiederholungen ohne Gewicht (z.B. Liegestütze, Klimmzüge, Burpees)
    case reps
    /// Zeitbasiert (z.B. Plank, Dehnen, Yoga, Seilspringen)
    case duration
    /// Distanz + Zeit (z.B. Laufen, Radfahren, Rudern, Schwimmen)
    case distanceDuration
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .repsWeight:       "Reps × Gewicht"
        case .reps:             "Wiederholungen"
        case .duration:         "Zeit"
        case .distanceDuration: "Distanz & Zeit"
        }
    }
    
    /// Welche Felder die UI anzeigt
    var showsWeight: Bool   { self == .repsWeight }
    var showsReps: Bool     { self == .repsWeight || self == .reps }
    var showsDuration: Bool { self == .duration || self == .distanceDuration }
    var showsDistance: Bool { self == .distanceDuration }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AccentTheme: String, Codable, CaseIterable, Identifiable {
    case forest, ocean, sunset, lavender, rose, mono
    var id: String { rawValue }
    var label: String {
        switch self {
        case .forest: "Wald"
        case .ocean: "Ozean"
        case .sunset: "Sonne"
        case .lavender: "Lavendel"
        case .rose: "Rosé"
        case .mono: "Monochrom"
        }
    }
    var color: Color {
        switch self {
        case .forest: .green
        case .ocean: .blue
        case .sunset: .orange
        case .lavender: .purple
        case .rose: .pink
        case .mono: .primary
        }
    }
}
