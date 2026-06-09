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
    var color: Color {
        switch self {
        case .green:  .green
        case .mint:   .mint
        case .teal:   .teal
        case .blue:   .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink:   .pink
        case .red:    .red
        case .orange: .orange
        case .yellow: .yellow
        case .brown:  .brown
        case .gray:   .gray
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
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
    // Oberkörper - Vorne
    case chest
    case upperChest
    case shoulders
    case frontDelts
    case sideDelts
    case rearDelts
    case biceps
    case forearms
    case core
    case obliques
    case serratus
    
    // Oberkörper - Hinten
    case lats
    case upperBack
    case midBack
    case lowerBack
    case traps
    case rhomboids
    case triceps
    case rearShoulders
    
    // Unterkörper - Vorne
    case quads
    case hipFlexors
    case adductors
    case tibialis
    
    // Unterkörper - Hinten
    case hamstrings
    case glutes
    case abductors
    case calves
    
    // Spezial
    case neck
    case rotatorCuff
    case fullBody
    case cardio
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .chest: "Brust"
        case .upperChest: "Obere Brust"
        case .shoulders: "Schultern"
        case .frontDelts: "Vordere Schulter"
        case .sideDelts: "Seitliche Schulter"
        case .rearDelts: "Hintere Schulter"
        case .biceps: "Bizeps"
        case .forearms: "Unterarme"
        case .core: "Bauch"
        case .obliques: "Seitliche Bauch"
        case .serratus: "Serratus"
        case .lats: "Latissimus"
        case .upperBack: "Oberer Rücken"
        case .midBack: "Mittlerer Rücken"
        case .lowerBack: "Unterer Rücken"
        case .traps: "Trapezius"
        case .rhomboids: "Rhomboiden"
        case .triceps: "Trizeps"
        case .rearShoulders: "Hintere Schultern"
        case .quads: "Quadrizeps"
        case .hipFlexors: "Hüftbeuger"
        case .adductors: "Adduktoren"
        case .tibialis: "Fußheber"
        case .hamstrings: "Beinbizeps"
        case .glutes: "Gesäß"
        case .abductors: "Abduktoren"
        case .calves: "Waden"
        case .neck: "Nacken"
        case .rotatorCuff: "Rotatorenmansch."
        case .fullBody: "Ganzkörper"
        case .cardio: "Cardio"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .upperChest: "Ob. Brust"
        case .frontDelts: "Vo. Schulter"
        case .sideDelts: "Se. Schulter"
        case .rearDelts: "Hi. Schulter"
        case .rearShoulders: "Hi. Schulter"
        case .upperBack: "Ob. Rücken"
        case .midBack: "Mi. Rücken"
        case .lowerBack: "Un. Rücken"
        case .hipFlexors: "Hüftbeuger"
        case .rotatorCuff: "Rotatoren"
        default: label
        }
    }
    
    var icon: String {
        switch self {
        case .chest, .upperChest: "figure.strengthtraining.traditional"
        case .shoulders, .frontDelts, .sideDelts, .rearDelts, .rearShoulders: "figure.boxing"
        case .biceps: "figure.strengthtraining.functional"
        case .triceps: "figure.highintensity.intervaltraining"
        case .forearms: "hand.raised.fingers.spread.fill"
        case .core, .obliques, .serratus: "figure.core.training"
        case .lats, .upperBack, .midBack, .rhomboids: "figure.rowing"
        case .lowerBack: "figure.flexibility"
        case .traps, .neck: "person.bust.fill"
        case .quads, .hipFlexors: "figure.walk"
        case .hamstrings: "figure.run"
        case .glutes: "figure.stairs"
        case .calves, .tibialis: "shoeprints.fill"
        case .adductors, .abductors: "figure.dance"
        case .rotatorCuff: "arrow.triangle.2.circlepath"
        case .fullBody: "figure.mixed.cardio"
        case .cardio: "heart.fill"
        }
    }
    
    /// Kategorisierung für Gruppierung
    var category: MuscleCategory {
        switch self {
        case .chest, .upperChest, .shoulders, .frontDelts, .sideDelts, .biceps, .forearms, .core, .obliques, .serratus:
            return .upperFront
        case .lats, .upperBack, .midBack, .lowerBack, .traps, .rhomboids, .triceps, .rearDelts, .rearShoulders, .rotatorCuff:
            return .upperBack
        case .quads, .hipFlexors, .adductors, .tibialis:
            return .lowerFront
        case .hamstrings, .glutes, .abductors, .calves:
            return .lowerBack
        case .neck:
            return .neck
        case .fullBody, .cardio:
            return .special
        }
    }
    
    /// Ob Muskel im Diagramm angezeigt wird
    var showInDiagram: Bool {
        self != .fullBody && self != .cardio
    }
    
    /// Ob der Muskel in der Liste unter der Anatomie-Ansicht angezeigt wird
    var showInList: Bool {
        switch self {
        case .fullBody, .cardio:
            return false
        default:
            return true
        }
    }
    
    /// Position im Body-Diagramm (x, y normalisiert 0-1, isFront)
    var bodyPosition: (x: CGFloat, y: CGFloat, isFront: Bool) {
        switch self {
            // Front - Upper Body
        case .neck:         return (0.50, 0.11, true)
        case .traps:        return (0.50, 0.14, true)
        case .chest:        return (0.50, 0.21, true)
        case .upperChest:   return (0.50, 0.18, true)
        case .shoulders:    return (0.26, 0.16, true)
        case .frontDelts:   return (0.26, 0.17, true)
        case .sideDelts:    return (0.24, 0.16, true)
        case .biceps:       return (0.18, 0.26, true)
        case .forearms:     return (0.14, 0.38, true)
        case .serratus:     return (0.32, 0.26, true)
        case .core:         return (0.50, 0.32, true)
        case .obliques:     return (0.36, 0.32, true)
        case .hipFlexors:   return (0.42, 0.42, true)
            
            // Front - Lower Body
        case .quads:        return (0.38, 0.58, true)
        case .adductors:    return (0.50, 0.55, true)
        case .tibialis:     return (0.36, 0.80, true)
            
            // Back - Upper Body
        case .rearDelts:    return (0.25, 0.17, false)
        case .rearShoulders: return (0.25, 0.17, false)
        case .upperBack:    return (0.50, 0.22, false)
        case .lats:         return (0.36, 0.28, false)
        case .midBack:      return (0.50, 0.26, false)
        case .rhomboids:    return (0.50, 0.24, false)
        case .triceps:      return (0.17, 0.26, false)
        case .lowerBack:    return (0.50, 0.38, false)
        case .rotatorCuff:  return (0.28, 0.18, false)
            
            // Back - Lower Body
        case .glutes:       return (0.50, 0.49, false)
        case .abductors:    return (0.32, 0.50, false)
        case .hamstrings:   return (0.38, 0.62, false)
        case .calves:       return (0.37, 0.78, false)
            
        case .fullBody:     return (0.50, 0.50, true)
        case .cardio:       return (0.50, 0.21, true)
        }
    }
    
    
    /// Größen-Faktor für die Visualisierung
    var sizeFactor: CGFloat {
        switch self {
        case .chest, .lats, .quads, .glutes, .hamstrings: return 1.0
        case .shoulders, .core, .upperBack: return 0.85
        case .biceps, .triceps, .calves, .traps: return 0.7
        case .forearms, .obliques, .adductors, .abductors, .lowerBack: return 0.6
        case .neck, .serratus, .hipFlexors, .tibialis, .rotatorCuff: return 0.45
        default: return 0.55
        }
    }
    
    static func resolve(_ groups: [MuscleGroup]) -> [MuscleGroup] {
        groups.flatMap { group -> [MuscleGroup] in
            switch group {
            case .back:
                return [.lats, .upperBack, .midBack]  // Standard-Mapping
            default:
                return [group]
            }
        }
    }
    
    /// Legacy case für Rückwärtskompatibilität
    static var back: MuscleGroup { .lats }
}

