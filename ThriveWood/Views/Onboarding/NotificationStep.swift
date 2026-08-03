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
        VStack(spacing: 0) {
            Spacer()

            // Hero Icon
            ZStack {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(Color.orange.opacity(0.10 - Double(i) * 0.03))
                        .frame(width: 160 - CGFloat(i) * 40,
                               height: 160 - CGFloat(i) * 40)
                        .scaleEffect(appear ? 1 : 0.4)
                        .animation(
                            .spring(response: 0.7, dampingFraction: 0.5)
                            .delay(Double(i) * 0.15 + 0.2),
                            value: appear
                        )
                }

                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: granted ? "checkmark.circle.fill" : "bell.badge.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(granted ? .green : .red, .orange)
                    .scaleEffect(appear ? 1 : 0.6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3), value: appear)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: granted)
            }

            VStack(spacing: Theme.Spacing.s) {
                BentoText(granted ? "Erledigt!" : "Erinnerungen", style: .title1)
                BentoText(
                    granted
                        ? "Du wirst keine Gewohnheit mehr vergessen."
                        : "Damit du keinen Habit vergisst, können wir dich täglich sanft erinnern.",
                    style: .callout,
                    color: .secondary
                )
                .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.l)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)

            // Info-Card
            BentoCard(padding: .lg, radius: .large) {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    infoRow(
                        icon: "hand.raised.fill",
                        tone: .blue,
                        text: "Kein Spam – nur Erinnerungen für deine Habits, die du selbst festlegst."
                    )
                    BentoDivider()
                    infoRow(
                        icon: "gearshape.fill",
                        tone: .neutral,
                        text: "Du kannst Erinnerungen jederzeit in den Einstellungen anpassen."
                    )
                }
            }
            .padding(.top, Theme.Spacing.l)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 30)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: appear)

            Spacer()

            // Actions
            VStack(spacing: Theme.Spacing.m) {
                if granted {
                    BentoCallout(
                        kind: .success,
                        title: Text("Mitteilungen aktiviert!"),
                        message: nil
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)

                    if granted {
                        OnboardingButton(title: "Weiter", accent: accent, icon: "arrow.right", action: onNext)
                    } else {
                        OnboardingButton(title: "Aktivieren", accent: accent, icon: "bell.fill") {
                            requestPermission()
                        }
                    }
                }

                if !granted {
                    BentoButton(
                        Text("Später"),
                        variant: .ghost,
                        size: .medium,
                        action: onSkip
                    )
                }
            }
            .animation(.bouncy, value: granted)

            Spacer().frame(height: Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear { appear = true }
    }

    private func infoRow(icon: String, tone: BentoTone, text: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.gray.opacity(0.12)))
            BentoText(verbatim: text, style: .caption, color: .secondary)
            Spacer(minLength: 0)
        }
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
