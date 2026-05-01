//
//  DailyHabitsEntry.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import WidgetKit
import Foundation

struct DailyHabitsEntry: TimelineEntry {
    let date: Date
    let habits: [(habit: Habit, completed: Bool, progress: Double, streak: Int)]
    let pointsEarned: Int
    let pointsGoal: Int
}

struct HabitStreakEntry: TimelineEntry {
    let date: Date
    let habitTitle: String
    let habitIcon: String
    let habitColor: String
    let streak: Int
    let completedToday: Bool
    let progress: Double
}

struct ForestEntry: TimelineEntry {
    let date: Date
    let treeCount: Int
    let coverage: Double
    let species: Int
    let availablePoints: Int
    let trees: [(species: String, gridX: Int, gridY: Int, stage: Int)]
}

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let sessions: [(name: String, date: Date, duration: Int, volume: Double)]
}
