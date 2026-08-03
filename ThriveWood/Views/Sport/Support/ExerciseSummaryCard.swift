//
//  ExerciseSummaryCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct ExerciseSummaryCard: View {
    let exercise: Exercise
    let sets: [SetEntry]

    @Environment(\.bentoTheme) private var theme
    @State private var expanded = true

    private var type: ExerciseTrackingType { exercise.trackingType }

    private var completedCount: Int { sets.filter(\.isCompleted).count }

    private var tone: BentoTone {
        switch type {
        case .repsWeight:       return .blue
        case .reps:             return .green
        case .duration:         return .warning
        case .distanceDuration: return .info
        }
    }

    private var bestSetText: String? {
        switch type {
        case .repsWeight:
            guard let best = sets.filter(\.isCompleted)
                .max(by: { ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0) })
            else { return nil }
            return best.summaryText
        case .reps:
            let total = sets.filter(\.isCompleted).reduce(0) { $0 + ($1.reps ?? 0) }
            return total > 0 ? "\(total) Reps gesamt" : nil
        case .duration:
            let total = sets.filter(\.isCompleted).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return total > 0 ? formatDuration(total) : nil
        case .distanceDuration:
            let dist = sets.filter(\.isCompleted).reduce(0.0) { $0 + ($1.distanceMeters ?? 0) }
            let dur = sets.filter(\.isCompleted).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return String(format: "%.2f km · %@", dist / 1000, formatDuration(dur))
        }
    }

    var body: some View {
        BentoDisclosureCard(isExpanded: $expanded, tone: tone) {
            header
        } content: {
            setsList
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: exercise.iconSystemName)
                    .font(.callout.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(theme.colors.onSurface)
                    .lineLimit(1)

                if let best = bestSetText {
                    Text(best)
                        .font(Theme.Typography.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                }
            }

            Spacer()

            BentoBadge(
                Text("\(completedCount)/\(sets.count)"),
                tone: completedCount == sets.count ? .success : .neutral,
                systemImage: completedCount == sets.count ? "checkmark.seal.fill" : nil
            )
        }
    }

    // MARK: - Sets List

    private var setsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                setRow(index: idx + 1, set: set)
                if idx < sets.count - 1 {
                    BentoDivider()
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.top, theme.spacing.sm)
    }

    @ViewBuilder
    private func setRow(index: Int, set: SetEntry) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .frame(width: 24)

            ZStack {
                Circle()
                    .fill(set.isCompleted ? theme.colors.success : theme.colors.outlineSubtle)
                    .frame(width: 22, height: 22)
                Image(systemName: set.isCompleted ? "checkmark" : "")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(theme.colors.onSuccess)
            }

            if set.isWarmup {
                BentoBadge(Text("WU"), tone: .warning)
            }

            Text(set.summaryText)
                .font(Theme.Typography.subheadline.monospacedDigit())
                .foregroundStyle(set.isCompleted ? theme.colors.onSurface : theme.colors.onSurfaceMuted)

            Spacer()
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, 8)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
