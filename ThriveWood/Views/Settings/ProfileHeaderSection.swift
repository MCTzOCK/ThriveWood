//
//  ProfileHeaderSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct ProfileHeaderSection: View {
    @Bindable var profile: UserProfile
    let totalEarned: Int
    let totalSpent: Int

    var body: some View {
        Section {
            VStack(spacing: Theme.Spacing.l) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [profile.accentTheme.color, profile.accentTheme.color.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: profile.accentTheme.color.opacity(0.3), radius: 12, y: 4)
                    Text(initials)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }

                TextField("Dein Name", text: $profile.displayName)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)

                HStack(spacing: Theme.Spacing.l) {
                    KPI(value: "\(totalEarned)", label: "Punkte", tint: .green)
                    Divider().frame(height: 32)
                    KPI(value: "\(totalSpent)", label: "Investiert", tint: .blue)
                    Divider().frame(height: 32)
                    KPI(value: "\(max(0, totalEarned - totalSpent))",
                        label: "Verfügbar", tint: .orange)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
            .listRowBackground(Color.clear)
        }
    }

    private var initials: String {
        let trimmed = profile.displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "🌱" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private struct KPI: View {
        let value: String; let label: String; let tint: Color
        var body: some View {
            VStack(spacing: 2) {
                Text(value).font(.headline.monospacedDigit()).foregroundStyle(tint)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
