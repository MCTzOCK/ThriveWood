//
//  TreeStyle.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct TreeStyle {
    let canopyColors: [Color]
    let trunkColor: Color
    let canopyShape: CanopyShape
    let layered: Bool

    enum CanopyShape { case round, triangle, teardrop, weeping, umbrella, cloud }
}

extension TreeSpecies {
    var style: TreeStyle {
        switch self {
        case .oak:
            TreeStyle(canopyColors: [Color(red: 0.36, green: 0.60, blue: 0.30),
                                     Color(red: 0.22, green: 0.45, blue: 0.20)],
                      trunkColor: Color(red: 0.36, green: 0.24, blue: 0.14),
                      canopyShape: .cloud, layered: true)
        case .pine:
            TreeStyle(canopyColors: [Color(red: 0.16, green: 0.45, blue: 0.26),
                                     Color(red: 0.10, green: 0.32, blue: 0.18)],
                      trunkColor: Color(red: 0.30, green: 0.20, blue: 0.10),
                      canopyShape: .triangle, layered: true)
        case .birch:
            TreeStyle(canopyColors: [Color(red: 0.70, green: 0.82, blue: 0.45),
                                     Color(red: 0.55, green: 0.70, blue: 0.30)],
                      trunkColor: Color(white: 0.92),
                      canopyShape: .teardrop, layered: false)
        case .maple:
            TreeStyle(canopyColors: [Color(red: 0.88, green: 0.40, blue: 0.18),
                                     Color(red: 0.70, green: 0.22, blue: 0.10)],
                      trunkColor: Color(red: 0.32, green: 0.20, blue: 0.10),
                      canopyShape: .round, layered: true)
        case .willow:
            TreeStyle(canopyColors: [Color(red: 0.55, green: 0.72, blue: 0.45),
                                     Color(red: 0.40, green: 0.58, blue: 0.30)],
                      trunkColor: Color(red: 0.38, green: 0.26, blue: 0.14),
                      canopyShape: .weeping, layered: false)
        case .cherry:
            TreeStyle(canopyColors: [Color(red: 0.98, green: 0.75, blue: 0.85),
                                     Color(red: 0.92, green: 0.55, blue: 0.70)],
                      trunkColor: Color(red: 0.32, green: 0.18, blue: 0.10),
                      canopyShape: .cloud, layered: true)
        case .sequoia:
            TreeStyle(canopyColors: [Color(red: 0.15, green: 0.38, blue: 0.22),
                                     Color(red: 0.08, green: 0.24, blue: 0.14)],
                      trunkColor: Color(red: 0.42, green: 0.18, blue: 0.10),
                      canopyShape: .triangle, layered: true)
        case .bonsai:
            TreeStyle(canopyColors: [Color(red: 0.30, green: 0.55, blue: 0.30),
                                     Color(red: 0.18, green: 0.38, blue: 0.18)],
                      trunkColor: Color(red: 0.28, green: 0.18, blue: 0.08),
                      canopyShape: .umbrella, layered: true)
        }
    }

    var displayName: String {
        switch self {
        case .oak: "Eiche"
        case .pine: "Kiefer"
        case .birch: "Birke"
        case .maple: "Ahorn"
        case .willow: "Weide"
        case .cherry: "Kirschbaum"
        case .sequoia: "Mammutbaum"
        case .bonsai: "Bonsai"
        }
    }
}

extension TreeGrowthStage {
    /// Relativer Größenfaktor (Seed … Ancient).
    var scale: CGFloat {
        switch self {
        case .seed: 0.25
        case .sprout: 0.40
        case .sapling: 0.58
        case .young: 0.75
        case .mature: 0.90
        case .ancient: 1.0
        }
    }

    var label: String {
        switch self {
        case .seed: "Samen"
        case .sprout: "Keimling"
        case .sapling: "Setzling"
        case .young: "Jung"
        case .mature: "Ausgewachsen"
        case .ancient: "Uralt"
        }
    }
}
