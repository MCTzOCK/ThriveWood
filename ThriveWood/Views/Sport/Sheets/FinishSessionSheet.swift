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
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

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
                Section("Notizen") {
                    TextField("Gedanken zum Workout…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Workout beenden")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
