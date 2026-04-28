//
//  ConceptStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct ConceptStep: View {
    let accent: AccentTheme
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var appear = false

    private let pillars: [(icon: String, title: String, text: String, color: Color)] = [
        ("checkmark.circle.fill", "Habits tracken",
         "Erstelle Gewohnheiten und hake sie täglich ab.", .green),
        ("leaf.fill", "Punkte sammeln",
         "Jedes Abhaken bringt 1–3 Punkte, je nach Schwierigkeit.", .mint),
        ("tree.fill", "Wald aufbauen",
         "Investiere deine Punkte, um Bäume zu pflanzen und wachsen zu lassen.", .brown)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Text("So funktioniert's")
                .font(.title2.bold())
                .opacity(appear ? 1 : 0)

            VStack(spacing: Theme.Spacing.l) {
                ForEach(Array(pillars.enumerated()), id: \.offset) { idx, pillar in
                    HStack(spacing: Theme.Spacing.l) {
                        Image(systemName: pillar.icon)
                            .font(.title2)
                            .foregroundStyle(pillar.color)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle().fill(pillar.color.opacity(0.12))
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pillar.title).font(.headline)
                            Text(pillar.text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(Theme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.m)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .opacity(appear ? 1 : 0)
                    .offset(x: appear ? 0 : 40)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(idx) * 0.15 + 0.2),
                        value: appear
                    )
                }
            }

            // Kleine Wald-Illustration
            HStack(spacing: 8) {
                ForEach(TreeSpecies.allCases.prefix(5)) { species in
                    TreeShapeView(species: species, stage: .mature)
                        .frame(width: 38, height: 50)
                }
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeOut.delay(0.7), value: appear)

            Spacer()

            HStack(spacing: Theme.Spacing.m) {
                OnboardingBackButton(action: onBack)
                OnboardingButton(title: "Weiter", accent: accent, action: onNext)
            }

            Spacer().frame(height: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }
}
