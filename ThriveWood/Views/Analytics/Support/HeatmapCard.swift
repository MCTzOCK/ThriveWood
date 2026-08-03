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
    @Environment(\.bentoTheme) private var theme

    private let rows = 7
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3

    var body: some View {
        BentoSection(title: Text("Aktivität"), subtitle: Text("90 Tage Verlauf")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(performances) { p in
                                Button {
                                    Haptics.selection()
                                    onSelect(p.habitID)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: p.iconSystemName)
                                            .font(.caption.weight(.semibold))
                                        Text(p.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, theme.spacing.sm)
                                    .padding(.vertical, theme.spacing.xxs)
                                    .background(
                                        Capsule().fill(
                                            p.habitID == selectedHabitID
                                            ? p.color.color
                                            : p.color.color.opacity(0.12)
                                        )
                                    )
                                    .foregroundStyle(
                                        p.habitID == selectedHabitID
                                        ? .white
                                        : p.color.color
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    grid
                    legend
                }
            }
        }
    }

    private var columns: [[HabitHeatmapCell?]] {
        guard let first = heatmap.first else { return [] }
        let cal = Calendar.app
        let weekday = cal.component(.weekday, from: first.date)
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
                    .strokeBorder(
                        theme.colors.accent.opacity(cell == nil ? 0 : 0.04),
                        lineWidth: 1
                    )
            )
    }

    private func color(for cell: HabitHeatmapCell?) -> Color {
        guard let cell, cell.points > 0 else {
            return theme.colors.onSurface.opacity(0.08)
        }
        let intensity: Double = switch cell.points {
        case 1: 0.25
        case 2: 0.45
        case 3: 0.65
        case 4...5: 0.8
        default: 1.0
        }
        return theme.colors.accent.opacity(intensity)
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Weniger")
                .font(.caption2)
                .foregroundStyle(theme.colors.onSurfaceMuted)
            ForEach([0.12, 0.25, 0.45, 0.65, 0.85, 1.0], id: \.self) { op in
                RoundedRectangle(cornerRadius: 3)
                    .fill(op <= 0.12
                          ? theme.colors.onSurface.opacity(0.08)
                          : theme.colors.accent.opacity(op))
                    .frame(width: 12, height: 12)
            }
            Text("Mehr")
                .font(.caption2)
                .foregroundStyle(theme.colors.onSurfaceMuted)
            Spacer()
        }
    }
}