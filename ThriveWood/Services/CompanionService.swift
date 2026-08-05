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
        static let cap: Double = 100
        static let habitGain: Double = 6
        static let workoutGain: Double = 12
        static let dailyGoalBonus: Double = 15
        static let loginBonus: Double = 3
        /// Verfall pro verpassten Tag (ab Tag 2 der Inaktivität).
        static let dailyDecay: Double = 8

        // Haustier-Bedürfnisse
        /// Bedürfnis-Verfall pro verpassten Tag (Hunger/Hygiene/Fun).
        static let dailyNeedDecay: Double = 15
        /// Wie viel eine Pflegaktion auffüllt (0...100).
        static let feedAmount: Double = 35
        static let cleanAmount: Double = 40
        static let playAmount: Double = 35
        static let petBondGain: Double = 4
        /// Wie viel Bond andere Aktionen geben.
        static let feedBondGain: Double = 1.5
        static let cleanBondGain: Double = 1.0
        static let playBondGain: Double = 2.0
        /// Cooldowns für Pflegaktionen (Sekunden).
        static let feedCooldown: TimeInterval = 60
        static let cleanCooldown: TimeInterval = 60
        static let playCooldown: TimeInterval = 60
        static let petCooldown: TimeInterval = 5

        // Coins
        static let coinsPerHabit: Int = 5
        static let coinsPerWorkout: Int = 10
        static let coinsPerDailyGoal: Int = 20
        static let coinsPerLogin: Int = 2
        /// Kosten der Pflegaktionen in Coins. Streicheln bleibt kostenlos
        /// (reine Zutrauens-Aktion). Die anderen erzeugen eine Währungssenke,
        /// damit Coins nicht nur ausgegeben, sondern auch verbraucht werden.
        static let feedCost: Int = 3
        static let cleanCost: Int = 4
        static let playCost: Int = 3

        // Speech
        static let speechThrottle: TimeInterval = 60
    }

    /// `true`, sobald mindestens eine Energie-Änderung ausgelöst wurde
    /// (für UI-Animationen / Haptik).
    private(set) var lastDelta: Double = 0

    /// Gespiegelte Werte für direkte UI-Observation. Werden bei jeder
    /// Änderung aktualisiert, sodass Views (z.B. CompanionCard) live
    /// reagieren, ohne manuell neu laden zu müssen.
    private(set) var energy: Double = 60
    private(set) var hunger: Double = 80
    private(set) var hygiene: Double = 80
    private(set) var fun: Double = 80
    private(set) var bond: Double = 20
    private(set) var name: String = ""
    private(set) var species: CompanionSpecies = .fox
    private(set) var stage: CompanionStage = .seedling
    private(set) var activeDaysTotal: Int = 0
    private(set) var mood: CompanionMood = .content
    private(set) var decayPaused: Bool = false
    private(set) var coins: Int = 0
    private(set) var ownedAccessoryIDs: [String] = []
    private(set) var equippedAccessoryID: String? = nil
    /// Aktuelle Sprechblase (AI-generiert oder Template). nil = keine sichtbar.
    private(set) var speechBubble: String? = nil
    /// Das aktuell ausgerüstete Accessoire (aufgelöst aus equippedAccessoryID).
    var equippedAccessory: AccessoryCatalogItem? {
        guard let raw = equippedAccessoryID else { return nil }
        return AccessoryCatalogItem.item(rawID: raw)
    }
    /// Letzte Pflegaktion-Zeitstempel (für Cooldown-Anzeige in der UI).
    private(set) var lastFedAt: Date = .distantPast
    private(set) var lastCleanedAt: Date = .distantPast
    private(set) var lastPlayedAt: Date = .distantPast
    private(set) var lastPettedAt: Date = .distantPast
    /// Letzte Reaktion (für Animations-Trigger im Tier). nil = keine.
    private(set) var lastReaction: CompanionReaction? = nil
    /// Letzte Pflegaktion (für die sofortige Reaktions-Sprechblase in der UI).
    /// nil = keine. Wird von der UI nach kurzer Zeit ignoriert.
    private(set) var lastCareAction: CompanionCareAction? = nil
    /// Monoton wachsender Trigger — Views können darauf .animation(value:)
    /// setzen, um auf jegliche Companion-Änderung zu reagieren.
    private(set) var revision: Int = 0

    init(repo: any CompanionRepository) {
        self.repo = repo
        syncSnapshot()
    }

    // MARK: - Read

    func current() throws -> Companion { try repo.currentCompanion() }

    /// Aktualisiert die gespiegelten Werte aus dem persistenten Companion.
    private func syncSnapshot() {
        guard let c = try? repo.currentCompanion() else { return }
        energy = c.energy
        hunger = c.hunger
        hygiene = c.hygiene
        fun = c.fun
        bond = c.bond
        name = c.name
        species = c.species
        activeDaysTotal = c.activeDaysTotal
        stage = CompanionStage.stage(forActiveDays: c.activeDaysTotal)
        mood = c.mood
        decayPaused = c.decayPaused
        coins = c.coins
        ownedAccessoryIDs = c.ownedAccessoryIDs
        equippedAccessoryID = c.equippedAccessoryID
        lastFedAt = c.lastFedAt
        lastCleanedAt = c.lastCleanedAt
        lastPlayedAt = c.lastPlayedAt
        lastPettedAt = c.lastPettedAt
        revision &+= 1
    }

    // MARK: - Trigger

    /// Habit erledigt (toggle oder increment-Schritt, der ≥0 Punkte bringt).
    func feedHabit(pointsDelta: Int) {
        guard pointsDelta > 0 else { return }
        apply(gain: Config.habitGain) { c in
            // Ein erledigter Habit beschäftigt das Tier leicht + kleines
            // Zutrauen durch die gemeinsame Routine.
            c.fun = min(Config.cap, c.fun + 3)
            c.bond = min(Config.cap, c.bond + 0.5)
            c.coins &+= Config.coinsPerHabit
        }
    }

    /// Workout abgeschlossen.
    func feedWorkout() {
        apply(gain: Config.workoutGain) { c in
            c.fun = min(Config.cap, c.fun + 8)
            c.bond = min(Config.cap, c.bond + 1.0)
            c.coins &+= Config.coinsPerWorkout
        }
    }

    /// Tagesziel erreicht — zusätzlicher Bonus.
    func onDailyGoalReached() {
        apply(gain: Config.dailyGoalBonus) { c in
            c.fun = min(Config.cap, c.fun + 5)
            c.bond = min(Config.cap, c.bond + 2.0)
            c.coins &+= Config.coinsPerDailyGoal
        }
    }

    /// Täglicher Login-Bonus (einmal pro Tag). Aufruf beim App-Start.
    func onAppAppear() {
        processDayRollover()
        grantLoginBonusIfNeeded()
    }

    // MARK: - Internals

    /// Wendet eine Energie-Zunahme an und markiert den heutigen Tag als aktiv.
    private func apply(gain: Double, extras: ((Companion) -> Void)? = nil) {
        do {
            let c = try repo.currentCompanion()
            c.energy = min(Config.cap, c.energy + gain)
            lastDelta = gain
            extras?(c)
            markActiveDay(c)
            try repo.update(c)
            syncSnapshot()
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
            c.energy = min(Config.cap, c.energy + Config.loginBonus)
            c.bond = min(Config.cap, c.bond + 0.5)
            c.coins &+= Config.coinsPerLogin
            c.lastLoginDay = today
            try repo.update(c)
            syncSnapshot()
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
            syncSnapshot()
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

                // Haustier-Bedürfnisse verfallen jeden verpassten Tag (auch
                // ohne Inaktivität — das ist die Kern-Pflege-Mechanik).
                // missingDays = Tage seit letztem Rollover. Davon ist „heute"
                // noch nicht voll verstrichen → nur (missingDays) Tage decay.
                let needDays = max(0, missingDays)
                if needDays > 0 {
                    let drop = Double(needDays) * Config.dailyNeedDecay
                    c.hunger = max(0, c.hunger - drop)
                    c.hygiene = max(0, c.hygiene - drop)
                    c.fun = max(0, c.fun - drop)
                    // Bei niedriger Energie/Mood sinkt auch Bond leicht.
                    let wellbeing = (c.energy + c.hunger + c.hygiene + c.fun + c.bond) / 5.0
                    if wellbeing < 30 {
                        c.bond = max(0, c.bond - Double(needDays) * 2)
                    }
                }

                c.lastEnergyDecayDay = today
                try repo.update(c)
            syncSnapshot()
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

    // MARK: - Pflege-Aktionen (Haustier)

    /// Füttern. Kostet Coins, füllt Hunger + kleines Bond. Cooldown-gated.
    @discardableResult
    func feed() -> Bool {
        let ok = performCare(\.lastFedAt, cooldown: Config.feedCooldown, coinCost: Config.feedCost, action: .feed) { c in
            c.hunger = min(Config.cap, c.hunger + Config.feedAmount)
            c.bond = min(Config.cap, c.bond + Config.feedBondGain)
            c.lastFedAt = .now
        }
        if ok { setReaction(.eats) }
        return ok
    }

    /// Pflegen (baden/bürsten). Kostet Coins, füllt Hygiene + kleines Bond.
    @discardableResult
    func clean() -> Bool {
        let ok = performCare(\.lastCleanedAt, cooldown: Config.cleanCooldown, coinCost: Config.cleanCost, action: .clean) { c in
            c.hygiene = min(Config.cap, c.hygiene + Config.cleanAmount)
            c.bond = min(Config.cap, c.bond + Config.cleanBondGain)
            c.lastCleanedAt = .now
        }
        if ok { setReaction(.bubbles) }
        return ok
    }

    /// Spielen. Kostet Coins, füllt Fun + Bond.
    @discardableResult
    func play() -> Bool {
        let ok = performCare(\.lastPlayedAt, cooldown: Config.playCooldown, coinCost: Config.playCost, action: .play) { c in
            c.fun = min(Config.cap, c.fun + Config.playAmount)
            c.bond = min(Config.cap, c.bond + Config.playBondGain)
            c.lastPlayedAt = .now
        }
        if ok { setReaction(.plays) }
        return ok
    }

    /// Streicheln. Kostenlos (reine Zutrauens-Aktion), kurzer Cooldown.
    @discardableResult
    func pet() -> Bool {
        let ok = performCare(\.lastPettedAt, cooldown: Config.petCooldown, coinCost: 0, action: .pet) { c in
            c.bond = min(Config.cap, c.bond + Config.petBondGain)
            c.lastPettedAt = .now
        }
        if ok { setReaction(.hearts) }
        return ok
    }

    /// Generische Care-Aktion mit Cooldown + Coin-Kosten. `true` bei Erfolg,
    /// `false` wenn im Cooldown oder zu wenige Coins (UI gibt Feedback).
    @discardableResult
    private func performCare(_ keyPath: ReferenceWritableKeyPath<Companion, Date>, cooldown: TimeInterval, coinCost: Int, action: CompanionCareAction, mutate: (Companion) -> Void) -> Bool {
        do {
            let c = try repo.currentCompanion()
            let last = c[keyPath: keyPath]
            if Date().timeIntervalSince(last) < cooldown { return false }
            if c.coins < coinCost { return false }
            c.coins -= coinCost
            mutate(c)
            lastCareAction = action
            try repo.update(c)
            syncSnapshot()
            Haptics.impact(.soft)
            return true
        } catch {
            #if DEBUG
            print("[CompanionService] care failed: \(error)")
            #endif
            return false
        }
    }

    /// Setzt eine kurze Reaktion (für UI-Animation), die nach ~1.2s verblasst.
    private func setReaction(_ reaction: CompanionReaction) {
        lastReaction = reaction
        let trigger = revision
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if revision == trigger + 1 || revision == trigger {
                lastReaction = nil
            }
        }
    }

    // MARK: - Cooldown-Helper (für UI)

    func cooldownRemaining(for need: CompanionNeed) -> TimeInterval {
        let c = (try? repo.currentCompanion())
        guard let c else { return 0 }
        let last: Date
        let cd: TimeInterval
        switch need {
        case .hunger: last = c.lastFedAt;     cd = Config.feedCooldown
        case .hygiene: last = c.lastCleanedAt; cd = Config.cleanCooldown
        case .fun:    last = c.lastPlayedAt;  cd = Config.playCooldown
        default:      return 0
        }
        let elapsed = Date().timeIntervalSince(last)
        return max(0, cd - elapsed)
    }

    // MARK: - Sprechblasen

    /// Setzt die aktuelle Sprechblase (von CompanionSpeechService geliefert).
    func setSpeechBubble(_ text: String?) {
        speechBubble = text
        revision &+= 1
        if let c = try? repo.currentCompanion() {
            c.lastSpeechAt = .now
            try? repo.update(c)
        }
    }

    /// `true`, wenn eine neue Sprechblase generiert werden darf (Throttle).
    var canSpeak: Bool {
        guard let c = try? repo.currentCompanion() else { return true }
        return Date().timeIntervalSince(c.lastSpeechAt) >= Config.speechThrottle
    }

    /// Liefert eine **sofortige** Reaktions-Sprechblase nach einer Pflegaktion
    /// (umgeht das Throttle — die Bestätigung soll sofort kommen). Greift auf
    /// statische Templates zurück, kein AI-Call (schnell + vorhersehbar).
    func reactionSpeech(for action: CompanionCareAction) -> String {
        let name = (try? repo.currentCompanion().name) ?? ""
        let pool: [String]
        switch action {
        case .feed:
            pool = ["Mhhh, lecker! Danke! 😋", "Das hat gutgetan!", "\(name) ist satt und glücklich.", "Yummy!"]
        case .clean:
            pool = ["Puuh, viel besser! 🫧", "Jetzt bin ich wieder frisch!", "Das hat genötigt … aber danke!", "Blitzsauber!"]
        case .play:
            pool = ["Jaaaa, das war lustig! 🎉", "Nochmal! Nochmal!", "Ich liebe es, mit dir zu spielen!", "Das war toll!"]
        case .pet:
            pool = ["Ich liebe deine Streicheleinheiten ❤️", "Schnurr …", "Fühl mich so geborgen bei dir.", "Mehr davon!"]
        }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Shop

    /// Kauft ein Accessoire. `true` bei Erfolg, `false` wenn zu teuer oder
    /// schon besessen.
    @discardableResult
    func buy(_ item: AccessoryCatalogItem) -> Bool {
        do {
            let c = try repo.currentCompanion()
            guard !c.ownedAccessoryIDs.contains(item.rawID) else { return false }
            guard c.coins >= item.cost else { return false }
            c.coins -= item.cost
            c.ownedAccessoryIDs.append(item.rawID)
            try repo.update(c)
            syncSnapshot()
            Haptics.success()
            return true
        } catch {
            #if DEBUG
            print("[CompanionService] buy failed: \(error)")
            #endif
            return false
        }
    }

    /// Rüstet ein Accessoire aus (oder ab, wenn `rawID` nil oder gleich).
    func equip(rawID: String?) {
        do {
            let c = try repo.currentCompanion()
            // Nur ausrüsten, wenn auch besessen.
            if let rawID, !c.ownedAccessoryIDs.contains(rawID) { return }
            c.equippedAccessoryID = (c.equippedAccessoryID == rawID) ? nil : rawID
            try repo.update(c)
            syncSnapshot()
            Haptics.selection()
        } catch {
            #if DEBUG
            print("[CompanionService] equip failed: \(error)")
            #endif
        }
    }

    // MARK: - Setup / Wahl

    @discardableResult
    func choose(species: CompanionSpecies, name: String) throws -> Companion {
        // Vorherige Art merken, um einen realistischen Bond-Reset zu machen,
        // wenn wirklich die Art gewechselt wird (neues Wesen = fremd).
        let previousSpecies = (try? repo.currentCompanion().species)
        let isSpeciesChange = previousSpecies != nil && previousSpecies != species

        let c = try repo.choose(species: species, name: name)
        // Bei einem echten Art-Wechsel startet das neue Wesen mit etwas
        // weniger Zutrauen (es muss sich erst an dich gewöhnen) — aber Coins,
        // Accessoires, Evolution und Bedürfnisse bleiben komplett erhalten.
        if isSpeciesChange {
            c.bond = min(c.bond, 30)
            try? repo.update(c)
        }
        syncSnapshot()
        return c
    }

    func rename(_ name: String) {
        do {
            let c = try repo.currentCompanion()
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            c.name = trimmed.isEmpty ? c.species.defaultName : trimmed
            try repo.update(c)
            syncSnapshot()
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
            syncSnapshot()
        } catch {
            #if DEBUG
            print("[CompanionService] setDecayPaused failed: \(error)")
            #endif
        }
    }
}

// MARK: - Reaction Types

/// Visualische Reaktion des Tieres auf eine Pflegaktion (für CompanionKit).
enum CompanionReaction: Sendable {
    case hearts   // Streicheln → Herzen
    case eats     // Füttern → Futter-Emoji
    case bubbles  // Pflegen → Seifenblasen
    case plays    // Spielen → Ball/Spielzeug
    case happy    // generische Freude

    var emoji: String {
        switch self {
        case .hearts:  return "💖"
        case .eats:    return "😋"
        case .bubbles: return "🫧"
        case .plays:   return "🎉"
        case .happy:   return "✨"
        }
    }
}

// MARK: - Care Action Type

/// Pflegaktion-Arten (für Sofort-Sprechblasen + UI-Helfer).
enum CompanionCareAction: Sendable {
    case feed, clean, play, pet

    var need: CompanionNeed {
        switch self {
        case .feed:  return .hunger
        case .clean: return .hygiene
        case .play:  return .fun
        case .pet:   return .bond
        }
    }

    var coinCost: Int {
        switch self {
        case .feed:  return CompanionService.Config.feedCost
        case .clean: return CompanionService.Config.cleanCost
        case .play:  return CompanionService.Config.playCost
        case .pet:   return 0
        }
    }

    var icon: String {
        switch self {
        case .feed:  return "fork.knife"
        case .clean: return "drop.degreesign"
        case .play:  return "tennisball.fill"
        case .pet:   return "hand.draw.fill"
        }
    }

    var label: String {
        switch self {
        case .feed:  return "Füttern"
        case .clean: return "Pflegen"
        case .play:  return "Spielen"
        case .pet:   return "Streicheln"
        }
    }
}
