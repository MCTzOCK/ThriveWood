//
//  NotificationStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct NotificationStep: View {
    @Binding var granted: Bool
    let accent: AccentTheme
    let env: AppEnvironment
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var appear = false
    @State private var requesting = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .orange)
                    .scaleEffect(appear ? 1 : 0.6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3), value: appear)
            }

            VStack(spacing: Theme.Spacing.m) {
                Text("Erinnerungen")
                    .font(.title2.bold())
                Text("Damit du keinen Habit vergisst, können wir dich täglich sanft erinnern.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appear ? 1 : 0)

            VStack(spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "hand.raised.fill").foregroundStyle(.blue)
                    Text("Kein Spam – nur Erinnerungen für deine Habits, die du selbst festlegst.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "gear").foregroundStyle(.gray)
                    Text("Du kannst Erinnerungen jederzeit in den Einstellungen anpassen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(Color.cardBackground)
            )
            .opacity(appear ? 1 : 0)
            .animation(.easeOut.delay(0.3), value: appear)

            Spacer()

            VStack(spacing: Theme.Spacing.m) {
                if granted {
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Aktiviert!").font(.headline).foregroundStyle(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)

                    if granted {
                        OnboardingButton(title: "Weiter", accent: accent, action: onNext)
                    } else {
                        OnboardingButton(title: "Aktivieren", accent: accent) {
                            requestPermission()
                        }
                    }
                }

                if !granted {
                    Button("Später", action: onSkip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer().frame(height: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: granted)
        .onAppear { appear = true }
    }

    private func requestPermission() {
        requesting = true
        Task {
            let result = await env.notificationService.ensureAuthorized()
            granted = result
            requesting = false
        }
    }
}
