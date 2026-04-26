//
//  SettingsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 24.04.26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var profile: UserProfile?
    @State private var notificationsAuth: UNAuthorizationStatus = .notDetermined
    @State private var pendingRequestCount: Int = 0
    @State private var showingResetConfirm = false
    @State private var showingDebug = false
    @State private var showingIconPicker = false
    @State private var errors = ErrorState()

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(profile: profile)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await loadAll() }
        .errorAlert(errors)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(profile: UserProfile) -> some View {
        @Bindable var profile = profile

        Form {
            ProfileHeaderSection(profile: profile,
                                 totalEarned: env.scoringService.totalsCached.earned,
                                 totalSpent: env.scoringService.totalsCached.spent)

            // MARK: Erscheinungsbild
            Section("Erscheinungsbild") {
                Picker("Modus", selection: $profile.appearanceRaw) {
                    ForEach(AppAppearance.allCases) { Text($0.label).tag($0.rawValue) }
                }
                NavigationLink {
                    AccentThemePicker(selection: Binding(
                        get: { profile.accentTheme },
                        set: { profile.accentTheme = $0; save(profile) }
                    ))
                } label: {
                    HStack {
                        Text("Akzentfarbe")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(profile.accentTheme.color)
                                .frame(width: 18, height: 18)
                            Text(profile.accentTheme.label)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    showingIconPicker = true
                } label: {
                    HStack {
                        Text("App-Icon").foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // MARK: Habits & Ziele
            Section {
                Stepper(value: $profile.dailyPointGoal, in: 1...50) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(.green)
                        Text("Tagesziel")
                        Spacer()
                        Text("\(profile.dailyPointGoal) P")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Picker(selection: $profile.weekStartsOnRaw) {
                    ForEach([Weekday.monday, .sunday, .saturday]) {
                        Text($0.fullLabel).tag($0.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar").foregroundStyle(.blue)
                        Text("Wochenbeginn")
                    }
                }
            } header: {
                Text("Habits & Ziele")
            }

            // MARK: Sport
            Section {
                Picker(selection: $profile.preferredWeightUnitRaw) {
                    Text("Kilogramm (kg)").tag(WeightUnit.kilograms.rawValue)
                    Text("Pounds (lb)").tag(WeightUnit.pounds.rawValue)
                } label: {
                    HStack {
                        Image(systemName: "scalemass.fill").foregroundStyle(.purple)
                        Text("Gewichtseinheit")
                    }
                }

                Stepper(value: $profile.defaultRestSeconds, in: 0...600, step: 15) {
                    HStack {
                        Image(systemName: "timer").foregroundStyle(.orange)
                        Text("Standard-Pause")
                        Spacer()
                        Text(formatRest(profile.defaultRestSeconds))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Sport")
            }

            // MARK: Mitteilungen
            NotificationsSection(
                profile: profile,
                authStatus: notificationsAuth,
                pendingCount: pendingRequestCount,
                onSave: { save(profile) },
                onOpenSettings: openSystemSettings,
                onTestFire: testNotification,
                onRefresh: { await loadAll() }
            )

            // MARK: Über
            AboutSection()

            // MARK: Debug
            #if DEBUG
            Section("Debug") {
                Button {
                    showingDebug = true
                } label: {
                    Label("Debug-Menü", systemImage: "hammer.fill")
                }
                .foregroundStyle(.orange)
            }
            #endif

            // MARK: Danger Zone
            Section {
                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    Label("Alle Daten löschen", systemImage: "trash.fill")
                }
            } header: {
                Text("Gefahrenzone")
            } footer: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
        .tint(profile.accentTheme.color)
        .preferredColorScheme(profile.appearance.colorScheme)
        .onChange(of: profile.appearanceRaw) { _, _ in save(profile) }
        .onChange(of: profile.dailyPointGoal) { _, _ in save(profile) }
        .onChange(of: profile.weekStartsOnRaw) { _, _ in
            AppCalendarConfig.shared.update(weekStartsOn: profile.weekStartsOn)
            save(profile)
        }
        .onChange(of: profile.preferredWeightUnitRaw) { _, _ in save(profile) }
        .onChange(of: profile.defaultRestSeconds) { _, _ in save(profile) }
        .onChange(of: profile.iCloudSyncEnabled) { _, _ in save(profile) }
        .sheet(isPresented: $showingIconPicker) { AppIconPickerView() }
        #if DEBUG
        .sheet(isPresented: $showingDebug) { DebugMenuView() }
        #endif
        .confirmationDialog(
            "Alle Daten wirklich löschen?",
            isPresented: $showingResetConfirm, titleVisibility: .visible
        ) {
            Button("Ja, alles löschen", role: .destructive) {
                do {
                    #if DEBUG
                    try env.debugService.wipeEverything()
                    #endif
                    Haptics.success()
                } catch { errors.show(error) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Habits, Wald, Trainings und Verlauf werden unwiderruflich entfernt.")
        }
    }

    // MARK: - Loading

    private func loadAll() async {
        do {
            profile = try env.profileRepo.currentProfile()
        } catch { errors.show(error) }

        await env.notificationService.refreshAuthorizationStatus()
        notificationsAuth = env.notificationService.authorizationStatus
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingRequestCount = pending.count
    }

    private func save(_ profile: UserProfile) {
        try? env.profileRepo.update(profile)
    }

    private func testNotification() {
        #if DEBUG
        Task { try? await env.debugService.fireTestNotification() }
        #endif
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s)) min"
    }
}
