//
//  EditDaySheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//

import SwiftUI

struct EditDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    let day: TrainingsPlanDay
    let plan: TrainingsPlan
    
    @State private var isRestDay = false
    @State private var notes = ""
    // Picker selection should be a Hashable value. Use the Workout's UUID id.
    @State private var selectedWorkoutID: UUID?
    @State private var availableWorkouts: [Workout] = []
    
    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                BentoCard(style: .outlined, padding: .lg) {
                    HStack {
                        Image(systemName: day.weekday.icon)
                            .foregroundStyle(.blue)
                        Text(day.weekday.label)
                            .font(.headline)
                    }
                }

                if !isRestDay {
                    BentoCard(style: .outlined, padding: .lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            BentoSectionHeader(title: Text("Workout auswählen"))
                            // Use the workout id (UUID) as the picker's selection tag because
                            // model objects are not Hashable for use as tags.
                            Picker("Workout", selection: $selectedWorkoutID) {
                                Text("Kein Workout").tag(nil as UUID?)
                                ForEach(availableWorkouts) { workout in
                                    Text(workout.name).tag(workout.id)
                                }
                            }
                        }
                    }
                }

                BentoCard(style: .outlined, padding: .lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        BentoSectionHeader(title: Text("Notizen"))
                        TextField("Notizen (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
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
        }
        .task { await load() }
        .onAppear {
            isRestDay = day.isRestDay
            notes = day.notes
            selectedWorkoutID = day.workout?.id
        }
    }
    
    private func load() async {
        do {
            availableWorkouts = try env.workoutService.allWorkouts()
        } catch {
            print("Load error: \(error)")
        }
    }
    
    private func save() {
        do {
            // Resolve the selected UUID back to a Workout instance (or nil)
            let chosenWorkout = availableWorkouts.first { $0.id == selectedWorkoutID }
            try env.trainingsPlanService.assignWorkout(chosenWorkout, to: day.weekday, in: plan)
            try env.trainingsPlanService.updateDayNotes(notes, for: day.weekday, in: plan)
            
            if isRestDay {
                try env.trainingsPlanService.toggleRestDay(day.weekday, in: plan)
            }
            
            Haptics.success()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}
