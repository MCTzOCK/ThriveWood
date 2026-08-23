//
//  SettingsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 24.04.26.
//

import SwiftUI
import StoreKit
import UserNotifications

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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingExport) {
                if env.entitlements.canExportData {
                    ExportSheet()
                } else {
                    PaywallView()
                }
            }
            .sheet(isPresented: $showingImport) {
                if env.entitlements.canExportData {
                    ImportSheet { await loadAll() }
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

        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                premiumHeader

                ProfileHeroCard(profile: profile,
                                totalEarned: env.scoringService.totalsCached.earned,
                                totalSpent: env.scoringService.totalsCached.spent)

                SubscriptionStatusCard()

                // MARK: Erscheinungsbild
                SettingsGroup(title: "Erscheinungsbild", icon: "paintbrush.fill", iconColor: .pink) {
                    NavigationLink {
                        AccentThemePicker(selection: Binding(
                            get: { profile.accentTheme },
                            set: { profile.accentTheme = $0; save(profile) }
                        ))
                    } label: {
                        SettingsRow(
                            icon: "circlepalette.fill",
                            iconColor: profile.accentTheme.color,
                            title: "Akzentfarbe",
                            trailingView: AnyView(
                                HStack(spacing: Theme.Spacing.xs) {
                                    Circle()
                                        .fill(profile.accentTheme.color)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: profile.accentTheme.color.opacity(0.3), radius: 3)
                                    Text(profile.accentTheme.label)
                                        .font(Theme.Typography.footnote)
                                        .foregroundStyle(.secondary)
                                    chevron
                                }
                            )
                        )
                    }
                    .buttonStyle(PressScaleStyle())

                    Button {
                        showingIconPicker = true
                    } label: {
                        SettingsRow(
                            icon: "app.fill",
                            iconColor: .blue,
                            title: "App-Icon",
                            trailingView: AnyView(chevron)
                        )
                    }
                    .buttonStyle(PressScaleStyle())

                    Divider().padding(.horizontal, Theme.Spacing.l)

                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack(spacing: Theme.Spacing.m) {
                            IconBadge(icon: "circle.lefthalf.filled", color: .gray)
                            Text("Modus")
                                .font(Theme.Typography.body)
                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)

                        Picker("Modus", selection: $profile.appearanceRaw) {
                            ForEach(AppAppearance.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.m)
                    }
                }

                // MARK: Habits & Ziele
                SettingsGroup(title: "Habits & Ziele", icon: "target", iconColor: .green) {
                    VStack(spacing: 0) {
                        StepperRow(icon: "target", iconColor: .green, title: "Tagesziel", value: "\(profile.dailyPointGoal) P") {
                            Stepper(value: $profile.dailyPointGoal, in: 1...50) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }

                        Divider().padding(.horizontal, Theme.Spacing.l)

                        MenuPickerRow(
                            icon: "calendar",
                            iconColor: .orange,
                            title: "Wochenbeginn",
                            selection: $profile.weekStartsOnRaw,
                            options: [Weekday.monday, .sunday, .saturday].map { ($0.rawValue, $0.fullLabel) }
                        )
                    }
                }

                // MARK: Sport
                SettingsGroup(title: "Sport", icon: "dumbbell.fill", iconColor: .red) {
                    VStack(spacing: 0) {
                        MenuPickerRow(
                            icon: "scalemass.fill",
                            iconColor: .red,
                            title: "Gewichtseinheit",
                            selection: $profile.preferredWeightUnitRaw,
                            options: [
                                (WeightUnit.kilograms.rawValue, "Kilogramm (kg)"),
                                (WeightUnit.pounds.rawValue, "Pounds (lb)")
                            ]
                        )

                        Divider().padding(.horizontal, Theme.Spacing.l)

                        StepperRow(icon: "timer", iconColor: .blue, title: "Standard-Pause", value: formatRest(profile.defaultRestSeconds)) {
                            Stepper(value: $profile.defaultRestSeconds, in: 0...600, step: 15) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }

                        Divider().padding(.horizontal, Theme.Spacing.l)

                        MenuPickerRow(
                            icon: "figure.run",
                            iconColor: .purple,
                            title: "Aktivitätsprofil",
                            selection: $activityProfileRaw,
                            options: ActivityProfile.allCases.map { ($0.rawValue, $0.label) }
                        )

                        Divider().padding(.horizontal, Theme.Spacing.l)

                        ToggleRow(
                            icon: "chart.bar.fill",
                            iconColor: .teal,
                            title: "Untrainierte Muskeln zählen",
                            isOn: Binding(
                                get: { UserDefaults.standard.bool(forKey: "includeUntrainedMuscles") },
                                set: { UserDefaults.standard.set($0, forKey: "includeUntrainedMuscles") }
                            )
                        )
                    }
                }

                // MARK: Mitteilungen
                NotificationsCard(
                    profile: profile,
                    authStatus: notificationsAuth,
                    pendingCount: pendingRequestCount,
                    onSave: { save(profile) },
                    onOpenSettings: openSystemSettings,
                    onTestFire: testNotification,
                    onRefresh: { await loadAll() }
                )

                // MARK: Apple Health
                SettingsGroup(title: "Apple Health", icon: "heart.fill", iconColor: .red) {
                    if !env.healthService.isAvailable {
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "heart.slash")
                                .font(Theme.Typography.body)
                                .foregroundStyle(.red)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.red.opacity(0.12)))
                            Text("HealthKit ist auf diesem Gerät nicht verfügbar.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.s)
                    } else {
                        ToggleRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "Apple Health Sync",
                            isOn: Binding(
                                get: { env.healthService.isAuthorized },
                                set: { newValue in
                                    if newValue {
                                        Task { await env.healthService.requestAuthorization() }
                                    }
                                }
                            )
                        )
                        Text("Workouts werden automatisch in Apple Health gespeichert. Schritte und Kalorien erscheinen in der Analyse.")
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.bottom, Theme.Spacing.s)
                    }
                }

                // MARK: Onboarding
                SettingsGroup(title: "Onboarding", icon: "sparkles", iconColor: .indigo) {
                    Button {
                        showOnboarding = true
                    } label: {
                        SettingsRow(
                            icon: "arrow.counterclockwise",
                            iconColor: .indigo,
                            title: "Onboarding wiederholen",
                            trailingView: AnyView(chevron)
                        )
                    }
                    .buttonStyle(PressScaleStyle())
                }

                // MARK: Daten
                SettingsGroup(title: "Daten", icon: "externaldrive.fill", iconColor: .gray) {
                    Button {
                        showingExport = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            iconColor: .blue,
                            title: "Daten exportieren",
                            trailingView: AnyView(chevron)
                        )
                    }
                    .buttonStyle(PressScaleStyle())

                    Divider().padding(.horizontal, Theme.Spacing.l)

                    Button {
                        showingImport = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.down",
                            iconColor: .green,
                            title: "Daten importieren",
                            trailingView: AnyView(chevron)
                        )
                    }
                    .buttonStyle(PressScaleStyle())

                    Text("Erstelle ein vollständiges JSON-Backup aller Habits, Workouts, Sessions und deines Waldes.")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.s)
                }

                // MARK: Unio
                UnioSettingsSection()

                // MARK: Über
                AboutCard(version: version)

                #if DEBUG
                Button {
                    showingDebug = true
                } label: {
                    SettingsRow(
                        icon: "hammer.fill",
                        iconColor: .orange,
                        title: "Debug-Menü",
                        trailingView: AnyView(chevron)
                    )
                }
                .buttonStyle(PressScaleStyle())
                .padding(.horizontal, Theme.Spacing.l)
                #endif

                // MARK: Gefahrenzone
                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "trash.fill")
                            .font(Theme.Typography.body)
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.red.opacity(0.12)))
                        Text("Alle Daten löschen")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(Theme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                            .fill(Color.red.opacity(0.06))
                    )
                }
                .buttonStyle(BounceButtonStyle())
                .padding(.horizontal, Theme.Spacing.l)

                Text("Mit ❤️ in Hattingen")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, Theme.Spacing.s)
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
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

    // MARK: - Premium Header

    private var premiumHeader: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Einstellungen")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text("Profil")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(Theme.Typography.caption.weight(.bold))
            .foregroundStyle(.tertiary)
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(v) (\(b))"
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

