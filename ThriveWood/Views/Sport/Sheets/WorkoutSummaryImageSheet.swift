//
//  WorkoutSummaryImageSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//


import SwiftUI

struct WorkoutSummaryImageSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var shareItem: ShareItem?

    private var sortedExercises: [(Exercise, [SetEntry])] {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        if let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }), !plan.isEmpty {
            return plan.compactMap { slot in
                guard let ex = slot.exercise else { return nil }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                guard !sets.isEmpty else { return nil }
                return (ex, sets)
            }
        }
        let unique = Set(session.sets.compactMap { $0.exercise })
        return unique.sorted { $0.name < $1.name }.map { ex in
            (ex, (groups[ex.id] ?? []).sorted { $0.order < $1.order })
        }
    }

    private var completedSets: Int { session.sets.filter(\.isCompleted).count }
    private var totalSets: Int { session.sets.count }

    private var totalVolumeKg: Double {
        session.sets
            .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
            .reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }

    private var totalReps: Int {
        session.sets
            .filter {
                guard let t = $0.exercise?.trackingType else { return false }
                return (t == .reps || t == .repsWeight) && $0.isCompleted
            }
            .reduce(0) { $0 + ($1.reps ?? 0) }
    }

    private var totalDistanceKm: Double {
        session.sets
            .filter { $0.exercise?.trackingType == .distanceDuration && $0.isCompleted }
            .reduce(0) { $0 + ($1.distanceMeters ?? 0) } / 1000
    }

    private var activeDurationSeconds: Int {
        session.sets
            .filter { $0.exercise?.trackingType == .duration && $0.isCompleted }
            .reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.l) {
                summaryImagePreview
                shareButton
            }
            .padding(Theme.Spacing.l)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Zusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .sheet(item: $shareItem) { item in
                WorkoutSummaryShareSheet(items: [item.image])
            }
        }
    }

    private var summaryImagePreview: some View {
        WorkoutSummaryImage(
            session: session,
            sortedExercises: sortedExercises,
            totalVolumeKg: totalVolumeKg,
            totalReps: totalReps,
            totalDistanceKm: totalDistanceKm,
            activeDurationSeconds: activeDurationSeconds,
            completedSets: completedSets,
            totalSets: totalSets
        )
    }

    private var shareButton: some View {
        Button {
            let renderer = ImageRenderer(content: summaryImagePreview)
            renderer.scale = 3.0
            if let uiImage = renderer.uiImage {
                shareItem = ShareItem(image: uiImage)
                Haptics.success()
            }
        } label: {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "square.and.arrow.up")
                Text("Bild teilen")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .background(Capsule().fill(Color.accentColor))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
