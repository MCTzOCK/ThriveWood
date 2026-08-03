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
    case fox, owl, bear, wolf, deer

    var id: String { rawValue }

    /// Anzeigename.
    var label: String {
        switch self {
        case .fox:  return "Fuchsjunges"
        case .owl:  return "Eulenjunges"
        case .bear: return "Bärenkeimling"
        case .wolf: return "Wolfswelpe"
        case .deer: return "Rehkitz"
        }
    }

    /// Spitzname-Vorschlag.
    var defaultName: String {
        switch self {
        case .fox:  return "Funke"
        case .owl:  return "Weise"
        case .bear: return "Wurzel"
        case .wolf: return "Pfad"
        case .deer: return "Sanft"
        }
    }

    /// SF-Symbol für das Wesen (pro Evolutionsstufe skaliert).
    var symbol: String {
        switch self {
        case .fox:  return "figure.play"
        case .owl:  return "bird.fill"
        case .bear: return "pawprint.fill"
        case .wolf: return "pawprint.fill"
        case .deer: return "figure.walk"
        }
    }

    /// Akzentfarbe des Wesens.
    var color: String {
        switch self {
        case .fox:  return "orange"
        case .owl:  return "indigo"
        case .bear: return "brown"
        case .wolf: return "gray"
        case .deer: return "pink"
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

/// Zustand des Wesens, abgeleitet aus `energy`.
enum CompanionMood: Sendable {
    case vibrant   // >= 70
    case content   // >= 40
    case tired     // >= 15
    case critical  // < 15

    static func mood(forEnergy energy: Double) -> CompanionMood {
        if energy >= 70 { return .vibrant }
        if energy >= 40 { return .content }
        if energy >= 15 { return .tired }
        return .critical
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

    var mood: CompanionMood { CompanionMood.mood(forEnergy: energy) }
}
