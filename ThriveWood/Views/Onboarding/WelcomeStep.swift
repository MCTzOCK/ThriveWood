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
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accent.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(appear ? 1 : 0.5)
                Circle()
                    .fill(accent.color.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .scaleEffect(appear ? 1 : 0.3)
                Image(systemName: "tree.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(accent.color.gradient)
                    .scaleEffect(appear ? 1 : 0.6)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2), value: appear)

            VStack(spacing: Theme.Spacing.m) {
                Text("Willkommen bei")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("ThriveWood")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(accent.color.gradient)
                Text("Baue Gewohnheiten auf.\nLass deinen Wald wachsen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)

            Spacer()

            OnboardingButton(title: "Los geht's", accent: accent, action: onNext)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.6), value: appear)

            Spacer().frame(height: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }
}
