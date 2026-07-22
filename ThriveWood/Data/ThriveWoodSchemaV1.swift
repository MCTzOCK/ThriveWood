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

enum ThriveWoodSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        ThriveWoodSchemaV2.models + [WellnessEntry.self]
    }
}

enum ThriveWoodSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        ThriveWoodSchemaV3.models + [RotationTrainingsPlan.self, RotationPlanEntry.self]
    }
}

enum ThriveWoodMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ThriveWoodSchemaV1.self, ThriveWoodSchemaV2.self, ThriveWoodSchemaV3.self, ThriveWoodSchemaV4.self]
    }
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: ThriveWoodSchemaV1.self, toVersion: ThriveWoodSchemaV2.self),
            .lightweight(fromVersion: ThriveWoodSchemaV2.self, toVersion: ThriveWoodSchemaV3.self),
            .lightweight(fromVersion: ThriveWoodSchemaV3.self, toVersion: ThriveWoodSchemaV4.self)
        ]
    }
}