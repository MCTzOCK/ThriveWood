//
//  WorkoutSummaryImageSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//


import SwiftUI

struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct WorkoutSummaryImageSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var selectedDesign: SummaryDesign = .dark
    @State private var renderScale: CGFloat = 3.0

    private var data: SummaryData {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        let sorted: [(Exercise, [SetEntry])]
        if let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }), !plan.isEmpty {
            var result: [(Exercise, [SetEntry])] = []
            for slot in plan {
                guard let ex = slot.exercise else { continue }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty { result.append((ex, sets)) }
            }
            let unique = Set(session.sets.compactMap { $0.exercise })
            for ex in unique.sorted(by: { $0.name < $1.name }) {
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty && !plan.contains(where: { $0.exercise?.id == ex.id }) {
                    result.append((ex, sets))
                }
            }
            sorted = result
        } else {
            let unique = Set(session.sets.compactMap { $0.exercise })
            sorted = unique.sorted { $0.name < $1.name }.map { ex in
                (ex, (groups[ex.id] ?? []).sorted { $0.order < $1.order })
            }
        }
        return SummaryData(
            session: session,
            sortedExercises: sorted,
            totalVolumeKg: session.sets
                .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
                .reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) },
            totalReps: session.sets
                .filter { guard let t = $0.exercise?.trackingType else { return false }; return (t == .reps || t == .repsWeight) && $0.isCompleted }
                .reduce(0) { $0 + ($1.reps ?? 0) },
            totalDistanceKm: session.sets
                .filter { $0.exercise?.trackingType == .distanceDuration && $0.isCompleted }
                .reduce(0) { $0 + ($1.distanceMeters ?? 0) } / 1000,
            activeDurationSeconds: session.sets
                .filter { $0.exercise?.trackingType == .duration && $0.isCompleted }
                .reduce(0) { $0 + ($1.durationSeconds ?? 0) },
            completedSets: session.sets.filter(\.isCompleted).count,
            totalSets: session.sets.count
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedDesign) {
                ForEach(SummaryDesign.allCases) { design in
                    ScrollView(.vertical, showsIndicators: false) {
                        WorkoutSummaryImage(data: data, design: design)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 560)
                            .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            shareButton
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var shareButton: some View {
        let rendered = renderImage()
        if let rendered {
            ShareLink(
                item: Image(uiImage: rendered),
                preview: SharePreview(session.workout?.name ?? "Workout", image: Image(uiImage: rendered))
            ) {
                BentoButton(
                    Text("Bild teilen"),
                    systemImage: "square.and.arrow.up",
                    variant: .primary,
                    expands: true
                ) {}
                    .allowsHitTesting(false)
            }
        }
    }

    private func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: WorkoutSummaryImage(data: data, design: selectedDesign))
        renderer.scale = renderScale
        return renderer.uiImage
    }
}
