//
//  NutritionTab.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct NutritionTab: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedDate: Date = .now
    @State private var selectedSegment: NutritionSegment = .supplements
    @State private var showAddFood = false
    @State private var showAddSupplement = false
    @State private var showingPaywall = false

    enum NutritionSegment: String, CaseIterable {
        case food = "Ernährung"
        case supplements = "Supplements"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSegment) {
                    ForEach(NutritionSegment.allCases, id: \.self) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSegment {
                case .food:
                    //FoodDiaryView(selectedDate: $selectedDate)
                    // content coming soon
                    ContentUnavailableView(
                        "In Kürze verfügbar",
                        systemImage: "fork.knife.circle",
                        description: Text("Die Ernährungsübersicht ist derzeit in Entwicklung.")
                    )
                case .supplements:
                    Text("In Kürze verfügbar")
                    //SupplementListView(selectedDate: $selectedDate)
                }
            }
            .navigationTitle("Ernährung")
            .toolbar {
                if selectedSegment == .supplements {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if env.entitlements.canCreateSupplement {
                                showAddSupplement = true
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    if env.aiService.isAvailable() {
                        ToolbarItem(placement: .automatic) {
                            NavigationLink {
                                SupplementAnalysisView()
                            } label: {
                                Image(systemName: "sparkles")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                FoodSearchView(selectedDate: selectedDate)
            }
            .sheet(isPresented: $showAddSupplement) {
                SupplementEditorView(supplement: nil)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .background(Color.groupedBackground)
        }
    }
}
