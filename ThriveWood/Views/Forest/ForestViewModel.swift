//
//  ForestViewModel.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftUI

@MainActor
@Observable
final class ForestViewModel {
    let env: AppEnvironment

    // Grid-Größe
    let gridWidth: Int = 6
    let gridHeight: Int = 8

    // State
    var forest: Forest?
    var trees: [TreeEntity] = []
    var availablePoints: Int = 0
    var totalEarned: Int = 0
    var coverage: Double = 0

    // Interaktion
    var selectedCell: GridCoord?
    var selectedTree: TreeEntity?
    var showingSpeciesPicker: Bool = false
    var wateringTreeID: UUID?

    let errors = ErrorState()

    struct GridCoord: Hashable { let x: Int; let y: Int }

    init(env: AppEnvironment) { self.env = env }

    // MARK: - Load

    func load() {
        do {
            forest = try env.forestService.currentForest()
            trees = try env.forestService.trees()
            availablePoints = try env.scoringService.availablePoints()
            totalEarned = try env.scoringService.totalEarned()
            coverage = try env.forestService.coverage(
                gridWidth: gridWidth, gridHeight: gridHeight
            )
        } catch { errors.show(error) }
    }

    // MARK: - Lookup

    func tree(at x: Int, y: Int) -> TreeEntity? {
        trees.first { $0.gridX == x && $0.gridY == y }
    }

    func unlockedSpecies() -> [TreeSpecies] {
        (try? env.forestService.unlockedSpecies()) ?? [.oak]
    }

    func cost(for species: TreeSpecies) -> Int {
        env.forestService.cost(toPlant: species)
    }

    func isUnlocked(_ species: TreeSpecies) -> Bool {
        totalEarned >= species.unlockThreshold
    }

    // MARK: - Actions

    func tapCell(x: Int, y: Int) {
        Haptics.selection()
        if let existing = tree(at: x, y: y) {
            selectedTree = existing
        } else {
            selectedCell = GridCoord(x: x, y: y)
            showingSpeciesPicker = true
        }
    }

    func plant(_ species: TreeSpecies) {
        guard let cell = selectedCell else { return }
        do {
            _ = try env.forestService.plant(species: species, at: cell.x, y: cell.y)
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { load() }
            selectedCell = nil
            showingSpeciesPicker = false
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }

    func water(_ tree: TreeEntity, amount: Int = 5) {
        do {
            try env.forestService.water(tree, growthAmount: amount)
            wateringTreeID = tree.id
            Haptics.impact(.soft)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.wateringTreeID = nil
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { load() }
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }

    func remove(_ tree: TreeEntity) {
        do {
            try env.forestService.remove(tree)
            withAnimation(.easeInOut) { load() }
            selectedTree = nil
        } catch { errors.show(error) }
    }
}
