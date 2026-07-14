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
                        .fill(
                            LinearGradient(
                                colors: [group.color.color, group.color.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: group.color.color.opacity(0.3), radius: 4, x: 0, y: 2)
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
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground).opacity(0.6))
            )
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

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray, Color.gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
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
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground).opacity(0.6))
        )
    }
}
