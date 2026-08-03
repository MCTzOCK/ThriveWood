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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.l) {
                Spacer().frame(height: Theme.Spacing.m)

                // Header
                VStack(spacing: Theme.Spacing.xs) {
                    BentoBadge(Text("SO FUNKTIONIERT'S"), tone: .accent, systemImage: "sparkles")
                    BentoText("Drei einfache Schritte", style: .title1)
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appear)

                // Pillar 1
                conceptCard(
                    icon: "checkmark.circle.fill",
                    title: "Habits tracken",
                    text: "Erstelle Gewohnheiten und hake sie täglich ab.",
                    tone: .green,
                    step: "1",
                    delay: 0.2
                )

                // Pillar 2
                conceptCard(
                    icon: "star.circle.fill",
                    title: "Punkte sammeln",
                    text: "Jedes Abhaken bringt 1–3 Punkte, je nach Schwierigkeit.",
                    tone: .yellow,
                    step: "2",
                    delay: 0.35
                )

                // Pillar 3
                conceptCard(
                    icon: "tree.fill",
                    title: "Wald aufbauen",
                    text: "Investiere deine Punkte, um Bäume zu pflanzen und wachsen zu lassen.",
                    tone: .blue,
                    step: "3",
                    delay: 0.5
                )

                // Wald-Illustration als BentoCard
                BentoCard(tone: .green, style: .elevated, padding: .lg, radius: .large) {
                    VStack(spacing: Theme.Spacing.s) {
                        BentoText("Dein Wald wartet", style: .headline)
                        HStack(spacing: Theme.Spacing.s) {
                            ForEach(TreeSpecies.allCases.prefix(5)) { species in
                                TreeShapeView(species: species, stage: .mature)
                                    .frame(width: 38, height: 50)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: appear)

                Spacer().frame(height: Theme.Spacing.m)

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)
                    OnboardingButton(title: "Weiter", accent: accent, icon: "arrow.right", action: onNext)
                }

                Spacer().frame(height: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .onAppear { appear = true }
    }

    private func conceptCard(
        icon: String,
        title: String,
        text: String,
        tone: BentoTone,
        step: String,
        delay: Double
    ) -> some View {
        BentoTile(tone: tone, minimumHeight: 110, alignment: .topLeading) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(verbatim: step)
                            .font(.caption.weight(.heavy))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.white.opacity(0.25)))
                        BentoText(verbatim: title, style: .headline)
                    }
                    BentoText(verbatim: text, style: .caption, color: .primary)
                }
                Spacer(minLength: 0)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : 50)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
            value: appear
        )
    }
}
