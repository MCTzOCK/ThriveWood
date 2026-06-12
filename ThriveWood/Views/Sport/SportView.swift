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
                pagePicker()
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
            .background(Color.groupedBackground)
            .navigationTitle("Sport")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                if selectedPage == .workouts {
                    ToolbarItem(placement: .automatic) {
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
                
                ToolbarItem(placement: .automatic) {
                    if env.entitlements.isPro {
                        NavigationLink {
                            MuscleRankingScreen()
                        } label: {
                            Image(systemName: "trophy")
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Image(systemName: "trophy")
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
            #if os(iOS)
            .fullScreenCover(item: $presentedSession) { session in
                ActiveSessionView(session: session).onDisappear { vm?.load() }
            }
            #else
            .sheet(item: $presentedSession) { session in
                ActiveSessionView(session: session).onDisappear { vm?.load() }
            }
            #endif
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
                
                if !vm.recentSessions.isEmpty {
                    RecentSessionsSection(sessions: vm.recentSessions) { selected in
                        detailSession = selected
                    }
                        .padding(.horizontal, Theme.Spacing.l)
                }
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(Color.groupedBackground)
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
        .navigationDestination(item: $detailSession) { session in
            WorkoutSessionDetailView(session: session)
        }
        .searchable(text: $searchText)
    }
}
