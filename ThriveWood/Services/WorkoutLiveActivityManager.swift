//
//  WorkoutLiveActivityManager.swift
//  ThriveWood
//
//  Created by Ben Siebert on 08.05.26.
//


#if os(iOS)
import ActivityKit
import Foundation

@MainActor
@Observable
final class WorkoutLiveActivityManager {
    private var currentActivity: Activity<WorkoutActivityAttributes>?

    var isActive: Bool { currentActivity != nil }

    func start(
        workoutName: String,
        workoutIcon: String,
        firstExercise: String,
        totalExercises: Int,
        totalSets: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities nicht erlaubt")
            return
        }

        end()

        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            workoutIcon: workoutIcon,
            startedAt: .now
        )

        let initialState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: firstExercise,
            currentExerciseIndex: 1,
            totalExercises: totalExercises,
            completedSets: 0,
            totalSets: totalSets,
            elapsedSeconds: 0,
            isResting: false,
            restSecondsRemaining: nil,
            lastSetInfo: nil
        )

        do {
            currentActivity = try Activity<WorkoutActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("Workout Live Activity gestartet")
        } catch {
            print("Live Activity Start fehlgeschlagen: \(error)")
        }
    }

    func update(
        currentExercise: String,
        exerciseIndex: Int,
        totalExercises: Int,
        completedSets: Int,
        totalSets: Int,
        elapsedSeconds: Int,
        isResting: Bool = false,
        restSecondsRemaining: Int? = nil,
        lastSetInfo: String? = nil
    ) {
        guard let activity = currentActivity else { return }

        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: currentExercise,
            currentExerciseIndex: exerciseIndex,
            totalExercises: totalExercises,
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsedSeconds,
            isResting: isResting,
            restSecondsRemaining: restSecondsRemaining,
            lastSetInfo: lastSetInfo
        )

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func startRest(
        duration: Int,
        currentExercise: String,
        exerciseIndex: Int,
        totalExercises: Int,
        completedSets: Int,
        totalSets: Int,
        elapsedSeconds: Int,
        lastSetInfo: String?
    ) {
        update(
            currentExercise: currentExercise,
            exerciseIndex: exerciseIndex,
            totalExercises: totalExercises,
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsedSeconds,
            isResting: true,
            restSecondsRemaining: duration,
            lastSetInfo: lastSetInfo
        )
    }

    func endRest(
        currentExercise: String,
        exerciseIndex: Int,
        totalExercises: Int,
        completedSets: Int,
        totalSets: Int,
        elapsedSeconds: Int
    ) {
        update(
            currentExercise: currentExercise,
            exerciseIndex: exerciseIndex,
            totalExercises: totalExercises,
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsedSeconds,
            isResting: false,
            restSecondsRemaining: nil,
            lastSetInfo: nil
        )
    }

    func end() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
            print("Workout Live Activity beendet")
        }
    }

    func endWithSummary(
        completedSets: Int,
        totalSets: Int,
        elapsedSeconds: Int
    ) {
        guard let activity = currentActivity else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "Fertig! 💪",
            currentExerciseIndex: 0,
            totalExercises: 0,
            completedSets: completedSets,
            totalSets: totalSets,
            elapsedSeconds: elapsedSeconds,
            isResting: false,
            restSecondsRemaining: nil,
            lastSetInfo: nil
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(300))
            )
            self.currentActivity = nil
        }
    }
}
#else
import Foundation

@MainActor
@Observable
final class WorkoutLiveActivityManager {
    var isActive: Bool { false }
    func start(workoutName: String, workoutIcon: String, firstExercise: String, totalExercises: Int, totalSets: Int) {}
    func update(currentExercise: String, exerciseIndex: Int, totalExercises: Int, completedSets: Int, totalSets: Int, elapsedSeconds: Int, isResting: Bool = false, restSecondsRemaining: Int? = nil, lastSetInfo: String? = nil) {}
    func startRest(duration: Int, currentExercise: String, exerciseIndex: Int, totalExercises: Int, completedSets: Int, totalSets: Int, elapsedSeconds: Int, lastSetInfo: String?) {}
    func endRest(currentExercise: String, exerciseIndex: Int, totalExercises: Int, completedSets: Int, totalSets: Int, elapsedSeconds: Int) {}
    func end() {}
    func endWithSummary(completedSets: Int, totalSets: Int, elapsedSeconds: Int) {}
}
#endif
