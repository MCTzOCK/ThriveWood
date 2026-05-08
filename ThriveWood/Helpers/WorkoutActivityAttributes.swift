//
//  WorkoutActivityAttributes.swift
//  ThriveWood
//
//  Created by Ben Siebert on 08.05.26.
//


import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    // Statische Daten (ändern sich nicht während der Session)
    let workoutName: String
    let workoutIcon: String  // SF Symbol
    let startedAt: Date

    // Dynamische Daten (werden live aktualisiert)
    struct ContentState: Codable, Hashable {
        let currentExerciseName: String
        let currentExerciseIndex: Int
        let totalExercises: Int
        let completedSets: Int
        let totalSets: Int
        let elapsedSeconds: Int
        let isResting: Bool
        let restSecondsRemaining: Int?
        let lastSetInfo: String?  // z.B. "80kg × 10"
    }
}
