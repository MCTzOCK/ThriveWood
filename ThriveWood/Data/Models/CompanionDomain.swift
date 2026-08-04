//
//  CompanionDomain.swift
//  ThriveWood
//
//  „Thrive Companion" — ein einzelnes Wesen (Tamagotchi-Style), das die
//  Konsistenz des Users verkörpert. Energie 0...100, Evolution über aktive
//  Tage. Additive SwiftData-Ergänzung, unberührt vom Wald-System.
//

import Foundation
import SwiftData

/// Wählbare Companion-Arten. Default „fox".
enum CompanionSpecies: String, CaseIterable, Identifiable, Sendable {
    case fox, owl, bear, wolf, deer, highlandCow

    var id: String { rawValue }

    /// Anzeigename.
    var label: String {
        switch self {
        case .fox:        return "Fuchsjunges"
        case .owl:        return "Eulenjunges"
        case .bear:       return "Bärenkeimling"
        case .wolf:       return "Wolfswelpe"
        case .deer:       return "Rehkitz"
        case .highlandCow:return "Highland-Kalb"
        }
    }

    /// Spitzname-Vorschlag.
    var defaultName: String {
        switch self {
        case .fox:        return "Funke"
        case .owl:        return "Weise"
        case .bear:       return "Wurzel"
        case .wolf:       return "Pfad"
        case .deer:       return "Sanft"
        case .highlandCow:return "Moorle"
        }
    }

    /// SF-Symbol für das Wesen (pro Evolutionsstufe skaliert).
    var symbol: String {
        switch self {
        case .fox:        return "figure.play"
        case .owl:        return "bird.fill"
        case .bear:       return "pawprint.fill"
        case .wolf:       return "pawprint.fill"
        case .deer:       return "figure.walk"
        case .highlandCow:return "tortoise.fill"
        }
    }

    /// Akzentfarbe des Wesens.
    var color: String {
        switch self {
        case .fox:        return "orange"
        case .owl:        return "indigo"
        case .bear:       return "brown"
        case .wolf:       return "gray"
        case .deer:       return "pink"
        case .highlandCow:return "brown"
        }
    }
}

/// Evolutionsstufen, abgeleitet aus `activeDaysTotal`.
enum CompanionStage: Int, CaseIterable, Sendable {
    case seedling = 1   // 0–13 aktive Tage
    case juvenile       // 14–44
    case adult          // 45–119
    case enlightened    // 120+

    /// Schwellen der aktiven Tage.
    static let thresholds: [Int] = [0, 14, 45, 120]

    static func stage(forActiveDays days: Int) -> CompanionStage {
        if days >= 120 { return .enlightened }
        if days >= 45  { return .adult }
        if days >= 14  { return .juvenile }
        return .seedling
    }

    var label: String {
        switch self {
        case .seedling:    return "Keimling"
        case .juvenile:    return "Jung"
        case .adult:       return "Erwachsen"
        case .enlightened: return "Erleuchtet"
        }
    }

    var nextThreshold: Int? {
        switch self {
        case .seedling:    return 14
        case .juvenile:    return 45
        case .adult:       return 120
        case .enlightened: return nil
        }
    }
}

/// Zustand des Wesens, abgeleitet aus dem Durchschnitt aller Bedürfnisse
/// (Energie, Hunger, Hygiene, Aktivität, Zutrauen).
enum CompanionMood: Sendable {
    case vibrant   // >= 70
    case content   // >= 40
    case tired     // >= 15
    case critical  // < 15

    /// Berechnet den Mood aus dem Durchschnitt der übergebenen Werte (je 0...100).
    static func mood(energy: Double, hunger: Double, hygiene: Double, fun: Double, bond: Double) -> CompanionMood {
        let avg = (energy + hunger + hygiene + fun + bond) / 5.0
        return mood(forAverage: avg)
    }

    /// Berechnet den Mood aus einem einzelnen 0...100-Wert (Durchschnitt).
    static func mood(forAverage avg: Double) -> CompanionMood {
        if avg >= 70 { return .vibrant }
        if avg >= 40 { return .content }
        if avg >= 15 { return .tired }
        return .critical
    }

    /// Legacy: nur aus Energie (für Code, der noch keinen Zugang zu den
    /// Bedürfnissen hat — z.B. CompanionKit-Brücke).
    static func mood(forEnergy energy: Double) -> CompanionMood {
        mood(forAverage: energy)
    }

    var label: String {
        switch self {
        case .vibrant:  return "voller Energie"
        case .content:  return "zufrieden"
        case .tired:    return "müde"
        case .critical: return "erschöpft"
        }
    }

    var emoji: String {
        switch self {
        case .vibrant:  return "✨"
        case .content:  return "😊"
        case .tired:    return "😴"
        case .critical: return "🥵"
        }
    }
}

