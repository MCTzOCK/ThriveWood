//
//  CompanionViewModel.swift
//  ThriveWood
//
//  View-Model für die Companion-Karte (Home) und CompanionView (Detail).
//  Lädt das Companion, spiegelt die relevanten Felder als Werttypen in die
//  UI und sorgt für saubere @Observable-Updates.
//

import SwiftUI

@MainActor
@Observable
final class CompanionViewModel {
    private let env: AppEnvironment

    var species: CompanionSpecies = .fox
    var name: String = ""
    var energy: Double = 60
    var stage: CompanionStage = .seedling
    var activeDaysTotal: Int = 0
    var decayPaused: Bool = false
    var mood: CompanionMood = .content

    var loaded: Bool = false
    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    func load() {
        do {
            let c = try env.companionService.current()
            species = c.species
            name = c.name
            energy = c.energy
            stage = CompanionStage.stage(forActiveDays: c.activeDaysTotal)
            activeDaysTotal = c.activeDaysTotal
            decayPaused = c.decayPaused
            mood = CompanionMood.mood(forEnergy: c.energy)
            loaded = true
        } catch {
            errors.show(error)
        }
    }

    // MARK: - Evolution

    /// Fortschritt zur nächsten Evolutionsstufe (0...1).
    var nextStageProgress: Double {
        guard let next = stage.nextThreshold else { return 1 }
        let current = CompanionStage.thresholds.firstIndex(of: next).map {
            CompanionStage.thresholds[max(0, $0 - 1)]
        } ?? 0
        let span = next - current
        guard span > 0 else { return 1 }
        return min(1, Double(activeDaysTotal - current) / Double(span))
    }

    var nextStageLabel: String {
        guard let next = stage.nextThreshold else { return "Maximale Stufe erreicht" }
        return "Nächste Stufe in \(max(0, next - activeDaysTotal)) aktiven Tagen"
    }

    // MARK: - Aktionen

    func rename(_ newName: String) {
        env.companionService.rename(newName)
        load()
    }

    func toggleDecayPaused() {
        env.companionService.setDecayPaused(!decayPaused)
        load()
    }

    func choose(species: CompanionSpecies, name: String) {
        do {
            _ = try env.companionService.choose(species: species, name: name)
            load()
        } catch {
            errors.show(error)
        }
    }
}
