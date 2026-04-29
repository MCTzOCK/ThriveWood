//
//  AnalyticsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: AnalyticsViewModel?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm { content(vm: vm) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Analyse")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if vm == nil { vm = AnalyticsViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: AnalyticsViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                Picker("Zeitraum", selection: $vm.range) {
                    Text("7T").tag(AnalyticsRange.week)
                    ForEach([AnalyticsRange.month, .quarter, .year]) { r in
                        HStack {
                            Text(r.rawValue)
                        }.tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.range) { _, newRange in
                    if newRange != .week && !env.entitlements.canAccessFullAnalytics {
                        vm.range = .week
                        showingPaywall = true
                    }
                    vm.load()
                }
                /*
                RangePicker(range: $vm.range)
                    .padding(.horizontal, Theme.Spacing.l)
                    .onChange(of: vm.range) { _, _ in vm.load() }*/

                if let summary = vm.summary {
                    SummaryGrid(summary: summary)
                        .padding(.horizontal, Theme.Spacing.l)
                }

                PointsTrendCard(samples: vm.dailySamples, goal: vm.dailyGoal)
                    .padding(.horizontal, Theme.Spacing.l)

                WeekdayDistributionCard(data: vm.weekdayDistribution)
                    .padding(.horizontal, Theme.Spacing.l)

                if !vm.habitPerformances.isEmpty {
                    HabitLeaderboardCard(performances: vm.habitPerformances)
                        .padding(.horizontal, Theme.Spacing.l)

                    HeatmapCard(
                        performances: vm.habitPerformances,
                        selectedHabitID: vm.selectedHabitID,
                        heatmap: vm.heatmap,
                        onSelect: vm.selectHabit
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                }

                if let totals = vm.workoutTotals,
                   !vm.workoutMetrics.isEmpty,
                   totals.totalSessions > 0 {
                    WorkoutStatsCard(samples: vm.workoutMetrics, totals: totals)
                        .padding(.horizontal, Theme.Spacing.l)
                }

                if env.healthService.isAuthorized {
                    StepsCard(range: vm.range.dateRange())
                        .padding(.horizontal, Theme.Spacing.l)
                }

                if vm.habitPerformances.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Daten",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Hake deine ersten Habits ab, um Auswertungen zu sehen.")
                    )
                    .padding(.top, Theme.Spacing.xl)
                }
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .background(Color(.systemGroupedBackground))
        .refreshable { vm.load() }
        .errorAlert(vm.errors)
    }
}