enum MuscleCategory: String, CaseIterable {
    case upperFront = "Oberkörper Vorne"
    case upperBack = "Oberkörper Hinten"
    case lowerFront = "Unterkörper Vorne"
    case lowerBack = "Unterkörper Hinten"
    case neck = "Nacken"
    case special = "Spezial"
}


enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, mobility, stretching, plyometrics, balance, other
    var id: String {
        switch self {
        case .strength: "Kraft"
        case .cardio: "Cardio"
        case .mobility: "Mobilität"
        case .stretching: "Dehnen"
        case .plyometrics: "Plyometrisch"
        case .balance: "Balance"
        case .other: "Andere"
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
    case forest, ocean, sunset, lavender, rose
    static var availableInFree: [AccentTheme] = [.forest]
    var id: String { rawValue }
    var label: String {
        switch self {
        case .forest: "Wald"
        case .ocean: "Ozean"
        case .sunset: "Sonne"
        case .lavender: "Lavendel"
        case .rose: "Rosé"
        }
    }
    var color: Color {
        switch self {
        case .forest: .green
        case .ocean: .blue
        case .sunset: .orange
        case .lavender: .purple
        case .rose: .pink
        }
    }
}

enum HabitTrackingMode: String, Codable, CaseIterable, Identifiable {
    /// Einfaches Abhaken (erledigt / nicht erledigt)
    case simple
    /// Zählbar mit Zielwert (z.B. 2000ml Wasser, 10.000 Schritte, 5 Seiten lesen)
    case measurable
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .simple:     "Abhaken"
        case .measurable: "Messbar"
        }
    }
}

