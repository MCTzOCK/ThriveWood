//
//  HeatmapCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct HeatmapCard: View {
    let performances: [HabitPerformance]
    let selectedHabitID: UUID?
    let heatmap: [HabitHeatmapCell]
    let onSelect: (UUID) -> Void

    private let rows = 7        // Wochentage
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Aktivität (90 Tage)").font(.headline)
                Text("Je dunkler, desto mehr Punkte")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(performances) { p in
                        HabitChip(
                            performance: p,
                            isSelected: p.habitID == selectedHabitID,
                            action: { onSelect(p.habitID) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            grid
            legend
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    // MARK: Grid

    private var columns: [[HabitHeatmapCell?]] {
        guard let first = heatmap.first else { return [] }
        let cal = Calendar.app
        let weekday = cal.component(.weekday, from: first.date)
        // Offset relativ zum Wochenstart
        let offset = (weekday - cal.firstWeekday + 7) % 7
        var cells: [HabitHeatmapCell?] = Array(repeating: nil, count: offset)
        cells.append(contentsOf: heatmap.map { Optional($0) })
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map {
            Array(cells[$0..<min($0 + 7, cells.count)])
        }
    }

    private var grid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            cellView(column[safe: row] ?? nil)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func cellView(_ cell: HabitHeatmapCell?) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color(for: cell))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.accentColor.opacity(cell == nil ? 0 : 0.04), lineWidth: 1)
            )
    }

    private func color(for cell: HabitHeatmapCell?) -> Color {
        guard let cell, cell.points > 0 else {
            return Color.secondary.opacity(0.12)
        }
        let intensity: Double = switch cell.points {
        case 1: 0.25
        case 2: 0.45
        case 3: 0.65
        case 4...5: 0.8
        default: 1.0
        }
        return Color.accentColor.opacity(intensity)
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Weniger").font(.caption2).foregroundStyle(.secondary)
            ForEach([0.12, 0.25, 0.45, 0.65, 0.85, 1.0], id: \.self) { op in
                RoundedRectangle(cornerRadius: 3)
                    .fill(op <= 0.12 ? Color.secondary.opacity(0.12) : Color.accentColor.opacity(op))
                    .frame(width: 12, height: 12)
            }
            Text("Mehr").font(.caption2).foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: Chip
    private struct HabitChip: View {
        let performance: HabitPerformance
        let isSelected: Bool
        let action: () -> Void
        var body: some View {
            Button(action: { Haptics.selection(); action() }) {
                HStack(spacing: 6) {
                    Image(systemName: performance.iconSystemName)
                        .font(.caption.weight(.semibold))
                    Text(performance.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected
                                   ? performance.color.color
                                   : performance.color.color.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : performance.color.color)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Safe subscript helper
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
