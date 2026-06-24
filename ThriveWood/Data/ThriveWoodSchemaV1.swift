//
//  ThriveWoodSchemaV1.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

enum ThriveWoodSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitCompletion.self,
            TreeEntity.self,
            Forest.self,
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            SetEntry.self,
            UserProfile.self,
            Gym.self,
            GymExercise.self,
            GymEquipment.self,
            EquipmentExercise.self,
            FloorPlan.self,
            FloorZone.self,
            WallSegment.self
        ]
    }
}

enum ThriveWoodSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        ThriveWoodSchemaV1.models + [HabitGroup.self]
    }
}

enum ThriveWoodMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ThriveWoodSchemaV1.self, ThriveWoodSchemaV2.self]
    }
    static var stages: [MigrationStage] { [] }
}