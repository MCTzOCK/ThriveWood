//
//  ForestService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

@MainActor
@Observable
final class ForestService {
    private let forestRepo: any ForestRepository
    private let treeRepo: any TreeRepository
    private let scoring: ScoringService

    /// Kosten pro Spezies zum Pflanzen eines Setzlings.
    static let plantingCost: [TreeSpecies: Int] = [
        .oak: 5, .pine: 8, .birch: 10, .maple: 15,
        .willow: 20, .cherry: 30, .sequoia: 50, .bonsai: 80
    ]

    /// Kosten pro Wachstumspunkt beim Gießen.
    static let wateringCostPerGrowth: Int = 1

    init(forestRepo: any ForestRepository, treeRepo: any TreeRepository, scoring: ScoringService) {
        self.forestRepo = forestRepo
        self.treeRepo = treeRepo
        self.scoring = scoring
    }

    // MARK: Read

    func currentForest() throws -> Forest { try forestRepo.currentForest() }
    func trees() throws -> [TreeEntity] { try treeRepo.fetchAll(in: currentForest()) }

    func unlockedSpecies() throws -> [TreeSpecies] {
        let total = try scoring.totalEarned()
        return TreeSpecies.allCases.filter { $0.unlockThreshold <= total }
    }

    func cost(toPlant species: TreeSpecies) -> Int {
        Self.plantingCost[species] ?? 10
    }

    // MARK: Plant

    @discardableResult
    func plant(species: TreeSpecies, at x: Int, y: Int, nickname: String? = nil) throws -> TreeEntity {
        let totalEarned = try scoring.totalEarned()
        guard species.unlockThreshold <= totalEarned
        else { throw ServiceError.speciesLocked(species, requires: species.unlockThreshold) }

        let forest = try currentForest()
        if try treeRepo.tree(at: x, y: y, in: forest) != nil {
            throw ServiceError.gridCellOccupied(x: x, y: y)
        }

        let cost = cost(toPlant: species)
        let available = try scoring.availablePoints()
        guard available >= cost
        else { throw ServiceError.insufficientPoints(required: cost, available: available) }

        let tree = TreeEntity(species: species, gridX: x, gridY: y, forest: forest)
        try treeRepo.add(tree)

        forest.spentPoints += cost
        try forestRepo.update(forest)
        return tree
    }

    // MARK: Water (Wachstum)

    func water(_ tree: TreeEntity, growthAmount: Int = 5) throws {
        let cost = growthAmount * Self.wateringCostPerGrowth
        let available = try scoring.availablePoints()
        guard available >= cost
        else { throw ServiceError.insufficientPoints(required: cost, available: available) }

        tree.growthPoints += growthAmount
        try treeRepo.update(tree)

        let forest = try currentForest()
        forest.spentPoints += cost
        try forestRepo.update(forest)
    }

    // MARK: Remove

    func remove(_ tree: TreeEntity) throws {
        try treeRepo.delete(tree)
    }

    // MARK: Derived

    /// 0...1 Abdeckung des Waldes (für UI-Fortschrittsanzeige).
    func coverage(gridWidth: Int = 8, gridHeight: Int = 8) throws -> Double {
        let count = try trees().count
        let capacity = gridWidth * gridHeight
        return min(1.0, Double(count) / Double(capacity))
    }
}
