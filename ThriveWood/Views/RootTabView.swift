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

    var oldBody: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(AppTab.home.label, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            AnalyticsView()
                .tabItem { Label(AppTab.analytics.label, systemImage: AppTab.analytics.icon) }
                .tag(AppTab.analytics)

            SportViewV2()
                .tabItem { Label(AppTab.sport.label, systemImage: AppTab.sport.icon) }
                .tag(AppTab.sport)

            SettingsView()
                .tabItem { Label(AppTab.settings.label, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(accentColor)
        .preferredColorScheme(profile?.appearance.colorScheme)
        .onChange(of: selection) { _, _ in Haptics.selection() }
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
    
    var body: some View {
        BentoTabScaffold(selection: $selection, items: [
            BentoTabItem(id: AppTab.home, title: Text("Habits"), systemImage: "checklist"),
            BentoTabItem(id: AppTab.analytics, title: Text("Annalyse"), systemImage: "chart.bar.xaxis"),
            BentoTabItem(id: AppTab.sport, title: Text("Sport"), systemImage: "dumbbell.fill"),
            BentoTabItem(id: AppTab.settings, title: Text("Profil"), systemImage: "person.crop.circle")
        ]) {
            switch selection {
            case .home: HomeView()
            case .analytics: AnalyticsView()
            case .sport: SportViewV2()
            case .settings: BentoSettingsView()
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: selection) { _, _ in Haptics.selection() }
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
    }
}
