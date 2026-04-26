//
//  Repositories.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftData

// MARK: - Base

@MainActor
class SwiftDataRepository {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func save() throws {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { throw RepositoryError.persistenceFailed(underlying: error) }
    }
}

// MARK: - Habit

@MainActor
final class SwiftDataHabitRepository: SwiftDataRepository, HabitRepository {
    func fetchAll(includeArchived: Bool = false) throws -> [Habit] {
        let predicate: Predicate<Habit> = includeArchived
            ? #Predicate { _ in true }
            : #Predicate { $0.archivedAt == nil }
        let descriptor = FetchDescriptor<Habit>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> Habit? {
        var d = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func create(_ habit: Habit) throws {
        guard !habit.title.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Titel darf nicht leer sein.") }
        context.insert(habit)
        try save()
    }

    func update(_ habit: Habit) throws { try save() }

    func archive(_ habit: Habit) throws {
        habit.archivedAt = .now
        try save()
    }

    func delete(_ habit: Habit) throws {
        context.delete(habit)
        try save()
    }

    func reorder(_ habits: [Habit]) throws {
        for (index, habit) in habits.enumerated() { habit.sortOrder = index }
        try save()
    }
}

// MARK: - HabitCompletion

@MainActor
final class SwiftDataHabitCompletionRepository: SwiftDataRepository, HabitCompletionRepository {
    func completion(for habit: Habit, on day: Date) throws -> HabitCompletion? {
        let start = Calendar.app.startOfDay(day)
        let habitID = habit.id
        var d = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.habit?.id == habitID && $0.day == start }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func completions(for habit: Habit, in range: ClosedRange<Date>) throws -> [HabitCompletion] {
        let start = Calendar.app.startOfDay(range.lowerBound)
        let end   = Calendar.app.startOfDay(range.upperBound)
        let habitID = habit.id
        let d = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate {
                $0.habit?.id == habitID && $0.day >= start && $0.day <= end
            },
            sortBy: [SortDescriptor(\.day)]
        )
        return try context.fetch(d)
    }

    func completions(in range: ClosedRange<Date>) throws -> [HabitCompletion] {
        let start = Calendar.app.startOfDay(range.lowerBound)
        let end   = Calendar.app.startOfDay(range.upperBound)
        let d = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.day >= start && $0.day <= end },
            sortBy: [SortDescriptor(\.day)]
        )
        return try context.fetch(d)
    }

    func allCompletions() throws -> [HabitCompletion] {
        try context.fetch(FetchDescriptor<HabitCompletion>(sortBy: [SortDescriptor(\.day)]))
    }

    func add(_ completion: HabitCompletion) throws {
        context.insert(completion)
        try save()
    }

    func delete(_ completion: HabitCompletion) throws {
        context.delete(completion)
        try save()
    }
}

// MARK: - Forest

@MainActor
final class SwiftDataForestRepository: SwiftDataRepository, ForestRepository {
    func currentForest() throws -> Forest {
        let d = FetchDescriptor<Forest>(sortBy: [SortDescriptor(\.createdAt)])
        if let existing = try context.fetch(d).first { return existing }
        let forest = Forest()
        context.insert(forest)
        try save()
        return forest
    }

    func update(_ forest: Forest) throws { try save() }
}

// MARK: - Tree

@MainActor
final class SwiftDataTreeRepository: SwiftDataRepository, TreeRepository {
    func fetchAll(in forest: Forest) throws -> [TreeEntity] {
        let forestID = forest.id
        let d = FetchDescriptor<TreeEntity>(
            predicate: #Predicate { $0.forest?.id == forestID },
            sortBy: [SortDescriptor(\.plantedAt)]
        )
        return try context.fetch(d)
    }

    func tree(at x: Int, y: Int, in forest: Forest) throws -> TreeEntity? {
        let forestID = forest.id
        var d = FetchDescriptor<TreeEntity>(
            predicate: #Predicate {
                $0.forest?.id == forestID && $0.gridX == x && $0.gridY == y
            }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func add(_ tree: TreeEntity) throws { context.insert(tree); try save() }
    func update(_ tree: TreeEntity) throws { try save() }
    func delete(_ tree: TreeEntity) throws { context.delete(tree); try save() }
}

// MARK: - Exercise

@MainActor
final class SwiftDataExerciseRepository: SwiftDataRepository, ExerciseRepository {
    func fetchAll() throws -> [Exercise] {
        try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))
    }

    func fetch(id: UUID) throws -> Exercise? {
        var d = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func search(_ query: String) throws -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return try fetchAll() }
        let d = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.name.localizedStandardContains(q) },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(d)
    }

    func create(_ exercise: Exercise) throws {
        guard !exercise.name.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Name darf nicht leer sein.") }
        context.insert(exercise)
        try save()
    }

    func update(_ exercise: Exercise) throws { try save() }

    func delete(_ exercise: Exercise) throws {
        guard !exercise.isBuiltIn
        else { throw RepositoryError.invalidInput("Standard-Übungen können nicht gelöscht werden.") }
        context.delete(exercise)
        try save()
    }

    func seedBuiltInsIfNeeded() throws {
        let existing = try context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.isBuiltIn == true })
        )
        let existingNames = Set(existing.map(\.name))

        var added = 0
        for builtin in BuiltInExercises.all where !existingNames.contains(builtin.name) {
            context.insert(builtin)
            added += 1
        }
        if added > 0 { try save() }
    }
}

// MARK: - Workout

@MainActor
final class SwiftDataWorkoutRepository: SwiftDataRepository, WorkoutRepository {
    func fetchAll(includeArchived: Bool = false) throws -> [Workout] {
        let predicate: Predicate<Workout> = includeArchived
            ? #Predicate { _ in true }
            : #Predicate { $0.archivedAt == nil }
        let d = FetchDescriptor<Workout>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return try context.fetch(d)
    }

    func fetch(id: UUID) throws -> Workout? {
        var d = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func create(_ workout: Workout) throws {
        guard !workout.name.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Name darf nicht leer sein.") }
        context.insert(workout)
        try save()
    }

    func update(_ workout: Workout) throws { try save() }

    func archive(_ workout: Workout) throws {
        workout.archivedAt = .now
        try save()
    }

    func delete(_ workout: Workout) throws {
        context.delete(workout)
        try save()
    }
}

// MARK: - WorkoutSession

@MainActor
final class SwiftDataWorkoutSessionRepository: SwiftDataRepository, WorkoutSessionRepository {
    func fetchAll() throws -> [WorkoutSession] {
        try context.fetch(
            FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        )
    }

    func fetch(id: UUID) throws -> WorkoutSession? {
        var d = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func activeSession() throws -> WorkoutSession? {
        var d = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func sessions(in range: ClosedRange<Date>) throws -> [WorkoutSession] {
        let lo = range.lowerBound, hi = range.upperBound
        let d = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.startedAt >= lo && $0.startedAt <= hi },
            sortBy: [SortDescriptor(\.startedAt)]
        )
        return try context.fetch(d)
    }

    func create(_ session: WorkoutSession) throws { context.insert(session); try save() }
    func update(_ session: WorkoutSession) throws { try save() }
    func delete(_ session: WorkoutSession) throws { context.delete(session); try save() }
}

// MARK: - UserProfile

@MainActor
final class SwiftDataUserProfileRepository: SwiftDataRepository, UserProfileRepository {
    func currentProfile() throws -> UserProfile {
        let d = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        if let existing = try context.fetch(d).first { return existing }
        let profile = UserProfile()
        context.insert(profile)
        try save()
        return profile
    }

    func update(_ profile: UserProfile) throws { try save() }
}
