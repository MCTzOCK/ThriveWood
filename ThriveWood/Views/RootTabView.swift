//
//  RootTabView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

enum AppTab: Hashable {
    case home, forest, analytics, sport, settings
}

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "checklist") }
                .tag(AppTab.home)

            ForestView()
                .tabItem { Label("Wald", systemImage: "tree.fill") }
                .tag(AppTab.forest)

            AnalyticsView()
                .tabItem { Label("Analyse", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.analytics)

            SportView()
                .tabItem { Label("Sport", systemImage: "dumbbell.fill") }
                .tag(AppTab.sport)
            
            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.green)
        .onChange(of: selection) { _, _ in Haptics.selection() }
    }
}
