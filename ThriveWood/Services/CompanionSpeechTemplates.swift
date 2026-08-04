//
//  CompanionSpeechTemplates.swift
//  ThriveWood
//
//  Statische Sprechblasen-Templates als Fallback, wenn Apple Intelligence
//  (Foundation Models) nicht verfügbar ist. Kategorisiert nach Mood und
//  dem jeweils niedrigsten Bedürfnis.
//

import Foundation

enum CompanionSpeechTemplates {
    /// Liefert eine zufällige Sprechblase basierend auf Mood + niedrigstem
    /// Bedürfnis + Tageszeit. Rein deterministisch, kein Netzwerk nötig.
    static func line(name: String, species: CompanionSpecies, mood: CompanionMood, lowestNeed: CompanionNeed, hour: Int) -> String {
        let bucket = bucket(for: mood, lowestNeed: lowestNeed)
        let pool = templates(for: bucket, name: name)
        let greeting = timeGreeting(hour: hour)
        // Leichte Variation: mit ~30% Wahrscheinlichkeit die Begrüßung voranstellen.
        if Bool.random() {
            return "\(greeting) \(pool.randomElement() ?? pool[0])"
        }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Buckets

    enum Bucket: String {
        case hungry, dirty, bored, lonely  // niedrigstes Bedürfnis
        case critical, vibrant             // Mood-Extrema
        case content                       // Default
    }

    private static func bucket(for mood: CompanionMood, lowestNeed: CompanionNeed) -> Bucket {
        if mood == .critical { return .critical }
        if mood == .vibrant { return .vibrant }
        switch lowestNeed {
        case .hunger:  return .hungry
        case .hygiene: return .dirty
        case .fun:     return .bored
        case .bond:    return .lonely
        case .energy:  return .critical
        }
    }

    // MARK: - Template-Pools

    private static func templates(for bucket: Bucket, name: String) -> [String] {
        switch bucket {
        case .hungry:
            return [
                "Ich habe so einen Hunger! 🍖",
                "Mein Magen knurrt … hast du was zu essen?",
                "Fütterst du mich bald? 🥺",
                "Ein Snack wäre jetzt perfekt!"
            ]
        case .dirty:
            return [
                "Ich fühle mich so schmutzig 🛁",
                "Zeit für ein Bad, oder?",
                "Puh, ich könnte eine Pflege gebrauchen …",
                "Bitte bürste mich! 🧴"
            ]
        case .bored:
            return [
                "Mir ist langweilig … spielst du mit mir? 🎾",
                "Lass uns was unternehmen!",
                "Ich will spielen! 🎉",
                "Hast du Zeit für ein kleines Spiel?"
            ]
        case .lonely:
            return [
                "Streichelst du mich? Ich liebe deine Nähe ❤️",
                "Ich vermisse unsere gemeinsame Zeit …",
                "Komm, sei mir nah!",
                "Deine Streicheleinheiten fehlen mir 💕"
            ]
        case .critical:
            return [
                "Ich fühle mich gar nicht gut … bitte kümmer dich um mich 🥵",
                "Ich brauche dich jetzt wirklich!",
                "Mir geht's nicht so gut heute …",
                "Bitte pflege mich, ich bin erschöpft 😔"
            ]
        case .vibrant:
            return [
                "Ich fühle mich fantastisch! ✨",
                "Was für ein großartiger Tag!",
                "Danke, dass du so gut auf mich aufpasst! 💖",
                "Ich bin voller Energie — lass uns was erleben!"
            ]
        case .content:
            return [
                "Danke, dass du da bist 😊",
                "Ich bin zufrieden mit dir zusammen.",
                "Alles ist gut gerade.",
                "Du bist ein toller Begleiter!",
                "Lass uns gemeinsam weitermachen."
            ]
        }
    }

    private static func timeGreeting(hour: Int) -> String {
        switch hour {
        case 5..<11:  return "Guten Morgen! ☀️"
        case 11..<14: return "Hallo! 🌤️"
        case 14..<18: return "Schöner Nachmittag!"
        case 18..<22: return "Guten Abend! 🌙"
        default:      return "Psst … spät noch wach? 🌌"
        }
    }
}
