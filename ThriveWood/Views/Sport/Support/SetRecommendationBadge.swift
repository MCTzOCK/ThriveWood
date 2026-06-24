//
//  SetRecommendationBadge.swift
//  ThriveWood
//

import SwiftUI
import FoundationModels

struct SetRecommendationBadge: View {
    let recommendation: SetRecommendation
    let unit: WeightUnit
    let exerciseName: String
    let aiService: AIService
    let onApply: () -> Void

    @State private var aiMotivation: String?
    @State private var isLoadingAI = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: recommendation.reason.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(reasonColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Empfehlung")
                            .font(.caption.weight(.bold))
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(recommendation.reason.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(String(format: "%.1f", recommendation.recommendedWeight)) \(unit.rawValue) × \(recommendation.recommendedReps) Reps")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }

                Spacer()

                Button {
                    Haptics.selection()
                    onApply()
                } label: {
                    Text("Übernehmen")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if let aiMotivation {
                Text(aiMotivation)
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if isLoadingAI {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("KI denkt nach...")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(reasonColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .strokeBorder(reasonColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            loadAIMotivation()
        }
    }

    private var reasonColor: Color {
        switch recommendation.confidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }

    private func loadAIMotivation() {
        guard aiService.isAvailable() else { return }
        isLoadingAI = true
        let rec = recommendation
        let name = exerciseName
        Task {
            let prompt = """
            Du bist ein motivierender Personal Trainer. Gib eine kurze, maximal 2 Sätze lange motivierende Aussage auf Deutsch für den nächsten Satz der Übung "\(name)". Die Empfehlung ist \(String(format: "%.1f", rec.recommendedWeight)) kg × \(rec.recommendedReps) Reps. Grund: \(rec.reason.label). Sei direkt, aggressiv motivierend und push den Nutzer an sein Limit. Keine Emojis.
            """
            do {
                let session = LanguageModelSession(model: SystemLanguageModel.default)
                let response = try await session.respond(to: prompt)
                withAnimation(.spring(response: 0.3)) {
                    aiMotivation = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    isLoadingAI = false
                }
            } catch {
                isLoadingAI = false
            }
        }
    }
}