/// Vordefinierte Einheiten für messbare Habits.
enum HabitUnit: String, Codable, CaseIterable, Identifiable {
    case milliliters = "ml"
    case liters      = "l"
    case glasses     = "Gläser"
    case steps       = "Schritte"
    case minutes     = "min"
    case hours       = "Std"
    case pages       = "Seiten"
    case times       = "Mal"
    case pieces      = "Stück"
    case kilometers  = "km"
    case calories    = "kcal"
    case custom      = ""
    
    var id: String { rawValue }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case fruits, vegetables, grains, protein, dairy, fats, beverages, snacks, prepared, other
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .fruits: "Obst"
        case .vegetables: "Gemüse"
        case .grains: "Getreide & Brot"
        case .protein: "Protein"
        case .dairy: "Milchprodukte"
        case .fats: "Fette & Öle"
        case .beverages: "Getränke"
        case .snacks: "Snacks"
        case .prepared: "Fertiggerichte"
        case .other: "Sonstiges"
        }
    }
    
    var icon: String {
        switch self {
        case .fruits: "apple.fill"
        case .vegetables: "carrot.fill"
        case .grains: "takeoutbag.and.cup.and.straw.fill"
        case .protein: "fish.fill"
        case .dairy: "mug.fill"
        case .fats: "drop.fill"
        case .beverages: "cup.and.saucer.fill"
        case .snacks: "birthday.cake.fill"
        case .prepared: "fork.knife"
        case .other: "questionmark.circle.fill"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .breakfast: "Frühstück"
        case .lunch: "Mittagessen"
        case .dinner: "Abendessen"
        case .snacks: "Snacks"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.fill"
        case .snacks: "carrot.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: .orange
        case .lunch: .yellow
        case .dinner: .indigo
        case .snacks: .green
        }
    }
}

struct NutritionValues: Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double // mg
    
    static let zero = NutritionValues(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0)
    
    static func + (lhs: NutritionValues, rhs: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodium: lhs.sodium + rhs.sodium
        )
    }
}

struct NutritionGoals: Codable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    static let `default` = NutritionGoals(calories: 2000, protein: 120, carbs: 250, fat: 65)
}

enum SupplementError: LocalizedError {
    case cannotModifyPastEntries
    
    var errorDescription: String? {
        switch self {
        case .cannotModifyPastEntries:
            return "Vergangene Einnahmen können nicht mehr geändert werden."
        }
    }
}


// MARK: Muscle Rankings
enum MuscleRank: Int, CaseIterable, Comparable {
    case untrained = 0
    case bronze = 1
    case silver = 2
    case gold = 3
    case platinum = 4
    case diamond = 5
    case champion = 6
    case legend = 7
    
