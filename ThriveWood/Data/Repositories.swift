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


protocol BodyProgressRepository {
    func fetchAll() throws -> [BodyProgressEntry]
    func add(_ entry: BodyProgressEntry) throws
    func update(_ entry: BodyProgressEntry) throws
    func delete(_ entry: BodyProgressEntry) throws
}

@MainActor
final class SwiftDataBodyProgressRepository: SwiftDataRepository, BodyProgressRepository {
    func fetchAll() throws -> [BodyProgressEntry] {
        try context.fetch(FetchDescriptor<BodyProgressEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }
    
    func add(_ entry: BodyProgressEntry) throws {
        context.insert(entry)
        try save()
    }
    
    func update(_ entry: BodyProgressEntry) throws { try save() }
    
    func delete(_ entry: BodyProgressEntry) throws {
        context.delete(entry)
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

// MARK: - Food Repository

protocol FoodRepository {
    func fetchAll() throws -> [Food]
    func search(query: String) throws -> [Food]
    func fetch(barcode: String) throws -> Food?
    func fetch(id: UUID) throws -> Food?
    func create(_ food: Food) throws
    func update(_ food: Food) throws
    func delete(_ food: Food) throws
    func recentFoods(limit: Int) throws -> [Food]
    func favoriteFoods() throws -> [Food]
    func incrementUsage(_ food: Food) throws
}

final class SwiftDataFoodRepository: FoodRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    
    func fetchAll() throws -> [Food] {
        try context.fetch(FetchDescriptor<Food>(sortBy: [SortDescriptor(\.name)]))
    }
    
    func search(query: String) throws -> [Food] {
        let q = query.lowercased()
        let all = try fetchAll()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            ($0.brand?.lowercased().contains(q) ?? false)
        }
    }
    
    func fetch(barcode: String) throws -> Food? {
        try context.fetch(FetchDescriptor<Food>(
            predicate: #Predicate { $0.barcode == barcode }
        )).first
    }
    
    func fetch(id: UUID) throws -> Food? {
        try context.fetch(FetchDescriptor<Food>(
            predicate: #Predicate { $0.id == id }
        )).first
    }
    
    func create(_ food: Food) throws {
        context.insert(food)
        try save()
    }
    
    func update(_ food: Food) throws { try save() }
    
    func delete(_ food: Food) throws {
        context.delete(food)
        try save()
    }
    
    func recentFoods(limit: Int) throws -> [Food] {
        let all = try fetchAll()
        return Array(all.filter { $0.usageCount > 0 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit))
    }
    
    func favoriteFoods() throws -> [Food] {
        try context.fetch(FetchDescriptor<Food>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.name)]
        ))
    }
    
    func incrementUsage(_ food: Food) throws {
        food.usageCount += 1
        try save()
    }
    
    private func save() throws { try context.save() }
}

// MARK: - FoodEntry Repository

protocol FoodEntryRepository {
    func entries(on day: Date) throws -> [FoodEntry]
    func entries(in range: ClosedRange<Date>) throws -> [FoodEntry]
    func add(_ entry: FoodEntry) throws
    func update(_ entry: FoodEntry) throws
    func delete(_ entry: FoodEntry) throws
}

final class SwiftDataFoodEntryRepository: FoodEntryRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    
    func entries(on day: Date) throws -> [FoodEntry] {
        let start = Calendar.current.startOfDay(for: day)
        let all = try context.fetch(FetchDescriptor<FoodEntry>())
        return all.filter { Calendar.current.isDate($0.day, inSameDayAs: start) }
            .sorted { $0.loggedAt < $1.loggedAt }
    }
    
    func entries(in range: ClosedRange<Date>) throws -> [FoodEntry] {
        let all = try context.fetch(FetchDescriptor<FoodEntry>())
        return all.filter { range.contains($0.day) }
    }
    
    func add(_ entry: FoodEntry) throws {
        context.insert(entry)
        try context.save()
    }
    
    func update(_ entry: FoodEntry) throws { try context.save() }
    
    func delete(_ entry: FoodEntry) throws {
        context.delete(entry)
        try context.save()
    }
}

// MARK: - Supplement Repository

protocol SupplementRepository {
    func fetchAll(includeArchived: Bool) throws -> [Supplement]
    func fetch(id: UUID) throws -> Supplement?
    func create(_ supplement: Supplement) throws
    func update(_ supplement: Supplement) throws
    func archive(_ supplement: Supplement) throws
    func delete(_ supplement: Supplement) throws
}

