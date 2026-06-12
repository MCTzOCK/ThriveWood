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
    var id: UUID = UUID()
    var date: Date = Date()
    
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
    
    var photoPaths: [String] = []
    var notes: String = ""
    
    var tags: [String]?
    var energyLevel: Int?
    var onPump: Bool = false
    
    var weightUnitRaw: String = "kg"
    var measurementUnitRaw: String = "cm"
    
    init(id: UUID = UUID(), date: Date = Date(), weightUnitRaw: String = "kg", measurementUnitRaw: String = "cm") {
        self.id = id
        self.date = date
        self.photoPaths = []
        self.notes = ""
        self.weightUnitRaw = weightUnitRaw
        self.measurementUnitRaw = measurementUnitRaw
    }
}
