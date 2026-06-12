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
    
    var body: some View {
        List {
            // Aktiver Plan Highlight
            if let activePlan = plans.first(where: \.isActive) {
                Section {
                    ActivePlanCard(plan: activePlan) {
                        selectedPlan = activePlan
                    }
                } header: {
                    Text("Aktiver Plan")
                }
            }
            
            // Alle Pläne
            Section {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "Keine Trainingspläne",
                        systemImage: "calendar.badge.plus",
                        description: Text("Erstelle deinen ersten Trainingsplan")
                    )
                } else {
                    planList(plans: plans)
                }
            } header: {
                Text("Alle Pläne")
            }
        }
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
                Task {
                    await load()
                }
            })
        }
        .sheet(item: $selectedPlan) { plan in
            NavigationStack {
                TrainingsPlanDetailView(plan: plan)
            }
        }
        .searchable(text: $searchText, prompt: "Pläne durchsuchen") {
            planList(plans: plans.filter { $0.name.lowercased().contains(searchText.lowercased()) })
        }
        .task { await load() }
        .refreshable { await load() }
    }
    
    private func planList(plans: [TrainingsPlan]) -> some View {
        ForEach(plans) { plan in
            TrainingsPlanRow(plan: plan) {
                selectedPlan = plan
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    deletePlan(plan)
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
                
                if !plan.isActive {
                    Button {
                        setActive(plan)
                    } label: {
                        Label("Aktivieren", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
            }
        }
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

// MARK: - Active Plan Card

// MARK: - Plan Row
