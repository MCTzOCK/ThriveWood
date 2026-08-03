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
    @State private var showAIGenerator = false
    @State private var selectedPlan: TrainingsPlan?
    @State private var searchText: String = ""

    private var filteredPlans: [TrainingsPlan] {
        guard !searchText.isEmpty else { return plans }
        return plans.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            VStack(spacing: Theme.Spacing.l) {
                BentoPageHeader(
                    eyebrow: Text("PLÄNE"),
                    title: Text("Trainingspläne"),
                    subtitle: Text(filteredPlans.count > 0 ? "\(filteredPlans.count) Pläne" : "Erstelle deinen ersten Plan")
                ) {
                    BentoIconButton(
                        systemImage: "plus",
                        accessibilityLabel: Text("Plan erstellen"),
                        variant: .primary
                    ) {
                        showCreateSheet = true
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)

                if let activePlan = plans.first(where: \.isActive) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        BentoText(verbatim: "AKTIVER PLAN", style: .overline, color: .secondary)
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
                    BentoText(verbatim: "ALLE PLÄNE", style: .overline, color: .secondary)
                        .padding(.horizontal, Theme.Spacing.l)

                    if filteredPlans.isEmpty {
                        BentoEmptyState(
                            systemImage: "calendar.badge.plus",
                            title: Text("Keine Trainingspläne"),
                            message: Text("Erstelle deinen ersten Trainingsplan über das Plus-Symbol."),
                            actionTitle: Text("Plan erstellen"),
                            action: { showCreateSheet = true }
                        )
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
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Trainingspläne")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 4) {
                    /*if env.aiService.isAvailable() {
                        Button {
                            showAIGenerator = true
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                        }
                    }*/
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .bentoSheet(
            isPresented: $showCreateSheet,
            title: Text("Neuer Trainingsplan"),
            detents: [.large]
        ) {
            CreateTrainingsPlanSheet(onCreate: {
                Task { await load() }
            })
        }
        .bentoSheet(
            isPresented: $showAIGenerator,
            title: Text("KI-Plan-Generator"),
            detents: [.large]
        ) {
            NavigationStack {
                AIPlanGeneratorView()
            }
        }
        .bentoSheet(
            isPresented: Binding(
                get: { selectedPlan != nil },
                set: { if !$0 { selectedPlan = nil } }
            ),
            title: Text("Trainingsplan"),
            detents: [.large]
        ) {
            if let plan = selectedPlan {
                NavigationStack {
                    TrainingsPlanDetailView(plan: plan)
                }
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