// MARK: - Profile Hero Card

private struct ProfileHeroCard: View {
    @Bindable var profile: UserProfile
    let totalEarned: Int
    let totalSpent: Int

    private var initials: String {
        let trimmed = profile.displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "🌱" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(profile.accentTheme.color)
                    .frame(width: 88, height: 88)
                Text(initials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            TextField("Dein Name", text: $profile.displayName)
                .font(Theme.Typography.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.Spacing.xl)

            HStack(spacing: 0) {
                KPI(value: "\(totalEarned)", label: "Punkte", tint: .green)
                VerticalDivider()
                KPI(value: "\(totalSpent)", label: "Investiert", tint: .blue)
                VerticalDivider()
                KPI(value: "\(max(0, totalEarned - totalSpent))", label: "Verfügbar", tint: .orange)
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Theme.Spacing.l)
    }

    private struct KPI: View {
        let value: String
        let label: String
        let tint: Color

        var body: some View {
            VStack(spacing: 2) {
                Text(value)
                    .font(Theme.Typography.headline.monospacedDigit())
                    .foregroundStyle(tint)
                Text(label)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct VerticalDivider: View {
        var body: some View {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5, height: 32)
        }
    }
}

// MARK: - Settings Group Container

private struct SettingsGroup<Content: View>: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .accentColor
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(iconColor)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(iconColor.opacity(0.12)))
                }
                Text(title)
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, Theme.Spacing.l)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}

