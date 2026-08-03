//
//  BentoSettingsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 24.04.26.
//

import SwiftUI
import StoreKit
import UserNotifications

struct BentoSettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var profile: UserProfile?
    @State private var notificationsAuth: UNAuthorizationStatus = .notDetermined
    @State private var pendingRequestCount: Int = 0
    @State private var showingResetConfirm = false
    @State private var showingIconPicker = false
    @State private var showOnboarding = false
    @State private var errors = ErrorState()
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var showingPaywall = false
    @State private var showingManageSubs = false
    @State private var showingCompanion = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.bentoTheme) private var theme

    @AppStorage("activityProfile") private var activityProfileRaw: String = ActivityProfile.moderat.rawValue

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                if let profile {
                    content(profile: profile)
                } else {
                    loadingView
                }
            }
        }
        .task { await loadAll() }
        .errorAlert(errors)
        .bentoSheet(
            isPresented: $showingExport,
            title: Text("Export"),
            detents: [.medium, .large]
        ) {
            ExportSheet()
        }
        .bentoSheet(
            isPresented: $showingImport,
            title: Text("Import"),
            detents: [.medium, .large]
        ) {
            ImportSheet { await loadAll() }
        }
        .sheet(isPresented: $showingIconPicker) {
            AppIconPickerView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .bentoSheet(isPresented: $showingCompanion, title: Text("Companion"), detents: [.large]) {
            CompanionView(vm: CompanionViewModel(env: env))
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isRerun: true) { showOnboarding = false }
        }
        .bentoDialog(
            isPresented: $showingResetConfirm,
            systemImage: "exclamationmark.triangle.fill",
            title: Text("Alle Daten wirklich löschen?"),
            message: Text("Habits, Wald, Trainings und Verlauf werden unwiderruflich entfernt."),
            actions: resetDialogActions
        )
    }

    private var resetDialogActions: [BentoDialogAction] {
        [
            BentoDialogAction(title: Text("Abbrechen"), role: .cancel) { },
            BentoDialogAction(
                title: Text("Ja, alles löschen"),
                variant: .destructive,
                role: .destructive
            ) { performReset() }
        ]
    }

    private func performReset() {
        #if DEBUG
        do {
            try env.debugService.wipeEverything()
            Haptics.success()
        } catch { errors.show(error) }
        #endif
    }

    // MARK: - Loading

    private var loadingView: some View {
        BentoScreen(scrolls: false) {
            VStack(spacing: Theme.Spacing.m) {
                BentoSpinner(size: 40)
                BentoText(verbatim: "Profil wird geladen…", style: .callout, color: .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Content

    private func content(profile: UserProfile) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            // Type-Erasure an den Sektions-Grenzen: verhindert, dass der
            // gesamte Profil-Tab als ein einziger riesiger generischer
            // Composite-Type kompiliert wird (Stack-Overflow auf dem Gerät:
            // EXC_BAD_ACCESS code=2 beim Tab-Wechsel).
            AnyView(
                VStack(spacing: Theme.Spacing.l) {
                    AnyView(pageHeader)
                    AnyView(profileHeroCard(profile: profile))
                    AnyView(subscriptionCard)

                    AnyView(
                        VStack(spacing: Theme.Spacing.l) {
                            AnyView(habitsAndGoalsSection(profile: profile))
                            AnyView(sportSection(profile: profile))
                            AnyView(notificationsSection(profile: profile))
                    AnyView(appleHealthSection)
                    AnyView(companionSection)
                    AnyView(appIconSection)
                            AnyView(onboardingSection)
                            AnyView(dataSection)
                            AnyView(aboutSection)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                    )

                    AnyView(dangerZone)
                    AnyView(footerText)
                }
                .padding(.bottom, Theme.Spacing.xxxl)
            )
            .onChange(of: profile.dailyPointGoal) { _, _ in save(profile) }
            .onChange(of: profile.weekStartsOnRaw) { _, _ in
                AppCalendarConfig.shared.update(weekStartsOn: profile.weekStartsOn)
                save(profile)
            }
            .onChange(of: profile.preferredWeightUnitRaw) { _, _ in save(profile) }
            .onChange(of: profile.defaultRestSeconds) { _, _ in save(profile) }
            .onChange(of: profile.iCloudSyncEnabled) { _, _ in save(profile) }
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        BentoPageHeader(
            eyebrow: Text("EINSTELLUNGEN"),
            title: Text("Profil"),
            subtitle: Text("Personalisierung, Daten & Mitgliedschaft")
        )
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
    }

    // MARK: - Profile Hero Card

    private func profileHeroCard(profile: UserProfile) -> some View {
        @Bindable var profile = profile
        let totals = env.scoringService.totalsCached
        let available = max(0, totals.earned - totals.spent)

        return BentoCard(tone: .accent, style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: Theme.Spacing.m) {
                BentoAvatar(
                    source: .initials(profileInitials(profile)),
                    size: 88,
                    tone: .accent
                )

                BentoTextField(
                    text: $profile.displayName,
                    prompt: Text("Dein Name"),
                    showsClearButton: false
                )
                .multilineTextAlignment(.center)

                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "earned",
                        title: Text("Punkte"),
                        value: Text(verbatim: "\(totals.earned)"),
                        detail: Text("verdient")
                    ),
                    BentoStatValue(
                        id: "spent",
                        title: Text("Investiert"),
                        value: Text(verbatim: "\(totals.spent)"),
                        detail: Text("ausgegeben")
                    ),
                    BentoStatValue(
                        id: "available",
                        title: Text("Verfügbar"),
                        value: Text(verbatim: "\(available)"),
                        detail: Text("übrig")
                    )
                ])
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func profileInitials(_ profile: UserProfile) -> String {
        let trimmed = profile.displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "🌱" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        Group {
            if env.entitlements.isPro {
                proCard
            } else {
                freeCard
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var proCard: some View {
        let store = env.storeService

        return BentoCard(background: Color.orange.opacity(0.06), foreground: .primary, style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: Theme.Spacing.l) {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: Theme.Spacing.xs) {
                            BentoText("ThriveWood Pro", style: .title2, color: .white)
                        }
                        Text(subscriptionDescription(store: store))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Color.orange.opacity(0.8))
                    }
                    Spacer()
                }


                BentoDivider()

                VStack(spacing: Theme.Spacing.s) {
                    BentoButton(Text("Abo verwalten"), systemImage: "creditcard.fill",
                                variant: .secondary, size: .medium, expands: true) {
                        showingManageSubs = true
                    }
                    .manageSubscriptionsSheet(isPresented: $showingManageSubs)

                    BentoButton(Text("Käufe wiederherstellen"), systemImage: "arrow.clockwise",
                                variant: .secondary, size: .small, expands: true) {
                        Task { await store.restore() }
                    }
                }
            }
        }
    }

    private func proPerk(icon: String, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.orange)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.orange.opacity(0.15)))
            Text(label)
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var freeCard: some View {
        let store = env.storeService

        return BentoCard(style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: Theme.Spacing.l) {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundStyle(Color.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        BentoText("ThriveWood Free", style: .headline)
                        BentoText(verbatim: freeLimitDescription, style: .caption, color: .secondary)
                    }
                    Spacer()
                }

                VStack(spacing: Theme.Spacing.s) {
                    freeLimitBar(icon: "checklist", label: "Habits",
                                 current: currentHabitCount, limit: EntitlementService.freeHabitLimit)
                    freeLimitBar(icon: "dumbbell.fill", label: "Workouts",
                                 current: currentWorkoutCount, limit: EntitlementService.freeWorkoutLimit)
                    freeLimitBar(icon: "pills.fill", label: "Supplements",
                                 current: currentSupplementCount, limit: EntitlementService.freeSupplementLimit)
                }

                BentoCard(background: Color.orange.opacity(0.08), style: .flat, padding: .md, radius: .large) {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            BentoText(verbatim: "Pro freischalten", style: .bodyStrong)
                            BentoText(verbatim: "Unbegrenzte Habits, Themes & mehr", style: .caption, color: .secondary)
                        }
                        Spacer()
                    }
                }

                VStack(spacing: Theme.Spacing.s) {
                    BentoButton(Text("Auf Pro upgraden"), systemImage: "crown.fill",
                                variant: .primary, size: .medium, expands: true) {
                        showingPaywall = true
                    }

                    BentoButton(Text("Käufe wiederherstellen"), systemImage: "arrow.clockwise",
                                variant: .ghost, size: .small, expands: true) {
                        Task { await store.restore() }
                    }
                }
            }
        }
    }

    private func freeLimitBar(icon: String, label: String, current: Int, limit: Int) -> some View {
        let progress = limit > 0 ? min(1.0, Double(current) / Double(limit)) : 0.0
        let isAtLimit = current >= limit

        return HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundStyle(isAtLimit ? Color.orange : Color.secondary)
                .frame(width: 24)
            BentoText(verbatim: label, style: .body)
            Spacer()
            BentoProgressBar(
                progress: progress,
                tone: isAtLimit ? .warning : .success,
                height: 6
            )
            .frame(width: 60)
            BentoText(verbatim: "\(current)/\(limit)", style: .caption, color: isAtLimit ? .orange : .secondary)
        }
    }

    private func subscriptionDescription(store: StoreService) -> String {
        let ids = store.purchasedIDs
        if ids.contains(ProProduct.lifetime.rawValue) { return "Lifetime – für immer freigeschaltet" }
        if ids.contains(ProProduct.yearly.rawValue) { return "Jahresabo – verlängert sich automatisch" }
        if ids.contains(ProProduct.monthly.rawValue) { return "Monatsabo – verlängert sich automatisch" }
        return "Aktiv"
    }

    private var freeLimitDescription: String {
        let remaining = env.entitlements.remainingFreeHabits
        if remaining > 0 { return "Noch \(remaining) Habit\(remaining == 1 ? "" : "s") frei" }
        return "Habit-Limit erreicht – upgrade auf Pro"
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

    // MARK: - Settings Group Wrapper

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        tone: BentoTone,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Theme.Typography.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(toneFill(.neutral).opacity(0.15))
                    )
                BentoText(verbatim: title, style: .overline)
            }

            BentoCard(padding: .none, radius: .large) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    // MARK: - Habits & Goals

    private func habitsAndGoalsSection(profile: UserProfile) -> some View {
        @Bindable var profile = profile

        return settingsSection(title: "HABITS & ZIELE", icon: "target", tone: .green) {
            BentoStepper(
                Text("Tagesziel"),
                value: $profile.dailyPointGoal,
                in: 1...50,
                step: 1
            ) { Text(verbatim: "\($0) P") }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)

            BentoDivider()

            BentoMenuPicker(
                Text("Wochenbeginn"),
                options: [Weekday.monday, .sunday, .saturday],
                selection: Binding(
                    get: { profile.weekStartsOn },
                    set: { profile.weekStartsOn = $0 }
                )
            ) { Text(verbatim: $0.fullLabel) }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
        }
    }

    // MARK: - Sport

    private func sportSection(profile: UserProfile) -> some View {
        @Bindable var profile = profile

        return settingsSection(title: "SPORT", icon: "dumbbell.fill", tone: .danger) {
            BentoMenuPicker(
                Text("Gewichtseinheit"),
                options: [WeightUnit.kilograms, .pounds],
                selection: Binding(
                    get: { profile.preferredWeightUnit },
                    set: { profile.preferredWeightUnit = $0 }
                )
            ) { unit in
                Text(verbatim: unit == .kilograms ? "Kilogramm (kg)" : "Pounds (lb)")
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)

            BentoDivider()

            BentoStepper(
                Text("Standard-Pause"),
                value: $profile.defaultRestSeconds,
                in: 0...600,
                step: 15
            ) { Text(verbatim: formatRest($0)) }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)

            BentoDivider()

            BentoMenuPicker(
                Text("Aktivitätsprofil"),
                options: ActivityProfile.allCases,
                selection: Binding(
                    get: { ActivityProfile(rawValue: activityProfileRaw) ?? .moderat },
                    set: { activityProfileRaw = $0.rawValue }
                )
            ) { Text(verbatim: $0.label) }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)

            BentoDivider()

            BentoToggleRow(
                Text("Untrainierte Muskeln zählen"),
                subtitle: Text("In der Analyse anzeigen"),
                systemImage: "chart.bar.fill",
                isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "includeUntrainedMuscles") },
                    set: { UserDefaults.standard.set($0, forKey: "includeUntrainedMuscles") }
                )
            )
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
        }
    }

    // MARK: - Notifications

    private func notificationsSection(profile: UserProfile) -> some View {
        @Bindable var profile = profile

        return settingsSection(title: "MITTEILUNGEN", icon: "bell.fill", tone: .blue) {
            VStack(spacing: 0) {
                if notificationsAuth == .denied {
                    VStack(spacing: Theme.Spacing.s) {
                        BentoCallout(
                            kind: .warning,
                            title: Text("Mitteilungen deaktiviert"),
                            message: Text("Aktiviere sie in den iOS-Einstellungen.")
                        )
                        BentoButton(
                            Text("Einstellungen öffnen"),
                            systemImage: "arrow.up.right.square",
                            variant: .secondary,
                            size: .small,
                            expands: true
                        ) { openSystemSettings() }
                    }
                    .padding(Theme.Spacing.m)

                    BentoDivider()
                } else if notificationsAuth == .notDetermined {
                    BentoCallout(
                        kind: .info,
                        title: Text("Berechtigung erforderlich"),
                        message: Text("Du wirst beim ersten Reminder nach Erlaubnis gefragt.")
                    )
                    .padding(Theme.Spacing.m)

                    BentoDivider()
                }

                BentoToggleRow(
                    Text("Mitteilungen aktiv"),
                    subtitle: Text("Erinnerungen für Habits"),
                    systemImage: "bell.fill",
                    isOn: $profile.enableNotifications
                )
                .onChange(of: profile.enableNotifications) { _, _ in save(profile) }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)

                if profile.enableNotifications && notificationsAuth != .denied {
                    BentoDivider()

                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .frame(width: 24)
                            .foregroundStyle(.secondary)
                        BentoText(verbatim: "Geplante Erinnerungen", style: .body)
                        Spacer()
                        BentoBadge(Text(verbatim: "\(pendingRequestCount)"), tone: .info)
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
                }

                BentoDivider()

                BentoText(
                    "Erinnerungen werden lokal verarbeitet und verlassen nie dein Gerät.",
                    style: .caption,
                    color: .secondary
                )
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.m)
            }
        }
        .task { await refreshNotifications() }
    }

    // MARK: - Apple Health

    private var appleHealthSection: some View {
        settingsSection(title: "APPLE HEALTH", icon: "heart.fill", tone: .danger) {
            if !env.healthService.isAvailable {
                BentoCallout(
                    kind: .info,
                    title: Text("Nicht verfügbar"),
                    message: Text("HealthKit ist auf diesem Gerät nicht verfügbar.")
                )
                .padding(Theme.Spacing.m)
            } else {
                BentoToggleRow(
                    Text("Apple Health Sync"),
                    subtitle: Text("Workouts automatisch synchronisieren"),
                    systemImage: "heart.fill",
                    isOn: Binding(
                        get: { env.healthService.isAuthorized },
                        set: { newValue in
                            if newValue {
                                Task { await env.healthService.requestAuthorization() }
                            }
                        }
                    )
                )
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)

                BentoDivider()

                BentoText(
                    "Workouts werden in Apple Health gespeichert. Schritte und Kalorien erscheinen in der Analyse.",
                    style: .caption,
                    color: .secondary
                )
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.m)
            }
        }
    }

    // MARK: - Companion

    private var companionSection: some View {
        let companion = (try? env.companionService.current())
        let energy = companion?.energy ?? 0
        let name = companion?.name ?? "—"
        let mood = companion?.mood ?? .content
        let species = companion?.species ?? .fox

        return settingsSection(title: "COMPANION", icon: "pawprint.fill", tone: .warning) {
            Button {
                showingCompanion = true
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(companionColor(for: species).opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: species.symbol)
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(companionColor(for: species))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        BentoText(verbatim: "\(name) \(mood.emoji)", style: .body)
                        BentoText(verbatim: "\(mood.label) · \(Int(energy))/100 Energie", style: .caption, color: .secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
            }
            .buttonStyle(.plain)
        }
    }

    private func companionColor(for species: CompanionSpecies) -> Color {
        switch species {
        case .fox:  return .orange
        case .owl:  return .indigo
        case .bear: return .brown
        case .wolf: return .gray
        case .deer: return .pink
        }
    }

    // MARK: - App Icon

    private var appIconSection: some View {
        settingsSection(title: "APP-SYMBOL", icon: "app.fill", tone: .blue) {
            Button {
                showingIconPicker = true
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "app.fill")
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                .fill(theme.colors.background)
                        )
                    BentoText(verbatim: "App-Symbol wählen", style: .body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Onboarding

    private var onboardingSection: some View {
        settingsSection(title: "ONBOARDING", icon: "sparkles", tone: .info) {
            Button {
                showOnboarding = true
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                .fill(theme.colors.background)
                        )
                    BentoText(verbatim: "Onboarding wiederholen", style: .body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        settingsSection(title: "DATEN", icon: "externaldrive.fill", tone: .neutral) {
            Button {
                if env.entitlements.canExportData {
                    showingExport = true
                } else {
                    showingPaywall = true
                }
            } label: {
                settingsNavRow(icon: "square.and.arrow.up", iconColor: theme.colors.background, title: "Daten exportieren")
            }
            .buttonStyle(.plain)

            BentoDivider()
                .padding(.leading, Theme.Spacing.l + 48)

            Button {
                if env.entitlements.canExportData {
                    showingImport = true
                } else {
                    showingPaywall = true
                }
            } label: {
                settingsNavRow(icon: "square.and.arrow.down", iconColor: theme.colors.background, title: "Daten importieren")
            }
            .buttonStyle(.plain)

            BentoDivider()

            BentoText(
                "Erstelle ein JSON-Backup aller Habits, Workouts, Sessions und deines Waldes.",
                style: .caption,
                color: .secondary
            )
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
        }
    }

    private func settingsNavRow(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                        .fill(iconColor)
                )
            BentoText(verbatim: title, style: .body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(Theme.Typography.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        settingsSection(title: "ÜBER", icon: "info.circle.fill", tone: .neutral) {
            VStack(spacing: 0) {
                HStack {
                    BentoText(verbatim: "Version", style: .body)
                    Spacer()
                    BentoText(verbatim: version, style: .caption, color: .secondary)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)

                BentoDivider()

                aboutLinkRow(icon: "hand.raised.fill", iconColor: theme.colors.background, title: "Datenschutz", url: "https://mctzock.github.io/ios-apps-pages/legal/privacy")
                BentoDivider().padding(.leading, 48 + Theme.Spacing.l)
                aboutLinkRow(icon: "doc.text.fill", iconColor: theme.colors.background, title: "Impressum", url: "https://mctzock.github.io/ios-apps-pages/legal/notice")
                BentoDivider().padding(.leading, 48 + Theme.Spacing.l)
                aboutLinkRow(icon: "doc.text.fill", iconColor: theme.colors.background, title: "AGBs", url: "https://mctzock.github.io/ios-apps-pages/legal/terms")
                BentoDivider().padding(.leading, 48 + Theme.Spacing.l)
                aboutLinkRow(icon: "envelope.fill", iconColor: theme.colors.background, title: "Feedback senden", url: "mailto:hello@ben-siebert.de")
                BentoDivider().padding(.leading, 48 + Theme.Spacing.l)

                NavigationLink {
                    LicenseViewer(libraries: [
                        OpenSourceLibrary(name: "textual", copyright: "Copyright (c) 2024 Guille Gonzalez", licenseText: MIT_LICENSE),
                        OpenSourceLibrary(name: "swiftui-math", copyright: "Copyright (c) 2026 Guille Gonzalez Copyright (c) 2023 Computer Inspirations (SwiftMath) Copyright (c) 2013 MathChat (iosMath)", licenseText: MIT_LICENSE),
                        OpenSourceLibrary(name: "swift-concurrency-extras", copyright: "Copyright (c) 2023 Point-Free", licenseText: MIT_LICENSE),
                        OpenSourceLibrary(name: "Body Muscles", copyright: "Copyright 2024 Ivan Vulović", licenseText: APACHE_2_0_LICENSE)
                    ])
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "books.vertical.fill")
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                    .fill(theme.colors.background)
                            )
                        BentoText(verbatim: "Lizenzen", style: .body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(Theme.Typography.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
                }
                .buttonStyle(.plain)

                BentoDivider().padding(.leading, 48 + Theme.Spacing.l)

                ShareLink(
                    item: URL(string: "https://apps.apple.com/app/id6763886527")!,
                    subject: Text("ThriveWood"),
                    message: Text("Lass deinen Wald durch gute Gewohnheiten wachsen 🌱")
                ) {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "square.and.arrow.up")
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                    .fill(theme.colors.background)
                            )
                        BentoText(verbatim: "App teilen", style: .body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(Theme.Typography.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
                }
                .buttonStyle(.plain)

                BentoDivider()

                BentoText(
                    "ThriveWood ist 100% deine App – keine Daten verlassen dein Gerät ohne deine Zustimmung.",
                    style: .caption,
                    color: .secondary
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.m)
            }
        }
    }

    @ViewBuilder
    private func aboutLinkRow(icon: String, iconColor: Color, title: String, url: String) -> some View {
        if let linkURL = URL(string: url) {
            Link(destination: linkURL) {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: icon)
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                .fill(iconColor)
                        )
                    BentoText(verbatim: title, style: .body)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        Button(role: .destructive) {
            showingResetConfirm = true
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "trash.fill")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.red.opacity(0.12)))
                BentoText("Alle Daten löschen", style: .headline, color: .red)
                Spacer()
            }
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Color.red.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BounceButtonStyle())
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Footer

    private var footerText: some View {
        VStack(spacing: Theme.Spacing.xs) {
            BentoText(verbatim: "ThriveWood", style: .overline, color: .secondary)
            BentoText(verbatim: "Mit ❤️ in Hattingen", style: .caption, color: .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Helpers

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(v) (\(b))"
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s)) min"
    }

    // MARK: - Loading & Saving

    private func loadAll() async {
        do {
            profile = try env.profileRepo.currentProfile()
        } catch { errors.show(error) }
        await refreshNotifications()
    }

    private func refreshNotifications() async {
        await env.notificationService.refreshAuthorizationStatus()
        notificationsAuth = env.notificationService.authorizationStatus
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingRequestCount = pending.count
    }

    private func save(_ profile: UserProfile) {
        try? env.profileRepo.update(profile)
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func toneFill(_ tone: BentoTone) -> Color {
        switch tone {
        case .neutral: return Color.gray
        case .accent: return Color.green
        case .success: return Color.green
        case .warning: return Color.orange
        case .danger: return Color.red
        case .info: return Color.blue
        case .yellow: return Color.yellow
        case .green: return Color.green
        case .blue: return Color.blue
        case .pink: return Color.pink
        }
    }
}


