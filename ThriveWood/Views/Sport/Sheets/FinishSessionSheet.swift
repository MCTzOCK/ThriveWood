//
//  FinishSessionSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct FinishSessionSheet: View {
    @Binding var rpe: Int
    @Binding var notes: String
    var overloadSuggestions: [OverloadSuggestion] = []
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    struct OverloadSuggestion: Identifiable {
        let id = UUID()
        let exerciseName: String
        let exerciseIcon: String
        let lastWeight: Double
        let lastReps: Int
        let suggestedWeight: Double
        let suggestedReps: Int
        let increasePercent: Double
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wie anstrengend war's?") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack {
                            Text("RPE")
                            Spacer()
                            Text("\(rpe)/10").font(.headline).monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { Double(rpe) },
                            set: { rpe = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                }
                if !overloadSuggestions.isEmpty {
                    Section {
                        ForEach(overloadSuggestions) { sug in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: sug.exerciseIcon)
                                        .foregroundStyle(.tint)
                                    Text(sug.exerciseName)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text("+\(String(format: "%.0f", sug.increasePercent))%")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                }
                                HStack(spacing: 4) {
                                    Text("\(sug.lastWeight.clean)kg × \(sug.lastReps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text("\(sug.suggestedWeight.clean)kg × \(sug.suggestedReps)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Progressive Overload")
                        }
                    } footer: {
                        Text("Vorschläge für das nächste Mal – basierend auf deiner letzten Performance.")
                    }
                }
                Section("Notizen") {
                    TextField("Gedanken zum Workout…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Workout beenden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zurück") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { onConfirm(); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
