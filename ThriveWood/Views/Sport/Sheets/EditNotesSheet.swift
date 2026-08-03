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
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Anstrengung (RPE)"))

                        BentoSlider(
                            Text("RPE"),
                            value: Binding(
                                get: { Double(rpe) },
                                set: { rpe = Int($0) }
                            ),
                            in: 1...10,
                            step: 1,
                            valueLabel: { _ in
                                Text("\(rpe)/10").monospacedDigit()
                            }
                        )
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Notizen"))

                        BentoTextArea(
                            text: $notes,
                            prompt: Text("Wie war's?"),
                            minimumHeight: 90
                        )
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                onSave()
                dismiss()
            }
        }
    }
}
