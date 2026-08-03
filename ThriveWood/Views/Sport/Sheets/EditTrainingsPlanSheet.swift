//
//  EditTrainingsPlanSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//
import SwiftUI


struct EditTrainingsPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    let plan: TrainingsPlan
    
    @State private var name = ""
    @State private var details = ""
    @State private var selectedColor = ""
    
    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#FFEB3B", "#795548"
    ]
    
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Allgemein"))

                        BentoTextField(
                            label: Text("Name"),
                            text: $name,
                            prompt: Text("Name")
                        )

                        BentoTextArea(
                            label: Text("Beschreibung"),
                            text: $details,
                            prompt: Text("Beschreibung"),
                            minimumHeight: 90
                        )
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Farbe"))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                        Haptics.selection()
                                    }
                            }
                        }
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Toggle("Als aktiven Plan setzen", isOn: Binding(
                            get: { plan.isActive },
                            set: { if $0 { setActive() } }
                        ))
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
                save()
            }
            .disabled(name.isEmpty)
        }
        .onAppear {
            name = plan.name
            details = plan.details
            selectedColor = plan.color
        }
    }
    
    private func save() {
        do {
            try env.trainingsPlanService.updatePlan(
                plan,
                name: name,
                details: details,
                color: selectedColor
            )
            Haptics.success()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
    
    private func setActive() {
        do {
            try env.trainingsPlanService.setActivePlan(plan)
            Haptics.success()
        } catch {
            print("Set active error: \(error)")
        }
    }
}