final class SwiftDataSupplementRepository: SupplementRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    
    func fetchAll(includeArchived: Bool) throws -> [Supplement] {
        var all = try context.fetch(FetchDescriptor<Supplement>(
            sortBy: [SortDescriptor(\.sortOrder)]
        ))
        if !includeArchived { all = all.filter { !$0.isArchived } }
        return all
    }
    
    func fetch(id: UUID) throws -> Supplement? {
        try context.fetch(FetchDescriptor<Supplement>(
            predicate: #Predicate { $0.id == id }
        )).first
    }
    
    func create(_ supplement: Supplement) throws {
        context.insert(supplement)
        try context.save()
    }
    
    func update(_ supplement: Supplement) throws { try context.save() }
    
    func archive(_ supplement: Supplement) throws {
        supplement.archivedAt = .now
        try context.save()
    }
    
    func delete(_ supplement: Supplement) throws {
        context.delete(supplement)
        try context.save()
    }
}

// MARK: - SupplementEntry Repository

protocol SupplementEntryRepository {
    func entries(on day: Date) throws -> [SupplementEntry]
    func entry(for supplement: Supplement, on day: Date, dose: Int) throws -> SupplementEntry?
    func add(_ entry: SupplementEntry) throws
    func delete(_ entry: SupplementEntry) throws
    func fetchAll() throws -> [SupplementEntry]
}

final class SwiftDataSupplementEntryRepository: SupplementEntryRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func entries(on day: Date) throws -> [SupplementEntry] {
        let start = Calendar.current.startOfDay(for: day)
        let all = try context.fetch(FetchDescriptor<SupplementEntry>())
        return all.filter { Calendar.current.isDate($0.day, inSameDayAs: start) }
    }
    
    func entry(for supplement: Supplement, on day: Date, dose: Int) throws -> SupplementEntry? {
        let start = Calendar.current.startOfDay(for: day)
        let all = try context.fetch(FetchDescriptor<SupplementEntry>())
        return all.first {
            $0.supplement?.id == supplement.id &&
            Calendar.current.isDate($0.day, inSameDayAs: start) &&
            $0.doseNumber == dose
        }
    }
    
    func add(_ entry: SupplementEntry) throws {
        context.insert(entry)
        try context.save()
    }
    
    func delete(_ entry: SupplementEntry) throws {
        context.delete(entry)
        try context.save()
    }
    
    func fetchAll() throws -> [SupplementEntry] {
        return try context.fetch(FetchDescriptor<SupplementEntry>(sortBy: [SortDescriptor(\.day), SortDescriptor(\.doseNumber)]))
    }
}

protocol MealTemplateRepository {
    func fetchAll() throws -> [MealTemplate]
    func fetch(id: UUID) throws -> MealTemplate?
    func create(_ template: MealTemplate) throws
    func update(_ template: MealTemplate) throws
    func delete(_ template: MealTemplate) throws
    func deleteItem(_ item: MealTemplateItem) throws
    func incrementUsage(_ template: MealTemplate) throws
}

final class SwiftDataMealTemplateRepository: MealTemplateRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    
    func fetchAll() throws -> [MealTemplate] {
        try context.fetch(FetchDescriptor<MealTemplate>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        ))
    }
    
    func fetch(id: UUID) throws -> MealTemplate? {
        try context.fetch(FetchDescriptor<MealTemplate>(
            predicate: #Predicate { $0.id == id }
        )).first
    }
    
    func create(_ template: MealTemplate) throws {
        context.insert(template)
        try context.save()
    }
    
    func update(_ template: MealTemplate) throws {
        try context.save()
    }
    
    func delete(_ template: MealTemplate) throws {
        context.delete(template)
        try context.save()
    }
    
    func deleteItem(_ item: MealTemplateItem) throws {
        context.delete(item)
        // Kein save() hier - wird beim Template-Update gemacht
    }
    
    func incrementUsage(_ template: MealTemplate) throws {
        template.usageCount += 1
        try context.save()
    }
}


@MainActor
final class SwiftDataAchievementRepository: SwiftDataRepository, AchievementRepository {
    func fetchAll() throws -> [AchievementRecord] {
        try context.fetch(FetchDescriptor<AchievementRecord>(
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        ))
    }

    func fetch(definition: AchievementDefinition) throws -> AchievementRecord? {
        let raw = definition.rawValue
        var d = FetchDescriptor<AchievementRecord>(
            predicate: #Predicate { $0.definitionRaw == raw }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func add(_ record: AchievementRecord) throws {
        context.insert(record)
        try save()
    }

    func delete(_ record: AchievementRecord) throws {
        context.delete(record)
        try save()
    }
}


// MARK: - HabitGroup

@MainActor
final class SwiftDataHabitGroupRepository: SwiftDataRepository, HabitGroupRepository {
    func fetchAll() throws -> [HabitGroup] {
        try context.fetch(FetchDescriptor<HabitGroup>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        ))
    }

