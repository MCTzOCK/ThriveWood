//
//  TrainingsPlanDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//


import SwiftUI

struct TrainingsPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    let plan: TrainingsPlan
    
    @State private var showEditSheet = false
    @State private var selectedDay: TrainingsPlanDay?
    
    var body: some View {
        List {
            // Header Info
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color(hex: plan.color) ?? .blue)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.title2.bold())
                            
                            if !plan.details.isEmpty {
                                Text(plan.details)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack(alignment: .center, spacing: 20) {
                        StatBadge(
                            icon: "calendar",
                            value: "\(plan.trainingDaysPerWeek)",
                            label: "Tage/Woche",
                            color: Color(hex: plan.color) ?? .blue
                        )
                        
                        StatBadge(
                            icon: "dumbbell.fill",
                            value: "\(plan.totalExercises)",
                            label: "Übungen",
                            color: .orange
                        )
                        
                        StatBadge(
                            icon: plan.isActive ? "checkmark.seal.fill" : "circle",
                            value: plan.isActive ? "Aktiv" : "Inaktiv",
                            label: "",
                            color: plan.isActive ? .green : .gray
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }
            
            // Plan-Typ abhängige Ansicht
            Section {
                if plan.isRotationPlan {
                    ForEach(plan.rotationSequence) { day in
                        RotationSlotRow(day: day, plan: plan) {
                            selectedDay = day
                        }
                    }
                    Button {
                        addRotationSlot()
                    } label: {
                        Label("Slot hinzufügen", systemImage: "plus.circle")
                    }
                } else {
                    ForEach(plan.sortedDays) { day in
                        WeekdayRow(day: day) {
                            selectedDay = day
                        }
                    }
                }
            } header: {
                Text(plan.isRotationPlan ? "Rotations-Slots" : "Wochenplan")
            }

            // Rotations-Steuerung
            if plan.isRotationPlan {
                Section {
                    HStack(spacing: Theme.Spacing.l) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aktueller Slot")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                            Text(plan.nextRotationLabel)
                                .font(Theme.Typography.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Runde")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                            Text("\(plan.completedRotations + 1)")
                                .font(Theme.Typography.headline)
                        }
                    }

                    HStack(spacing: Theme.Spacing.s) {
                        Button {
                            advance()
                        } label: {
                            Label("Weiter", systemImage: "arrow.forward.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.s)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
                        }
                        .buttonStyle(BounceButtonStyle())

                        Button {
                            resetRotation()
                        } label: {
                            Label("Reset", systemImage: "arrow.uturn.left")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.s)
                                .background(Color(.tertiarySystemFill))
                                .foregroundStyle(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                } header: {
                    Text("Rotation")
                }
            }
        }
        .navigationTitle("Trainingsplan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Bearbeiten")
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Fertig") { dismiss() }
            }
        }
        .bentoSheet(
            isPresented: $showEditSheet,
            title: Text("Plan bearbeiten"),
            detents: [.large]
        ) {
            EditTrainingsPlanSheet(plan: plan)
        }
        .bentoSheet(
            isPresented: Binding(
                get: { selectedDay != nil },
                set: { if !$0 { selectedDay = nil } }
            ),
            title: Text("Tag bearbeiten"),
            detents: [.large]
        ) {
            NavigationStack {
                if let day = selectedDay {
                    if plan.isRotationPlan {
                        EditRotationSlotSheet(day: day, plan: plan)
                    } else {
                        EditDaySheet(day: day, plan: plan)
                    }
                }
            }
        }
    }

    // MARK: - Rotation Actions

    private func addRotationSlot() {
        let label = String(Character(UnicodeScalar(65 + plan.rotationCount)!))
        do {
            try env.trainingsPlanService.addRotationWorkout(nil, label: label, to: plan)
            Haptics.success()
        } catch {
            print("Add slot error: \(error)")
        }
    }

    private func advance() {
        do {
            try env.trainingsPlanService.advanceRotation(plan)
            Haptics.success()
        } catch {
            print("Advance error: \(error)")
        }
    }

    private func resetRotation() {
        do {
            try env.trainingsPlanService.resetRotation(plan)
            Haptics.success()
        } catch {
            print("Reset error: \(error)")
        }
    }
}

