//
//  Protocols.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

protocol HabitRepository {
    func fetchAll(includeArchived: Bool) throws -> [Habit]
    func fetch(id: UUID) throws -> Habit?
    func create(_ habit: Habit) throws
    func update(_ habit: Habit) throws
    func archive(_ habit: Habit) throws
    func delete(_ habit: Habit) throws
    func reorder(_ habits: [Habit]) throws
}

protocol HabitCompletionRepository {
    func completion(for habit: Habit, on day: Date) throws -> HabitCompletion?
    func completions(for habit: Habit, in range: ClosedRange<Date>) throws -> [HabitCompletion]
    func completions(in range: ClosedRange<Date>) throws -> [HabitCompletion]
    func allCompletions() throws -> [HabitCompletion]
    func add(_ completion: HabitCompletion) throws
    func delete(_ completion: HabitCompletion) throws
}

protocol ForestRepository {
    func currentForest() throws -> Forest
    func update(_ forest: Forest) throws
}

protocol TreeRepository {
    func fetchAll(in forest: Forest) throws -> [TreeEntity]
    func tree(at x: Int, y: Int, in forest: Forest) throws -> TreeEntity?
    func add(_ tree: TreeEntity) throws
    func update(_ tree: TreeEntity) throws
    func delete(_ tree: TreeEntity) throws
}

protocol ExerciseRepository {
    func fetchAll() throws -> [Exercise]
    func fetch(id: UUID) throws -> Exercise?
    func search(_ query: String) throws -> [Exercise]
    func create(_ exercise: Exercise) throws
    func update(_ exercise: Exercise) throws
    func delete(_ exercise: Exercise) throws
    func seedBuiltInsIfNeeded() throws
}

protocol WorkoutRepository {
    func fetchAll(includeArchived: Bool) throws -> [Workout]
    func fetch(id: UUID) throws -> Workout?
    func create(_ workout: Workout) throws
    func update(_ workout: Workout) throws
    func archive(_ workout: Workout) throws
    func delete(_ workout: Workout) throws
}

protocol WorkoutSessionRepository {
    func fetchAll() throws -> [WorkoutSession]
    func fetch(id: UUID) throws -> WorkoutSession?
    func activeSession() throws -> WorkoutSession?
    func sessions(in range: ClosedRange<Date>) throws -> [WorkoutSession]
    func create(_ session: WorkoutSession) throws
    func update(_ session: WorkoutSession) throws
    func delete(_ session: WorkoutSession) throws
}

protocol UserProfileRepository {
    func currentProfile() throws -> UserProfile
    func update(_ profile: UserProfile) throws
}

protocol AchievementRepository {
    func fetchAll() throws -> [AchievementRecord]
    func fetch(definition: AchievementDefinition) throws -> AchievementRecord?
    func add(_ record: AchievementRecord) throws
    func delete(_ record: AchievementRecord) throws
}

protocol GymRepository {
    func fetchAll(includeArchived: Bool) throws -> [Gym]
    func fetch(id: UUID) throws -> Gym?
    func create(_ gym: Gym) throws
    func update(_ gym: Gym) throws
    func archive(_ gym: Gym) throws
    func delete(_ gym: Gym) throws
}

protocol HabitGroupRepository {
    func fetchAll() throws -> [HabitGroup]
    func fetch(id: UUID) throws -> HabitGroup?
    func create(_ group: HabitGroup) throws
    func update(_ group: HabitGroup) throws
    func delete(_ group: HabitGroup) throws
    func reorder(_ groups: [HabitGroup]) throws
    func addHabit(_ habitID: UUID, to groupID: UUID) throws
    func removeHabit(_ habitID: UUID, from groupID: UUID) throws
    func removeHabitFromAllGroups(_ habitID: UUID) throws
    func groupForHabit(_ habitID: UUID) throws -> HabitGroup?
}

protocol HabitRoutineRepository {
    func fetchAll() throws -> [HabitRoutine]
    func fetch(id: UUID) throws -> HabitRoutine?
    func create(_ routine: HabitRoutine) throws
    func update(_ routine: HabitRoutine) throws
    func delete(_ routine: HabitRoutine) throws
    func reorder(_ routines: [HabitRoutine]) throws
    /// Entfernt die Habit-ID aus allen Routinen (Auto-Cleanup beim Archivieren/Löschen).
    func removeHabitFromAllRoutines(_ habitID: UUID) throws
}

protocol CompanionRepository {
    /// Liefert das Companion des Users (erstellt ggf. ein Default-Wesen).
    func currentCompanion() throws -> Companion
    func update(_ companion: Companion) throws
    /// Erstellt/ersetzt das Companion bei der Wahl im Onboarding.
    func choose(species: CompanionSpecies, name: String) throws -> Companion
}
