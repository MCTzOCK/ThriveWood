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
    @State private var showOnboarding = false
    @State private var errors = ErrorState()
    @State private var showingImport = false
    @State private var showingExport = false

    @AppStorage("activityProfile") private var activityProfileRaw: String = ActivityProfile.moderat.rawValue

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
            .sheet(isPresented: $showingExport) {
                if env.entitlements.canExportData {
                    ExportSheet()
                } else {
                    PaywallView()
                }
            }
            .sheet(isPresented: $showingImport) {
                if env.entitlements.canExportData {
                    ImportSheet {
                        await loadAll()
                    }
                } else {
                    PaywallView()
                }
            }
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

            SubscriptionStatusSection()
            
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
                            .foregroundStyle(.tint)
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
                        Image(systemName: "calendar").foregroundStyle(.tint)
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
                        Image(systemName: "scalemass.fill").foregroundStyle(.tint)
                        Text("Gewichtseinheit")
                    }
                }

                Stepper(value: $profile.defaultRestSeconds, in: 0...600, step: 15) {
                    HStack {
                        Image(systemName: "timer").foregroundStyle(.tint)
                        Text("Standard-Pause")
                        Spacer()
                        Text(formatRest(profile.defaultRestSeconds))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Picker(selection: $activityProfileRaw) {
                    ForEach(ActivityProfile.allCases) { profile in
                        Label(profile.label, systemImage: profile.icon).tag(profile.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "figure.highintensity.interval").foregroundStyle(.tint)
                        Text("Aktivitätsprofil")
                    }
                }
                
                HStack {
                    Image(systemName: "chart.bar.fill").foregroundStyle(.tint)
                    Toggle("Untrainierte Muskeln zählen", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "includeUntrainedMuscles") },
                        set: { UserDefaults.standard.set($0, forKey: "includeUntrainedMuscles") }
                    ))
                }
            } header: {
                Text("Sport")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wenn aus, werden Muskeln mit 0 kg Volumen vom Gesamt-Rang ausgenommen.")
                    Text("Das Aktivitätsprofil beeinflusst die Erholungs-Empfehlungen in der Muskelkarte.")
                }
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
            
            // MARK: Onboarding

            Section("Onboarding") {
                Button {
                    showOnboarding = true
                } label: {
                    Label("Onboarding wiederholen", systemImage: "arrow.counterclockwise")
                }
            }
            
            Section {
                if !env.healthService.isAvailable {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "heart.slash").foregroundStyle(.red)
                        Text("HealthKit ist auf diesem Gerät nicht verfügbar.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        Toggle("Apple Health Sync", isOn: Binding(
                            get: { env.healthService.isAuthorized },
                            set: { newValue in
                                if newValue {
                                    Task { await env.healthService.requestAuthorization() }
                                }
                            }
                        ))
                    }
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text("Workouts werden automatisch in Apple Health gespeichert. Schritte und Kalorien erscheinen in der Analyse.")
            }

            Section {
                Button {
                    showingExport = true
                } label: {
                    Label("Daten exportieren", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingImport = true
                } label: {
                    Label("Daten importieren", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Daten")
            } footer: {
                Text("Erstelle ein vollständiges JSON-Backup aller Habits, Workouts, Sessions und deines Waldes.")
            }

            
            
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
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isRerun: true) {
                showOnboarding = false
            }
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
