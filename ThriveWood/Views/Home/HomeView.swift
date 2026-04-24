//
//  HomeView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: HomeViewModel?
    @State private var showingNewHabit = false
    @State private var editingHabit: Habit?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbar }
            .sheet(isPresented: $showingNewHabit) {
                HabitEditorView(habit: nil)
                    .onDisappear { vm?.load() }
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorView(habit: habit)
                    .onDisappear { vm?.load() }
            }
        }
        .task {
            if vm == nil { vm = HomeViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: HomeViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                WeekStripView(
                    selectedDate: Binding(
                        get: { vm.selectedDate },
                        set: { vm.changeDate(to: $0) }
                    )
                )
                .padding(.horizontal, Theme.Spacing.l)

                DailySummaryCard(
                    points: vm.pointsToday,
                    goal: vm.dailyGoal,
                    progress: vm.progress,
                    availablePoints: vm.availablePoints
                )
                .padding(.horizontal, Theme.Spacing.l)

                habitList(vm: vm)
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
    }

    @ViewBuilder
    private func habitList(vm: HomeViewModel) -> some View {
        if vm.habits.isEmpty {
            EmptyHabitsView { showingNewHabit = true }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.xl)
        } else if vm.filteredHabits.isEmpty {
            ContentUnavailableView.search(text: vm.searchText)
                .frame(height: 240)
        } else {
            LazyVStack(spacing: Theme.Spacing.m) {
                ForEach(vm.filteredHabits) { habit in
                    HabitRowView(
                        habit: habit,
                        isCompleted: vm.completedHabitIDs.contains(habit.id),
                        streak: vm.streak(for: habit),
                        onToggle: { vm.toggle(habit) }
                    )
                    .contextMenu {
                        Button("Bearbeiten", systemImage: "pencil") { editingHabit = habit }
                        Button("Archivieren", systemImage: "archivebox", role: .destructive) {
                            vm.delete(habit)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { vm.delete(habit) } label: {
                            Label("Archivieren", systemImage: "archivebox")
                        }
                        Button { editingHabit = habit } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }.tint(.blue)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingNewHabit = true } label: {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .accessibilityLabel("Neuer Habit")
        }
    }
}
