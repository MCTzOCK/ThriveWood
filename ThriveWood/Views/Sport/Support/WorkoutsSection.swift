//
//  WorkoutsSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct WorkoutsSection: View {
    let workouts: [Workout]
    let onStart: (Workout) -> Void
    let onEdit: (Workout) -> Void
    let onDelete: (Workout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Meine Workouts")
                .font(Theme.Typography.headline)

            if workouts.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Noch keine Workouts")
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Erstelle deinen ersten Plan über das Plus-Symbol.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
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
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(workouts) { w in
                        WorkoutCard(workout: w, onStart: { onStart(w) }, onEdit: { onEdit(w) })
                            .contextMenu {
                                Button("Bearbeiten", systemImage: "pencil") { onEdit(w) }
                                Button("Archivieren", systemImage: "archivebox", role: .destructive) {
                                    onDelete(w)
                                }
                            }
                    }
                }
            }
        }
    }
}