    func fetch(id: UUID) throws -> HabitGroup? {
        var d = FetchDescriptor<HabitGroup>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func create(_ group: HabitGroup) throws {
        guard !group.title.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Titel darf nicht leer sein.") }
        context.insert(group)
        try save()
    }

    func update(_ group: HabitGroup) throws { try save() }

    func delete(_ group: HabitGroup) throws {
        context.delete(group)
        try save()
    }

    func reorder(_ groups: [HabitGroup]) throws {
        for (index, group) in groups.enumerated() { group.sortOrder = index }
        try save()
    }

    func addHabit(_ habitID: UUID, to groupID: UUID) throws {
        guard let group = try fetch(id: groupID) else { return }
        if !group.habitIDs.contains(habitID) {
            group.habitIDs.append(habitID)
            try save()
        }
    }

    func removeHabit(_ habitID: UUID, from groupID: UUID) throws {
        guard let group = try fetch(id: groupID) else { return }
        group.habitIDs.removeAll { $0 == habitID }
        try save()
    }

    func removeHabitFromAllGroups(_ habitID: UUID) throws {
        let all = try fetchAll()
        for group in all where group.habitIDs.contains(habitID) {
            group.habitIDs.removeAll { $0 == habitID }
        }
        if context.hasChanges { try save() }
    }

    func groupForHabit(_ habitID: UUID) throws -> HabitGroup? {
        try fetchAll().first { $0.habitIDs.contains(habitID) }
    }
}

// MARK: - HabitRoutine

@MainActor
final class SwiftDataHabitRoutineRepository: SwiftDataRepository, HabitRoutineRepository {
    func fetchAll() throws -> [HabitRoutine] {
        try context.fetch(FetchDescriptor<HabitRoutine>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        ))
    }

    func fetch(id: UUID) throws -> HabitRoutine? {
        var d = FetchDescriptor<HabitRoutine>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func create(_ routine: HabitRoutine) throws {
        guard !routine.title.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Titel darf nicht leer sein.") }
        context.insert(routine)
        try save()
    }

    func update(_ routine: HabitRoutine) throws { try save() }

    func delete(_ routine: HabitRoutine) throws {
        context.delete(routine)
        try save()
    }

    func reorder(_ routines: [HabitRoutine]) throws {
        for (index, routine) in routines.enumerated() { routine.sortOrder = index }
        try save()
    }

    func removeHabitFromAllRoutines(_ habitID: UUID) throws {
        let all = try fetchAll()
        for routine in all where routine.habitIDs.contains(habitID) {
            routine.habitIDs.removeAll { $0 == habitID }
        }
        if context.hasChanges { try save() }
    }
}

// MARK: - Gym

@MainActor
final class SwiftDataGymRepository: SwiftDataRepository, GymRepository {
    func fetchAll(includeArchived: Bool = false) throws -> [Gym] {
        let predicate: Predicate<Gym> = includeArchived
        ? #Predicate { _ in true }
        : #Predicate { $0.archivedAt == nil }
        let descriptor = FetchDescriptor<Gym>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> Gym? {
        var d = FetchDescriptor<Gym>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func create(_ gym: Gym) throws {
        guard !gym.name.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw RepositoryError.invalidInput("Name darf nicht leer sein.") }
        context.insert(gym)
        try save()
    }

    func update(_ gym: Gym) throws { try save() }

    func archive(_ gym: Gym) throws {
        gym.archivedAt = .now
        try save()
    }

    func delete(_ gym: Gym) throws {
        context.delete(gym)
        try save()
    }
}


// MARK: Training Plans

@MainActor
final class TrainingsPlanRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch
    
