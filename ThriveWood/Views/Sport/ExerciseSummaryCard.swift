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

    @State private var expanded = true

    private var type: ExerciseTrackingType { exercise.trackingType }

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
        VStack(alignment: .leading, spacing: 0) {
            header
            if expanded {
                Divider().padding(.horizontal, Theme.Spacing.l)
                setsTable
            }
        }
        .cardStyle()
    }

    private var header: some View {
        Button {
            withAnimation(.snappy) { expanded.toggle() }
            Haptics.selection()
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: exercise.iconSystemName)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name).font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let best = bestSetText {
                        Text(best).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(expanded ? 0 : -90))
            }
            .padding(Theme.Spacing.l)
        }
        .buttonStyle(.plain)
    }

    private var setsTable: some View {
        VStack(spacing: 0) {
            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                SetSummaryRow(index: idx + 1, set: set, type: type)
                if idx < sets.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.s)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

private struct SetSummaryRow: View {
    let index: Int
    let set: SetEntry
    let type: ExerciseTrackingType

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28)

            HStack(spacing: 6) {
                if set.isWarmup {
                    Text("WU")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundStyle(.orange)
                }
                Text(set.summaryText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(set.isCompleted ? .primary : .secondary)
            }

            Spacer()

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.callout)
                .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.5))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, 8)
    }
}