    static func < (lhs: MuscleRank, rhs: MuscleRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .untrained: "Untrainiert"
        case .bronze: "Bronze"
        case .silver: "Silber"
        case .gold: "Gold"
        case .platinum: "Platin"
        case .diamond: "Diamant"
        case .champion: "Champion"
        case .legend: "Legende"
        }
    }
    
    var icon: String {
        switch self {
        case .untrained: "circle.dotted"
        case .bronze: "shield.fill"
        case .silver: "shield.fill"
        case .gold: "shield.fill"
        case .platinum: "seal.fill"
        case .diamond: "diamond.fill"
        case .champion: "trophy.fill"
        case .legend: "crown.fill"
        }
    }
    
    var minSets: Int {
        switch self {
        case .untrained: 0
        case .bronze: 30
        case .silver: 100
        case .gold: 250
        case .platinum: 500
        case .diamond: 1000
        case .champion: 2000
        case .legend: 4000
        }
    }
    
    var minVolume: Int {
        switch self {
        case .untrained: 0
        case .bronze: 5000
        case .silver: 10000
        case .gold: 25000
        case .platinum: 50000
        case .diamond: 100000
        case .champion: 200000
        case .legend: 400000
        }
    }
    
    // Premium Farbpalette
    var primaryColor: Color {
        switch self {
        case .untrained: Color(white: 0.5)
        case .bronze: Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: Color(red: 0.75, green: 0.77, blue: 0.80)
        case .gold: Color(red: 1.00, green: 0.78, blue: 0.20)
        case .platinum: Color(red: 0.70, green: 0.85, blue: 0.90)
        case .diamond: Color(red: 0.40, green: 0.75, blue: 1.00)
        case .champion: Color(red: 0.95, green: 0.30, blue: 0.40)
        case .legend: Color(red: 0.85, green: 0.55, blue: 1.00)
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .untrained: Color(white: 0.3)
        case .bronze: Color(red: 0.55, green: 0.30, blue: 0.10)
        case .silver: Color(red: 0.55, green: 0.58, blue: 0.62)
        case .gold: Color(red: 0.85, green: 0.55, blue: 0.00)
        case .platinum: Color(red: 0.50, green: 0.70, blue: 0.80)
        case .diamond: Color(red: 0.20, green: 0.45, blue: 0.80)
        case .champion: Color(red: 0.70, green: 0.15, blue: 0.25)
        case .legend: Color(red: 0.60, green: 0.30, blue: 0.85)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .untrained: Color(white: 0.6)
        case .bronze: Color(red: 1.00, green: 0.75, blue: 0.50)
        case .silver: Color.white
        case .gold: Color(red: 1.00, green: 0.95, blue: 0.70)
        case .platinum: Color.white
        case .diamond: Color(red: 0.70, green: 0.92, blue: 1.00)
        case .champion: Color(red: 1.00, green: 0.60, blue: 0.65)
        case .legend: Color(red: 1.00, green: 0.85, blue: 1.00)
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var meshGradient: some ShapeStyle {
        gradient
    }
    
    var glowColor: Color {
        primaryColor.opacity(0.6)
    }
    
    static func fromSets(_ sets: Int) -> MuscleRank {
        for rank in Self.allCases.reversed() {
            if sets >= rank.minSets { return rank }
        }
        return .untrained
    }
    
    static func fromVolume(_ volume: Int) -> MuscleRank {
        for rank in Self.allCases.reversed() {
            if volume >= rank.minVolume { return rank }
        }
        return .untrained
    }
    
    func progressToNext(currentSets: Int) -> Double {
        guard self != .legend else { return 1.0 }
        guard let nextRank = MuscleRank(rawValue: rawValue + 1) else { return 1.0 }
        let range = nextRank.minSets - minSets
        let progress = currentSets - minSets
        return min(1.0, max(0.0, Double(progress) / Double(range)))
    }
    
    func setsToNext(currentSets: Int) -> Int? {
        guard let nextRank = MuscleRank(rawValue: rawValue + 1) else { return nil }
        return max(0, nextRank.minSets - currentSets)
    }
    
    func progressToNext(currentVolume: Int) -> Double {
        guard self != .legend else { return 1.0 }
        guard let nextRank = MuscleRank(rawValue: rawValue + 1) else { return 1.0 }
        let range = nextRank.minVolume - minVolume
        let progress = currentVolume - minVolume
        return min(1.0, max(0.0, Double(progress) / Double(range)))
    }
    
    func volumeToNext(currentVolume: Int) -> Int? {
        guard let nextRank = MuscleRank(rawValue: rawValue + 1) else { return 0 }
        return max(0, nextRank.minVolume - currentVolume)
    }
}


struct MuscleRankingData: Identifiable, Equatable {
    var id: MuscleGroup { muscleGroup }
    let muscleGroup: MuscleGroup
    let totalSets: Int
    let totalVolume: Double  // kg
    let lastWorked: Date?
    let rank: MuscleRank
    let progressToNext: Double
    
    init(muscleGroup: MuscleGroup, totalSets: Int, totalVolume: Double, lastWorked: Date?) {
        self.muscleGroup = muscleGroup
        self.totalSets = totalSets
        self.totalVolume = totalVolume
        self.lastWorked = lastWorked
        self.rank = totalVolume > 0 ? MuscleRank.fromVolume(Int(totalVolume)) : MuscleRank.fromSets(totalSets)
        self.progressToNext = self.rank.progressToNext(currentVolume: Int(totalVolume))
    }
    
    static func == (lhs: MuscleRankingData, rhs: MuscleRankingData) -> Bool {
        lhs.muscleGroup == rhs.muscleGroup && lhs.totalSets == rhs.totalSets
    }
}

enum BodyProportions {
    // Basierend auf dem 8-Kopf-Modell
    static let headHeight: CGFloat = 0.125        // 1/8 der Gesamthöhe
    static let neckHeight: CGFloat = 0.03
    static let torsoHeight: CGFloat = 0.30        // Schulter bis Hüfte
    static let legHeight: CGFloat = 0.47          // Hüfte bis Fuß
    static let armLength: CGFloat = 0.38
    
    static let shoulderWidth: CGFloat = 0.44      // Schulterbreite
    static let hipWidth: CGFloat = 0.28           // Hüftbreite
    static let headWidth: CGFloat = 0.15
    static let neckWidth: CGFloat = 0.08
    static let waistWidth: CGFloat = 0.22
    
    // Y-Positionen (von oben nach unten, 0-1)
    static let headTop: CGFloat = 0.01
    static let headBottom: CGFloat = 0.11
    static let neckBottom: CGFloat = 0.14
    static let shoulderY: CGFloat = 0.16
    static let chestY: CGFloat = 0.22
    static let waistY: CGFloat = 0.38
    static let hipY: CGFloat = 0.44
    static let crotchY: CGFloat = 0.50
    static let kneeY: CGFloat = 0.72
    static let ankleY: CGFloat = 0.94
    static let footY: CGFloat = 0.98
}


enum WorkoutMetric: String, CaseIterable, Identifiable {
    case volume, reps, duration, distance
    var id: String { rawValue }

    var label: String {
        switch self {
        case .volume:   "Volumen"
        case .reps:     "Reps"
        case .duration: "Zeit"
        case .distance: "Distanz"
        }
    }

    var unit: String {
        switch self {
        case .volume: "kg"
        case .reps: ""
        case .duration: "min"
        case .distance: "km"
        }
    }

    var color: Color {
        switch self {
        case .volume:   .blue
        case .reps:     .purple
        case .duration: .pink
        case .distance: .teal
        }
    }

    var icon: String {
        switch self {
        case .volume:   "scalemass.fill"
        case .reps:     "number"
        case .duration: "timer"
        case .distance: "location.fill"
        }
    }
}

enum MeasurablePreset: String, CaseIterable, Identifiable {
    case water, reading, exercise, meditation, steps, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .water:      "Wasser"
        case .reading:    "Lesen"
        case .exercise:   "Bewegung"
        case .meditation: "Meditation"
        case .steps:      "Schritte"
        case .custom:     "Eigene"
        }
    }
    var icon: String {
        switch self {
        case .water: "drop.fill"
        case .reading: "book.fill"
        case .exercise: "figure.walk"
        case .meditation: "brain.head.profile"
        case .steps: "shoeprints.fill"
        case .custom: "slider.horizontal.3"
        }
    }
    var target: Double {
        switch self {
        case .water: 2000
        case .reading: 30
        case .exercise: 30
        case .meditation: 20
        case .steps: 10000
        case .custom: 10
        }
    }
    var increment: Double {
        switch self {
        case .water: 200
        case .reading: 5
        case .exercise: 5
        case .meditation: 5
        case .steps: 1000
        case .custom: 1
        }
    }
    var unit: HabitUnit {
        switch self {
        case .water: .milliliters
        case .reading: .pages
        case .exercise: .minutes
        case .meditation: .minutes
        case .steps: .steps
        case .custom: .custom
        }
    }
}


