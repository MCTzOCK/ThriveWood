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
                BentoEmptyState(
                    systemImage: "dumbbell.fill",
                    title: Text("Noch keine Workouts"),
                    message: Text("Erstelle deinen ersten Plan über das Plus-Symbol.")
                )
                .cardStyle()
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
