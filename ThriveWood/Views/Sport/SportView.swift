//
//  SportView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI

struct SportView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: SportViewModel?
    @State private var showingNewWorkout = false
    @State private var editingWorkout: Workout?
    @State private var presentedSession: WorkoutSession?
    @State private var detailSession: WorkoutSession?
    @State private var showingPaywall = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    VStack {
                        BentoSpinner()
                    }
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
                ActiveSessionViewV3(session: session).onDisappear { vm?.load() }
            }
        }
        .task {
            if vm == nil { vm = SportViewModel(env: env) }
            vm?.load()
        }
    }

    @State private var selectedExercise: Exercise?

    @ViewBuilder
    private func content(vm: SportViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                premiumHeader

                if let active = vm.activeSession {
                    ActiveSessionBanner(session: active) {
                        presentedSession = active
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }

                QuickStartCard {
                    if let s = vm.startSession(for: nil) { presentedSession = s }
                }
                .padding(.horizontal, Theme.Spacing.l)

                WorkoutsSection(
                    workouts: vm.workouts.filter {
                        searchText.lowercased().isEmpty || $0.name.lowercased().contains(searchText.lowercased())
                    },
                    onStart: { w in
                        if let s = vm.startSession(for: w) { presentedSession = s }
                    },
                    onEdit: { editingWorkout = $0 },
                    onDelete: vm.delete
                )
                .padding(.horizontal, Theme.Spacing.l)

                featureGrid(vm: vm)
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

    // MARK: - Premium Header

    private var premiumHeader: some View {
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
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Feature Grid

    @ViewBuilder
    private func featureGrid(vm: SportViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Entdecken")
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible(), spacing: Theme.Spacing.m)], spacing: Theme.Spacing.m) {
                NavigationLink(destination: { AllSessionsView() }) {
                    OrganisationCard(title: "Alle Sessions", subtitle: "Verlauf", icon: "clock.fill", iconColor: .green)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { SportInsightsView() }) {
                    OrganisationCard(title: "Insights", subtitle: "Analysen", icon: "chart.bar.xaxis", iconColor: .teal)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { MuscleRankingScreen() }) {
                    OrganisationCard(title: "Muskel-Ranking", subtitle: "Erholung", icon: "trophy.fill", iconColor: .yellow)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: {
                    ExerciseLibraryView(onSelect: { exercise in
                        selectedExercise = exercise
                    }, asSheet: false, onlyFor: nil)
                }) {
                    OrganisationCard(title: "Übungen", subtitle: "Bibliothek", icon: "figure.strengthtraining.traditional", iconColor: .red)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { TrainingsPlanListView() }) {
                    OrganisationCard(title: "Trainingspläne", subtitle: "Pläne", icon: "list.bullet.rectangle.portrait", iconColor: .blue)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { PRListView() }) {
                    OrganisationCard(title: "PRs", subtitle: "Rekorde", icon: "flame.fill", iconColor: .orange)
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink(destination: { BodyProgressView() }) {
                    OrganisationCard(title: "Körper", subtitle: "Fortschritt", icon: "figure.stand.line.dotted.figure.stand", iconColor: .purple)
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
    }
}
