//
//  OnboardingView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome, concept, profile, firstHabit, notifications, ready
}

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    /// `true` wenn aus Settings geöffnet (kein forced-Modus).
    let isRerun: Bool
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var direction: Edge = .trailing
    @State private var currentPage: Int = 0

    // Shared Form-State über alle Schritte
    @State private var displayName: String = ""
    @State private var dailyGoal: Int = 5
    @State private var accentTheme: AccentTheme = .forest

    @State private var habitTitle: String = ""
    @State private var habitIcon: String = "leaf.fill"
    @State private var habitColor: HabitColor = .green
    @State private var habitPoints: HabitPoints = .medium

    @State private var notificationsGranted: Bool = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.l)

                stepContent
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: direction).combined(with: .opacity),
                            removal: .move(edge: direction == .trailing ? .leading : .trailing)
                                .combined(with: .opacity)
                        )
                    )
                    .id(step)
            }
        }
        .animation(.bouncy, value: step)
        .interactiveDismissDisabled(!isRerun)
        .onChange(of: step) { _, newStep in
            currentPage = newStep.rawValue
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                accentTheme.color.opacity(0.10),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.bouncy, value: accentTheme)
    }

    // MARK: - Progress

    private var progressBar: some View {
        BentoPageIndicator(
            count: OnboardingStep.allCases.count,
            current: $currentPage,
            allowsDirectSelection: false
        )
        .tint(accentTheme.color)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStep(accent: accentTheme, onNext: next)
        case .concept:
            ConceptStep(accent: accentTheme, onNext: next, onBack: back)
        case .profile:
            ProfileStep(
                displayName: $displayName,
                dailyGoal: $dailyGoal,
                accentTheme: $accentTheme,
                onNext: next, onBack: back
            )
        case .firstHabit:
            FirstHabitStep(
                title: $habitTitle,
                icon: $habitIcon,
                color: $habitColor,
                points: $habitPoints,
                accent: accentTheme,
                onNext: next, onBack: back, onSkip: next
            )
        case .notifications:
            NotificationStep(
                granted: $notificationsGranted,
                accent: accentTheme,
                env: env,
                onNext: next, onBack: back, onSkip: next
            )
        case .ready:
            ReadyStep(accent: accentTheme, onFinish: finish)
        }
    }

    // MARK: - Navigation

    private func next() {
        Haptics.impact(.light)
        direction = .trailing
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else {
            finish(); return
        }
        step = nextStep
    }

    private func back() {
        Haptics.impact(.light)
        direction = .leading
        guard let prevStep = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prevStep
    }

    private func finish() {
        Haptics.success()
        saveAll()
        onComplete()
        dismiss()
    }

    // MARK: - Persistence

    private func saveAll() {
        do {
            let profile = try env.profileRepo.currentProfile()
            if !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                profile.displayName = displayName
            }
            profile.dailyPointGoal = dailyGoal
            profile.accentTheme = accentTheme
            profile.enableNotifications = notificationsGranted
            profile.onboardingCompletedAt = .now
            try env.profileRepo.update(profile)

            AppCalendarConfig.shared.update(weekStartsOn: profile.weekStartsOn)

            // Ersten Habit anlegen, falls ausgefüllt
            let trimmed = habitTitle.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                let habit = Habit(
                    title: trimmed,
                    iconSystemName: habitIcon,
                    color: habitColor,
                    points: habitPoints,
                    sortOrder: 0
                )
                try env.habitRepo.create(habit)
            }

            // Wald sicherstellen
            _ = try env.forestRepo.currentForest()
        } catch {
            // Leise – Onboarding soll nicht crashen
        }
    }
}