@Model
final class Companion {
    @Attribute(.unique) var id: UUID
    var speciesRaw: String
    var name: String
    /// 0...100. Steigt durch Erledigungen/Workouts/Login, sinkt bei
    /// mehrtägiger Inaktivität (lazy Day-Rollover).
    var energy: Double
    /// 1...4 — abgeleitet aus `activeDaysTotal`, hier persistiert, damit
    /// die UI ohne Rechnung zugreifen kann.
    var consistencyLevel: Int
    /// Kumulierte Tage mit ≥1 Erledigung (für Evolution).
    var activeDaysTotal: Int
    /// Letzter Tag, an dem ≥1 Habit/Workout erledigt wurde.
    var lastActiveDay: Date
    /// Letzter Tag, an dem der Login-Bonus gewährt wurde.
    var lastLoginDay: Date
    /// Letzter Tag, für den der Energie-Verfall bereits angewendet wurde.
    var lastEnergyDecayDay: Date
    /// `true`, wenn der tägliche Energie-Verfall pausiert ist (User-Wunsch
    /// in den Einstellungen — gemischte Tonalität respektieren).
    var decayPaused: Bool
    var createdAt: Date

    // MARK: Haustier-Bedürfnisse (0...100, höher = besser)

    /// Sättigung. 0 = hungrig, 100 = satt. Sinkt täglich, gefüllt per feed().
    var hunger: Double = 80
    /// Sauberkeit. 0 = dreckig, 100 = sauber. Sinkt täglich, gefüllt per clean().
    var hygiene: Double = 80
    /// Beschäftigung. 0 = gelangweilt, 100 = beschäftigt. Sinkt täglich,
    /// gefüllt per play() + durch Habit-/Workout-Aktionen.
    var fun: Double = 80
    /// Zutrauen / Bindung. 0 = fremd, 100 = tiefe Bindung. Startet niedrig,
    /// steigt durch Interaktion (streicheln, füttern, spielen).
    var bond: Double = 20

    // MARK: Zeitstempel der letzten Pflegaktion

    var lastFedAt: Date = Date.distantPast
    var lastCleanedAt: Date = Date.distantPast
    var lastPlayedAt: Date = Date.distantPast
    var lastPettedAt: Date = Date.distantPast
    /// Throttle für AI-Sprechblasen.
    var lastSpeechAt: Date = Date.distantPast

    // MARK: Coins & Accessoires

    /// Währung für Accessoires (parallel zu Punkten, damit der Wald
    /// unangetastet bleibt). Verdient durch Habit-/Workout-Aktionen.
    var coins: Int = 0
    /// IDs der gekauften Accessoires (RawIDs aus AccessoryCatalog).
    var ownedAccessoryIDs: [String] = []
    /// RawID des aktuell ausgerüsteten Accessoires (oder nil).
    var equippedAccessoryID: String? = nil

    init(
        id: UUID = UUID(),
        species: CompanionSpecies = .fox,
        name: String = "",
        energy: Double = 60.0,
        consistencyLevel: Int = 1,
        activeDaysTotal: Int = 0,
        lastActiveDay: Date = .distantPast,
        lastLoginDay: Date = .distantPast,
        lastEnergyDecayDay: Date = .now,
        decayPaused: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.speciesRaw = species.rawValue
        self.name = (name.isEmpty ? species.defaultName : name)
        self.energy = energy
        self.consistencyLevel = consistencyLevel
        self.activeDaysTotal = activeDaysTotal
        self.lastActiveDay = lastActiveDay
        self.lastLoginDay = lastLoginDay
        self.lastEnergyDecayDay = lastEnergyDecayDay
        self.decayPaused = decayPaused
        self.createdAt = createdAt
    }

    // MARK: - Derived

    var species: CompanionSpecies {
        get { CompanionSpecies(rawValue: speciesRaw) ?? .fox }
        set { speciesRaw = newValue.rawValue }
    }

    var stage: CompanionStage {
        CompanionStage.stage(forActiveDays: activeDaysTotal)
    }

    /// Mood aus dem Durchschnitt aller Bedürfnisse + Energie.
    var mood: CompanionMood {
        CompanionMood.mood(energy: energy, hunger: hunger, hygiene: hygiene, fun: fun, bond: bond)
    }

    /// Durchschnitt aller 5 Werte (0...100) — für die Gesamtzustands-Anzeige.
    var overallWellbeing: Double {
        (energy + hunger + hygiene + fun + bond) / 5.0
    }

    /// Das aktuell niedrigste Bedürfnis (für AI-Sprechblasen-Priorisierung).
    var lowestNeed: CompanionNeed {
        let values: [(CompanionNeed, Double)] = [
            (.hunger, hunger), (.hygiene, hygiene), (.fun, fun), (.bond, bond), (.energy, energy)
        ]
        return values.min(by: { $0.1 < $1.1 })?.0 ?? .hunger
    }

    var equippedAccessory: AccessoryCatalogItem? {
        guard let raw = equippedAccessoryID else { return nil }
        return AccessoryCatalog.item(rawID: raw)
    }
}

