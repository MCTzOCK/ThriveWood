//
//  CompanionService.swift
//  ThriveWood
//
//  „Thrive Companion" — Service, der Energie, aktive Tage und Evolution
//  verwaltet. Wird an bestehende Trigger (Habit/Workout/Login/Tagesziel)
//  angebunden. Energie steigt durch Erledigungen, sinkt bei mehrtägiger
//  Inaktivität (lazy Day-Rollover on appear — kein BG-Task nötig).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class CompanionService {
    private let repo: any CompanionRepository

    /// Tunbare Energie-Regeln (finetunbar).
    enum Config {
        static let energyCap: Double = 100
        static let habitGain: Double = 6
        static let workoutGain: Double = 12
        static let dailyGoalBonus: Double = 15
        static let loginBonus: Double = 3
        /// Verfall pro verpassten Tag (ab Tag 2 der Inaktivität).
        static let dailyDecay: Double = 8
    }

    /// `true`, sobald mindestens eine Energie-Änderung ausgelöst wurde
    /// (für UI-Animationen / Haptik).
    private(set) var lastDelta: Double = 0

    init(repo: any CompanionRepository) {
        self.repo = repo
    }

    // MARK: - Read

    func current() throws -> Companion { try repo.currentCompanion() }

    // MARK: - Trigger

    /// Habit erledigt (toggle oder increment-Schritt, der ≥0 Punkte bringt).
    func feedHabit(pointsDelta: Int) {
        guard pointsDelta > 0 else { return }
        apply(gain: Config.habitGain)
    }

    /// Workout abgeschlossen.
    func feedWorkout() {
        apply(gain: Config.workoutGain)
    }

    /// Tagesziel erreicht — zusätzlicher Bonus.
    func onDailyGoalReached() {
        apply(gain: Config.dailyGoalBonus)
    }

    /// Täglicher Login-Bonus (einmal pro Tag). Aufruf beim App-Start.
    func onAppAppear() {
        processDayRollover()
        grantLoginBonusIfNeeded()
    }

    // MARK: - Internals

    /// Wendet eine Energie-Zunahme an und markiert den heutigen Tag als aktiv.
    private func apply(gain: Double) {
        do {
            let c = try repo.currentCompanion()
            c.energy = min(Config.energyCap, c.energy + gain)
            lastDelta = gain
            markActiveDay(c)
            try repo.update(c)
        } catch {
            #if DEBUG
            print("[CompanionService] apply failed: \(error)")
            #endif
        }
    }

    /// Erkennt einen neu aktiven Tag (≥1 Erledigung) und zählt
    /// `activeDaysTotal` hoch → treibt die Evolution.
    private func markActiveDay(_ c: Companion) {
        let today = Calendar.app.startOfDay(for: .now)
        let last = Calendar.app.startOfDay(for: c.lastActiveDay)
        if today != last {
            c.activeDaysTotal += 1
            c.lastActiveDay = today
            c.consistencyLevel = CompanionStage.stage(forActiveDays: c.activeDaysTotal).rawValue
        }
    }

    /// Gewährt den täglichen Login-Bonus, falls heute noch nicht geschehen.
    private func grantLoginBonusIfNeeded() {
        do {
            let c = try repo.currentCompanion()
            let today = Calendar.app.startOfDay(for: .now)
            let last = Calendar.app.startOfDay(for: c.lastLoginDay)
            guard today != last else { return }
            c.energy = min(Config.energyCap, c.energy + Config.loginBonus)
            c.lastLoginDay = today
            try repo.update(c)
        } catch {
            #if DEBUG
            print("[CompanionService] login bonus failed: \(error)")
            #endif
        }
    }

    /// Holt fehlende Tage seit dem letzten Decay nach (lazy, beim App-Start).
    /// Ab dem 2. Inaktivitätstag sinkt die Energie um `dailyDecay` pro Tag.
    /// 1 Erledigung/Tag stoppt den Verfall bereits.
    private func processDayRollover() {
        do {
            let c = try repo.currentCompanion()
            guard !c.decayPaused else {
                c.lastEnergyDecayDay = Calendar.app.startOfDay(for: .now)
                try repo.update(c)
                return
            }

            let cal = Calendar.app
            let today = cal.startOfDay(for: .now)
            var lastDecay = cal.startOfDay(for: c.lastEnergyDecayDay)
            let lastActive = cal.startOfDay(for: c.lastActiveDay)

            // Tage seit letztem Decay durchlaufen (mit Cap, damit nach sehr
            // langer Pause nicht hunderte Tage abgezogen werden).
            var missingDays = 0
            while lastDecay < today {
                lastDecay = cal.date(byAdding: .day, value: 1, to: lastDecay) ?? lastDecay
                missingDays += 1
                if missingDays > 30 { break }
            }

            if missingDays > 0 {
                // Ab dem 2. Tag ohne Aktivität fällt Energie. Ein Tag, an dem
                // aktiv war (`lastActive == lastDecay`), zählt nicht als Pause.
                var decayDays = 0
                var walk = cal.startOfDay(for: c.lastEnergyDecayDay)
                for _ in 0..<missingDays {
                    walk = cal.date(byAdding: .day, value: 1, to: walk) ?? walk
                    let inactive = walk != lastActive && walk != today
                        && !wasActiveOnOrAfter(c, walk, calendar: cal)
                    // Tag gilt als Pause, wenn weder Aktivität noch heute
                    // („heute" wird erst bei der nächsten Erledigung aktiv).
                    if inactive && walk != today {
                        decayDays += 1
                    }
                }
                // Erster Inaktivitätstag ist gratis (Tag 1), ab Tag 2 decay.
                let chargeable = max(0, decayDays - 1)
                if chargeable > 0 {
                    c.energy = max(0, c.energy - Double(chargeable) * Config.dailyDecay)
                    lastDelta = -Double(chargeable) * Config.dailyDecay
                }
                c.lastEnergyDecayDay = today
                try repo.update(c)
            }
        } catch {
            #if DEBUG
            print("[CompanionService] day rollover failed: \(error)")
            #endif
        }
    }

    /// Hilfsprüfung: war der Companion an `day` (oder danach, bis heute)
    /// bereits aktiv? Wir tracken nur `lastActiveDay`, daher gilt: aktiv,
    /// falls `day == lastActiveDay` oder `day >= lastActiveDay` (dann war
    /// mindestens eine spätere Erledigung, die den Verfall ab dann stoppt).
    private func wasActiveOnOrAfter(_ c: Companion, _ day: Date, calendar: Calendar) -> Bool {
        let d = calendar.startOfDay(for: day)
        let last = calendar.startOfDay(for: c.lastActiveDay)
        return d >= last
    }

    // MARK: - Setup / Wahl

    @discardableResult
    func choose(species: CompanionSpecies, name: String) throws -> Companion {
        try repo.choose(species: species, name: name)
    }

    func rename(_ name: String) {
        do {
            let c = try repo.currentCompanion()
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            c.name = trimmed.isEmpty ? c.species.defaultName : trimmed
            try repo.update(c)
        } catch {
            #if DEBUG
            print("[CompanionService] rename failed: \(error)")
            #endif
        }
    }

    func setDecayPaused(_ paused: Bool) {
        do {
            let c = try repo.currentCompanion()
            c.decayPaused = paused
            try repo.update(c)
        } catch {
            #if DEBUG
            print("[CompanionService] setDecayPaused failed: \(error)")
            #endif
        }
    }
}
