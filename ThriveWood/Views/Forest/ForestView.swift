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
        Group {
            if let vm { content(vm: vm) }
            else {
                BentoScreen(scrolls: false) {
                    VStack(spacing: Theme.Spacing.m) {
                        BentoSpinner(size: 40)
                        BentoText(verbatim: "Wald wird geladen…", style: .callout, color: .secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        // Standard-NavBar sichtbar lassen (für den Back-Button), aber den
        // Titel ausblenden, da der BentoPageHeader den Titel bereits zeigt.
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { EmptyView() }
        }
        .task {
            if vm == nil { vm = ForestViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: ForestViewModel) -> some View {
        @Bindable var vm = vm

        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            VStack(spacing: Theme.Spacing.l) {
                BentoPageHeader(
                    eyebrow: Text("DEIN WALD"),
                    title: Text("Mein Wald"),
                    subtitle: Text("Pflanze Bäume und sieh sie wachsen")
                )
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)

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
            .padding(.bottom, 120)
        }
        .bentoSheet(
            isPresented: $vm.showingSpeciesPicker,
            title: Text("Baum pflanzen"),
            subtitle: Text("Wähle eine Spezies für dein Feld"),
            detents: [.medium, .large]
        ) {
            SpeciesPickerSheet(vm: vm)
        }
        .bentoSheet(
            isPresented: Binding(
                get: { vm.selectedTree != nil },
                set: { if !$0 { vm.selectedTree = nil } }
            ),
            title: Text("Baum"),
            subtitle: Text("Gießen oder entfernen"),
            detents: [.medium, .large]
        ) {
            if let tree = vm.selectedTree {
                TreeDetailSheet(tree: tree, vm: vm)
            }
        }
        .errorAlert(vm.errors)
    }
}
