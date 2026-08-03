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
    @State private var confettiOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Celebratory Hero
            ZStack {
                // Animated rings
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(accent.color.opacity(0.18 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 36), height: CGFloat(120 + i * 36))
                        .scaleEffect(appear ? 1 : 0.3)
                        .opacity(appear ? 1 : 0)
                        .animation(
                            .spring(response: 0.7, dampingFraction: 0.6)
                            .delay(Double(i) * 0.1 + 0.15),
                            value: appear
                        )
                }

                // Glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.color.opacity(0.25), accent.color.opacity(0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(appear ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: appear)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(accent.color.gradient)
                    .symbolEffect(.bounce, value: appear)
                    .scaleEffect(appear ? 1 : 0.4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1), value: appear)
            }

            // Title
            VStack(spacing: Theme.Spacing.m) {
                Text("Alles bereit! 🌱")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(accent.color.gradient)
                BentoText(
                    "Dein Wald wartet auf dich.\nHake deinen ersten Habit ab und pflanze deinen ersten Baum.",
                    style: .body,
                    color: .secondary
                )
                .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xl)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)

            // Summary als BentoStatStrip
            BentoCard(style: .elevated, padding: .lg, radius: .large) {
                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "habits",
                        title: Text("Bereit"),
                        value: Text("1"),
                        detail: Text("Habit")
                    ),
                    BentoStatValue(
                        id: "trees",
                        title: Text("Wald"),
                        value: Text("0"),
                        detail: Text("Bäume")
                    ),
                    BentoStatValue(
                        id: "goal",
                        title: Text("Ziel"),
                        value: Text("∞"),
                        detail: Text("Punkte")
                    )
                ])
            }
            .padding(.top, Theme.Spacing.xl)
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appear)

            // Mini-Wald Vorschau
            HStack(spacing: Theme.Spacing.m) {
                ForEach([TreeSpecies.oak, .pine, .cherry], id: \.self) { species in
                    TreeShapeView(species: species, stage: .mature)
                        .frame(width: 50, height: 65)
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)
                }
            }
            .padding(.top, Theme.Spacing.l)
            .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.6), value: appear)

            Spacer()

            OnboardingButton(title: "Loslegen", accent: accent, icon: "arrow.right", action: onFinish)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.8), value: appear)

            Spacer().frame(height: Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear {
            appear = true
            Haptics.success()
        }
    }
}
