//
//  NotificationsSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//

import SwiftUI
import UserNotifications

struct NotificationsSection: View {
    @Bindable var profile: UserProfile
    let authStatus: UNAuthorizationStatus
    let pendingCount: Int
    let onSave: () -> Void
    let onOpenSettings: () -> Void
    let onTestFire: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        Section {
            if authStatus == .denied {
                deniedBanner
            } else if authStatus == .notDetermined {
                notDeterminedBanner
            }

            Toggle(isOn: $profile.enableNotifications) {
                Label("Mitteilungen aktiv", systemImage: "bell.fill")
            }
            .onChange(of: profile.enableNotifications) { _, _ in onSave() }

            if profile.enableNotifications && authStatus != .denied {
                HStack {
                    Label("Geplante Erinnerungen", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text("\(pendingCount)")
                        .foregroundStyle(.secondary).monospacedDigit()
                }

                #if DEBUG
                Button {
                    onTestFire()
                } label: {
                    Label("Test-Mitteilung in 5s", systemImage: "bell.badge.fill")
                }
                .foregroundStyle(.tint)
                #endif
            }
        } header: {
            Text("Mitteilungen")
        } footer: {
            Text("Erinnerungen helfen dir, deine Habits konsequent abzuhaken – sie werden lokal auf deinem Gerät verarbeitet.")
        }
        .task { await onRefresh() }
    }

    // MARK: Banners

    private var deniedBanner: some View {
        Button(action: onOpenSettings) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mitteilungen sind deaktiviert").font(.subheadline.weight(.semibold))
                    Text("Aktiviere sie in den iOS-Einstellungen, damit Reminder funktionieren.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square").foregroundStyle(.orange)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var notDeterminedBanner: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "info.circle.fill").foregroundStyle(.tint)
            Text("Du wirst beim Aktivieren eines Reminders nach Erlaubnis gefragt.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
