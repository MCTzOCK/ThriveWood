//
//  AchievementsView.swift
//  ThriveWood
//

import SwiftUI

struct AchievementsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: AchievementCategory?
    @State private var appeared = false

    private var svc: AchievementService { env.achievementService }

    private var filteredDefinitions: [AchievementDefinition] {
        guard let category = selectedCategory else {
            return AchievementDefinition.allCases
        }
        return svc.achievements(for: category)
    }

    private var unlockedCount: Int { svc.unlockedCount() }
    private var totalCount: Int { svc.totalCount() }
    private var progressFraction: Double {
        totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    heroHeader
                    categoryFilter
                    achievementsGrid
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Erfolge")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.2)) { appeared = true } }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: Theme.Spacing.l) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.15), .mint.opacity(0.1), .teal.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                VStack(spacing: Theme.Spacing.m) {
                    trophyIcon
                    progressStats
                    progressBar
                }
                .padding(Theme.Spacing.l)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var trophyIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 72, height: 72)

            Image(systemName: "trophy.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var progressStats: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            statItem(value: "\(unlockedCount)", label: "Freigeschaltet")
            statItem(value: "\(totalCount - unlockedCount)", label: "Verbleibend")
            statItem(value: "\(Int(progressFraction * 100))%", label: "Fortschritt")
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: appeared ? geo.size.width * progressFraction : 0,
                        height: 8
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: appeared)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                filterChip(label: "Alle", icon: "trophy.fill", color: .gray, isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedCategory = nil }
                }
                ForEach(AchievementCategory.allCases) { cat in
                    filterChip(
                        label: cat.label,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selectedCategory == cat
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedCategory = cat }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private func filterChip(label: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        LazyVStack(spacing: Theme.Spacing.m) {
            ForEach(filteredDefinitions) { def in
                achievementRow(for: def)
                    .padding(.horizontal, Theme.Spacing.l)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedCategory)
    }

    private func achievementRow(for def: AchievementDefinition) -> some View {
        let unlocked = svc.isUnlocked(def)
        let progress = svc.progress(for: def)
        let fraction = progress.target > 0 ? Double(progress.current) / Double(progress.target) : 0.0
        let records = svc.unlockedRecords()
        let unlockDate = records.first(where: { $0.definitionRaw == def.rawValue })?.unlockedAt

        return VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.m) {
                iconCircle(for: def, unlocked: unlocked, fraction: fraction)

                VStack(alignment: .leading, spacing: 3) {
                    Text(def.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(unlocked ? .primary : .secondary)

                    Text(unlocked ? def.description : progressText(for: def))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if unlocked, let date = unlockDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                unlockedBadge(unlocked: unlocked)
            }
            .padding(Theme.Spacing.m)

            if !unlocked {
                progressLayer(for: def, fraction: fraction)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .stroke(unlocked ? def.category.color.opacity(0.3) : Color(.systemGray5), lineWidth: unlocked ? 1.5 : 0.5)
        )
        .opacity(unlocked ? 1.0 : 0.75)
        .saturation(unlocked ? 1.0 : 0.4)
    }

    // MARK: - Sub-Components

    @ViewBuilder
    private func iconCircle(for def: AchievementDefinition, unlocked: Bool, fraction: Double) -> some View {
        ZStack {
            Circle()
                .fill(
                    unlocked
                    ? LinearGradient(colors: [def.category.color.opacity(0.2), def.category.color.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
                )

            if unlocked {
                Image(systemName: def.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(def.category.color)
            } else {
                ZStack {
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(def.category.color.opacity(0.5), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(-.degrees(90))

                    Image(systemName: def.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
        }
        .frame(width: 48, height: 48)
    }

    @ViewBuilder
    private func unlockedBadge(unlocked: Bool) -> some View {
        if unlocked {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: unlocked)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func progressLayer(for def: AchievementDefinition, fraction: Double) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray6))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [def.category.color.opacity(0.8), def.category.color.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(fraction, 0.02))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }

    private func progressText(for def: AchievementDefinition) -> String {
        let p = svc.progress(for: def)
        return "\(p.current)/\(p.target)"
    }
}