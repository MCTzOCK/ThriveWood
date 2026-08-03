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
        GeometryReader { geo in
            VStack(spacing: 0) {
                TabView(selection: $selectedDesign) {
                    ForEach(SummaryDesign.allCases) { design in
                        WorkoutSummaryImage(data: data, design: design)
                            .frame(width: geo.size.width, height: geo.size.height - 140)
                    }
                    .tag(selectedDesign)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(maxWidth: .infinity)

                bottomBar
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomBar: some View {
        VStack(spacing: Theme.Spacing.s) {
            shareButton

            HStack(spacing: Theme.Spacing.m) {
                Text(selectedDesign.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                qualityButton(label: "Standard", scale: 2.0, selected: renderScale == 2.0)
                qualityButton(label: "Hoch", scale: 3.0, selected: renderScale == 3.0)
            }
        }
        .padding(Theme.Spacing.l)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var shareButton: some View {
        let rendered = renderImage()
        if let rendered {
            ShareLink(
                item: Image(uiImage: rendered),
                preview: SharePreview(session.workout?.name ?? "Workout", image: Image(uiImage: rendered))
            ) {
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
        }
    }

    private func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: WorkoutSummaryImage(data: data, design: selectedDesign))
        renderer.scale = renderScale
        return renderer.uiImage
    }

    private func qualityButton(label: String, scale: CGFloat, selected: Bool) -> some View {
        Button {
            renderScale = scale
            Haptics.selection()
        } label: {
            Text(label)
                .font(.caption.weight(selected ? .bold : .regular))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(selected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill)))
                .foregroundStyle(selected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
