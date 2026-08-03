//
//  SportViewV2.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

struct SportViewV2: View {

    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme

    @State private var vm: SportViewV2Model?
    @State private var showingNewWorkout = false
    @State private var editingWorkout: Workout?
    @State private var presentedSession: WorkoutSession?
    @State private var detailSession: WorkoutSession?
    @State private var showingPaywall = false
    @State private var selectedExercise: Exercise?
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                        .transition(.opacity)
                } else {
                    BentoScreen(scrolls: false) {
                        VStack(spacing: theme.spacing.md) {
                            BentoSpinner(size: 36)
                            BentoText(verbatim: "Sport wird geladen…", style: .callout, color: .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .transition(.opacity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .bentoSheet(
                isPresented: $showingNewWorkout,
                title: Text("Neues Workout"),
                subtitle: Text("Lege Übungen, Sätze und Ziele fest"),
                detents: [.large]
            ) {
                WorkoutEditorView(workout: nil).onDisappear { vm?.load() }
            }
            .bentoSheet(
                isPresented: Binding(
                    get: { editingWorkout != nil },
                    set: { if !$0 { editingWorkout = nil } }
                ),
                title: Text("Workout bearbeiten"),
                detents: [.large]
            ) {
                if let workout = editingWorkout {
                    WorkoutEditorView(workout: workout).onDisappear { vm?.load() }
                }
            }
            .bentoSheet(isPresented: $showingPaywall, title: Text("ThriveWood Pro"), detents: [.large]) {
                PaywallView()
            }
            .bentoSheet(
                isPresented: Binding(
                    get: { selectedExercise != nil },
                    set: { if !$0 { selectedExercise = nil } }
                ),
                title: Text("Übung"),
                detents: [.large]
            ) {
                if let exercise = selectedExercise {
                    ExerciseDetailsSheet(exercise: exercise)
                }
            }
            .fullScreenCover(item: $presentedSession) { session in
                ActiveSessionViewV2(session: session).onDisappear { vm?.load() }
            }
            .task {
                if vm == nil { vm = SportViewV2Model(env: env) }
                vm?.load()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: SportViewV2Model) -> some View {
        @Bindable var vm = vm
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("TRAINING"),
                title: Text("Sport"),
                subtitle: Text("\(vm.weeklySessionCount) Sessions diese Woche")
            ) {
                BentoIconButton(
                    systemImage: "plus",
                    accessibilityLabel: Text("Neues Workout"),
                    variant: .primary,
                    size: .medium
                ) {
                    if env.entitlements.canCreateWorkout {
                        showingNewWorkout = true
                    } else {
                        showingPaywall = true
                    }
                }
            }

            if let active = vm.activeSession {
                ActiveSessionBanner(session: active) {
                    presentedSession = active
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            todayHero(vm: vm)

            weekAndRecoveryRow(vm: vm)

            quickStartSection(vm: vm)

            if vm.weeklySessionCount > 0 {
                WeeklyStatsCardV2(
                    sessionCount: vm.weeklySessionCount,
                    volume: vm.weeklyVolume,
                    durationMinutes: vm.weeklyDurationMinutes
                )
            }

            if !vm.recentSessions.isEmpty {
                RecentSessionsSection(sessions: vm.recentSessions) { selected in
                    detailSession = selected
                }
            }

            exploreSection

            Spacer(minLength: theme.spacing.xxl)
        }
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .navigationDestination(item: $detailSession) { session in
            WorkoutSessionDetailView(session: session)
        }
    }

    // MARK: - Today Hero

    @ViewBuilder
    private func todayHero(vm: SportViewV2Model) -> some View {
        if vm.todayIsRestDay {
            BentoCard(
                background: theme.colors.info.opacity(0.15),
                foreground: .primary,
                style: .flat,
                padding: .lg,
                radius: .extraLarge
            ) {
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.colors.info)
                        .symbolEffect(.pulse, options: .repeating)
                    BentoText("Ruhetag", style: .title3)
                    BentoText(
                        "Dein Plan sieht heute Pause vor. Nutze den Tag für Mobilität, Spaziergänge oder Schlaf.",
                        style: .callout,
                        color: theme.colors.onSurfaceMuted
                    )
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            TodayWorkoutCardV2(
                workout: vm.todaysPlannedWorkout ?? vm.lastSession?.workout,
                estimatedDuration: avgDuration(
                    for: vm.todaysPlannedWorkout ?? vm.lastSession?.workout,
                    fallback: vm.todaysPlannedWorkout?.estimatedDurationMinutes
                        ?? vm.lastSession?.workout?.estimatedDurationMinutes ?? 0
                ),
                exerciseCount: vm.todaysPlannedWorkout?.exercises.count
                    ?? vm.lastSession?.workout?.exercises.count ?? 0,
                isCompleted: vm.todayWorkoutCompleted,
                onStart: {
                    let workout = vm.todaysPlannedWorkout ?? vm.lastSession?.workout
                    if let s = vm.startSession(for: workout) { presentedSession = s }
                }
            )
        }
    }

    // MARK: - Week + Recovery Row

    @ViewBuilder
    private func weekAndRecoveryRow(vm: SportViewV2Model) -> some View {
        BentoSplitCard {
            SportWeekStripCard(model: vm)
        } trailing: {
            RecoveryMiniCard(dashboard: vm.recoveryDashboard)
        }
    }

    // MARK: - Quick Start

    @ViewBuilder
    private func quickStartSection(vm: SportViewV2Model) -> some View {
        QuickStartGridV2(
            onFreeTraining: {
                if let s = vm.startSession(for: nil) { presentedSession = s }
            },
            onRepeatLast: {
                if let last = vm.lastSession, let w = last.workout {
                    if let s = vm.startSession(for: w) { presentedSession = s }
                } else {
                    if let s = vm.startSession(for: nil) { presentedSession = s }
                }
            },
            onWorkoutSelect: { w in
                if let s = vm.startSession(for: w) { presentedSession = s }
            },
            onEdit: { editingWorkout = $0 },
            onDelete: { vm.delete($0) },
            workouts: vm.workouts.filter {
                searchText.lowercased().isEmpty || $0.name.lowercased().contains(searchText.lowercased())
            }
        )
    }

    // MARK: - Explore

    private func avgDuration(for workout: Workout?, fallback: Int?) -> Int {
        guard let workout else { return fallback ?? 0 }
        let avg = env.workoutService.getAverageDuration(workout: workout)
        return avg > 0 ? Int(avg) : (fallback ?? 0)
    }

    @ViewBuilder
    private var exploreSection: some View {
        BentoSectionHeader(
            title: Text("Entdecken"),
            subtitle: Text("Mehr aus dem Sport-Tab")
        )
        .padding(.top, theme.spacing.md)

        BentoCard(style: .outlined, padding: .md, radius: .large) {
            BentoAdaptiveGrid(minimumItemWidth: 150) {
                exploreTile(title: "Verlauf", subtitle: "Sessions", icon: "clock.fill", tone: .green) {
                    AnyView(AllSessionsView())
                }
                exploreTile(title: "Insights", subtitle: "Analysen", icon: "chart.bar.xaxis", tone: .info) {
                    AnyView(SportInsightsView())
                }
                exploreTile(title: "Muskeln", subtitle: "Ranking", icon: "figure.musculature.fill", tone: .warning) {
                    AnyView(MuscleRankingScreen())
                }
                exploreTile(title: "Übungen", subtitle: "Bibliothek", icon: "figure.strengthtraining.traditional", tone: .danger) {
                    AnyView(ExerciseLibraryView(onSelect: { exercise in
                        selectedExercise = exercise
                    }, asSheet: false, onlyFor: nil))
                }
                exploreTile(title: "Pläne", subtitle: "Trainingspläne", icon: "list.bullet.rectangle.portrait", tone: .blue) {
                    AnyView(TrainingsPlanListView())
                }
                exploreTile(title: "PRs", subtitle: "Rekorde", icon: "flame.fill", tone: .warning) {
                    AnyView(PRListView())
                }
                exploreTile(title: "Körper", subtitle: "Fortschritt", icon: "figure.stand.line.dotted.figure.stand", tone: .pink) {
                    AnyView(BodyProgressView())
                }
            }
        }
    }

    private func exploreTile<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        tone: BentoTone,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            BentoTile(
                tone: tone,
                minimumHeight: 130,
                alignment: .center
            ) {
                VStack(spacing: theme.spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                    }
                    VStack(spacing: 1) {
                        Text(title)
                            .font(Theme.Typography.subheadline.weight(.semibold))
                        BentoText(verbatim: subtitle, style: .caption)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(BounceButtonStyle())
    }
}
