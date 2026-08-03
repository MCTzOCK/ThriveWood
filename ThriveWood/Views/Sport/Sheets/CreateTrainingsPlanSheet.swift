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
    @State private var planType: TrainingsPlanType = .weekday
    @State private var workoutCount = 3
    
    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#FFEB3B", "#795548"
    ]
    
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .elevated, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Allgemein"))

                        BentoTextField(
                            label: Text("Name"),
                            text: $name,
                            prompt: Text("z. B. Push / Pull / Legs"),
                            leadingSystemImage: "textformat",
                            required: true,
                            maximumLength: 60
                        )

                        BentoTextArea(
                            label: Text("Beschreibung (optional)"),
                            text: $details,
                            prompt: Text("Worum geht es in diesem Plan?"),
                            maximumLength: 280,
                            minimumHeight: 90
                        )
                    }
                }

                BentoCard(style: .elevated, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Plantyp"))

                        BentoSegmentedPicker(options: TrainingsPlanType.allCases, selection: $planType) { type in
                            Text(verbatim: type.label)
                        }

                        if planType == .rotation {
                            BentoStepper(
                                Text("Workouts"),
                                value: $workoutCount,
                                in: 2...6
                            )
                            BentoText(
                                "Die Workouts rotieren fortlaufend (A, B, C, A, B, C …), unabhängig von Wochentagen.",
                                style: .caption,
                                color: .secondary
                            )
                        }
                    }
                }

                BentoCard(style: .elevated, padding: .lg) {
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

                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Plan erstellen"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                create()
            }
            .disabled(name.isEmpty)
        }
    }
    
    private func create() {
        do {
            if planType == .rotation {
                _ = try env.trainingsPlanService.createRotationPlan(
                    name: name,
                    details: details,
                    color: selectedColor,
                    workoutCount: workoutCount
                )
            } else {
                _ = try env.trainingsPlanService.createPlan(
                    name: name,
                    details: details,
                    color: selectedColor
                )
            }
            Haptics.success()
            dismiss()
            onCreate()
        } catch {
            print("Create error: \(error)")
        }
    }
}
