//
//  WorkoutCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct WorkoutCard: View {

    @Environment(AppEnvironment.self) private var env

    let workout: Workout
    let onStart: () -> Void
    let onEdit: () -> Void

    var body: some View {
        BentoCard(style: .outlined, padding: .md) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(workout.color.color.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(workout.color.color)
                        .font(Theme.Typography.title3)
                        .symbolEffect(.bounce, value: workout.name)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(Theme.Typography.headline)
                        .lineLimit(1)
                    HStack(spacing: Theme.Spacing.m) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(Theme.Typography.caption2)
                            Text("\(workout.exercises.count)")
                                .contentTransition(.numericText())
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(Theme.Typography.caption2)
                            Text("\(env.workoutService.getAverageDuration(workout: workout).clean) min")
                        }
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: Theme.Spacing.s) {
                    BentoIconButton(
                        systemImage: "ellipsis",
                        accessibilityLabel: Text("Bearbeiten"),
                        variant: .ghost,
                        size: .small
                    ) {
                        Haptics.impact()
                        onEdit()
                    }

                    BentoIconButton(
                        systemImage: "play.fill",
                        accessibilityLabel: Text("Starten"),
                        variant: .primary,
                        size: .small
                    ) {
                        Haptics.impact()
                        onStart()
                    }
                }
            }
        }
    }
}
