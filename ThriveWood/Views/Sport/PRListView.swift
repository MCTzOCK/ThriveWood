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
                BentoEmptyState(
                    systemImage: "trophy",
                    title: Text("Noch keine PRs"),
                    message: Text("Schließe dein erstes Workout ab, um hier deine persönlichen Rekorde zu sehen.")
                )
            } else {
                prContent
            }
        }
        .onAppear { load() }
        .bentoSheet(
            isPresented: Binding(
                get: { selectedPR != nil },
                set: { if !$0 { selectedPR = nil } }
            ),
            title: Text("Progression"),
            detents: [.large]
        ) {
            if let selection = selectedPR {
                ExerciseProgressionSheet(exercise: selection.exercise, topSet: selection.topSet)
            }
        }
    }

    private var prContent: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("REKORDE"),
                title: Text("Persönliche PRs"),
                subtitle: Text("\(entries.count) Übungen mit PR")
            )

            BentoSearchField(text: $searchText, prompt: Text("Übung suchen")) {
                Haptics.selection()
            }

            LazyVStack(alignment: .leading, spacing: Theme.Spacing.l, pinnedViews: [.sectionHeaders]) {
                ForEach(sections, id: \.letter) { letter, items in
                    Section {
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
                    } header: {
                        BentoText(verbatim: letter, style: .overline, color: .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer(minLength: 40)
        }
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
