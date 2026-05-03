//
//  NutritionGoalEditor.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct NutritionGoalEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goals: NutritionGoals
    let onSave: (NutritionGoals) -> Void

    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double

    init(goals: Binding<NutritionGoals>, onSave: @escaping (NutritionGoals) -> Void) {
        self._goals = goals
        self.onSave = onSave
        self._calories = State(initialValue: goals.wrappedValue.calories)
        self._protein = State(initialValue: goals.wrappedValue.protein)
        self._carbs = State(initialValue: goals.wrappedValue.carbs)
        self._fat = State(initialValue: goals.wrappedValue.fat)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tagesziele") {
                    GoalRow(label: "Kalorien", value: $calories, unit: "kcal", color: .orange)
                    GoalRow(label: "Protein", value: $protein, unit: "g", color: .blue)
                    GoalRow(label: "Kohlenhydrate", value: $carbs, unit: "g", color: .green)
                    GoalRow(label: "Fett", value: $fat, unit: "g", color: .yellow)
                }

                Section {
                    Button("Zurücksetzen") {
                        let defaults = NutritionGoals.default
                        calories = defaults.calories
                        protein = defaults.protein
                        carbs = defaults.carbs
                        fat = defaults.fat
                    }
                    .foregroundStyle(.red)
                }

                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Schnellauswahl")
                            .font(.headline)
                        HStack(spacing: Theme.Spacing.s) {
                            PresetButton(label: "Abnehmen", calories: 1500, protein: 130, carbs: 150, fat: 50) {
                                applyPreset($0, $1, $2, $3)
                            }
                            PresetButton(label: "Halten", calories: 2000, protein: 120, carbs: 250, fat: 65) {
                                applyPreset($0, $1, $2, $3)
                            }
                            PresetButton(label: "Aufbauen", calories: 2500, protein: 180, carbs: 300, fat: 80) {
                                applyPreset($0, $1, $2, $3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ziele bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let newGoals = NutritionGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
                        goals = newGoals
                        onSave(newGoals)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyPreset(_ c: Double, _ p: Double, _ carb: Double, _ f: Double) {
        calories = c
        protein = p
        carbs = carb
        fat = f
    }
}

struct GoalRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

struct PresetButton: View {
    let label: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let onTap: (Double, Double, Double, Double) -> Void

    var body: some View {
        Button {
            onTap(calories, protein, carbs, fat)
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
