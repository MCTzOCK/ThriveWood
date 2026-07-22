//
//  SportViewV2Support.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

// MARK: - Today's Workout Card

struct TodayWorkoutCardV2: View {
    let workout: Workout?
    let estimatedDuration: Int
    let exerciseCount: Int
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                    Text("Heutiges Training")
                        .font(Theme.Typography.caption.weight(.semibold))
                    Spacer()
                    PillBadge(text: "Geplant", icon: "clock", color: .white)
                }
                .foregroundStyle(.white.opacity(0.9))

                if let workout {
                    Text(workout.name)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: Theme.Spacing.l) {
                        Label("\(exerciseCount) Übungen", systemImage: "list.bullet")
                        Label("\(estimatedDuration) min", systemImage: "clock")
                    }
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Freies Training")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(.white)
                    Text("Kein Workout geplant – starte frei")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                HStack {
                    Spacer()
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Starten")
                            .font(Theme.Typography.headline)
                        Image(systemName: "play.fill")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.s + 2)
                    .background(
                        Capsule().fill(Color.white.opacity(0.2))
                    )
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Rest Day Card

struct RestDayCardV2: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "moon.circle.fill")
                    .font(.title2)
                Text("Ruhetag")
                    .font(Theme.Typography.caption.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))

            Text("Heute steht Erholung an")
                .font(Theme.Typography.title2)
                .foregroundStyle(.white)

            Text("Dein Plan sieht heute Pause vor. Nutze den Tag für Mobilität, Spaziergänge oder Schlaf.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.Spacing.m) {
                Label("Mobilität", systemImage: "figure.flexibility")
                Label("Spaziergang", systemImage: "figure.walk")
                Label("Schlaf", systemImage: "bed.double.fill")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.indigo, Color.indigo.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
    }
}

// MARK: - Week Strip Card

struct SportWeekStripCard: View {
    let model: SportViewV2Model

    private let calendar = Calendar.app

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("Diese Woche")
                    .font(Theme.Typography.headline)
                Spacer()
                Text("\(model.weeklySessionCount) Sessions")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                ForEach(model.weekDays, id: \.self) { date in
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(weekdayLabel(date))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .fill(dayColor(date))
                                .frame(width: 28, height: 28)

                            if model.isToday(date) {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }

                            if model.sessionCompleted(on: date) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private func weekdayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EE"
        return fmt.string(from: date)
    }

    private func dayColor(_ date: Date) -> Color {
        if model.sessionCompleted(on: date) {
            return .green
        }
        if model.isRestDay(date) {
            return Color(.tertiarySystemFill)
        }
        if model.plannedWorkout(for: date) != nil {
            return Color.accentColor.opacity(0.4)
        }
        return Color(.tertiarySystemFill).opacity(0.5)
    }
}

// MARK: - Recovery Mini Card

struct RecoveryMiniCard: View {
    let dashboard: MuscleRecoveryService.RecoveryDashboard?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("Erholung")
                    .font(Theme.Typography.headline)
                Spacer()
                NavigationLink {
                    MuscleRankingScreen()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let dash = dashboard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack(spacing: Theme.Spacing.m) {
                        ZStack {
                            Circle()
                                .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                                .frame(width: 52, height: 52)
                            Circle()
                                .trim(from: 0, to: dash.readinessScore / 100)
                                .stroke(readinessColor(dash.readinessScore), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 52, height: 52)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(dash.readinessScore))")
                                .font(Theme.Typography.subheadline.weight(.bold).monospacedDigit())
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bereitschaft")
                                .font(Theme.Typography.subheadline.weight(.semibold))
                            Text(dash.recommendedFocus)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }

                    HStack(spacing: Theme.Spacing.l) {
                        Label("\(dash.sessionCount7d)", systemImage: "figure.strengthtraining.traditional")
                            .font(Theme.Typography.caption)
                        Label("\(dash.recoveredMuscles.count) erholt", systemImage: "checkmark.circle.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.green)
                        if !dash.needsRestMuscles.isEmpty {
                            Label("\(dash.needsRestMuscles.count) Pause", systemImage: "exclamationmark.triangle.fill")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } else {
                Text("Noch keine Trainingsdaten")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private func readinessColor(_ score: Double) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }
}

// MARK: - Quick Start Grid

struct QuickStartGridV2: View {
    let onFreeTraining: () -> Void
    let onRepeatLast: () -> Void
    let onWorkoutSelect: (Workout) -> Void
    let workouts: [Workout]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Schnellstart")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.m) {
                quickStartItem(
                    title: "Freies Training",
                    subtitle: "Sofort loslegen",
                    icon: "play.fill",
                    color: .accentColor,
                    action: onFreeTraining
                )
                quickStartItem(
                    title: "Letztes wiederholen",
                    subtitle: "Vorlage nutzen",
                    icon: "arrow.clockwise",
                    color: .blue,
                    action: onRepeatLast
                )
            }

            if !workouts.isEmpty {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(workouts) { w in
                        Button { onWorkoutSelect(w) } label: {
                            HStack(spacing: Theme.Spacing.m) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                                        .fill(w.color.color.opacity(0.15))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "dumbbell.fill")
                                        .font(Theme.Typography.callout)
                                        .foregroundStyle(w.color.color)
                                }
                                Text(w.name)
                                    .font(Theme.Typography.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(Theme.Typography.caption.weight(.bold))
                                    .foregroundStyle(w.color.color)
                            }
                            .padding(Theme.Spacing.m)
                            .cardStyle()
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
            }
        }
    }

    private func quickStartItem(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.s) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(Theme.Typography.body.weight(.bold))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .cardStyle()
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Weekly Stats Card

struct WeeklyStatsCardV2: View {
    let sessionCount: Int
    let volume: Double
    let durationMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Wochenstatistik")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.m) {
                StatPill(icon: "figure.strengthtraining.traditional", value: "\(sessionCount)", label: "Sessions", color: .accentColor)
                StatPill(icon: "scalemass.fill", value: formatVolume, label: "Volumen", color: .blue)
                StatPill(icon: "clock.fill", value: "\(durationMinutes)", label: "Minuten", color: .orange)
            }
        }
    }

    private var formatVolume: String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Sport Navigation Card

struct SportNavigationCardV2: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
