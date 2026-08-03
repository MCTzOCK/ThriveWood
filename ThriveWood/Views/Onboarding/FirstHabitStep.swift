//
//  FirstHabitStep.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct FirstHabitStep: View {
    @Binding var title: String
    @Binding var icon: String
    @Binding var color: HabitColor
    @Binding var points: HabitPoints
    let accent: AccentTheme
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var appear = false

    private let quickSuggestions: [(String, String, HabitColor)] = [
        ("Sport", "figure.run", .orange),
        ("Lesen", "book.fill", .indigo),
        ("Meditation", "brain.head.profile", .purple),
        ("Wasser trinken", "drop.fill", .blue),
        ("Früh aufstehen", "sun.max.fill", .yellow),
        ("Spaziergang", "figure.walk", .green),
        ("Tagebuch", "pencil", .pink),
        ("Kein Zucker", "fork.knife", .red)
    ]

    private let iconOptions = [
        "leaf.fill", "figure.run", "book.fill", "drop.fill",
        "brain.head.profile", "sun.max.fill", "heart.fill",
        "moon.fill", "dumbbell.fill", "fork.knife", "pencil",
        "cup.and.saucer.fill"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.l) {
                Spacer().frame(height: Theme.Spacing.m)

                // Header
                VStack(spacing: Theme.Spacing.xs) {
                    BentoBadge(Text("ERSTER HABIT"), tone: .accent, systemImage: "checklist")
                    BentoText("Womit möchtest du starten?", style: .title1)
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appear)

                // Quick-Suggestions als BentoFlowLayout
                BentoFlowLayout(spacing: Theme.Spacing.xs) {
                    ForEach(quickSuggestions, id: \.0) { name, iconName, c in
                        Button {
                            Haptics.selection()
                            withAnimation(.bouncy) {
                                title = name; icon = iconName; color = c
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconName).font(.caption)
                                Text(verbatim: name).font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, Theme.Spacing.s)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                Capsule().fill(
                                    title == name ? AnyShapeStyle(c.color) : AnyShapeStyle(c.color.opacity(0.12))
                                )
                            )
                            .foregroundStyle(title == name ? .white : c.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appear)

                // Eingabe-Card
                BentoCard(padding: .lg, radius: .large) {
                    VStack(spacing: Theme.Spacing.l) {
                        BentoTextField(
                            label: Text("Name"),
                            text: $title,
                            prompt: Text("Oder eigener Name…"),
                            showsClearButton: true
                        )

                        // Icon-Auswahl
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            BentoText(verbatim: "Symbol", style: .callout, color: .secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.xs) {
                                    ForEach(iconOptions, id: \.self) { name in
                                        Button {
                                            Haptics.selection()
                                            withAnimation(.bouncy) { icon = name }
                                        } label: {
                                            Image(systemName: name)
                                                .font(.title3)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(icon == name
                                                              ? color.color.opacity(0.2)
                                                              : Color(.tertiarySystemFill))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(icon == name ? color.color : .clear, lineWidth: 2)
                                                )
                                                .foregroundStyle(icon == name ? color.color : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        BentoDivider()

                        // Schwierigkeit
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            BentoText(verbatim: "Schwierigkeit", style: .callout, color: .secondary)
                            BentoSegmentedPicker(options: HabitPoints.allCases, selection: $points) { p in
                                Text(verbatim: p.label)
                            }
                            .tint(accent.color)
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                .animation(.easeOut.delay(0.3), value: appear)

                // Live-Vorschau
                if !title.trimmingCharacters(in: .whitespaces).isEmpty {
                    BentoCard(tone: habitBentoTone, style: .elevated, padding: .md, radius: .large) {
                        HStack(spacing: Theme.Spacing.m) {
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .fill(color.gradient)
                                    .frame(width: 48, height: 48)
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                BentoText(verbatim: title, style: .headline)
                                BentoText(
                                    verbatim: "\(points.rawValue) Punkt\(points.rawValue > 1 ? "e" : "") pro Tag",
                                    style: .caption,
                                    color: .secondary
                                )
                            }
                            Spacer()
                            BentoBadge(Text(verbatim: "+\(points.rawValue)"), tone: .success)
                        }
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }

                Spacer().frame(height: Theme.Spacing.m)

                HStack(spacing: Theme.Spacing.m) {
                    OnboardingBackButton(action: onBack)
                    OnboardingButton(
                        title: title.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "Überspringen" : "Weiter",
                        accent: accent,
                        icon: title.trimmingCharacters(in: .whitespaces).isEmpty ? nil : "arrow.right",
                        action: onNext,
                        isSecondary: title.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }

                Spacer().frame(height: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .onAppear { appear = true }
    }

    private var habitBentoTone: BentoTone {
        switch color {
        case .green: .green
        case .mint: .green
        case .teal: .info
        case .blue: .blue
        case .indigo: .info
        case .purple: .info
        case .pink: .pink
        case .red: .danger
        case .orange: .warning
        case .yellow: .yellow
        case .brown: .neutral
        case .gray: .neutral
        }
    }
}
