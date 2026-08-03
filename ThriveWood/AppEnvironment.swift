//
//  AppEnvironment.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    // Repositories
    let habitRepo: any HabitRepository
    let completionRepo: any HabitCompletionRepository
    let forestRepo: any ForestRepository
    let treeRepo: any TreeRepository
    let exerciseRepo: any ExerciseRepository
    let workoutRepo: any WorkoutRepository
    let sessionRepo: any WorkoutSessionRepository
    let profileRepo: any UserProfileRepository
    let achievementRepo: AchievementRepository
    let bodyProgressRepo: BodyProgressRepository
    let routineRepo: any HabitRoutineRepository
    
    let foodRepo: FoodRepository
    let foodEntryRepo: FoodEntryRepository
    let supplementRepo: SupplementRepository
    let supplementEntryRepo: SupplementEntryRepository
    let templateRepo: MealTemplateRepository
    let trainingsPlanRepo: TrainingsPlanRepository
    let gymRepo: any GymRepository
    let groupRepo: any HabitGroupRepository
    
    
    // Services
    let habitService: HabitService
    let scoringService: ScoringService
    let forestService: ForestService
    private(set) var workoutService: WorkoutService!
    let analyticsService: AnalyticsService
    let notificationService: NotificationService
    let healthService: HealthKitService
    let storeService: StoreService
    private(set) var backupService: BackupService!
    let nutritionService: NutritionService
    let supplementService: SupplementService
    let muscleRankingService: MuscleRankingService
    let muscleRecoveryService: MuscleRecoveryService
    let aiService: AIService
    private(set) var setRecommendationService: SetRecommendationService!
    let trainingsPlanService: TrainingsPlanService
    let gymService: GymService
    let achievementService: AchievementService
    var entitlements: EntitlementService
    let bodyProgressService: BodyProgressService
    let wellnessRepo: WellnessRepository
    let wellnessService: WellnessService
    let companionRepo: any CompanionRepository
    let companionService: CompanionService

    let workoutLiveActivity = WorkoutLiveActivityManager()
    
    
#if DEBUG
    var debugService: DebugService!
