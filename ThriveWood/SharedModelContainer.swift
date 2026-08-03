//
//  SharedModelContainer.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import SwiftData
import Foundation

enum SharedModelContainer {
    static let appGroupID = "group.com.bensiebert.thrivewood"

    static let shared: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            HabitGroup.self,
            HabitRoutine.self,
            Forest.self,
            TreeEntity.self,
            UserProfile.self,
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            SetEntry.self,
            Food.self,
            FoodEntry.self,
            Supplement.self,
            SupplementEntry.self,
            MealTemplate.self,
            MealTemplateItem.self,
            TrainingsPlan.self,
            TrainingsPlanDay.self,
            AchievementRecord.self,
            BodyProgressEntry.self,
            Gym.self,
            GymExercise.self,
            GymEquipment.self,
            EquipmentExercise.self,
            FloorPlan.self,
            FloorZone.self,
            WallSegment.self,
            WellnessEntry.self,
            Companion.self
        ])

        let modelConfiguration = ModelConfiguration(
            "ThriveWood",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
