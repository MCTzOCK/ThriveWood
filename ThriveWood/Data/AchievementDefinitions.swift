//
//  AchievementDefinitions.swift
//  ThriveWood
//

import SwiftUI

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case habit, workout, forest, muscle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .habit: "Gewohnheiten"
        case .workout: "Workouts"
        case .forest: "Wald"
        case .muscle: "Muskeln"
        }
    }

    var icon: String {
        switch self {
        case .habit: "checklist"
        case .workout: "dumbbell.fill"
        case .forest: "leaf.fill"
        case .muscle: "figure.strengthtraining.traditional"
        }
    }

    var color: Color {
        switch self {
        case .habit: .green
        case .workout: .blue
        case .forest: .mint
        case .muscle: .orange
        }
    }
}

enum AchievementDefinition: String, Codable, CaseIterable, Identifiable {
    case firstHabit
    case habitStreak7
    case habitStreak30
    case habitStreak100
    case totalPoints100
    case totalPoints500
    case totalPoints1000

    case firstWorkout
    case workouts10
    case workouts50
    case workouts100

    case firstTree
    case trees5
    case trees15
    case treeAncient
    case treesAncient2

    case muscleBronze
    case muscleGold10
    case musclePlatinum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstHabit: "Erstes Habit"
        case .habitStreak7: "7-Tage-Streak"
        case .habitStreak30: "30-Tage-Streak"
        case .habitStreak100: "100-Tage-Streak"
        case .totalPoints100: "Punkte-Sammler"
        case .totalPoints500: "Punkte-Meister"
        case .totalPoints1000: "Punkte-Legende"
        case .firstWorkout: "Erstes Workout"
        case .workouts10: "Zehn Workouts"
        case .workouts50: "50 Workouts"
        case .workouts100: "100 Workouts"
        case .firstTree: "Erster Baum"
        case .trees5: "Kleines Wäldchen"
        case .trees15: "Wachsender Wald"
        case .treeAncient: "Uralter Baum"
        case .treesAncient2: "Alter Hase"
        case .muscleBronze: "Erste Medaille"
        case .muscleGold10: "Gold-Routine"
        case .musclePlatinum: "Platin-Status"
        }
    }

    var description: String {
        switch self {
        case .firstHabit: "Erstelle dein erstes Habit"
        case .habitStreak7: "Schließe ein Habit 7 Tage in Folge ab"
        case .habitStreak30: "Schließe ein Habit 30 Tage in Folge ab"
        case .habitStreak100: "Erreiche einen 100-Tage-Streak"
        case .totalPoints100: "Verdiene insgesamt 100 Punkte"
        case .totalPoints500: "Verdiene insgesamt 500 Punkte"
        case .totalPoints1000: "Verdiene insgesamt 1.000 Punkte"
        case .firstWorkout: "Schließe dein erstes Workout ab"
        case .workouts10: "Schließe 10 Workouts ab"
        case .workouts50: "Schließe 50 Workouts ab"
        case .workouts100: "Schließe 100 Workouts ab"
        case .firstTree: "Pflanze deinen ersten Baum"
        case .trees5: "Pflanze 5 Bäume"
        case .trees15: "Pflanze 15 Bäume"
        case .treeAncient: "Bringe einen Baum auf Stufe 'Uralt'"
        case .treesAncient2: "Bringe 2 Bäume auf Stufe 'Uralt'"
        case .muscleBronze: "Bringe einen Muskel auf Bronze-Rang"
        case .muscleGold10: "Bringe 10 Muskeln auf Gold-Rang"
        case .musclePlatinum: "Bringe einen Muskel auf Platin-Rang"
        }
    }

    var icon: String {
        switch self {
        case .firstHabit: "leaf.fill"
        case .habitStreak7: "flame.fill"
        case .habitStreak30: "flame.circle.fill"
        case .habitStreak100: "fireplace.fill"
        case .totalPoints100: "star.fill"
        case .totalPoints500: "star.circle.fill"
        case .totalPoints1000: "stars.shield.fill"
        case .firstWorkout: "dumbbell.fill"
        case .workouts10: "figure.run"
        case .workouts50: "figure.run.square.stack.fill"
        case .workouts100: "trophy.fill"
        case .firstTree: "tree.fill"
        case .trees5: "forest.fill"
        case .trees15: "leaf.circle.fill"
        case .treeAncient: "tree.circle.fill"
        case .treesAncient2: "mountain.2.fill"
        case .muscleBronze: "shield.fill"
        case .muscleGold10: "shield.circle.fill"
        case .musclePlatinum: "seal.fill"
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstHabit, .habitStreak7, .habitStreak30, .habitStreak100,
             .totalPoints100, .totalPoints500, .totalPoints1000:
            return .habit
        case .firstWorkout, .workouts10, .workouts50, .workouts100:
            return .workout
        case .firstTree, .trees5, .trees15, .treeAncient, .treesAncient2:
            return .forest
        case .muscleBronze, .muscleGold10, .musclePlatinum:
            return .muscle
        }
    }

    var targetValue: Int {
        switch self {
        case .firstHabit: 1
        case .habitStreak7: 7
        case .habitStreak30: 30
        case .habitStreak100: 100
        case .totalPoints100: 100
        case .totalPoints500: 500
        case .totalPoints1000: 1000
        case .firstWorkout: 1
        case .workouts10: 10
        case .workouts50: 50
        case .workouts100: 100
        case .firstTree: 1
        case .trees5: 5
        case .trees15: 15
        case .treeAncient: 1
        case .treesAncient2: 2
        case .muscleBronze: 1
        case .muscleGold10: 10
        case .musclePlatinum: 1
        }
    }
}