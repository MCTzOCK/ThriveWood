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
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.l) {
                Spacer().frame(height: Theme.Spacing.m)

                // Header
                VStack(spacing: Theme.Spacing.xs) {
                    BentoBadge(Text("PROFIL"), tone: .accent, systemImage: "person.crop.circle.fill")
                    BentoText("Mach's zu deinem", style: .title1)
                    BentoText(
                        "Wie heißt du und was möchtest du täglich erreichen?",
                        style: .callout,
                        color: .secondary
                    )
                    .multilineTextAlignment(.center)
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appear)

                // Avatar-Preview
                BentoCard(style: .elevated, padding: .xl, radius: .extraLarge) {
                    VStack(spacing: Theme.Spacing.m) {
                        BentoAvatar(
                            source: .initials(avatarInitials),
                            size: 80,
                            tone: bentoToneForAccent
                        )
                        if !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                            BentoText(verbatim: displayName, style: .title2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appear)

                // Form-Card
                BentoCard(padding: .lg, radius: .large) {
                    VStack(spacing: Theme.Spacing.l) {
                        // Name
                        BentoTextField(
                            label: Text("Name"),
                            text: $displayName,
                            prompt: Text("Dein Name"),
                            showsClearButton: true
                        )

                        BentoDivider()

                        // Tagesziel
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            HStack {
                                BentoText(verbatim: "Tagesziel", style: .callout, color: .secondary)
                                Spacer()
                                Text(verbatim: "\(dailyGoal) Punkte")
                                    .bentoTextStyle(.bodyStrong, color: accentTheme.color)
                            }
                            BentoSlider(
                                Text("Tagesziel"),
                                value: Binding(
                                    get: { Double(dailyGoal) },
                                    set: { dailyGoal = Int($0) }
                                ),
                                in: 1...20,
                                step: 1
                            )
                            .tint(accentTheme.color)
                        }

                        BentoDivider()

                        // Akzentfarbe
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            BentoText(verbatim: "Akzentfarbe wählen", style: .callout, color: .secondary)

                            HStack(spacing: Theme.Spacing.s) {
                                ForEach(AccentTheme.allCases) { theme in
                                    Button {
                                        Haptics.selection()
                                        withAnimation(.bouncy) { accentTheme = theme }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(theme.color)
                                                .frame(width: 44, height: 44)
                                                .shadow(color: theme.color.opacity(0.3), radius: 4, y: 2)

                                            if theme == accentTheme {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 3)
                                                    .frame(width: 52, height: 52)
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .scaleEffect(theme == accentTheme ? 1.1 : 1)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: accentTheme)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appear)

                Spacer().frame(height: Theme.Spacing.m)

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)
                    OnboardingButton(title: "Weiter", accent: accentTheme, icon: "arrow.right", action: onNext)
                }

                Spacer().frame(height: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .onAppear { appear = true }
    }

    private var avatarInitials: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "🌱" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private var bentoToneForAccent: BentoTone {
        switch accentTheme {
        case .forest: .green
        case .ocean: .blue
        case .sunset: .warning
        case .lavender: .info
        case .rose: .pink
        }
    }
}