// MARK: - Menu Picker Row

private struct MenuPickerRow<T: Hashable>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: T
    let options: [(value: T, label: String)]

    private var selectedLabel: String {
        options.first { $0.value == selection }?.label ?? ""
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button {
                    Haptics.selection()
                    selection = option.value
                } label: {
                    if option.value == selection {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                IconBadge(icon: icon, color: iconColor)
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.primary)
                Spacer()
                Text(selectedLabel)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Icon Badge

private struct IconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                .fill(color)
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(Theme.Typography.callout.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailingView: AnyView?

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            IconBadge(icon: icon, color: iconColor)
            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(.primary)
            Spacer()
            if let trailingView { trailingView }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
    }
}

// MARK: - Toggle Row

private struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            IconBadge(icon: icon, color: iconColor)
            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}

// MARK: - Stepper Row

private struct StepperRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    @ViewBuilder let stepper: () -> Content

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            IconBadge(icon: icon, color: iconColor)
            Text(title)
                .font(Theme.Typography.body)
            Spacer()
            Text(value)
                .font(Theme.Typography.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
            stepper()
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}

// MARK: - Subscription Status Card

private struct SubscriptionStatusCard: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showingPaywall = false
    @State private var showingManage = false

    private var store: StoreService { env.storeService }
    private var isPro: Bool { env.entitlements.isPro }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: isPro ? "crown.fill" : "leaf.fill")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: isPro ? [.orange, .yellow] : [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    )
                Text("Mitgliedschaft")
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            if isPro {
                proStatus
            } else {
                freeStatus
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Theme.Spacing.l)
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private var proStatus: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ThriveWood Pro")
                            .font(Theme.Typography.headline)
                        Text("AKTIV")
                            .font(Theme.Typography.caption2.weight(.black))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                            .foregroundStyle(.white)
                    }
                    Text(subscriptionDescription)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            PremiumDivider()

            Button {
                showingManage = true
            } label: {
                HStack {
                    Image(systemName: "creditcard.fill").foregroundStyle(.blue)
                    Text("Abo verwalten")
                        .font(Theme.Typography.subheadline)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(PressScaleStyle())
            .manageSubscriptionsSheet(isPresented: $showingManage)

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                    Text("Käufe wiederherstellen")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    private var freeStatus: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ThriveWood Free")
                        .font(Theme.Typography.headline)
                    Text(limitsDescription)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(spacing: Theme.Spacing.s) {
                LimitBar(label: "Habits", icon: "checklist", current: currentHabitCount, limit: EntitlementService.freeHabitLimit)
                LimitBar(label: "Workouts", icon: "dumbbell.fill", current: currentWorkoutCount, limit: EntitlementService.freeWorkoutLimit)
                LimitBar(label: "Supplements", icon: "pills.fill", current: currentSupplementCount, limit: EntitlementService.freeSupplementLimit)
            }

            PremiumDivider()

            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.orange)
                    Text("Auf Pro upgraden")
                        .font(Theme.Typography.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(PressScaleStyle())

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                    Text("Käufe wiederherstellen")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    private var subscriptionDescription: String {
        let ids = store.purchasedIDs
        if ids.contains(ProProduct.lifetime.rawValue) { return "Lifetime – für immer freigeschaltet" }
        if ids.contains(ProProduct.yearly.rawValue) { return "Jahresabo – verlängert sich automatisch" }
        if ids.contains(ProProduct.monthly.rawValue) { return "Monatsabo – verlängert sich automatisch" }
        return "Aktiv"
    }

    private var limitsDescription: String {
        let remaining = env.entitlements.remainingFreeHabits
        if remaining > 0 { return "Noch \(remaining) Habit\(remaining == 1 ? "" : "s") frei" }
        return "Habit-Limit erreicht"
    }

    private var currentHabitCount: Int {
        (try? env.habitRepo.fetchAll(includeArchived: false).count) ?? 0
    }
    private var currentWorkoutCount: Int {
        (try? env.workoutRepo.fetchAll(includeArchived: false).count) ?? 0
    }
    private var currentSupplementCount: Int {
        (try? env.supplementRepo.fetchAll(includeArchived: false).count) ?? 0
    }
}

// MARK: - Limit Bar

private struct LimitBar: View {
    let label: String
    let icon: String
    let current: Int
    let limit: Int

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(1.0, Double(current) / Double(limit))
    }
    private var isAtLimit: Bool { current >= limit }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(Theme.Typography.caption)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(isAtLimit ? Color.orange : Color.green)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(width: 80, height: 6)
            Text("\(current)/\(limit)")
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(isAtLimit ? .orange : .secondary)
        }
    }
}

