//
//  TrainingsPlanDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//


import SwiftUI

struct TrainingsPlanDetailView: View {
    @Environment(AppEnvironment.self) private var env

    let plan: TrainingsPlan
    
    @State private var showEditSheet = false
    @State private var selectedDay: TrainingsPlanDay?
    
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                headerCard
                daysCard
                if plan.isRotationPlan {
                    rotationCard
                }
                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Bearbeiten"),
                systemImage: "pencil",
                variant: .secondary,
                expands: true
            ) {
                showEditSheet = true
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
            if let day = selectedDay {
                if plan.isRotationPlan {
                    EditRotationSlotSheet(day: day, plan: plan)
                } else {
                    EditDaySheet(day: day, plan: plan)
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        BentoCard(style: .elevated, padding: .lg, radius: .large) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: plan.color) ?? .blue)
                            .frame(width: 50, height: 50)
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(Theme.Typography.title3.weight(.bold))
                        if !plan.details.isEmpty {
                            Text(plan.details)
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "days",
                        title: Text("Tage/Woche"),
                        value: Text(verbatim: "\(plan.trainingDaysPerWeek)")
                    ),
                    BentoStatValue(
                        id: "ex",
                        title: Text("Übungen"),
                        value: Text(verbatim: "\(plan.totalExercises)")
                    ),
                    BentoStatValue(
                        id: "status",
                        title: Text("Status"),
                        value: Text(plan.isActive ? "Aktiv" : "Inaktiv")
                    )
                ])
            }
        }
    }

    // MARK: - Days Card

    @ViewBuilder
    private var daysCard: some View {
        BentoSection(
            title: Text(plan.isRotationPlan ? "Rotations-Slots" : "Wochenplan"),
            subtitle: Text(plan.isRotationPlan ? "Workouts rotieren fortlaufend" : "Tage pro Woche")
        ) {
            VStack(spacing: Theme.Spacing.s) {
                if plan.isRotationPlan {
                    ForEach(plan.rotationSequence) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            RotationSlotRow(day: day, plan: plan) {
                                selectedDay = day
                            }
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                    BentoButton(
                        Text("Slot hinzufügen"),
                        systemImage: "plus.circle",
                        variant: .tonal(.accent),
                        expands: true
                    ) {
                        addRotationSlot()
                    }
                } else {
                    ForEach(plan.sortedDays) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            WeekdayRow(day: day) {
                                selectedDay = day
                            }
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
            }
        }
    }

    // MARK: - Rotation Card

    private var rotationCard: some View {
        BentoSection(title: Text("Rotation"), subtitle: Text("Aktuelle Runde steuern")) {
            BentoCard(style: .outlined, padding: .lg, radius: .large) {
                VStack(spacing: Theme.Spacing.m) {
                    HStack(spacing: Theme.Spacing.l) {
                        VStack(alignment: .leading, spacing: 2) {
                            BentoText(verbatim: "Aktueller Slot", style: .caption, color: .secondary)
                            Text(plan.nextRotationLabel)
                                .font(Theme.Typography.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            BentoText(verbatim: "Runde", style: .caption, color: .secondary)
                            Text("\(plan.completedRotations + 1)")
                                .font(Theme.Typography.headline)
                        }
                    }

                    HStack(spacing: Theme.Spacing.s) {
                        BentoButton(
                            Text("Weiter"),
                            systemImage: "arrow.forward.circle.fill",
                            variant: .primary,
                            expands: true
                        ) {
                            advance()
                        }
                        BentoButton(
                            Text("Reset"),
                            systemImage: "arrow.uturn.left",
                            variant: .secondary,
                            expands: true
                        ) {
                            resetRotation()
                        }
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

