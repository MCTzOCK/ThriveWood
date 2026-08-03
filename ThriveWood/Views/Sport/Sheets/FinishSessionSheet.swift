//
//  FinishSessionSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct FinishSessionSheet: View {
    @Binding var rpe: Int
    @Binding var notes: String
    var overloadSuggestions: [OverloadSuggestion] = []
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    struct OverloadSuggestion: Identifiable {
        let id = UUID()
        let exerciseName: String
        let exerciseIcon: String
        let lastWeight: Double
        let lastReps: Int
        let suggestedWeight: Double
        let suggestedReps: Int
        let increasePercent: Double
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Wie anstrengend war's?"))

                        BentoSlider(
                            Text("RPE"),
                            value: Binding(
                                get: { Double(rpe) },
                                set: { rpe = Int($0) }
                            ),
                            in: 1...10,
                            step: 1,
                            valueLabel: { _ in
                                Text("\(rpe)/10").monospacedDigit()
                            }
                        )
                    }
                }

                if !overloadSuggestions.isEmpty {
                    BentoCard(style: .outlined, padding: .lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            BentoSectionHeader(title: Text("Progressive Overload").font(.subheadline))

                            ForEach(overloadSuggestions) { sug in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: sug.exerciseIcon)
                                            .foregroundStyle(.tint)
                                        Text(sug.exerciseName)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("+\(String(format: "%.0f", sug.increasePercent))%")
                                            .font(.caption.weight(.bold).monospacedDigit())
                                            .foregroundStyle(.green)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Capsule().fill(Color.green.opacity(0.15)))
                                    }
                                    HStack(spacing: 4) {
                                        Text("\(sug.lastWeight.clean)kg × \(sug.lastReps)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        Text("\(sug.suggestedWeight.clean)kg × \(sug.suggestedReps)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(.vertical, 2)
                            }

                            Text("Vorschläge für das nächste Mal – basierend auf deiner letzten Performance.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Notizen"))

                        BentoTextArea(
                            text: $notes,
                            prompt: Text("Gedanken zum Workout…"),
                            minimumHeight: 90
                        )
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                onConfirm()
                dismiss()
            }
        }
    }
}
