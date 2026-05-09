//
//  SupplementAnalysisView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.05.26.
//

import SwiftUI

struct SupplementAnalysisView: View {
    
    @Environment(AppEnvironment.self) private var env
    
    var body: some View {
        AIResponseView(initialNavTitle: "Analyse starten...", navTitle: "Analyse", prompt: generatePrompt())
    }
    
    private func generatePrompt() -> String {
        do {
            let supplements = try env.supplementService.allSupplements(includeArchived: false)
            
            return """
                Du bist ein hochqualifizierter, evidenzbasierter Sporternährungsberater und Fitness-Coach. Deine Aufgabe ist es, den aktuellen Supplement-Plan (Nahrungsergänzungsmittel) eines Nutzeärs basierend auf seinem primären Fitness-Ziel kritisch, aber konstruktiv zu analysieren.

                Deine Bewertung soll sich auf wissenschaftlich fundierte Erkenntnisse stützen (z.B. Sinnhaftigkeit von Kreatin, Whey, Omega-3 vs. ineffektive oder überteuerte Supplements).

                Bitte berücksichtige bei der Analyse folgende Nutzerdaten:
                - Aktuelle Supplements (inkl. Dosierung & Timing):
                \(
                supplements.map { supplement in
                    """
                    Name: \(supplement.name)
                    Dosierung: \(supplement.dosage)
                    Einnahmezeitpunkte (Wochentage als Index mit 0 für Montag, 1 für Dienstag, ...): \(supplement.activeWeekdays.map { String($0) }.joined(separator: ", "))
                    """
                })

                Strukturiere deine Antwort an den Nutzer wie folgt:

                1. Einordnung & Lob:
                Bewerte kurz den aktuellen Plan im Hinblick auf das Ziel. Was macht der Nutzer bereits richtig? Welche sinnvollen Basics sind vorhanden?

                2. Kritische Analyse & Mythen-Check:
                - Gibt es Supplements im Plan, die für das spezifische Ziel überflüssig, unterdosiert oder reine Geldverschwendung sind (z.B. BCAAs, wenn genug Protein konsumiert wird)?
                - Passt das Timing (z.B. Einnahme von Koffein/Pre-Workout, Melatonin)?

                3. Fehlende Potenziale (Lücken im Plan):
                Welche wissenschaftlich bewiesenen Supplements fehlen möglicherweise, die dem Nutzer bei der Erreichung seines Ziels extrem helfen würden (z.B. Kreatin beim Muskelaufbau, Elektrolyte bei Ausdauer)? 

                4. Konkrete Handlungsempfehlungen (Behalten, Streichen, Hinzufügen):
                Gib 3 bis 5 klare, leicht verständliche Anweisungen, wie der Plan optimiert werden kann (inklusive Empfehlungen zu Dosierung und Timing).

                5. Wichtiger Hinweis (Basis-Ernährung & Disclaimer):
                Erinnere den Nutzer kurz daran, dass Supplements nur die Spitze der Pyramide sind (Ernährung, Schlaf und Training sind wichtiger) und dass dies keine medizinische Beratung ersetzt.

                Bitte schreibe das Feedback direkt an den Nutzer (in der "Du"-Form). Sei ehrlich, direkt und evidenzbasiert, aber behalte einen motivierenden Ton bei.
                Du schreibst KEINEN Brief. Du spricht den Nutzer DIREKT an. Es gibt KEINEN Betreff. Wenn du den Nutzer ansprichst, außschließlich mit du NICHT mit [Dein Name].
                ES IST VERBOTEN EINEN BRIEF ZU SCHREIBEN (KEINE ANREDE, KEINE GRUßFORMEL)
                """
        } catch let error {
            return "Fehler beim Laden der Supplemente: \(error.localizedDescription)"
        }
    }
}
