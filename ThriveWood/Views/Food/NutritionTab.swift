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
    @State private var selectedSegment: NutritionSegment = .food
    @State private var showAddFood = false
    @State private var showAddSupplement = false

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
                    FoodDiaryView(selectedDate: $selectedDate)
                case .supplements:
                    SupplementListView(selectedDate: $selectedDate)
                }
            }
            .navigationTitle("Ernährung")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if selectedSegment == .food {
                            showAddFood = true
                        } else {
                            showAddSupplement = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                FoodSearchView(selectedDate: selectedDate)
            }
            .sheet(isPresented: $showAddSupplement) {
                SupplementEditorView(supplement: nil)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}
