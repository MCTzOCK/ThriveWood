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
    var isCompleted: Bool = false
    let onStart: () -> Void

    private var bgGradient: LinearGradient {
        LinearGradient(
            colors: isCompleted
                ? [Color.green, Color.green.opacity(0.75)]
                : [Color.accentColor, Color.accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: isCompleted ? "checkmark.seal.fill" : "calendar.circle.fill")
                        .font(.title2)
                        .symbolEffect(.bounce, value: isCompleted)
                    BentoText(verbatim: "Heutiges Training", style: .caption, color: .white.opacity(0.85))
                    Spacer()
                    BentoBadge(Text(isCompleted ? "Erledigt" : "Geplant"), tone: .neutral)
                }

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
                    BentoText(
                        verbatim: isCompleted ? "Heute schon aktiv gewesen" : "Kein Workout geplant – starte frei",
                        style: .callout,
                        color: .white.opacity(0.8)
                    )
                }

                HStack {
                    Spacer()
                    BentoButton(
                        Text(isCompleted ? "Wiederholen" : "Starten"),
                        systemImage: isCompleted ? "arrow.clockwise" : "play.fill",
                        iconPlacement: .trailing,
                        variant: .chrome,
                        size: .medium
                    ) {
                        onStart()
                    }
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
            .shadow(color: (isCompleted ? Color.green : Color.accentColor).opacity(0.3), radius: 12, y: 6)
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
                    .symbolEffect(.pulse, options: .repeating)
                BentoText(verbatim: "Ruhetag", style: .caption, color: .white.opacity(0.85))
                Spacer()
            }

            Text("Heute steht Erholung an")
                .font(Theme.Typography.title2)
                .foregroundStyle(.white)

            BentoText(
                verbatim: "Dein Plan sieht heute Pause vor. Nutze den Tag für Mobilität, Spaziergänge oder Schlaf.",
                style: .callout,
                color: .white.opacity(0.8)
            )

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
        .shadow(color: Color.indigo.opacity(0.25), radius: 12, y: 6)
    }
}

// MARK: - Week Strip Card

struct SportWeekStripCard: View {
    let model: SportViewV2Model
    private let calendar = Calendar.app