/// Bedürfnis-Arten (für UI-Slots und AI-Priorisierung).
enum CompanionNeed: String, CaseIterable, Sendable {
    case hunger, hygiene, fun, bond, energy

    var label: String {
        switch self {
        case .hunger: return "Hunger"
        case .hygiene: return "Hygiene"
        case .fun:    return "Aktivität"
        case .bond:   return "Zutrauen"
        case .energy: return "Energie"
        }
    }

    var icon: String {
        switch self {
        case .hunger: return "fork.knife"
        case .hygiene: return "drop.degreesign"
        case .fun:    return "tennisball.fill"
        case .bond:   return "heart.fill"
        case .energy: return "bolt.fill"
        }
    }

    var emoji: String {
        switch self {
        case .hunger: return "🍖"
        case .hygiene: return "🛁"
        case .fun:    return "🎾"
        case .bond:   return "❤️"
        case .energy: return "⚡"
        }
    }
}

// MARK: - Accessory Slot & Asset

/// Wo das Accessoire am Körper sitzt.
enum AccessorySlot: String, CaseIterable, Sendable {
    case hat, neck, toy

    var label: String {
        switch self {
        case .hat:  return "Kopf"
        case .neck: return "Hals"
        case .toy:  return "Spielzeug"
        }
    }
}

/// Welches konkrete Asset gerendert wird (CompanionKit-interne Darstellung).
enum AccessoryAsset: String, CaseIterable, Sendable {
    case topHat, partyHat, crown, flowerCrown
    case scarf, bowtie, pearlNecklace
    case ball, bone, featherToy

    var label: String {
        switch self {
        case .topHat:       return "Zylinder"
        case .partyHat:     return "Partyhut"
        case .crown:        return "Krone"
        case .flowerCrown:  return "Blumenkranz"
        case .scarf:        return "Schal"
        case .bowtie:       return "Fliege"
        case .pearlNecklace:return "Perlenkette"
        case .ball:         return "Ball"
        case .bone:         return "Knochen"
        case .featherToy:   return "Federstab"
        }
    }

    var emoji: String {
        switch self {
        case .topHat:       return "🎩"
        case .partyHat:     return "🥳"
        case .crown:        return "👑"
        case .flowerCrown:  return "🌸"
        case .scarf:        return "🧣"
        case .bowtie:       return "🎀"
        case .pearlNecklace:return "📿"
        case .ball:         return "⚽"
        case .bone:         return "🦴"
        case .featherToy:   return "🪶"
        }
    }

    var slot: AccessorySlot {
        switch self {
        case .topHat, .partyHat, .crown, .flowerCrown: return .hat
        case .scarf, .bowtie, .pearlNecklace:           return .neck
        case .ball, .bone, .featherToy:                 return .toy
        }
    }
}

// MARK: - AccessoryCatalogItem

struct AccessoryCatalogItem: Identifiable, Hashable, Sendable {
    let id: String
    let asset: AccessoryAsset
    let cost: Int

    var rawID: String { asset.rawValue }
    var name: String { asset.label }
    var emoji: String { asset.emoji }
    var slot: AccessorySlot { asset.slot }

    static let all: [AccessoryCatalogItem] = [
        .init(id: "topHat",        asset: .topHat,        cost: 50),
        .init(id: "partyHat",      asset: .partyHat,      cost: 80),
        .init(id: "crown",         asset: .crown,         cost: 200),
        .init(id: "flowerCrown",   asset: .flowerCrown,   cost: 120),
        .init(id: "scarf",         asset: .scarf,         cost: 40),
        .init(id: "bowtie",        asset: .bowtie,        cost: 60),
        .init(id: "pearlNecklace", asset: .pearlNecklace, cost: 150),
        .init(id: "ball",          asset: .ball,          cost: 30),
        .init(id: "bone",          asset: .bone,          cost: 30),
        .init(id: "featherToy",    asset: .featherToy,    cost: 45)
    ]

    static func item(rawID: String) -> AccessoryCatalogItem? {
        all.first { $0.rawID == rawID }
    }
}

/// Alias für Code, der „AccessoryCatalog" referenziert (historischer Name).
enum AccessoryCatalog {
    static var all: [AccessoryCatalogItem] { AccessoryCatalogItem.all }
    static func item(rawID: String) -> AccessoryCatalogItem? { AccessoryCatalogItem.item(rawID: rawID) }
}

// MARK: - AccessoryOwnership (SwiftData)

@Model
final class AccessoryOwnership {
    @Attribute(.unique) var id: UUID
    var rawID: String
    var purchasedAt: Date
    var companionID: UUID?

    init(
        id: UUID = UUID(),
        rawID: String,
        purchasedAt: Date = .now,
        companionID: UUID? = nil
    ) {
        self.id = id
        self.rawID = rawID
        self.purchasedAt = purchasedAt
        self.companionID = companionID
    }

    var item: AccessoryCatalogItem? { AccessoryCatalogItem.item(rawID: rawID) }
}
