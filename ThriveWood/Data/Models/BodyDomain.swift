//
//  BodyDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftData
import Foundation

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
