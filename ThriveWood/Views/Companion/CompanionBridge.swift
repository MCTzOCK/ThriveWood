//
//  CompanionBridge.swift
//  ThriveWood
//
//  Bridge: mappt die App-Enums (CompanionSpecies/Stage/Mood aus dem Domain-
//  Model) auf die CompanionKit-eigenen Typen, die die gezeichneten Kreaturen
//  erwarten. Hält CompanionKit frei von App-Abhängigkeiten.
//

import SwiftUI

extension CompanionSpecies {
    var kitType: CompanionSpeciesType {
        CompanionSpeciesType(rawValue: rawValue) ?? .fox
    }
}

extension CompanionStage {
    var kitType: CompanionStageType {
        CompanionStageType(rawValue: rawValue) ?? .seedling
    }
}

extension CompanionMood {
    var kitType: CompanionMoodType {
        switch self {
        case .vibrant:  return .vibrant
        case .content:  return .content
        case .tired:    return .tired
        case .critical: return .critical
        }
    }
}
