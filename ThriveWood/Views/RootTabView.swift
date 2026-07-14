//
//  RootTabView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable, CaseIterable {
    case home, analytics, sport, settings

    var label: String {
        switch self {
        case .home: "Habits"
        case .analytics: "Analyse"
        case .sport: "Sport"
        case .settings: "Profil"
        }
    }

    var icon: String {
        switch self {
        case .home: "checklist"
        case .analytics: "chart.bar.xaxis"
        case .sport: "dumbbell.fill"
        case .settings: "person.crop.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: "checkmark.circle.fill"
        case .analytics: "chart.bar.xaxis"
        case .sport: "dumbbell.fill"
        case .settings: "person.crop.circle.fill"
        }
    }
}

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env
    @Query private var profiles: [UserProfile]
    @State private var selection: AppTab = .home
    @State private var showOnboarding = false

    private var profile: UserProfile? { profiles.first }
    private var needsOnboarding: Bool {
        profile?.onboardingCompletedAt == nil
    }

    private var accentColor: Color {
        profile?.accentTheme.color ?? .green
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content(for: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity
                ))

            PremiumTabBar(selection: $selection, accentColor: accentColor)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.s)
        }
        .preferredColorScheme(profile?.appearance.colorScheme)
        .tint(accentColor)
        .task {
            _ = try? env.profileRepo.currentProfile()
            env.achievementService.checkAll(silent: true)
        }
        .onAppear {
            if needsOnboarding { showOnboarding = true }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isRerun: false) {
                showOnboarding = false
            }
        }
        .achievementHUD()
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .analytics:
            AnalyticsView()
        case .sport:
            SportView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Premium Tab Bar

private struct PremiumTabBar: View {
    @Binding var selection: AppTab
    let accentColor: Color
    @Namespace private var ns
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.s + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(scheme == .dark ? 0.15 : 0.6),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = selection == tab

        Button {
            guard !isSelected else { return }
            Haptics.impact(.light)
            withAnimation(Theme.Animation.spring) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 26)
                    .foregroundStyle(isSelected ? accentColor : .secondary)

                Text(tab.label)
                    .font(Theme.Typography.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                        .fill(accentColor.opacity(scheme == .dark ? 0.15 : 0.1))
                        .matchedGeometryEffect(id: "tabIndicator", in: ns)
                }
            }
        }
        .buttonStyle(PressScaleStyle())
        .sensoryFeedback(.selection, trigger: selection)
    }
}
