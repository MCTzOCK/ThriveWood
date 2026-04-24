//
//  BuiltInExercises.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation

enum BuiltInExercises {
    static var all: [Exercise] {
        [
            Exercise(name: "Bench Press", category: .strength,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.triceps, .shoulders],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Squat", category: .strength,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.hamstrings, .core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Deadlift", category: .strength,
                     primaryMuscleGroups: [.back, .hamstrings], secondaryMuscleGroups: [.glutes, .forearms],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Pull-Up", category: .strength,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps],
                     iconSystemName: "figure.pullup", isBuiltIn: true),
            Exercise(name: "Overhead Press", category: .strength,
                     primaryMuscleGroups: [.shoulders], secondaryMuscleGroups: [.triceps, .core],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Barbell Row", category: .strength,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps, .forearms],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Plank", category: .strength,
                     primaryMuscleGroups: [.core], iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Running", category: .cardio,
                     primaryMuscleGroups: [.cardio], iconSystemName: "figure.run", isBuiltIn: true),
            Exercise(name: "Cycling", category: .cardio,
                     primaryMuscleGroups: [.cardio, .quads], iconSystemName: "figure.outdoor.cycle", isBuiltIn: true),
            Exercise(name: "Jump Rope", category: .plyometrics,
                     primaryMuscleGroups: [.cardio, .calves], iconSystemName: "figure.jumprope", isBuiltIn: true)
        ]
    }
}
