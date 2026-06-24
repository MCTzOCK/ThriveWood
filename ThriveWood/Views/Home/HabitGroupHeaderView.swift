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
                        .fill(group.color.gradient)
                        .frame(width: 32, height: 32)
                    Image(systemName: group.iconSystemName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(habitCount) Habit\(habitCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { onEdit() }
            Button("Löschen", systemImage: "trash", role: .destructive) {
                onEdit()
            }
        }
    }
}

struct UngroupedHeaderView: View {
    let habitCount: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(Color.gray.gradient)
                    .frame(width: 32, height: 32)
                Image(systemName: "tray.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ohne Gruppe")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(habitCount) Habit\(habitCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
