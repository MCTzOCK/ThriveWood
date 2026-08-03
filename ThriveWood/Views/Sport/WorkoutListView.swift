//
//  WorkoutListView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 15.06.26.
//

import SwiftUI

struct WorkoutListView: View {
    
    @Environment(AppEnvironment.self) private var env
    @State private var vm: SportViewModel?
    @State private var showingNewWorkout = false
    @State private var editingWorkout: Workout?
    @State private var presentedSession: WorkoutSession?
    @State private var detailSession: WorkoutSession?
    @State private var showingPaywall = false
    @State private var showingExerciseDetails = false
    @State private var selectedExercise: Exercise?
    @State private var searchText: String = ""
    
    
    var body: some View {
        Group {
            if let vm {
                BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
                    VStack(spacing: Theme.Spacing.l) {
                        BentoPageHeader(
                            eyebrow: Text("TRAINING"),
                            title: Text("Workouts"),
                            subtitle: Text("\(vm.workouts.count) Workouts")
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.m)

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
                    .padding(.bottom, 120)
                }
                .refreshable { vm.load() }
                .errorAlert(vm.errors)
                .navigationDestination(item: $detailSession) { session in
                    WorkoutSessionDetailView(session: session)
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .navigationTitle("Workouts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showingNewWorkout) {
                    WorkoutEditorView(workout: nil).onDisappear { vm.load() }
                }
                .sheet(item: $editingWorkout) { w in
                    WorkoutEditorView(workout: w).onDisappear { vm.load() }
                }
                .sheet(isPresented: $showingPaywall) { PaywallView() }
                .sheet(item: $selectedExercise) { e in
                    ExerciseDetailsSheet(exercise: e)
                }
                .fullScreenCover(item: $presentedSession) { session in
                    ActiveSessionViewV3(session: session).onDisappear { vm.load() }
                }
            } else {
                BentoScreen(scrolls: false) {
                    VStack { BentoSpinner(size: 36) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            if vm == nil { vm = SportViewModel(env: env) }
            vm?.load()
        }
    }
}

