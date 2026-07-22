//
//  BodyDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftData
import Foundation
import SwiftUI

@Model
final class BodyProgressEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    var weightKg: Double?
    var bodyFatPercentage: Double?
    var muscleMassKg: Double?
    var waterPercentage: Double?
    
    var heightCm: Double?
    var chestCm: Double?
    var waistCm: Double?
    var hipCm: Double?
    var shoulderCm: Double?
    var neckCm: Double?
    
    var leftBicepCm: Double?
    var rightBicepCm: Double?
    var leftForearmCm: Double?
    var rightForearmCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?
    var leftCalfCm: Double?
    var rightCalfCm: Double?
    
    var photoPaths: [String]
    var notes: String
    
    var tags: [String]? // z.B. "Diät", "Massephase", "Nüchtern"
    var energyLevel: Int? // Skala 1-5 oder 1-10
    var onPump: Bool = false
    
    var weightUnitRaw: String // "kg" oder "lbs"
    var measurementUnitRaw: String // "cm" oder "in"
    
    init(id: UUID = UUID(), date: Date = Date(), weightUnitRaw: String = "kg", measurementUnitRaw: String = "cm") {
        self.id = id
        self.date = date
        self.photoPaths = []
        self.notes = ""
        self.weightUnitRaw = weightUnitRaw
        self.measurementUnitRaw = measurementUnitRaw
    }
}

// MARK: - Wellness Entry

@Model
final class WellnessEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var moodRaw: Int
    var energyRaw: Int
    var sleepQualityRaw: Int
    var stressRaw: Int
    var note: String
    var tagsRaw: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mood: Int = 3,
        energy: Int = 3,
        sleepQuality: Int = 3,
        stress: Int = 3,
        note: String = "",
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.moodRaw = mood
        self.energyRaw = energy
        self.sleepQualityRaw = sleepQuality
        self.stressRaw = stress
        self.note = note
        self.tagsRaw = tags
        self.createdAt = createdAt
    }

    var mood: Int { get { max(1, min(5, moodRaw)) } set { moodRaw = max(1, min(5, newValue)) } }
    var energy: Int { get { max(1, min(5, energyRaw)) } set { energyRaw = max(1, min(5, newValue)) } }
    var sleepQuality: Int { get { max(1, min(5, sleepQualityRaw)) } set { sleepQualityRaw = max(1, min(5, newValue)) } }
    var stress: Int { get { max(1, min(5, stressRaw)) } set { stressRaw = max(1, min(5, newValue)) } }

    var moodEmoji: String {
        switch mood {
        case 1: "😞"
        case 2: "😕"
        case 3: "😐"
        case 4: "🙂"
        case 5: "😄"
        default: "😐"
        }
    }

    var wellnessScore: Double {
        let moodScore = Double(mood)
        let energyScore = Double(energy)
        let sleepScore = Double(sleepQuality)
        let stressScore = Double(6 - stress)
        return (moodScore + energyScore + sleepScore + stressScore) / 4.0
    }

    var tags: [String] {
        get { tagsRaw }
        set { tagsRaw = newValue }
    }
}

enum WellnessMetric: String, CaseIterable, Identifiable {
    case mood, energy, sleep, stress
    var id: String { rawValue }

    var label: String {
        switch self {
        case .mood: "Stimmung"
        case .energy: "Energie"
        case .sleep: "Schlaf"
        case .stress: "Stress"
        }
    }

    var icon: String {
        switch self {
        case .mood: "face.smiling"
        case .energy: "bolt.fill"
        case .sleep: "bed.double.fill"
        case .stress: "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .mood: .yellow
        case .energy: .orange
        case .sleep: .indigo
        case .stress: .red
        }
    }

    func emoji(for value: Int) -> String {
        switch self {
        case .mood:
            switch value {
            case 1: "😞"
            case 2: "😕"
            case 3: "😐"
            case 4: "🙂"
            case 5: "😄"
            default: "😐"
            }
        case .energy:
            switch value {
            case 1: "😵"
            case 2: "😪"
            case 3: "🙂"
            case 4: "😊"
            case 5: "🤩"
            default: "🙂"
            }
        case .sleep:
            switch value {
            case 1: "😩"
            case 2: "🥱"
            case 3: "😴"
            case 4: "🌙"
            case 5: "✨"
            default: "😴"
            }
        case .stress:
            switch value {
            case 1: "🧘"
            case 2: "😌"
            case 3: "🤔"
            case 4: "😰"
            case 5: "🤯"
            default: "🤔"
            }
        }
    }
}
