//
//  RootTabView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home, analytics, sport, nutrition, settings
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

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Habits", systemImage: "checklist") }
                .tag(AppTab.home)

            AnalyticsView()
                .tabItem { Label("Analyse", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.analytics)

            SportView()
                .tabItem { Label("Sport", systemImage: "dumbbell.fill") }
                .tag(AppTab.sport)

            /*NutritionTab()
                .tabItem { Label("Ernährung", systemImage: "fork.knife") }
                .tag(AppTab.nutrition)*/
            
            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape.2") }
                .tag(AppTab.settings)
        }
        .tint(profile?.accentTheme.color ?? .green)
        .preferredColorScheme(profile?.appearance.colorScheme)
        .onChange(of: selection) { _, _ in Haptics.selection() }
        .task {
            _ = try? env.profileRepo.currentProfile()
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
