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

    // Services
    let habitService: HabitService
    let scoringService: ScoringService
    let forestService: ForestService
    let workoutService: WorkoutService
    let analyticsService: AnalyticsService
    let notificationService: NotificationService
    
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

        self.habitRepo = habitRepo
        self.completionRepo = completionRepo
        self.forestRepo = forestRepo
        self.treeRepo = treeRepo
        self.exerciseRepo = exerciseRepo
        self.workoutRepo = workoutRepo
        self.sessionRepo = sessionRepo
        self.profileRepo = profileRepo

        let habitService = HabitService(habits: habitRepo, completions: completionRepo)
        let scoring = ScoringService(habitService: habitService, forestRepo: forestRepo)
        self.habitService = habitService
        self.scoringService = scoring
        self.forestService = ForestService(forestRepo: forestRepo, treeRepo: treeRepo, scoring: scoring)
        self.workoutService = WorkoutService(workouts: workoutRepo, sessions: sessionRepo, exercises: exerciseRepo)
        self.analyticsService = AnalyticsService(completions: completionRepo, sessions: sessionRepo)
        self.notificationService = NotificationService.shared

        // Seed & Bootstrap
        try? exerciseRepo.seedBuiltInsIfNeeded()
        _ = try? profileRepo.currentProfile()
        _ = try? forestRepo.currentForest()
        
        #if DEBUG
        self.debugService = DebugService(env: self)
        #endif
    }
}
