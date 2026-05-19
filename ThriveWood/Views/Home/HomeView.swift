//
//  HomeView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(NotificationRouter.self) private var router
    
    @State private var vm: HomeViewModel?
    @State private var showingNewHabit = false
    @State private var editingHabit: Habit?
    
    @State private var showingDebug: Bool = false
    @State private var showingPaywall = false
    
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Habits")
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
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingDebug) {
#if DEBUG
                DebugMenuView()
#endif
            }
        }
        .task {
            if vm == nil { vm = HomeViewModel(env: env) }
            vm?.load()
        }
        .onChange(of: router.pendingHabitID) { _, id in
            guard let id else { return }
            
            if let habit = try? env.habitRepo.fetch(id: id) {
                editingHabit = habit
            }
            
            router.pendingHabitID = nil
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
                
                VStack(spacing: Theme.Spacing.m) {
                    DailySummaryCard(
                        points: vm.pointsToday,
                        goal: vm.dailyGoal,
                        progress: vm.progress,
                        availablePoints: vm.availablePoints
                    )
                }
                .padding(.horizontal, Theme.Spacing.l)
                
                habitList(vm: vm)
                
                VStack(spacing: Theme.Spacing.m) {
                    ProgressView(value: Double(vm.pointsToday), total: Double(
                        vm.habits.map { $0.points.rawValue }.reduce(0, +)
                    ))
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .padding(.horizontal, Theme.Spacing.l)

                    Text("Fortschritt: \(vm.pointsToday) / \(vm.habits.map { $0.points.rawValue }.reduce(0, +)) Punkte")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                        progress: vm.habitProgress[habit.id],
                        onToggle: { vm.toggle(habit) },
                        onIncrement: { vm.incrementMeasurable(habit) },
                        onDecrement: { vm.decrementMeasurable(habit) },
                        onEdit: {
                            editingHabit = habit
                        }
                    )
                    .contextMenu {
                        Button("Bearbeiten", systemImage: "pencil") { editingHabit = habit }
                        Button("Archivieren", systemImage: "archivebox", role: .destructive) {
                            vm.delete(habit)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if env.entitlements.canCreateHabit {
                    showingNewHabit = true
                } else {
                    showingPaywall = true
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Neuer Habit")
        }
#if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Button { showingDebug = true } label: {
                Image(systemName: "hammer.fill")
            }
        }
#endif
    }
}
