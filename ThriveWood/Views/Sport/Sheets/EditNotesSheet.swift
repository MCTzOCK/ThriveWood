//
//  EditNotesSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct EditNotesSheet: View {
    @Binding var notes: String
    @Binding var rpe: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Anstrengung (RPE)") {
                    VStack {
                        HStack {
                            Text("RPE").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(rpe)/10").font(.headline.monospacedDigit())
                        }
                        Slider(value: Binding(
                            get: { Double(rpe) },
                            set: { rpe = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                }
                Section("Notizen") {
                    TextField("Wie war's?", text: $notes, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("Bearbeiten")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(); dismiss()
                    }.fontWeight(.semibold)
                }
            }
        }
    }
}
