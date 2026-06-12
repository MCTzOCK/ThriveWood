//
//  ProfileStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct ProfileStep: View {
    @Binding var displayName: String
    @Binding var dailyGoal: Int
    @Binding var accentTheme: AccentTheme
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.s) {
                Text("Dein Profil")
                    .font(.title2.bold())
                Text("Sag uns, wie du heißt und was dein Tagesziel sein soll.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appear ? 1 : 0)

            VStack(spacing: Theme.Spacing.l) {
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    TextField("Dein Name", text: $displayName)
                        .font(.title3)
                        .padding(Theme.Spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(Color.cardBackground)
                        )
                }

                // Tagesziel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tagesziel").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(dailyGoal) Punkte")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(accentTheme.color)
                    }
                    Slider(value: Binding(
                        get: { Double(dailyGoal) },
                        set: { dailyGoal = Int($0) }
                    ), in: 1...20, step: 1)
                    .tint(accentTheme.color)
                }

                // Akzentfarbe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Farbe wählen").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button {
                                Haptics.selection()
                                withAnimation(.easeInOut) { accentTheme = theme }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 38, height: 38)
                                    if theme == accentTheme {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2.5)
                                            .frame(width: 46, height: 46)
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l)
                    .fill(Color.cardBackground)
            )
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 30)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: appear)

            Spacer()

            HStack(spacing: Theme.Spacing.m) {
                OnboardingBackButton(action: onBack)
                OnboardingButton(title: "Weiter", accent: accentTheme, action: onNext)
            }

            Spacer().frame(height: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }
}
