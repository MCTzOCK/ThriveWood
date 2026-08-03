//
//  HomeView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI

fileprivate enum HomeTab: Hashable, CaseIterable {
    case habits
    case supplements

    var label: String {
        switch self {
        case .habits: "Habits"
        case .supplements: "Supplements"
        }
    }
}

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(NotificationRouter.self) private var router

    @State private var vm: HomeViewModel?
    @State private var showingNewHabit = false
    @State private var editingHabit: Habit?
    @State private var editingGroup: HabitGroup?
    @State private var showingNewGroup = false
    @State private var showingReorder = false
    @State private var showingDebug: Bool = false
    @State private var showingPaywall = false
    @State private var completedCollapsed: Bool = true
    @State private var selectedTab: HomeTab = .habits
    @State private var selectedDate: Date = .now
    @State private var supplementSearch = ""
    @AppStorage("ungroupedCollapsed") private var ungroupedCollapsed: Bool = false
    
    @Environment(\.bentoTheme) private var theme

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    bentoContent(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .bentoSheet(
                isPresented: $showingNewHabit,
                title: Text("Neuer Habit"),
                subtitle: Text("Sammle Punkte und pflanze Bäume"),
                detents: [.large]
            ) {
                BentoNewHabitSheet()
                    .onDisappear { vm?.load() }
            }
            .bentoSheet(
                isPresented: Binding(
                    get: { editingHabit != nil },
                    set: { if !$0 { editingHabit = nil } }
                ),
                title: Text("Habit bearbeiten"),
                subtitle: Text("Ändere Details, Farbe und mehr"),
                detents: [.large]
            ) {
                if let habit = editingHabit {
                    BentoEditHabitSheet(habit: habit)
                        .onDisappear { vm?.load() }
                }
            }
            .sheet(isPresented: $showingNewGroup) {
                HabitGroupEditorView(group: nil).onDisappear { vm?.load() }
            }
            .sheet(item: $editingGroup) { group in
                HabitGroupEditorView(group: group).onDisappear { vm?.load() }
            }
            .sheet(isPresented: $showingReorder) {
                if let vm { HabitReorderView(vm: vm) }
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
    private func bentoContent(vm: HomeViewModel) -> some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text(greetingText.uppercased()),
                title: Text("Habits")
            ) {
                NavigationLink {
                    WellnessView()
                } label: {
                    BentoIconButton(systemImage: "heart.fill", accessibilityLabel: Text("Wellness"), variant: .tonal(.pink), size: .medium) {}
                        .allowsHitTesting(false)
                }
                NavigationLink {
                    AchievementsView()
                } label: {
                    BentoIconButton(systemImage: "trophy.fill", accessibilityLabel: Text("Erfolge"), variant: .tonal(.yellow), size: .medium) {}
                        .allowsHitTesting(false)
                }

                BentoIconButton(systemImage: "plus", accessibilityLabel: Text("Neues Habit"), variant: .primary, size: .medium) {
                    if env.entitlements.canCreateHabit {
                        showingNewHabit = true
                    } else {
                        showingPaywall = true
                    }
                }
            }

            if vm.habits.isEmpty {
                emptyHeroState
            } else {

                BentoWeekStripView(
                    selectedDate: Binding(
                        get: { vm.selectedDate },
                        set: { vm.changeDate(to: $0) }
                    )
                )
                
                
                heroProgressCard(vm: vm)

                CompanionCard()

                bentoHabitList(vm: vm)
            }
        }
    }

    // MARK: - Empty Hero

    private var emptyHeroState: some View {
        BentoCard(tone: .accent, style: .elevated, padding: .xl, radius: .extraLarge) {
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.colors.onAccent)
                    .symbolEffect(.bounce, value: true)

                VStack(spacing: theme.spacing.xs) {
                    BentoText("Starte deinen Wald", style: .title2, color: theme.colors.onAccent)
                    BentoText(
                        "Lege deinen ersten Habit an und sammle Punkte, um Bäume zu pflanzen.",
                        style: .body,
                        color: theme.colors.onAccent.opacity(0.85)
                    )
                }
                .multilineTextAlignment(.center)

                BentoButton(
                    Text("Ersten Habit erstellen"),
                    systemImage: "plus.circle.fill",
                    variant: .secondary,
                    expands: true
                ) {
                    showingNewHabit = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Hero Progress

    @ViewBuilder
    private func heroProgressCard(vm: HomeViewModel) -> some View {
        NavigationLink {
            ForestView()
        } label: {
            BentoCard(tone: .accent, style: .elevated, padding: .lg, radius: .extraLarge) {
                HStack(spacing: theme.spacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(theme.colors.onAccent.opacity(0.2), lineWidth: 10)
                            .frame(width: 84, height: 84)
                        Circle()
                            .trim(from: 0, to: max(0.001, vm.progress))
                            .stroke(
                                theme.colors.onAccent,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 84, height: 84)
                            .rotationEffect(.degrees(-90))
                            .animation(theme.motion.snappy, value: vm.progress)
                        BentoText(
                            "\(Int(vm.progress * 100))%",
                            style: .headline,
                            color: theme.colors.onAccent
                        )
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        BentoText(
                            verbatim: motivationalHeadline(vm: vm),
                            style: .title3,
                            color: theme.colors.onAccent
                        )
                        HStack(alignment: .lastTextBaseline, spacing: theme.spacing.xxs) {
                            BentoText(
                                "\(vm.pointsToday)",
                                style: .metric,
                                color: theme.colors.onAccent
                            )
                            BentoText(
                                "/ \(vm.dailyGoal) Punkte",
                                style: .callout,
                                color: theme.colors.onAccent.opacity(0.8)
                            )
                        }
                        BentoBadge(
                            Text("\(vm.availablePoints) verfügbar"),
                            tone: .neutral,
                            systemImage: "leaf.fill"
                        )
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "tree.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.colors.onAccent.opacity(0.35))
                        .symbolEffect(.pulse, value: vm.progress >= 1.0)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func motivationalHeadline(vm: HomeViewModel) -> String {
        if vm.pointsToday == 0 { return "Heute wird dein Tag!" }
        if vm.pointsToday < vm.dailyGoal { return "Du schaffst das!" }
        return "Ziel erreicht!"
    }

    @ViewBuilder
    private func bentoHabitList(vm: HomeViewModel) -> some View {
        if vm.filteredHabits.isEmpty {
            BentoEmptyState(
                systemImage: "magnifyingglass",
                title: Text("Keine Treffer"),
                message: Text("Für \"\(vm.searchText)\" wurden keine Habits gefunden.")
            )
            .padding(.top, theme.spacing.xl)
        } else {
            let incomplete = vm.filteredHabits.filter { !vm.completedHabitIDs.contains($0.id) }
            let completed = vm.filteredHabits.filter { vm.completedHabitIDs.contains($0.id) }

            VStack(spacing: theme.spacing.lg) {
                if incomplete.isEmpty {
                    allDoneCard
                } else {
                    BentoAdaptiveGrid(minimumItemWidth: 160) {
                        ForEach(incomplete) { habit in
                            BentoHabitRowView(
                                habit: habit,
                                isCompleted: false,
                                streak: vm.streak(for: habit),
                                progress: vm.habitProgress[habit.id],
                                onToggle: { vm.toggle(habit) },
                                onIncrement: { vm.incrementMeasurable(habit) },
                                onDecrement: { vm.decrementMeasurable(habit) },
                                onEdit: { editingHabit = habit }
                            )
                        }
                    }
                }

                if !completed.isEmpty {
                    completedSection(completed, vm: vm)
                }
            }
        }
    }

    // MARK: - All Done

    private var allDoneCard: some View {
        BentoCard(
            background: theme.colors.success.opacity(0.15),
            foreground: .primary,
            style: .flat,
            padding: .lg,
            radius: .large
        ) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.colors.success)
                BentoText("Alles erledigt!", style: .title3)
                BentoText(
                    "Du hast heute alle Habits abgeschlossen.",
                    style: .callout,
                    color: theme.colors.onSurfaceMuted
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Completed Section

    @ViewBuilder
    private func completedSection(_ habits: [Habit], vm: HomeViewModel) -> some View {
        VStack(spacing: theme.spacing.sm) {
            Button {
                withAnimation(theme.motion.snappy) { completedCollapsed.toggle() }
                Haptics.selection()
            } label: {
                BentoCard(
                    background: theme.colors.success.opacity(0.12),
                    foreground: .primary,
                    style: .flat,
                    padding: .sm,
                    radius: .large
                ) {
                    HStack(spacing: theme.spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(theme.colors.success)
                                .frame(width: 30, height: 30)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(theme.colors.onSuccess)
                        }
                        BentoText("Erledigt", style: .headline, color: .white)
                        Spacer()
                        BentoBadge(
                            Text("\(habits.count)"),
                            tone: .success
                        )
                        Image(systemName: completedCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            .buttonStyle(.plain)

            if !completedCollapsed {
                BentoAdaptiveGrid(minimumItemWidth: 160) {
                    ForEach(habits) { habit in
                        BentoHabitRowView(
                            habit: habit,
                            isCompleted: true,
                            streak: vm.streak(for: habit),
                            progress: vm.habitProgress[habit.id],
                            onToggle: { vm.toggle(habit) },
                            onIncrement: { vm.incrementMeasurable(habit) },
                            onDecrement: { vm.decrementMeasurable(habit) },
                            onEdit: { editingHabit = habit }
                        )
                    }
                }
                .padding(.top, theme.spacing.sm)
                .transition(.opacity)
            }
        }
        .animation(theme.motion.snappy, value: completedCollapsed)
        .animation(theme.motion.snappy, value: habits.map(\.id))
    }

    var oldBody: some View {
        NavigationStack {
            Group {
                if let vm {
                    VStack(spacing: 0) {
                        premiumHeader(vm: vm)
                        content(vm: vm)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewHabit) {
                HabitEditorView(habit: nil).onDisappear { vm?.load() }
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorView(habit: habit).onDisappear { vm?.load() }
            }
            .sheet(isPresented: $showingNewGroup) {
                HabitGroupEditorView(group: nil).onDisappear { vm?.load() }
            }
            .sheet(item: $editingGroup) { group in
                HabitGroupEditorView(group: group).onDisappear { vm?.load() }
            }
            .sheet(isPresented: $showingReorder) {
                if let vm { HabitReorderView(vm: vm) }
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

    // MARK: - Premium Header

    @ViewBuilder
    private func premiumHeader(vm: HomeViewModel) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Text(selectedTab == .habits ? "Habits" : "Supplements")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)

            actionButtons
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)

        PremiumSegmentedPicker(selection: $selectedTab, options: HomeTab.allCases) { tab in
            Text(tab.label)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        .animation(Theme.Animation.spring, value: selectedTab)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<5: return "Gute Nacht"
        case 5..<12: return "Guten Morgen"
        case 12..<18: return "Guten Tag"
        default: return "Guten Abend"
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.s) {
            NavigationLink {
                WellnessView()
            } label: {
                Image(systemName: "heart.fill")
                    .font(Theme.Typography.body)
                    .frame(width: 38, height: 38)
                    .foregroundStyle(Color.pink)
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.12))
                    )
            }
            .buttonStyle(PressScaleStyle())

            NavigationLink {
                AchievementsView()
            } label: {
                Image(systemName: "trophy.fill")
                    .font(Theme.Typography.body)
                    .frame(width: 38, height: 38)
                    .foregroundStyle(Color.orange)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                    )
            }
            .buttonStyle(PressScaleStyle())

            Button {
                if env.entitlements.canCreateHabit {
                    showingNewHabit = true
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
                    )
            }
            .buttonStyle(BounceButtonStyle())

            #if DEBUG
            Button {
                showingDebug = true
            } label: {
                Image(systemName: "hammer.fill")
                    .font(Theme.Typography.caption)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.secondary)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
            }
            .buttonStyle(PressScaleStyle())
            #endif
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: HomeViewModel) -> some View {
        if selectedTab == .habits {
            habitsContent(vm: vm)
        } else {
            SupplementListView(selectedDate: $selectedDate, search: $supplementSearch)
                .background(Color(.systemGroupedBackground))
                .searchable(text: $supplementSearch, placement: .navigationBarDrawer(displayMode: .automatic))
        }
    }

    @ViewBuilder
    private func habitsContent(vm: HomeViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                WeekStripView(
                    selectedDate: Binding(
                        get: { vm.selectedDate },
                        set: { vm.changeDate(to: $0) }
                    )
                )
                .padding(.horizontal, Theme.Spacing.l)

                heroSummaryCard(vm: vm)

                habitList(vm: vm)
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
    }

    // MARK: - Hero Summary Card

    @ViewBuilder
    private func heroSummaryCard(vm: HomeViewModel) -> some View {
        NavigationLink {
            ForestView()
        } label: {
            HStack(spacing: Theme.Spacing.l) {
                ZStack {
                    ProgressRing(progress: vm.progress, lineWidth: 7)
                        .frame(width: 76, height: 76)
                    VStack(spacing: 0) {
                        AnimatedNumberText(value: Double(vm.pointsToday), color: .primary)
                        Text("/ \(vm.dailyGoal)")
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.progress >= 1 ? "Ziel erreicht!" : "Tagesziel")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(.primary)
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "leaf.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Color.accentColor)
                        Text("\(vm.availablePoints) Punkte verfügbar")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "tree.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Color.green)
                        Text("Wald entdecken")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(Color.accentColor.opacity(0.06))
            )
        }
        .buttonStyle(PressScaleStyle())
        .padding(.horizontal, Theme.Spacing.l)
    }

    // MARK: - Habit List

    @ViewBuilder
    private func habitList(vm: HomeViewModel) -> some View {
        if vm.habits.isEmpty {
            PremiumEmptyState(
                icon: "leaf.circle.fill",
                title: "Starte deinen Wald",
                message: "Lege deinen ersten Habit an und sammle Punkte, um Bäume zu pflanzen.",
                actionTitle: "Habit erstellen"
            ) {
                showingNewHabit = true
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.xl)
        } else if vm.filteredHabits.isEmpty {
            PremiumEmptyState(
                icon: "magnifyingglass",
                title: "Keine Treffer",
                message: "Für \"\(vm.searchText)\" wurden keine Habits gefunden."
            )
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.xl)
        } else {
            LazyVStack(spacing: Theme.Spacing.m) {
                let sections = vm.groupedDisplaySections
                ForEach(sections, id: \.group?.id) { section in
                    VStack(spacing: Theme.Spacing.s) {
                        if let group = section.group {
                            HabitGroupHeaderView(
                                group: group,
                                habitCount: section.habits.count,
                                onToggle: { vm.toggleCollapsed(group) },
                                onEdit: { editingGroup = group }
                            )
                        } else {
                            Button {
                                withAnimation(Theme.Animation.spring) {
                                    ungroupedCollapsed.toggle()
                                }
                                Haptics.selection()
                            } label: {
                                UngroupedHeaderView(
                                    habitCount: section.habits.count,
                                    isCollapsed: ungroupedCollapsed
                                )
                            }
                            .buttonStyle(PressScaleStyle())
                        }

                        if section.group?.isCollapsed != true && (section.group != nil || !ungroupedCollapsed) {
                            ForEach(section.habits) { habit in
                                HabitRowView(
                                    habit: habit,
                                    isCompleted: vm.completedHabitIDs.contains(habit.id),
                                    streak: vm.streak(for: habit),
                                    progress: vm.habitProgress[habit.id],
                                    onToggle: { vm.toggle(habit) },
                                    onIncrement: { vm.incrementMeasurable(habit) },
                                    onDecrement: { vm.decrementMeasurable(habit) },
                                    onEdit: { editingHabit = habit }
                                )
                                .contextMenu {
                                    Button("Bearbeiten", systemImage: "pencil") { editingHabit = habit }
                                    Button("Archivieren", systemImage: "archivebox", role: .destructive) {
                                        vm.delete(habit)
                                    }
                                    if !vm.groups.isEmpty {
                                        Menu("In Gruppe verschieben", systemImage: "folder") {
                                            ForEach(vm.groups) { g in
                                                Button(g.title) {
                                                    vm.addHabitToGroup(habit.id, groupID: g.id)
                                                }
                                            }
                                            Button("Ohne Gruppe") {
                                                vm.addHabitToGroup(habit.id, groupID: nil)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
}