    func fetchAll() throws -> [TrainingsPlan] {
        let descriptor = FetchDescriptor<TrainingsPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActive() throws -> TrainingsPlan? {
        var descriptor = FetchDescriptor<TrainingsPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    func fetch(by id: UUID) throws -> TrainingsPlan? {
        let descriptor = FetchDescriptor<TrainingsPlan>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Create
    
    func create(
        name: String,
        details: String = "",
        color: String = "#4CAF50"
    ) throws -> TrainingsPlan {
        let plan = TrainingsPlan(
            name: name,
            details: details,
            color: color
        )
        
        // Alle Wochentage als leere Tage hinzufügen
        for weekday in TPWeekday.allCases {
            let day = TrainingsPlanDay(
                weekday: weekday,
                plan: plan
            )
            plan.days.append(day)
            modelContext.insert(day)
        }
        
        modelContext.insert(plan)
        try modelContext.save()
        return plan
    }
    
    // MARK: - Update
    
    func update(_ plan: TrainingsPlan) throws {
        try modelContext.save()
    }
    
    func setActive(_ plan: TrainingsPlan) throws {
        // Alle anderen deaktivieren
        let allPlans = try fetchAll()
        for p in allPlans {
            p.isActive = false
        }
        
        // Diesen aktivieren
        plan.isActive = true
        try modelContext.save()
    }
    
    func assignWorkout(_ workout: Workout?, to weekday: TPWeekday, in plan: TrainingsPlan) throws {
        guard let day = plan.days.first(where: { $0.weekday == weekday }) else {
            throw RepositoryError.notFound
        }
        
        day.workout = workout
        day.isRestDay = workout == nil
        try modelContext.save()
    }
    
    func setRestDay(_ weekday: TPWeekday, in plan: TrainingsPlan, isRest: Bool) throws {
        guard let day = plan.days.first(where: { $0.weekday == weekday }) else {
            throw RepositoryError.notFound
        }
        
        day.isRestDay = isRest
        if isRest {
            day.workout = nil
        }
        try modelContext.save()
    }
    
    func updateDayNotes(_ notes: String, for weekday: TPWeekday, in plan: TrainingsPlan) throws {
        guard let day = plan.days.first(where: { $0.weekday == weekday }) else {
            throw RepositoryError.notFound
        }
        
        day.notes = notes
        try modelContext.save()
    }
    
    // MARK: - Delete
    
    func delete(_ plan: TrainingsPlan) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }
    
    // MARK: - Helpers
    
    /// Workout für heute (aus aktivem Plan)
    func todaysWorkout() throws -> Workout? {
        guard let activePlan = try fetchActive() else { return nil }
        if activePlan.isRotationPlan {
            return activePlan.nextRotationWorkout
        }
        return activePlan.workout(for: .today)
    }
    
    /// Nächstes geplantes Workout
    func nextWorkout() throws -> (weekday: TPWeekday, workout: Workout)? {
        guard let activePlan = try fetchActive() else { return nil }
        
        let today = TPWeekday.today
        let sortedDays = activePlan.sortedDays
        
        // Suche ab heute
        for day in sortedDays where day.weekday >= today {
            if let workout = day.workout {
                return (day.weekday, workout)
            }
        }
        
        // Wenn nichts gefunden, suche ab Montag
        for day in sortedDays {
            if let workout = day.workout {
                return (day.weekday, workout)
            }
        }
        
        return nil
    }

    // MARK: - Rotation

    func advanceRotation(_ plan: TrainingsPlan) throws {
        guard plan.isRotationPlan, plan.rotationCount > 0 else { return }
        plan.currentRotationIndex += 1
        if plan.currentRotationIndex % plan.rotationCount == 0 {
            plan.completedRotations += 1
        }
        try modelContext.save()
    }

    func resetRotation(_ plan: TrainingsPlan) throws {
        plan.currentRotationIndex = 0
        plan.completedRotations = 0
        try modelContext.save()
    }

    func addRotationEntry(workout: Workout?, label: String, to plan: TrainingsPlan) throws {
        let order = plan.days.count
        let day = TrainingsPlanDay(
            weekday: .monday,
            rotationOrder: order,
            label: label,
            plan: plan,
            workout: workout
        )
        plan.days.append(day)
        modelContext.insert(day)
        try modelContext.save()
    }

    /// Entfernt einen einzelnen Tag/Slot physisch aus dem Store.
    func removeDay(_ day: TrainingsPlanDay, from plan: TrainingsPlan) throws {
        plan.days.removeAll { $0.id == day.id }
        modelContext.delete(day)
        try modelContext.save()
    }
}

// MARK: - Wellness

protocol WellnessRepository {
    func fetchAll() throws -> [WellnessEntry]
    func fetchForDay(_ day: Date) throws -> WellnessEntry?
    func add(_ entry: WellnessEntry) throws
    func update(_ entry: WellnessEntry) throws
    func delete(_ entry: WellnessEntry) throws
}

@MainActor
final class SwiftDataWellnessRepository: SwiftDataRepository, WellnessRepository {
    func fetchAll() throws -> [WellnessEntry] {
        try context.fetch(FetchDescriptor<WellnessEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }

    func fetchForDay(_ day: Date) throws -> WellnessEntry? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        var d = FetchDescriptor<WellnessEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func add(_ entry: WellnessEntry) throws {
        context.insert(entry)
        try save()
    }

    func update(_ entry: WellnessEntry) throws { try save() }

    func delete(_ entry: WellnessEntry) throws {
        context.delete(entry)
        try save()
    }
}