#endif
    
    init(context: ModelContext) {
        let habitRepo      = SwiftDataHabitRepository(context: context)
        let completionRepo = SwiftDataHabitCompletionRepository(context: context)
        let forestRepo     = SwiftDataForestRepository(context: context)
        let treeRepo       = SwiftDataTreeRepository(context: context)
        let exerciseRepo   = SwiftDataExerciseRepository(context: context)
        let workoutRepo    = SwiftDataWorkoutRepository(context: context)
        let sessionRepo    = SwiftDataWorkoutSessionRepository(context: context)
        let profileRepo    = SwiftDataUserProfileRepository(context: context)
        self.trainingsPlanRepo = TrainingsPlanRepository(modelContext: context)
        self.bodyProgressRepo = SwiftDataBodyProgressRepository(context: context)
        self.gymRepo = SwiftDataGymRepository(context: context)
        self.groupRepo = SwiftDataHabitGroupRepository(context: context)
        self.routineRepo = SwiftDataHabitRoutineRepository(context: context)


        self.habitRepo = habitRepo
        self.completionRepo = completionRepo
        self.forestRepo = forestRepo
        self.treeRepo = treeRepo
        self.exerciseRepo = exerciseRepo
        self.workoutRepo = workoutRepo
        self.sessionRepo = sessionRepo
        self.profileRepo = profileRepo
        self.foodRepo = SwiftDataFoodRepository(context: context)
        self.foodEntryRepo = SwiftDataFoodEntryRepository(context: context)
        self.supplementRepo = SwiftDataSupplementRepository(context: context)
        self.supplementEntryRepo = SwiftDataSupplementEntryRepository(context: context)
        self.templateRepo = SwiftDataMealTemplateRepository(context: context)
        
        
        let habitService = HabitService(habits: habitRepo, completions: completionRepo)
        let scoring = ScoringService(habitService: habitService, forestRepo: forestRepo)
        self.habitService = habitService
        self.scoringService = scoring
        self.forestService = ForestService(forestRepo: forestRepo, treeRepo: treeRepo, scoring: scoring)
        self.analyticsService = AnalyticsService(completions: completionRepo, sessions: sessionRepo)
        self.notificationService = NotificationService.shared
        self.healthService = HealthKitService.shared
        let storeService = StoreService()
        self.storeService = storeService
        self.entitlements = EntitlementService(store: storeService, habitRepo: habitRepo, workoutRepo: workoutRepo, supplementRepo: supplementRepo, gymRepo: gymRepo)
        self.nutritionService = NutritionService(
            foodRepo: foodRepo,
            entryRepo: foodEntryRepo,
            profileRepo: profileRepo,
            templateRepo: templateRepo
        )
        self.supplementService = SupplementService(
            supplementRepo: supplementRepo,
            entryRepo: supplementEntryRepo,
            notificationService: notificationService
        )
        self.muscleRankingService = MuscleRankingService(sessionRepo: sessionRepo)
        self.muscleRecoveryService = MuscleRecoveryService(sessionRepo: sessionRepo)
        self.aiService = AIService()
        self.trainingsPlanService = TrainingsPlanService(repo: trainingsPlanRepo)
        self.gymService = GymService(gymRepo: gymRepo, exerciseRepo: exerciseRepo)
        self.achievementRepo = SwiftDataAchievementRepository(context: context)
        self.achievementService = AchievementService(
            repo: achievementRepo,
            habitService: habitService,
            scoringService: scoring,
            forestService: forestService,
            sessionRepo: sessionRepo,
            muscleRankingService: muscleRankingService
        )
        self.bodyProgressService = BodyProgressService(repo: bodyProgressRepo)
        self.wellnessRepo = SwiftDataWellnessRepository(context: context)
        self.wellnessService = WellnessService(repo: wellnessRepo, completionRepo: completionRepo, sessionRepo: sessionRepo)
        let companionRepo = SwiftDataCompanionRepository(context: context)
        self.companionRepo = companionRepo
        self.companionService = CompanionService(repo: companionRepo)

        // Thrive Companion: Habit-Erledigung füttert das Wesen.
        habitService.onHabitCompleted = { [weak companionService] delta in
            companionService?.feedHabit(pointsDelta: delta)
        }
        
        
        // Seed & Bootstrap
        try? exerciseRepo.seedBuiltInsIfNeeded()
        _ = try? profileRepo.currentProfile()
        _ = try? forestRepo.currentForest()
        _ = try? companionRepo.currentCompanion()
        
        if let profile = try? profileRepo.currentProfile() {
            AppCalendarConfig.shared.update(weekStartsOn: profile.weekStartsOn)
        }
        
#if DEBUG
        self.debugService = DebugService(env: self)
#endif
        self.backupService = BackupService(env: self)
        self.workoutService = WorkoutService(workouts: workoutRepo, sessions: sessionRepo, exercises: exerciseRepo, profile: profileRepo, env: self)
        self.setRecommendationService = SetRecommendationService(
            workoutService: workoutService,
            rankingService: muscleRankingService,
            recoveryService: muscleRecoveryService,
            aiService: aiService
        )
    }
    
    func saveHabit(_ habit: Habit, isNew: Bool) async throws {
        if isNew { try habitRepo.create(habit) }
        else      { try habitRepo.update(habit) }
        try await notificationService.scheduleReminders(for: habit)
        achievementService.checkHabits()
    }
    
    func archiveHabit(_ habit: Habit) async throws {
        try habitRepo.archive(habit)
        try groupRepo.removeHabitFromAllGroups(habit.id)
        try routineRepo.removeHabitFromAllRoutines(habit.id)
        try await notificationService.cancelReminders(for: habit)
    }
    
    func deleteHabit(_ habit: Habit) async throws {
        try await notificationService.cancelReminders(for: habit)
        try groupRepo.removeHabitFromAllGroups(habit.id)
        try routineRepo.removeHabitFromAllRoutines(habit.id)
        try habitRepo.delete(habit)
    }

    func saveGroup(_ group: HabitGroup, isNew: Bool) throws {
        if isNew { try groupRepo.create(group) }
        else     { try groupRepo.update(group) }
    }

    func deleteGroup(_ group: HabitGroup) throws {
        try groupRepo.delete(group)
    }

    func moveHabitToGroup(_ habitID: UUID, from oldGroupID: UUID?, to newGroupID: UUID?) throws {
        if let oldID = oldGroupID {
            try groupRepo.removeHabit(habitID, from: oldID)
        } else {
            try groupRepo.removeHabitFromAllGroups(habitID)
        }
        if let newID = newGroupID {
            try groupRepo.addHabit(habitID, to: newID)
        }
    }
    
}
