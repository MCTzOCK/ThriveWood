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
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Beschreibung", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
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
                } header: {
                    Text("Farbe")
                }
                
                Section {
                    Toggle("Als aktiven Plan setzen", isOn: Binding(
                        get: { plan.isActive },
                        set: { if $0 { setActive() } }
                    ))
                }
            }
            .navigationTitle("Plan bearbeiten")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = plan.name
                details = plan.details
                selectedColor = plan.color
            }
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
