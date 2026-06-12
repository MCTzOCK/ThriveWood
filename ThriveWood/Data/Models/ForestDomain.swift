//
//  ForestDomain.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

@Model
final class Forest {
    var id: UUID = UUID()
    var name: String = "Mein Wald"
    var spentPoints: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \TreeEntity.forest)
    var trees: [TreeEntity]? = []

    init(
        id: UUID = UUID(),
        name: String = "Mein Wald",
        spentPoints: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.spentPoints = spentPoints
        self.createdAt = createdAt
    }
}

@Model
final class TreeEntity {
    var id: UUID = UUID()
    var speciesRaw: String = ""
    var gridX: Int = 0
    var gridY: Int = 0
    var growthPoints: Int = 0
    var plantedAt: Date = Date()
    var nickname: String?

    var forest: Forest?

    init(
        id: UUID = UUID(),
        species: TreeSpecies,
        gridX: Int,
        gridY: Int,
        growthPoints: Int = 0,
        plantedAt: Date = .now,
        nickname: String? = nil,
        forest: Forest? = nil
    ) {
        self.id = id
        self.speciesRaw = species.rawValue
        self.gridX = gridX
        self.gridY = gridY
        self.growthPoints = growthPoints
        self.plantedAt = plantedAt
        self.nickname = nickname
        self.forest = forest
    }

    var species: TreeSpecies {
        get { TreeSpecies(rawValue: speciesRaw) ?? .oak }
        set { speciesRaw = newValue.rawValue }
    }
    var stage: TreeGrowthStage { TreeGrowthStage.stage(forTreePoints: growthPoints) }
}
