//
//  ForestView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct ForestView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: ForestViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm { content(vm: vm) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Mein Wald")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if vm == nil { vm = ForestViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: ForestViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                ForestStatsHeader(
                    available: vm.availablePoints,
                    total: vm.totalEarned,
                    coverage: vm.coverage,
                    treeCount: vm.trees.count
                )
                .padding(.horizontal, Theme.Spacing.l)

                ForestGridView(vm: vm)
                    .padding(.horizontal, Theme.Spacing.l)

                HintCard()
                    .padding(.horizontal, Theme.Spacing.l)
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.93, blue: 0.98),
                    Color(red: 0.78, green: 0.90, blue: 0.82)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $vm.showingSpeciesPicker) {
            SpeciesPickerSheet(vm: vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $vm.selectedTree) { tree in
            TreeDetailSheet(tree: tree, vm: vm)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .errorAlert(vm.errors)
    }
}
