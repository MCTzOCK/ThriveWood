//
//  SportViewV2.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

struct SportViewV2: View {

    @Environment(AppEnvironment.self) private var env

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
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewWorkout) {
                WorkoutEditorView(workout: nil).onDisappear { vm?.load() }
            }
            .sheet(item: $editingWorkout) { w in
                WorkoutEditorView(workout: w).onDisappear { vm?.load() }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(item: $selectedExercise) { e in
                ExerciseDetailsSheet(exercise: e)
            }
            .fullScreenCover(item: $presentedSession) { session in
                ActiveSessionViewV2(session: session).onDisappear { vm?.load() }
            }
        }
        .task {
            if vm == nil { vm = SportViewV2Model(env: env) }
            vm?.load()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: SportViewV2Model) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                header

                if let active = vm.activeSession {
                    ActiveSessionBanner(session: active) {
                        presentedSession = active
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }

                todaySection(vm: vm)

                trainingSection(vm: vm)

                navigationGrid(vm: vm)
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .navigationDestination(item: $detailSession) { session in
            WorkoutSessionDetailView(session: session)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Training")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text("Sport")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)

            Button {
                if env.entitlements.canCreateWorkout {
                    showingNewWorkout = true
                } else {
                    showingPaywall = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(Theme.Typography.body.weight(.bold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Today Section

    @ViewBuilder
    private func todaySection(vm: SportViewV2Model) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Heute")
                .font(Theme.Typography.headline)
                .padding(.horizontal, Theme.Spacing.l)

            if vm.todayIsRestDay {
                RestDayCardV2()
                    .padding(.horizontal, Theme.Spacing.l)
            } else if let workout = vm.todaysPlannedWorkout {
                TodayWorkoutCardV2(
                    workout: workout,
                    estimatedDuration: Int(env.workoutService.getAverageDuration(workout: workout)) > 0
                        ? Int(env.workoutService.getAverageDuration(workout: workout))
                        : workout.estimatedDurationMinutes,
                    exerciseCount: workout.exercises.count,
                    onStart: {
                        if let s = vm.startSession(for: workout) { presentedSession = s }
                    }
                )
                .padding(.horizontal, Theme.Spacing.l)
            } else if let last = vm.lastSession, let lastWorkout = last.workout {
                TodayWorkoutCardV2(
                    workout: lastWorkout,
                    estimatedDuration: Int(env.workoutService.getAverageDuration(workout: lastWorkout)) > 0
                        ? Int(env.workoutService.getAverageDuration(workout: lastWorkout))
                        : lastWorkout.estimatedDurationMinutes,
                    exerciseCount: lastWorkout.exercises.count,
                    onStart: {
                        if let s = vm.startSession(for: lastWorkout) { presentedSession = s }
                    }
                )
                .padding(.horizontal, Theme.Spacing.l)
            } else {
                TodayWorkoutCardV2(
                    workout: nil,
                    estimatedDuration: 0,
                    exerciseCount: 0,
                    onStart: {
                        if let s = vm.startSession(for: nil) { presentedSession = s }
                    }
                )
                .padding(.horizontal, Theme.Spacing.l)
            }

            SportWeekStripCard(model: vm)
                .padding(.horizontal, Theme.Spacing.l)

            RecoveryMiniCard(dashboard: vm.recoveryDashboard)
                .padding(.horizontal, Theme.Spacing.l)
        }
    }

    // MARK: - Training Section

    @ViewBuilder
    private func trainingSection(vm: SportViewV2Model) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
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
                workouts: vm.workouts.filter {
                    searchText.lowercased().isEmpty || $0.name.lowercased().contains(searchText.lowercased())
                }
            )

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
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Navigation Grid

    @ViewBuilder
    private func navigationGrid(vm: SportViewV2Model) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Entdecken")
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible(), spacing: Theme.Spacing.m)], spacing: Theme.Spacing.m) {
                NavigationLink(destination: { AllSessionsView() }) {
                    SportNavigationCardV2(title: "Alle Sessions", subtitle: "Verlauf", icon: "clock.fill", iconColor: .green)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { SportInsightsView() }) {
                    SportNavigationCardV2(title: "Insights", subtitle: "Analysen", icon: "chart.bar.xaxis", iconColor: .teal)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { MuscleRankingScreen() }) {
                    SportNavigationCardV2(title: "Muskel-Ranking", subtitle: "Erholung", icon: "trophy.fill", iconColor: .yellow)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: {
                    ExerciseLibraryView(onSelect: { exercise in
                        selectedExercise = exercise
                    }, asSheet: false, onlyFor: nil)
                }) {
                    SportNavigationCardV2(title: "Übungen", subtitle: "Bibliothek", icon: "figure.strengthtraining.traditional", iconColor: .red)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { TrainingsPlanListView() }) {
                    SportNavigationCardV2(title: "Trainingspläne", subtitle: "Pläne", icon: "list.bullet.rectangle.portrait", iconColor: .blue)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { PRListView() }) {
                    SportNavigationCardV2(title: "PRs", subtitle: "Rekorde", icon: "flame.fill", iconColor: .orange)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { BodyProgressView() }) {
                    SportNavigationCardV2(title: "Körper", subtitle: "Fortschritt", icon: "figure.stand.line.dotted.figure.stand", iconColor: .purple)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { WellnessView() }) {
                    SportNavigationCardV2(title: "Wellness", subtitle: "Check-in", icon: "heart.fill", iconColor: .pink)
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}
