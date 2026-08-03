//
//  ProfileHubView.swift
//  ThriveWood
//

import SwiftUI

struct ProfileHubView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var treeCount: Int = 0
    @State private var availablePoints: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    statsBanner

                    VStack(spacing: Theme.Spacing.m) {
                        NavigationLink {
                            NutritionTab()
                        } label: {
                            hubCard(
                                icon: "fork.knife",
                                color: .pink,
                                title: "Ernährung",
                                subtitle: "Essen & Supplements tracken"
                            )
                        }

                        NavigationLink {
                            ForestView()
                        } label: {
                            hubCard(
                                icon: "tree.fill",
                                color: .brown,
                                title: "Mein Wald",
                                subtitle: "Bäume pflanzen & pflegen"
                            )
                        }

                        NavigationLink {
                            BentoSettingsView()
                        } label: {
                            hubCard(
                                icon: "gearshape.fill",
                                color: .gray,
                                title: "Einstellungen",
                                subtitle: "Profil, Theme & Daten"
                            )
                        }

                        if !env.entitlements.isPro {
                            NavigationLink {
                                PaywallView()
                            } label: {
                                hubCard(
                                    icon: "crown.fill",
                                    color: .yellow,
                                    title: "ThriveWood Pro",
                                    subtitle: "Alle Features freischalten"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mehr")
            .navigationBarTitleDisplayMode(.large)
            .task { loadStats() }
        }
    }

    private var statsBanner: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            statItem(icon: "tree.fill", color: .brown, value: "\(treeCount)", label: "Bäume")
            statItem(icon: "leaf.fill", color: .accentColor, value: "\(availablePoints)", label: "Punkte")
            statItem(icon: "trophy.fill", color: .orange, value: "Pro", label: env.entitlements.isPro ? "Aktiv" : "Frei")
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func hubCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private func loadStats() {
        treeCount = (try? env.forestService.trees().count) ?? 0
        availablePoints = (try? env.scoringService.availablePoints()) ?? 0
    }
}