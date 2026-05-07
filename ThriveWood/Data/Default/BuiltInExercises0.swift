//
//  BuiltInExercises.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation


enum BuiltInExercises0 {
    static var all: [Exercise] {
        chest + back + shoulders + arms + legs + core + cardio + mobility
    }

    // MARK: - Brust  (alle .repsWeight, außer Bodyweight)
    private static var chest: [Exercise] {
        [
            Exercise(name: "Bankdrücken (Langhantel)", details: "Klassisches Brustdrücken auf der Flachbank.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.triceps, .shoulders],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Schrägbankdrücken (Langhantel)", details: "Bankdrücken auf der Schrägbank.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.shoulders, .triceps],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Kurzhantel-Bankdrücken", details: "Bankdrücken mit Kurzhanteln.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.triceps, .shoulders],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Schrägbankdrücken (Kurzhantel)", details: "Schrägbank mit Kurzhanteln.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.shoulders, .triceps],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Fliegende (Kurzhantel)", details: "Brust-Isolation mit weitem ROM.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.shoulders],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Cable Crossover", details: "Brust-Isolation am Kabelzug.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.shoulders],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Liegestütze", details: "Klassische Liegestütze.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.chest], secondaryMuscleGroups: [.triceps, .shoulders, .core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Dips", details: "Barren-Dips für Brust und Trizeps.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.chest, .triceps], secondaryMuscleGroups: [.shoulders],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true)
        ]
    }

    // MARK: - Rücken
    private static var back: [Exercise] {
        [
            Exercise(name: "Kreuzheben", details: "Königsübung der hinteren Kette.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back, .hamstrings],
                     secondaryMuscleGroups: [.glutes, .forearms, .core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Rumänisches Kreuzheben", details: "RDL mit gestreckten Beinen.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.hamstrings, .back], secondaryMuscleGroups: [.glutes],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Klimmzüge", details: "Obergriff-Klimmzüge.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps, .forearms],
                     iconSystemName: "figure.pullup", isBuiltIn: true),
            Exercise(name: "Klimmzüge (Untergriff)", details: "Chin-Ups – mehr Bizeps.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.back, .biceps], secondaryMuscleGroups: [.forearms],
                     iconSystemName: "figure.pullup", isBuiltIn: true),
            Exercise(name: "Latziehen", details: "Lat-Pulldown am Kabelzug.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Langhantelrudern", details: "Vorgebeugtes Rudern.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps, .forearms, .core],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Kurzhantelrudern (einarmig)", details: "Einarmiges Rudern.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps, .forearms],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Kabelrudern (sitzend)", details: "Rudern am Kabel mit V-Griff.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "T-Bar Rudern", details: "Schweres T-Bar Rudern.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.biceps, .forearms],
                     iconSystemName: "dumbbell.fill", isBuiltIn: true),
            Exercise(name: "Hyperextensions", details: "Rückenstrecker am Römischen Stuhl.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.back], secondaryMuscleGroups: [.glutes, .hamstrings],
                     iconSystemName: "figure.core.training", isBuiltIn: true)
        ]
    }

    // MARK: - Schultern (alle .repsWeight)
    private static var shoulders: [Exercise] {
        [
            ("Schulterdrücken (Langhantel)", "Langhantel-Schulterdrücken."),
            ("Schulterdrücken (Kurzhantel)", "Schulterdrücken mit Kurzhanteln."),
            ("Arnold Press", "Drücken mit Rotation."),
            ("Seitheben", "Kurzhantel-Seitheben."),
            ("Frontheben", "Kurzhantel-Frontheben."),
            ("Reverse Flys", "Vorgebeugt Seitheben."),
            ("Face Pulls", "Kabelzug zum Gesicht."),
            ("Aufrechtes Rudern", "Upright Rows."),
            ("Shrugs", "Schulterheben für Trapezius.")
        ].map { name, details in
            Exercise(name: name, details: details, category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.shoulders], iconSystemName: "dumbbell.fill", isBuiltIn: true)
        }
    }

    // MARK: - Arme
    private static var arms: [Exercise] {
        let curls: [(String, String, [MuscleGroup])] = [
            ("Bizeps-Curls (Langhantel)",  "Curls mit SZ-/Langhantel.", [.biceps]),
            ("Bizeps-Curls (Kurzhantel)",  "Wechselseitige Curls.",     [.biceps]),
            ("Hammer-Curls",               "Neutralgriff-Curls.",       [.biceps, .forearms]),
            ("Konzentrations-Curls",       "Sitzende Isolation.",       [.biceps]),
            ("Preacher-Curls",             "Scott-Curls.",              [.biceps]),
            ("Trizeps-Drücken (Kabel)",    "Pushdown am Kabel.",        [.triceps]),
            ("Französisches Drücken",      "Liegendes Trizepsstrecken.",[.triceps]),
            ("Trizeps-Kickbacks",          "Vorgebeugte Kickbacks.",    [.triceps]),
            ("Enges Bankdrücken",          "Close-Grip Bench.",         [.triceps]),
            ("Unterarm-Curls",             "Wrist-Curls.",              [.forearms])
        ]
        return curls.map { n, d, mg in
            Exercise(name: n, details: d, category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: mg, iconSystemName: "dumbbell.fill", isBuiltIn: true)
        }
    }

    // MARK: - Beine
    private static var legs: [Exercise] {
        [
            Exercise(name: "Kniebeugen (Langhantel)", details: "Back Squats.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.hamstrings, .core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Front-Kniebeugen", details: "Front Squats.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads], secondaryMuscleGroups: [.glutes, .core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Beinpresse", details: "Beinpresse an der Maschine.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.hamstrings],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Ausfallschritte", details: "Lunges mit Kurzhanteln.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.hamstrings],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Bulgarische Split Squats", details: "Einbeinige Kniebeuge.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.hamstrings],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Beinstrecker", details: "Quad-Isolation.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Beinbeuger", details: "Hamstring-Curls.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.hamstrings], secondaryMuscleGroups: [.glutes],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Hip Thrusts", details: "Hüftheben mit Langhantel.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.glutes], secondaryMuscleGroups: [.hamstrings],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Glute Bridge", details: "Beckenheben am Boden.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.glutes], secondaryMuscleGroups: [.hamstrings, .core],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Wadenheben (stehend)", details: "Stehendes Calf Raise.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.calves],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true),
            Exercise(name: "Wadenheben (sitzend)", details: "Sitzendes Calf Raise.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.calves],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Goblet Squats", details: "Kniebeuge mit KH/KB vorne.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.core],
                     iconSystemName: "figure.strengthtraining.traditional", isBuiltIn: true)
        ]
    }

    // MARK: - Core
    private static var core: [Exercise] {
        [
            Exercise(name: "Plank", details: "Unterarmstütz.",
                     category: .strength, trackingType: .duration,
                     primaryMuscleGroups: [.core], secondaryMuscleGroups: [.shoulders],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Seitstütz", details: "Side Plank.",
                     category: .strength, trackingType: .duration,
                     primaryMuscleGroups: [.core], secondaryMuscleGroups: [.shoulders],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Crunches", details: "Bauchpressen am Boden.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.core],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Beinheben (hängend)", details: "Hanging Leg Raises.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.core], secondaryMuscleGroups: [.forearms],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Russian Twists", details: "Sitzende Rotation.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.core],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Mountain Climbers", details: "Dynamisch im Liegestütz.",
                     category: .strength, trackingType: .duration,
                     primaryMuscleGroups: [.core], secondaryMuscleGroups: [.cardio, .shoulders],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Ab Wheel Rollout", details: "Bauchroller.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.core], secondaryMuscleGroups: [.shoulders, .back],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Cable Crunches", details: "Crunches am Kabel.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.core],
                     iconSystemName: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Dead Bug", details: "Stabilisation am Boden.",
                     category: .strength, trackingType: .reps,
                     primaryMuscleGroups: [.core],
                     iconSystemName: "figure.core.training", isBuiltIn: true)
        ]
    }

    // MARK: - Cardio & Plyo
    private static var cardio: [Exercise] {
        [
            Exercise(name: "Laufen", details: "Outdoor oder Laufband.",
                     category: .cardio, trackingType: .distanceDuration,
                     primaryMuscleGroups: [.cardio], secondaryMuscleGroups: [.quads, .calves],
                     iconSystemName: "figure.run", isBuiltIn: true),
            Exercise(name: "Radfahren", details: "Outdoor / Spinning.",
                     category: .cardio, trackingType: .distanceDuration,
                     primaryMuscleGroups: [.cardio, .quads], secondaryMuscleGroups: [.calves, .glutes],
                     iconSystemName: "figure.outdoor.cycle", isBuiltIn: true),
            Exercise(name: "Rudergerät", details: "Indoor-Rudern.",
                     category: .cardio, trackingType: .distanceDuration,
                     primaryMuscleGroups: [.cardio, .back], secondaryMuscleGroups: [.quads, .biceps],
                     iconSystemName: "figure.rower", isBuiltIn: true),
            Exercise(name: "Seilspringen", details: "Cardio + Koordination.",
                     category: .plyometrics, trackingType: .duration,
                     primaryMuscleGroups: [.cardio, .calves],
                     iconSystemName: "figure.jumprope", isBuiltIn: true),
            Exercise(name: "Burpees", details: "Ganzkörper-HIIT.",
                     category: .plyometrics, trackingType: .reps,
                     primaryMuscleGroups: [.cardio, .fullBody],
                     secondaryMuscleGroups: [.chest, .quads, .core],
                     iconSystemName: "figure.mixed.cardio", isBuiltIn: true),
            Exercise(name: "Box Jumps", details: "Sprung auf Box.",
                     category: .plyometrics, trackingType: .reps,
                     primaryMuscleGroups: [.quads, .glutes], secondaryMuscleGroups: [.calves],
                     iconSystemName: "figure.jumprope", isBuiltIn: true),
            Exercise(name: "Kettlebell Swings", details: "Hüftdominante Schwünge.",
                     category: .strength, trackingType: .repsWeight,
                     primaryMuscleGroups: [.glutes, .hamstrings],
                     secondaryMuscleGroups: [.back, .core, .cardio],
                     iconSystemName: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Schwimmen", details: "Gelenkschonendes Cardio.",
                     category: .cardio, trackingType: .distanceDuration,
                     primaryMuscleGroups: [.cardio, .fullBody],
                     secondaryMuscleGroups: [.back, .shoulders],
                     iconSystemName: "figure.pool.swim", isBuiltIn: true),
            Exercise(name: "Stepper", details: "Stair Master.",
                     category: .cardio, trackingType: .duration,
                     primaryMuscleGroups: [.cardio, .quads],
                     secondaryMuscleGroups: [.glutes, .calves],
                     iconSystemName: "figure.stairs", isBuiltIn: true)
        ]
    }

    // MARK: - Mobility / Stretching (alle .duration)
    private static var mobility: [Exercise] {
        [
            ("Foam Rolling", "Selbstmassage.", ExerciseCategory.mobility, [MuscleGroup.fullBody], "figure.cooldown"),
            ("Hüftöffner", "Hip-Flow.", .mobility, [.glutes, .hamstrings], "figure.flexibility"),
            ("Cat-Cow", "Wirbelsäulen-Mobilisation.", .mobility, [.back, .core], "figure.flexibility"),
            ("Dehnen (Ganzkörper)", "Statisches Dehnen.", .stretching, [.fullBody], "figure.cooldown"),
            ("Yoga Flow", "Dynamische Yoga-Sequenz.", .mobility, [.fullBody, .core], "figure.yoga")
        ].map { n, d, c, mg, icon in
            Exercise(name: n, details: d, category: c, trackingType: .duration,
                     primaryMuscleGroups: mg, iconSystemName: icon, isBuiltIn: true)
        }
    }
}