// MARK: - Activity Profile & Muscle Recovery

enum ActivityProfile: String, CaseIterable, Identifiable {
    case leicht = "leicht"
    case moderat = "moderat"
    case extrem = "extrem"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .leicht: "Leicht"
        case .moderat: "Moderat"
        case .extrem: "Extrem"
        }
    }

    var icon: String {
        switch self {
        case .leicht: "figure.walk"
        case .moderat: "figure.run"
        case .extrem: "figure.highintensity.intervaltraining"
        }
    }

    var maxWeeklyVolumePerMuscle: Double {
        switch self {
        case .leicht: 10000
        case .moderat: 18000
        case .extrem: 28000
        }
    }

    var warningWeeklyVolumePerMuscle: Double {
        switch self {
        case .leicht: 6000
        case .moderat: 12000
        case .extrem: 20000
        }
    }

    var recoveryHours: Double {
        switch self {
        case .leicht: 72
        case .moderat: 48
        case .extrem: 36
        }
    }

    var maxConsecutiveDays: Int {
        switch self {
        case .leicht: 1
        case .moderat: 2
        case .extrem: 3
        }
    }

    var maxDailyVolumePerMuscle: Double {
        switch self {
        case .leicht: 5000
        case .moderat: 8000
        case .extrem: 12000
        }
    }

    var minVolumeForRecoveryCheck: Double {
        switch self {
        case .leicht: 500
        case .moderat: 1000
        case .extrem: 1500
        }
    }
}

