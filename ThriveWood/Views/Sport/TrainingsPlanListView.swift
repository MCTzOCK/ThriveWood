//
//  TrainingsPlanListView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//

import SwiftUI

struct TrainingsPlanListView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var plans: [TrainingsPlan] = []
    @State private var showCreateSheet = false
    @State private var selectedPlan: TrainingsPlan?
    @State private var searchText: String = ""

    private var filteredPlans: [TrainingsPlan] {
        guard !searchText.isEmpty else { return plans }
        return plans.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                if let activePlan = plans.first(where: \.isActive) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Aktiver Plan")
                            .font(Theme.Typography.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, Theme.Spacing.l)

                        Button {
                            selectedPlan = activePlan
                        } label: {
                            ActivePlanCard(plan: activePlan, onTap: { selectedPlan = activePlan })
                        }
                        .buttonStyle(BounceButtonStyle())
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Alle Pläne")
                        .font(Theme.Typography.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, Theme.Spacing.l)

                    if filteredPlans.isEmpty {
                        PremiumEmptyState(
                            icon: "calendar.badge.plus",
                            title: "Keine Trainingspläne",
                            message: "Erstelle deinen ersten Trainingsplan über das Plus-Symbol.",
                            actionTitle: "Plan erstellen"
                        ) {
                            showCreateSheet = true
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.xl)
                    } else {
                        VStack(spacing: Theme.Spacing.s) {
                            ForEach(filteredPlans) { plan in
                                Button {
                                    selectedPlan = plan
                                } label: {
                                    TrainingsPlanRow(plan: plan, onTap: { selectedPlan = plan })
                                }
                                .buttonStyle(PressScaleStyle())
                                .contextMenu {
                                    if !plan.isActive {
                                        Button {
                                            setActive(plan)
                                        } label: {
                                            Label("Aktivieren", systemImage: "checkmark.circle")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        deletePlan(plan)
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trainingspläne")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTrainingsPlanSheet(onCreate: {
                Task { await load() }
            })
        }
        .sheet(item: $selectedPlan) { plan in
            NavigationStack {
                TrainingsPlanDetailView(plan: plan)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            plans = try env.trainingsPlanService.fetchAll()
        } catch {
            print("Load error: \(error)")
        }
    }

    private func setActive(_ plan: TrainingsPlan) {
        do {
            try env.trainingsPlanService.setActivePlan(plan)
            Haptics.success()
            Task { await load() }
        } catch {
            print("Set active error: \(error)")
        }
    }

    private func deletePlan(_ plan: TrainingsPlan) {
        do {
            try env.trainingsPlanService.deletePlan(plan)
            Haptics.success()
            Task { await load() }
        } catch {
            print("Delete error: \(error)")
        }
    }
}
