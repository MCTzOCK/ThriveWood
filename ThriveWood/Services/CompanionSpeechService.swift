//
//  CompanionSpeechService.swift
//  ThriveWood
//
//  Generiert Sprechblasen für den Companion. Nutzt Apple Intelligence
//  (Foundation Models / SystemLanguageModel), falls verfügbar — sonst
//  Fallback auf statische Templates (CompanionSpeechTemplates). Muster
//  adaptiert aus AIPlanGeneratorView.
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class CompanionSpeechService {
    private let companionService: CompanionService

    /// `true`, während eine AI-Generierung läuft (für UI-Spinner).
    private(set) var isLoading: Bool = false

    /// `true`, wenn Apple Intelligence auf diesem Gerät verfügbar ist.
    var isAIAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    init(companionService: CompanionService) {
        self.companionService = companionService
    }

    /// Generiert die nächste Sprechblase und setzt sie im CompanionService.
    /// Respektiert das Throttle (CompanionService.canSpeak). Bei nicht
    /// verfügbarer AI sofortiger Template-Fallback.
    func generateNext() {
        guard companionService.canSpeak else { return }
        guard let c = try? companionService.current() else { return }

        if isAIAvailable {
            generateViaAI(c)
        } else {
            applyTemplate(c)
        }
    }

    // MARK: - Apple Intelligence

    private func generateViaAI(_ c: Companion) {
        isLoading = true
        let prompt = buildPrompt(c)

        Task {
            do {
                let session = LanguageModelSession(model: SystemLanguageModel.default)
                let response = try await session.respond(
                    to: prompt,
                    generating: CompanionLine.self
                )
                let text = response.content.text.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    self.isLoading = false
                    self.companionService.setSpeechBubble(text.isEmpty ? nil : text)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Fallback auf Template bei jedem AI-Fehler.
                    self.applyTemplate(c)
                }
            }
        }
    }

    private func buildPrompt(_ c: Companion) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let speciesLabel = c.species.label
        let moodLabel = c.mood.label
        let lowest = c.lowestNeed
        let name = c.name

        let moodHint: String
        switch c.mood {
        case .vibrant:  moodHint = "sehr glücklich und energiegeladen"
        case .content:  moodHint = "zufrieden"
        case .tired:    moodHint = "etwas müde und braucht Aufmerksamkeit"
        case .critical: moodHint = "vernachlässigt und braucht dringend Pflege"
        }

        let needHint: String
        switch lowest {
        case .hunger:  needHint = "hungrig"
        case .hygiene: needHint = "schmutzig und möchte gepflegt werden"
        case .fun:     needHint = "gelangweilt und will spielen"
        case .bond:    needHint = "einsam und möchte gestreichelt werden"
        case .energy:  needHint = "erschöpft"
        }

        return """
        Du bist \(name), ein süßes \(speciesLabel)-Haustier in einer Habit-Tracking-App. \
        Du sprichst in der Ich-Form, kindlich-herzig, maximal 1 kurzer Satz (≤ 12 Wörter), auf Deutsch. \
        Keine Emojis im Text. Aktuelle Stunde: \(hour). \
        Deine Stimmung: \(moodHint). \
        Dein dringendstes Bedürfnis gerade: du bist \(needHint). \
        Sage etwas Passendes zu deiner Situation, das deinen Besitzer motiviert, sich um dich zu kümmern oder dich lobt.
        """
    }

    // MARK: - Fallback

    private func applyTemplate(_ c: Companion) {
        let hour = Calendar.current.component(.hour, from: .now)
        let line = CompanionSpeechTemplates.line(
            name: c.name,
            species: c.species,
            mood: c.mood,
            lowestNeed: c.lowestNeed,
            hour: hour
        )
        companionService.setSpeechBubble(line)
    }
}

// MARK: - Generable Response

@Generable
private struct CompanionLine {
    var text: String
}