// MARK: - Notifications Card

private struct NotificationsCard: View {
    @Bindable var profile: UserProfile
    let authStatus: UNAuthorizationStatus
    let pendingCount: Int
    let onSave: () -> Void
    let onOpenSettings: () -> Void
    let onTestFire: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "bell.fill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
                Text("Mitteilungen")
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            if authStatus == .denied {
                Button(action: onOpenSettings) {
                    HStack(alignment: .top, spacing: Theme.Spacing.m) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mitteilungen sind deaktiviert")
                                .font(Theme.Typography.subheadline.weight(.semibold))
                            Text("Aktiviere sie in den iOS-Einstellungen, damit Reminder funktionieren.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.orange)
                    }
                }
                .buttonStyle(PressScaleStyle())
            } else if authStatus == .notDetermined {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.tint)
                    Text("Du wirst beim Aktivieren eines Reminders nach Erlaubnis gefragt.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ToggleRow(
                icon: "bell.fill",
                iconColor: .blue,
                title: "Mitteilungen aktiv",
                isOn: $profile.enableNotifications
            )
            .onChange(of: profile.enableNotifications) { _, _ in onSave() }

            if profile.enableNotifications && authStatus != .denied {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                    Text("Geplante Erinnerungen")
                        .font(Theme.Typography.body)
                    Spacer()
                    Text("\(pendingCount)")
                        .font(Theme.Typography.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Theme.Spacing.l)

                #if DEBUG
                Button {
                    onTestFire()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill").foregroundStyle(.tint)
                        Text("Test-Mitteilung in 5s")
                            .font(Theme.Typography.subheadline)
                        Spacer()
                    }
                }
                .buttonStyle(PressScaleStyle())
                .padding(.horizontal, Theme.Spacing.l)
                #endif
            }

            Text("Erinnerungen helfen dir, deine Habits konsequent abzuhaken – sie werden lokal auf deinem Gerät verarbeitet.")
                .font(Theme.Typography.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.l)
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Theme.Spacing.l)
        .task { await onRefresh() }
    }
}

