//
//  SportViewModel.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import Foundation
import SwiftUI

@MainActor
@Observable
final class SportViewModel {
    private let env: AppEnvironment

    var workouts: [Workout] = []
    var recentSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession? { env.workoutService.activeSession }

    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    func load() {
        do {
            workouts = try env.workoutService.allWorkouts()
            let range = Calendar.app.date(byAdding: .day, value: -30, to: .now)! ... Date.now
            recentSessions = try env.sessionRepo.sessions(in: range)
                .filter { $0.endedAt != nil }
                .sorted { $0.startedAt > $1.startedAt }
        } catch { errors.show(error) }
    }

    func startSession(for workout: Workout?) -> WorkoutSession? {
        do {
            let session = try env.workoutService.startSession(for: workout)
            Haptics.success()
            return session
        } catch {
            Haptics.warning()
            errors.show(error)
            return nil
        }
    }

    func resumeActive() -> WorkoutSession? { activeSession }

    func delete(_ workout: Workout) {
        do {
            try env.workoutService.archiveWorkout(workout)
            withAnimation { workouts.removeAll { $0.id == workout.id } }
        } catch { errors.show(error) }
    }
}
