//
//  HabitGroupHeaderView.swift
//  ThriveWood
//

import SwiftUI

struct HabitGroupHeaderView: View {
    let group: HabitGroup
    let habitCount: Int
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(group.color.color)
                        .frame(width: 34, height: 34)
                    Image(systemName: group.iconSystemName)
                        .font(Theme.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text("\(habitCount) Habit\(habitCount == 1 ? "" : "s")")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
        }
        .buttonStyle(PressScaleStyle())
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { onEdit() }
            Button("Löschen", systemImage: "trash", role: .destructive) { onEdit() }
        }
    }
}

struct UngroupedHeaderView: View {
    let habitCount: Int
    var isCollapsed: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(Color.gray)
                    .frame(width: 34, height: 34)
                Image(systemName: "tray.fill")
                    .font(Theme.Typography.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ohne Gruppe")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("\(habitCount) Habit\(habitCount == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
    }
}
