//
//  AchievementsView.swift
//  ThriveWood
//

import SwiftUI

struct AchievementsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: AchievementCategory?
    @State private var unlockedIds: Set<String> = []
    @State private var unlockDates: [String: Date] = [:]

    private var svc: AchievementService { env.achievementService }

    private var filteredDefinitions: [AchievementDefinition] {
        guard let category = selectedCategory else {
            return AchievementDefinition.allCases
        }
        return svc.achievements(for: category)
    }

    private var unlockedCount: Int { unlockedIds.count }
    private var totalCount: Int { AchievementDefinition.allCases.count }
    private var progressFraction: Double {
        totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                heroHeader
                categoryFilter
                ForEach(filteredDefinitions) { def in
                    AchievementRow(
                        def: def,
                        isUnlocked: unlockedIds.contains(def.rawValue),
                        unlockDate: unlockDates[def.rawValue],
                        progress: svc.progress(for: def)
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                }
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Erfolge")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { refreshState() }
        .onChange(of: svc.unlockedIds) { _, _ in refreshState() }
    }

    private func refreshState() {
        unlockedIds = svc.unlockedIds
        let records = svc.unlockedRecords()
        var dates: [String: Date] = [:]
        for record in records { dates[record.definitionRaw] = record.unlockedAt }
        unlockDates = dates
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.yellow)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.yellow.opacity(0.12)))

            HStack(spacing: Theme.Spacing.xxl) {
                statItem(value: "\(unlockedCount)", label: "Freigeschaltet")
                statItem(value: "\(totalCount - unlockedCount)", label: "Verbleibend")
                statItem(value: "\(Int(progressFraction * 100))%", label: "Fortschritt")
            }

            ProgressView(value: progressFraction)
                .tint(Color.accentColor)
                .frame(height: 8)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color.accentColor.opacity(0.06))
        )
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                filterChip(label: "Alle", icon: "trophy.fill", color: .gray, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(AchievementCategory.allCases) { cat in
                    filterChip(
                        label: cat.label,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private func filterChip(label: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(Theme.Typography.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? color : Color(.secondarySystemGroupedBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Row

private struct AchievementRow: View {
    let def: AchievementDefinition
    let isUnlocked: Bool
    let unlockDate: Date?
    let progress: (current: Int, target: Int)

    private var fraction: Double {
        progress.target > 0 ? Double(progress.current) / Double(progress.target) : 0.0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.m) {
                iconCircle

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(def.title)
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(isUnlocked ? .primary : .secondary)

                        if !isUnlocked {
                            Text("\(progress.current)/\(progress.target)")
                                .font(Theme.Typography.caption2.monospacedDigit())
                                .foregroundStyle(def.category.color.opacity(0.7))
                        }
                    }

                    Text(def.description)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if isUnlocked, let date = unlockDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }
            }
            .padding(Theme.Spacing.m)

            if !isUnlocked {
                ProgressView(value: fraction)
                    .tint(def.category.color)
                    .frame(height: 5)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.s)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .opacity(isUnlocked ? 1.0 : 0.75)
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(isUnlocked ? def.category.color.opacity(0.15) : Color(.tertiarySystemFill))

            if isUnlocked {
                Image(systemName: def.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(def.category.color)
            } else {
                Image(systemName: def.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .frame(width: 48, height: 48)
    }
}
