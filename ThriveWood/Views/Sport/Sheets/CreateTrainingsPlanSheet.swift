//
//  CreateTrainingsPlanSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//


import SwiftUI

// MARK: - Create Plan Sheet

struct CreateTrainingsPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    var onCreate: () -> Void
    
    @State private var name = ""
    @State private var details = ""
    @State private var selectedColor = "#4CAF50"
    
    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#FFEB3B", "#795548"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Beschreibung (optional)", text: $details, axis: .vertical)
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
            }
            .navigationTitle("Neuer Trainingsplan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") { create() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func create() {
        do {
            _ = try env.trainingsPlanService.createPlan(
                name: name,
                details: details,
                color: selectedColor
            )
            Haptics.success()
            dismiss()
            onCreate()
        } catch {
            print("Create error: \(error)")
        }
    }
}
