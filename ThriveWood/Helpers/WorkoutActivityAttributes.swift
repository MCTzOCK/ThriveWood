//
//  WorkoutActivityAttributes.swift
//  ThriveWood
//
//  Created by Ben Siebert on 08.05.26.
//


#if os(iOS)
import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    let workoutName: String
    let workoutIcon: String
    let startedAt: Date

    struct ContentState: Codable, Hashable {
        let currentExerciseName: String
        let currentExerciseIndex: Int
        let totalExercises: Int
        let completedSets: Int
        let totalSets: Int
        let elapsedSeconds: Int
        let isResting: Bool
        let restSecondsRemaining: Int?
        let lastSetInfo: String?
    }
}
#endif
