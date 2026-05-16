//
//  ThriveWoodBackup.swift
//  ThriveWood
//
//  Created by Ben Siebert on 30.04.26.
//


import Foundation

struct ThriveWoodBackup: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let profile: ProfileDTO?
    let habits: [HabitDTO]
    let completions: [CompletionDTO]
    let forest: ForestDTO?
    let trees: [TreeDTO]
    let exercises: [ExerciseDTO]
    let workouts: [WorkoutDTO]
    let workoutExercises: [WorkoutExerciseDTO]
    let sessions: [SessionDTO]
    let sets: [SetEntryDTO]
    let supplements: [SupplementDTO]
    let supplementEntries: [SupplementEntryDTO]

    static let currentVersion = 2

    // MARK: - Profile

    struct ProfileDTO: Codable {
        let displayName: String
        let preferredWeightUnit: String
        let weekStartsOn: Int
        let dailyPointGoal: Int
        let appearance: String
        let accentTheme: String
        let quietHoursEnabled: Bool
        let quietHoursStart: Date
        let quietHoursEnd: Date
        let defaultRestSeconds: Int
        let enableNotifications: Bool
        let enableHapticFeedback: Bool
        let onboardingCompletedAt: Date?
    }

    // MARK: - Habits

    struct HabitDTO: Codable {
        let id: UUID
        let title: String
        let details: String
        let iconSystemName: String
        let color: String
        let points: Int
        let frequency: String
        let activeWeekdays: [Int]
        let reminderTime: Date?
        let sortOrder: Int
        let createdAt: Date
        let archivedAt: Date?
        let trackingMode: String
        let targetValue: Double
        let incrementValue: Double
        let unitLabel: String
    }

    struct CompletionDTO: Codable {
        let id: UUID
        let habitID: UUID
        let day: Date
        let completedAt: Date
        let pointsAwarded: Int
        let currentValue: Double
        let note: String?
    }

    // MARK: - Forest

    struct ForestDTO: Codable {
        let id: UUID
        let name: String
        let spentPoints: Int
        let createdAt: Date
    }

    struct TreeDTO: Codable {
        let id: UUID
        let forestID: UUID
        let species: String
        let gridX: Int
        let gridY: Int
        let growthPoints: Int
        let plantedAt: Date
        let nickname: String?
    }

    // MARK: - Exercises

    struct ExerciseDTO: Codable {
        let id: UUID
        let name: String
        let details: String
        let category: String
        let trackingType: String
        let primaryMuscleGroups: [String]
        let secondaryMuscleGroups: [String]
        let iconSystemName: String
        let isBuiltIn: Bool
        let createdAt: Date
    }

    // MARK: - Workouts

    struct WorkoutDTO: Codable {
        let id: UUID
        let name: String
        let details: String
        let color: String
        let estimatedDurationMinutes: Int
        let sortOrder: Int
        let createdAt: Date
        let archivedAt: Date?
    }

    struct WorkoutExerciseDTO: Codable {
        let id: UUID
        let workoutID: UUID
        let exerciseID: UUID
        let order: Int
        let targetSets: Int
        let targetReps: Int?
        let targetWeight: Double?
        let targetDurationSeconds: Int?
        let targetDistanceMeters: Double?
        let restSeconds: Int
        let notes: String
    }

    // MARK: - Sessions

    struct SessionDTO: Codable {
        let id: UUID
        let workoutID: UUID?
        let startedAt: Date
        let endedAt: Date?
        let perceivedExertion: Int?
        let notes: String
        let weightUnit: String
    }

    struct SetEntryDTO: Codable {
        let id: UUID
        let sessionID: UUID
        let exerciseID: UUID
        let order: Int
        let reps: Int?
        let weight: Double?
        let durationSeconds: Int?
        let distanceMeters: Double?
        let isWarmup: Bool
        let isCompleted: Bool
        let completedAt: Date?
    }
    
    struct SupplementDTO: Codable {
        let id: UUID
        let name: String
        let dosage: String
        let details: String
        let iconSystemName: String
        let colorRaw: String
        let frequencyRaw: String
        let activeWeekdays: [Int]
        let timesPerDay: Int
        let reminderTimes: [Date]
        
        let sortOrder: Int
        let createdAt: Date
        let archivedAt: Date?
    }
    
    struct SupplementEntryDTO: Codable {
        let id: UUID
        let supplementID: UUID
        let day: Date
        let doseNumber: Int
        let takenAt: Date
        let skipped: Bool
    }
}
