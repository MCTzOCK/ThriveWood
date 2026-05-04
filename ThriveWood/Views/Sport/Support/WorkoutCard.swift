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
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(workout.color.gradient)
                    .frame(width: 54, height: 54)
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name).font(.headline).lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(workout.exercises.count) Übungen", systemImage: "list.bullet")
                    Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: { Haptics.impact(); onEdit() }) {
                    Image(systemName: "gear")
                        .font(.callout.weight(.bold))
                        .padding(12)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button(action: { Haptics.impact(); onStart() }) {
                    Image(systemName: "play.fill")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(workout.color.color))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
