//
//  ReadyStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct ReadyStep: View {
    let accent: AccentTheme
    let onFinish: () -> Void

    @State private var appear = false
    @State private var confetti = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(accent.color.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                        .scaleEffect(appear ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6)
                            .delay(Double(i) * 0.1 + 0.2),
                            value: appear
                        )
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(accent.color.gradient)
                    .scaleEffect(appear ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1), value: appear)
            }

            VStack(spacing: Theme.Spacing.m) {
                Text("Alles bereit! 🌱")
                    .font(.title.bold())
                Text("Dein Wald wartet auf dich.\nHake deinen ersten Habit ab und pflanze deinen ersten Baum.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)

            // Mini-Wald-Vorschau
            HStack(spacing: 12) {
                ForEach([TreeSpecies.oak, .pine, .cherry], id: \.self) { species in
                    TreeShapeView(species: species, stage: .mature)
                        .frame(width: 50, height: 65)
                }
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: appear)

            Spacer()

            OnboardingButton(title: "Loslegen", accent: accent, icon: "arrow.right", action: onFinish)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.7), value: appear)

            Spacer().frame(height: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }
}
