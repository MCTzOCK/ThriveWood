//
//  PRListView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 19.05.26.
//


import SwiftUI

struct PRListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var entries: [(exercise: Exercise, topSet: SetEntry)] = []
    @State private var searchText = ""
    @State private var selectedPR: PRSelection?

    private var filtered: [(exercise: Exercise, topSet: SetEntry)] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.exercise.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sections: [(letter: String, items: [(exercise: Exercise, topSet: SetEntry)])] {
        Dictionary(grouping: filtered) {
            let first = String($0.exercise.name.prefix(1)).uppercased()
            return first.unicodeScalars.first?.properties.isAlphabetic == true ? first : "#"
        }
        .sorted { $0.key < $1.key }
        .map { (letter: $0.key, items: $0.value) }
    }

    private var availableLetters: [String] {
        sections.map(\.letter)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                PremiumEmptyState(
                    icon: "trophy",
                    title: "Noch keine PRs",
                    message: "Schließe dein erstes Workout ab, um hier deine persönlichen Rekorde zu sehen."
                )
            } else {
                prContent
            }
        }
        .navigationTitle("PRs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Übung suchen")
        .onAppear { load() }
        .sheet(item: $selectedPR) { selection in
            ExerciseProgressionSheet(exercise: selection.exercise, topSet: selection.topSet)
        }
    }

    private var prContent: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                ForEach(sections, id: \.letter) { letter, items in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(letter)
                            .font(Theme.Typography.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, Theme.Spacing.l)

                        VStack(spacing: Theme.Spacing.s) {
                            ForEach(items, id: \.exercise.id) { exercise, topSet in
                                Button {
                                    selectedPR = PRSelection(exercise: exercise, topSet: topSet)
                                } label: {
                                    PRRow(exercise: exercise, topSet: topSet)
                                }
                                .buttonStyle(PressScaleStyle())
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
    }

    private func load() {
        entries = env.workoutService.getAllPRs()
    }
}

struct PRSelection: Identifiable {
    let exercise: Exercise
    let topSet: SetEntry
    var id: UUID { exercise.id }
}