enum MuscleRecoveryState {
    case recovered
    case warning
    case needsRest

    var color: Color {
        switch self {
        case .recovered: .green
        case .warning: .orange
        case .needsRest: .red
        }
    }
}

struct MuscleRecoveryData: Identifiable {
    var id: MuscleGroup { muscleGroup }

    let muscleGroup: MuscleGroup
    let weeklyVolume: Double
    let daysSinceLastWorked: Int?
    let consecutiveTrainingDays: Int
    let state: MuscleRecoveryState
    let restReason: MuscleRestReason
    let recommendedRestDays: Int

    var needsRest: Bool { state == .needsRest }
    var isWarning: Bool { state == .warning }

    var restReasonText: String {
        switch restReason {
        case .none:
            return "Keine Pause nötig."
        case .weeklyOverload:
            return "Wöchentliches Volumen (\(formatVol(weeklyVolume))) liegt über dem Limit für dein Profil (\(formatVol(ActivityProfile.current.maxWeeklyVolumePerMuscle)))."
        case .insufficientRecovery:
            let days = daysSinceLastWorked ?? 0
            let required = Int(ActivityProfile.current.recoveryHours / 24.0)
            return "Nur \(days) Tag\(days == 1 ? "" : "e") Ruhe – empfohlen werden \(required) Tag\(required == 1 ? "" : "e")."
        case .consecutiveOverload:
            return "\(consecutiveTrainingDays) Tage hintereinander trainiert. Maximal \(ActivityProfile.current.maxConsecutiveDays) für dein Profil."
        case .dailyOverload:
            return "Tägliches Volumen zu hoch für diesen Muskel."
        case .nearLimit:
            return "Volumen nähert sich dem Limit. \(formatVol(ActivityProfile.current.maxWeeklyVolumePerMuscle - weeklyVolume)) Puffer verbleibend."
        }
    }

    var stateIcon: String {
        switch state {
        case .recovered: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .needsRest: "exclamationmark.triangle.fill"
        }
    }

    private func formatVol(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }
}

enum MuscleRestReason {
    case none
    case weeklyOverload
    case insufficientRecovery
    case consecutiveOverload
    case dailyOverload
    case nearLimit
}

extension ActivityProfile {
    static var current: ActivityProfile {
        get {
            ActivityProfile(rawValue: UserDefaults.standard.string(forKey: "activityProfile") ?? "") ?? .moderat
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "activityProfile")
        }
    }
}
