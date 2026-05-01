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
        Forest.self,
        TreeEntity.self,
        UserProfile.self,
        Exercise.self,
        Workout.self,
        WorkoutExercise.self,
        WorkoutSession.self,
        SetEntry.self
    ])

    static let shared: ModelContainer = {
        let schema = Schema(ThriveWoodSchemaV1.models)
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
            fatalError("Could not create ModelContainer: \(error)")
        }

    }()
}
