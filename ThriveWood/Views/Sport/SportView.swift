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
    @State private var selectedPage: SportPage = .workouts
    @State private var showingExerciseDetails = false
    @State private var selectedExercise: Exercise?
    @State private var searchText: String = ""
    
    private enum SportPage {
        case workouts
        case plans
        case library
        case prs
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                //pagePicker()
                if let vm {
                    if selectedPage == .workouts {
                        content(vm: vm)
                    } else if selectedPage == .library {
                        libraryContent(vm: vm)
                    } else if selectedPage == .prs {
                        PRListView()
                    } else {
                        TrainingsPlanListView()
                    }
                }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sport")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedPage == .workouts {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if env.entitlements.canCreateWorkout {
                                showingNewWorkout = true
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
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
            if vm == nil { vm = SportViewModel(env: env) }
            vm?.load()
        }
    }
    
    @ViewBuilder
    private func pagePicker() -> some View {
        Picker(selection: $selectedPage) {
            Text("Workouts").tag(SportPage.workouts)
            Text("Pläne").tag(SportPage.plans)
            Text("Bibliothek").tag(SportPage.library)
            Text("PRs").tag(SportPage.prs)
        } label: {
            Text("Seite auswählen")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func libraryContent(vm: SportViewModel) -> some View {
        ExerciseLibraryView(onSelect: { exercise in
            print(exercise)
            selectedExercise = exercise
            showingExerciseDetails = true
        }, asSheet: false, onlyFor: nil)
    }
    
    @ViewBuilder
    private func content(vm: SportViewModel) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
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
                    workouts: vm.workouts.filter { searchText.lowercased().isEmpty || $0.name.lowercased().contains(searchText.lowercased()) },
                    onStart: { w in
                        if let s = vm.startSession(for: w) { presentedSession = s }
                    },
                    onEdit: { editingWorkout = $0 },
                    onDelete: vm.delete
                )
                .padding(.horizontal, Theme.Spacing.l)
                
                /*
                if !vm.recentSessions.isEmpty {
                    RecentSessionsSection(sessions: vm.recentSessions) { selected in
                        detailSession = selected
                    }
                        .padding(.horizontal, Theme.Spacing.l)
                }*/
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text("Weiteres").font(.headline)
                    featureGrid()
                }
                .padding(.horizontal, Theme.Spacing.l)
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
        .navigationDestination(item: $detailSession) { session in
            WorkoutSessionDetailView(session: session)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
    
    @ViewBuilder
    private func featureGrid() -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.l) {
            NavigationLink(destination: {
                AllSessionsView()
            }) {
                OrganisationCard(title: "Alle Sessions", subtitle: "", icon: "clock.fill", iconColor: .green)
            }
            NavigationLink(destination: {
                MuscleRankingScreen()
            }) {
                OrganisationCard(title: "Muskel-Ranking", subtitle: "", icon: "trophy.fill", iconColor: .yellow)
            }
            NavigationLink(destination: {
                ExerciseLibraryView(onSelect: { exercise in
                    print(exercise)
                    selectedExercise = exercise
                    showingExerciseDetails = true
                }, asSheet: false, onlyFor: nil)
            }) {
                OrganisationCard(title: "Übungen", subtitle: "", icon: "figure.strengthtraining.traditional", iconColor: .red)
            }
            NavigationLink(destination: {
                TrainingsPlanListView()
            }) {
                OrganisationCard(title: "Trainingspläne", subtitle: "", icon: "list.bullet.rectangle.portrait", iconColor: .blue)
            }
            NavigationLink(destination: {
                PRListView()
            }) {
                OrganisationCard(title: "PRs & Fortschritt", subtitle: "", icon: "flame.fill", iconColor: .orange)
            }
            NavigationLink(destination: {
                BodyProgressView()
            }) {
                OrganisationCard(title: "Körperfortschritt", subtitle: "", icon: "figure.stand.line.dotted.figure.stand", iconColor: .purple)
            }
            NavigationLink(destination: {
                MyGymListView()
            }) {
                OrganisationCard(title: "Mein Gym", subtitle: "", icon: "building.2.fill", iconColor: .cyan)
            }
        }
    }
}
