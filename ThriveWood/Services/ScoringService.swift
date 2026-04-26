//
//  ScoringService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

@MainActor
@Observable
final class ScoringService {
    private let habitService: HabitService
    private let forestRepo: any ForestRepository
    
    init(habitService: HabitService, forestRepo: any ForestRepository) {
        self.habitService = habitService
        self.forestRepo = forestRepo
    }
    
    /// Gesamt verdient – gesamt ausgegeben = verfügbares Budget für Pflanzungen.
    func availablePoints() throws -> Int {
        let earned = try habitService.totalPointsEarned()
        let spent = try forestRepo.currentForest().spentPoints
        return max(0, earned - spent)
    }
    
    func totalEarned() throws -> Int { try habitService.totalPointsEarned() }
    func totalSpent() throws -> Int { try forestRepo.currentForest().spentPoints }
    
    var totalsCached: (earned: Int, spent: Int) {
        let e = (try? totalEarned()) ?? 0
        let s = (try? totalSpent()) ?? 0
        return (e, s)
    }
}
