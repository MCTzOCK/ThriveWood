//
//  WelcomeStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct WelcomeStep: View {
    let accent: AccentTheme
    let onNext: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero Tree Icon mit pulsierenden Ringen
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(accent.color.opacity(0.06 - Double(i) * 0.015))
                        .frame(width: 240 - CGFloat(i) * 50,
                               height: 240 - CGFloat(i) * 50)
                        .scaleEffect(appear ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.5)
                            .delay(Double(i) * 0.12 + 0.1),
                            value: appear
                        )
                }

                Circle()
                    .fill(accent.color.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(appear ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.6).delay(0.2),
                        value: appear
                    )

                Image(systemName: "tree.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accent.color.gradient)
                    .symbolEffect(.bounce, value: appear)
                    .scaleEffect(appear ? 1 : 0.6)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.55).delay(0.3),
                        value: appear
                    )
            }

            VStack(spacing: Theme.Spacing.s) {
                BentoText("Willkommen bei", style: .title2, color: .secondary)
                Text("ThriveWood")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(accent.color.gradient)
                BentoText(
                    "Baue Gewohnheiten auf.\nLass deinen Wald wachsen.",
                    style: .body,
                    color: .secondary
                )
                .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xl)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: appear)

            Spacer()

            // Feature-Highlights als BentoTiles
            HStack(spacing: Theme.Spacing.s) {
                welcomeFeatureTile(
                    icon: "checklist",
                    label: "Tracken",
                    tone: .green
                )
                welcomeFeatureTile(
                    icon: "leaf.fill",
                    label: "Sammeln",
                    tone: .yellow
                )
                welcomeFeatureTile(
                    icon: "tree.fill",
                    label: "Wachsen",
                    tone: .blue
                )
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7), value: appear)

            Spacer().frame(height: Theme.Spacing.xl)

            OnboardingButton(title: "Los geht's", accent: accent, icon: "arrow.right", action: onNext)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.9), value: appear)

            Spacer().frame(height: Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }

    private func welcomeFeatureTile(icon: String, label: String, tone: BentoTone) -> some View {
        BentoTile(tone: tone, minimumHeight: 100, alignment: .center) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                BentoText(verbatim: label, style: .callout)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
