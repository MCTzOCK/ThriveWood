//
//  ExerciseEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Exercise) -> Void

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var category: ExerciseCategory = .strength
    @State private var primary: Set<MuscleGroup> = []
    @State private var icon: String = "dumbbell.fill"

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Beschreibung", text: $details, axis: .vertical).lineLimit(1...3)
                }
                Section("Kategorie") {
                    Picker("Kategorie", selection: $category) {
                        ForEach(ExerciseCategory.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }
                Section("Muskelgruppen") {
                    ForEach(MuscleGroup.allCases) { group in
                        Toggle(group.rawValue.capitalized, isOn: Binding(
                            get: { primary.contains(group) },
                            set: {
                                if $0 {
                                    primary.insert(group)
                                } else {
                                    primary.remove(group)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let e = Exercise(
                            name: name.trimmingCharacters(in: .whitespaces),
                            details: details, category: category,
                            primaryMuscleGroups: Array(primary),
                            iconSystemName: icon, isBuiltIn: false
                        )
                        onSave(e); dismiss()
                    }
                    .disabled(!isValid).fontWeight(.semibold)
                }
            }
        }
    }
}
