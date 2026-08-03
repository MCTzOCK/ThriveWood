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
                        .transition(.opacity)
                } else {
                    BentoScreen(scrolls: false) {
                        VStack(spacing: Theme.Spacing.m) {
                            BentoSpinner(size: 36)
                            BentoText(verbatim: "Sport wird geladen…", style: .callout, color: .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .transition(.opacity)
                }
            }
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
        .task {
            if vm == nil { vm = SportViewV2Model(env: env) }
            vm?.load()
        }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: SportViewV2Model) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            VStack(spacing: Theme.Spacing.l) {
                BentoPageHeader(
                    eyebrow: Text("TRAINING"),
                    title: Text("Sport"),
                    subtitle: Text("\(vm.weeklySessionCount) Sessions diese Woche")
                ) {
                    BentoIconButton(
                        systemImage: "plus",
                        accessibilityLabel: Text("Neues Workout"),
                        variant: .primary
                    ) {
                        if env.entitlements.canCreateWorkout {
                            showingNewWorkout = true
                        } else {
                            showingPaywall = true
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)

                if let active = vm.activeSession {
                    ActiveSessionBanner(session: active) {
                        presentedSession = active
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                todaySection(vm: vm)

                trainingSection(vm: vm)

                navigationGrid(vm: vm)
            }
            .padding(.bottom, 120)
        }
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .navigationDestination(item: $detailSession) { session in
            WorkoutSessionDetailView(session: session)
        }
    }

    // MARK: - Today Section

    @ViewBuilder
    private func todaySection(vm: SportViewV2Model) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            BentoSectionHeader(title: Text("Heute")) {
                EmptyView()
            }
            .padding(.horizontal, Theme.Spacing.l)

            if vm.todayIsRestDay {
                RestDayCardV2()
                    .padding(.horizontal, Theme.Spacing.l)
            } else if let workout = vm.todaysPlannedWorkout {
                TodayWorkoutCardV2(
                    workout: workout,
                    estimatedDuration: avgDuration(for: workout, fallback: workout.estimatedDurationMinutes),
                    exerciseCount: workout.exercises.count,
                    isCompleted: vm.todayWorkoutCompleted,
                    onStart: {
                        if let s = vm.startSession(for: workout) { presentedSession = s }
                    }
                )
                .padding(.horizontal, Theme.Spacing.l)
            } else if let last = vm.lastSession, let lastWorkout = last.workout {
                TodayWorkoutCardV2(
                    workout: lastWorkout,
                    estimatedDuration: avgDuration(for: lastWorkout, fallback: lastWorkout.estimatedDurationMinutes),
                    exerciseCount: lastWorkout.exercises.count,
                    isCompleted: vm.didCompleteToday(lastWorkout),
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
                    isCompleted: false,
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
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
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

    private func avgDuration(for workout: Workout, fallback: Int) -> Int {
        let avg = env.workoutService.getAverageDuration(workout: workout)
        return avg > 0 ? Int(avg) : fallback
    }

    @ViewBuilder
    private func navigationGrid(vm: SportViewV2Model) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            BentoSectionHeader(title: Text("Entdecken")) {
                EmptyView()
            }
            .padding(.horizontal, Theme.Spacing.l)

            BentoAdaptiveGrid(minimumItemWidth: 150) {
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
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
}