// MARK: - About Card

private struct AboutCard: View {
    let version: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "info.circle.fill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.gray)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.gray.opacity(0.12)))
                Text("Über")
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text(version)
                    .font(Theme.Typography.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.s)

            AboutLink(icon: "hand.raised.fill", iconColor: .blue, title: "Datenschutz", url: "https://mctzock.github.io/ios-apps-pages/legal/privacy")
            AboutLink(icon: "doc.text.fill", iconColor: .gray, title: "Impressum", url: "https://mctzock.github.io/ios-apps-pages/legal/notice")
            AboutLink(icon: "doc.text.fill", iconColor: .gray, title: "AGBs", url: "https://mctzock.github.io/ios-apps-pages/legal/terms")
            AboutLink(icon: "envelope.fill", iconColor: .orange, title: "Feedback senden", url: "mailto:hello@ben-siebert.de")

            NavigationLink {
                LicenseViewer(libraries: [
                    OpenSourceLibrary(name: "textual", copyright: "Copyright (c) 2024 Guille Gonzalez", licenseText: MIT_LICENSE),
                    OpenSourceLibrary(name: "swiftui-math", copyright: "Copyright (c) 2026 Guille Gonzalez Copyright (c) 2023 Computer Inspirations (SwiftMath) Copyright (c) 2013 MathChat (iosMath)", licenseText: MIT_LICENSE),
                    OpenSourceLibrary(name: "swift-concurrency-extras", copyright: "Copyright (c) 2023 Point-Free", licenseText: MIT_LICENSE),
                    OpenSourceLibrary(name: "Body Muscles", copyright: "Copyright 2024 Ivan Vulović", licenseText: APACHE_2_0_LICENSE)
                ])
            } label: {
                SettingsRow(
                    icon: "books.vertical.fill",
                    iconColor: .indigo,
                    title: "Lizenzen",
                    trailingView: AnyView(
                        Image(systemName: "chevron.right")
                            .font(Theme.Typography.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    )
                )
            }
            .buttonStyle(PressScaleStyle())

            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id6763886527")!,
                subject: Text("ThriveWood"),
                message: Text("Lass deinen Wald durch gute Gewohnheiten wachsen 🌱")
            ) {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: "App teilen",
                    trailingView: AnyView(EmptyView())
                )
            }
            .buttonStyle(PressScaleStyle())

            Text("ThriveWood ist 100% deine App – keine Daten verlassen dein Gerät ohne deine Zustimmung.")
                .font(Theme.Typography.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Theme.Spacing.l)
    }
}

private struct AboutLink: View {
    let icon: String
    let iconColor: Color
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            SettingsRow(
                icon: icon,
                iconColor: iconColor,
                title: title,
                trailingView: AnyView(
                    Image(systemName: "arrow.up.right.square")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                )
            )
        }
        .buttonStyle(PressScaleStyle())
    }
}
