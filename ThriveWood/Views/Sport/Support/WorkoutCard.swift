//
//  WorkoutCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    let onStart: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [workout.color.color, workout.color.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: workout.color.color.opacity(0.3), radius: 6, x: 0, y: 3)
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.white)
                    .font(Theme.Typography.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(Theme.Typography.headline)
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.m) {
                    Label("\(workout.exercises.count) Übungen", systemImage: "list.bullet")
                    Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: Theme.Spacing.s) {
                Button(action: { Haptics.impact(); onEdit() }) {
                    Image(systemName: "ellipsis")
                        .font(Theme.Typography.callout.weight(.bold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(BounceButtonStyle())

                Button(action: { Haptics.impact(); onStart() }) {
                    Image(systemName: "play.fill")
                        .font(Theme.Typography.callout.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(workout.color.color)
                                .shadow(color: workout.color.color.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Theme.Shadow.card, radius: 8, x: 0, y: 2)
    }
}
