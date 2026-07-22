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

    private static let schema = Schema([
        Habit.self,
        HabitCompletion.self,
        HabitGroup.self,
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
        WellnessEntry.self,
        RotationTrainingsPlan.self,
        RotationPlanEntry.self
    ])

    static let shared: ModelContainer = {
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
                migrationPlan: ThriveWoodMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            print("ModelContainer migration failed, attempting fresh store: \(error)")
            let storeURL = modelConfiguration.url
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("store-wal")
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("store-shm")
            for url in [storeURL, walURL, shmURL] {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer even after deleting store: \(error)")
            }
        }
    }()
}
