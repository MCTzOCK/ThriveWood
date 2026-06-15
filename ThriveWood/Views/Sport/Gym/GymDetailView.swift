//
//  GymDetailView.swift
//  ThriveWood
//


import SwiftUI

struct GymDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Bindable var gym: Gym

    @State private var selectedTab: GymDetailTab = .map
    @State private var showingEditGym = false
    @State private var errors = ErrorState()

    private enum GymDetailTab: String, CaseIterable {
        case map = "Karte"
        case exercises = "Übungen"
        case equipment = "Geräte"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(GymDetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)

            switch selectedTab {
            case .map:
                GymFloorPlanView(gym: gym)
            case .exercises:
                GymExerciseListView(gym: gym)
            case .equipment:
                GymEquipmentListView(gym: gym)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(gym.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditGym = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingEditGym) {
            GymEditorView(gym: gym)
        }
        .errorAlert(errors)
    }
}
