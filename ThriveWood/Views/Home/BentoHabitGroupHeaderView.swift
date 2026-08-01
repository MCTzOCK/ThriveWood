//
//  BentoHabitGroupHeaderView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.08.26.
//

import SwiftUI

struct BentoHabitGroupHeaderView: View {
    @Environment(\.bentoTheme) private var theme

    let group: HabitGroup
    let habitCount: Int
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: theme.radii.small,
                        style: .continuous
                    )
                    .fill(group.color.color)
                    .frame(width: 34, height: 34)
                    Image(systemName: group.iconSystemName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    BentoText("\(group.title)", style: .headline)
                    BentoText(
                        "\(habitCount) Habit\(habitCount == 1 ? "" : "s")",
                        style: .caption,
                        color: theme.colors.onSurfaceMuted
                    )
                }

                Spacer()

                Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(
                    cornerRadius: theme.radii.large,
                    style: .continuous
                )
                .fill(theme.colors.surface)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: theme.radii.large,
                    style: .continuous
                )
                .strokeBorder(
                    theme.colors.outlineSubtle,
                    lineWidth: theme.borders.thin
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { onEdit() }
            Button("Löschen", systemImage: "trash", role: .destructive) { onEdit() }
        }
    }
}

struct BentoUngroupedHeaderView: View {
    @Environment(\.bentoTheme) private var theme

    let habitCount: Int
    var isCollapsed: Bool = false

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: theme.radii.small,
                    style: .continuous
                )
                .fill(Color.gray)
                .frame(width: 34, height: 34)
                Image(systemName: "tray.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                BentoText("Ohne Gruppe", style: .headline)
                BentoText(
                    "\(habitCount) Habit\(habitCount == 1 ? "" : "s")",
                    style: .caption,
                    color: theme.colors.onSurfaceMuted
                )
            }

            Spacer()

            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
            RoundedRectangle(
                cornerRadius: theme.radii.large,
                style: .continuous
            )
            .fill(theme.colors.surface)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: theme.radii.large,
                style: .continuous
            )
            .strokeBorder(
                theme.colors.outlineSubtle,
                lineWidth: theme.borders.thin
            )
        }
    }
}