    var body: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Diese Woche")) {
                    BentoText(
                        verbatim: "\(model.weeklySessionCount) Sessions",
                        style: .caption,
                        color: .secondary
                    )
                }

                HStack(spacing: 0) {
                    ForEach(model.weekDays, id: \.self) { date in
                        VStack(spacing: Theme.Spacing.xs) {
                            BentoText(
                                verbatim: weekdayLabel(date),
                                style: .caption,
                                color: model.isToday(date) ? .accentColor : .secondary
                            )

                            ZStack {
                                Circle()
                                    .fill(dayColor(date))
                                    .frame(width: 28, height: 28)
                                    .scaleEffect(model.isToday(date) ? 1.1 : 1.0)
                                    .animation(.bouncy(duration: 0.4), value: model.isToday(date))

                                if model.isToday(date) {
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                }

                                if model.sessionCompleted(on: date) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .symbolEffect(.bounce, value: model.sessionCompleted(on: date))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EE"
        return fmt.string(from: date)
    }

    private func dayColor(_ date: Date) -> Color {
        if model.sessionCompleted(on: date) { return .green }
        if model.isRestDay(date) { return Color(.tertiarySystemFill) }
        if model.plannedWorkout(for: date) != nil { return Color.accentColor.opacity(0.4) }
        return Color(.tertiarySystemFill).opacity(0.5)
    }
}

// MARK: - Recovery Mini Card

struct RecoveryMiniCard: View {
    let dashboard: MuscleRecoveryService.RecoveryDashboard?

    var body: some View {
        BentoCard(style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Erholung")) {
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
                                    .animation(.bouncy(duration: 0.6), value: dash.readinessScore)
                                Text(verbatim: "\(Int(dash.readinessScore))")
                                    .font(Theme.Typography.subheadline.weight(.bold).monospacedDigit())
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bereitschaft")
                                    .font(Theme.Typography.subheadline.weight(.semibold))
                                BentoText(
                                    verbatim: dash.recommendedFocus,
                                    style: .caption,
                                    color: .secondary
                                )
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
                    BentoEmptyState(
                        systemImage: "heart.text.square",
                        title: Text("Noch keine Trainingsdaten"),
                        message: Text("Schließe ein Workout ab, um deine Erholung zu sehen.")
                    )
                }
            }
        }
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
    var onEdit: ((Workout) -> Void)? = nil
    var onDelete: ((Workout) -> Void)? = nil
    let workouts: [Workout]

    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            BentoSectionHeader(title: Text("Schnellstart")) {
                BentoText(verbatim: "\(workouts.count) Workouts", style: .caption, color: .secondary)
            }

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

            if workouts.isEmpty {
                BentoCallout(
                    kind: .info,
                    title: Text("Noch keine Workouts"),
                    message: Text("Erstelle deinen ersten Trainingsplan über das Plus-Symbol.")
                )
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(workouts) { w in
                        workoutRow(w)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func workoutRow(_ w: Workout) -> some View {
        let avg = env.workoutService.getAverageDuration(workout: w)
        Button { onWorkoutSelect(w) } label: {
            BentoCard(style: .outlined, padding: .md) {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                            .fill(w.color.color.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: "dumbbell.fill")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(w.color.color)
                            .symbolEffect(.bounce, value: w.id)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.name)
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .lineLimit(1)
                        HStack(spacing: Theme.Spacing.m) {
                            Label("\(w.exercises.count)", systemImage: "list.bullet")
                                .font(Theme.Typography.caption2)
                            Label("\(avg > 0 ? "\(avg.clean) min" : "\(w.estimatedDurationMinutes) min")", systemImage: "clock")
                                .font(Theme.Typography.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let onEdit {
                        BentoIconButton(
                            systemImage: "ellipsis",
                            accessibilityLabel: Text("Bearbeiten"),
                            variant: .ghost,
                            size: .small
                        ) {
                            Haptics.impact()
                            onEdit(w)
                        }
                    }
                    BentoIconButton(
                        systemImage: "play.fill",
                        accessibilityLabel: Text("Starten"),
                        variant: .primary,
                        size: .small
                    ) {
                        onWorkoutSelect(w)
                    }
                }
            }
        }
        .buttonStyle(PressScaleStyle())
        .contextMenu {
            if let onEdit {
                Button("Bearbeiten", systemImage: "pencil") { onEdit(w) }
            }
            if let onDelete {
                Button("Archivieren", systemImage: "archivebox", role: .destructive) { onDelete(w) }
            }
        }
    }

    private func quickStartItem(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            BentoCard(tone: .neutral, style: .outlined, padding: .md) {
                VStack(spacing: Theme.Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(Theme.Typography.body.weight(.bold))
                            .foregroundStyle(color)
                    }
                    BentoText(verbatim: title, style: .caption, color: .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    BentoText(verbatim: subtitle, style: .caption, color: .secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
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
        BentoCard(tone: .accent, style: .elevated, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Wochenstatistik")) {
                    EmptyView()
                }

                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "sessions",
                        title: Text("Sessions"),
                        value: Text(verbatim: "\(sessionCount)")
                    ),
                    BentoStatValue(
                        id: "volume",
                        title: Text("Volumen"),
                        value: Text(verbatim: formatVolume)
                    ),
                    BentoStatValue(
                        id: "duration",
                        title: Text("Minuten"),
                        value: Text(verbatim: "\(durationMinutes)")
                    ),
                ])
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
        BentoCard(
            tone: .neutral,
            style: .elevated,
            padding: .lg
        ) {
            VStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(iconColor)
                        .symbolEffect(.bounce, value: title)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                    if !subtitle.isEmpty {
                        BentoText(verbatim: subtitle, style: .caption, color: .secondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
