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
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(workout.color.color.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(workout.color.color)
                    .font(Theme.Typography.title3)
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
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(Theme.Typography.caption2)
                        Text("\(workout.estimatedDurationMinutes) min")
                    }
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
                        .background(Circle().fill(workout.color.color))
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
