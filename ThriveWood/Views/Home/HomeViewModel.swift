//
//  HomeViewModel.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    private let env: AppEnvironment
    
    var selectedDate: Date = Calendar.app.startOfDay()
    var habits: [Habit] = []
    var completedHabitIDs: Set<UUID> = []
    var pointsToday: Int = 0
    var dailyGoal: Int = 5
    var availablePoints: Int = 0
    var searchText: String = ""
    var habitProgress: [UUID: (value: Double, target: Double, progress: Double)] = [:]
    
    let errors = ErrorState()
    
    var filteredHabits: [Habit] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return habits }
        return habits.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }
    
    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(pointsToday) / Double(dailyGoal))
    }
    
    var isToday: Bool { Calendar.app.isSameDay(selectedDate, .now) }
    
    init(env: AppEnvironment) { self.env = env }
    
    // MARK: - Load
    
    func load() {
        do {
            habits = try env.habitService.habitsDue(on: selectedDate)
            completedHabitIDs = try Set(
                habits.compactMap {
                    try env.habitService.isCompleted($0, on: selectedDate) ? $0.id : nil
                }
            )
            habitProgress = try Dictionary(uniqueKeysWithValues:
                habits.compactMap { habit -> (UUID, (Double, Double, Double))? in
                    guard habit.isMeasurable else { return nil }
                    let p = try env.habitService.currentProgress(habit, on: selectedDate)
                    return (habit.id, p)
                }
            )
            pointsToday = try env.habitService.pointsEarned(on: selectedDate)
            dailyGoal = try env.profileRepo.currentProfile().dailyPointGoal
            availablePoints = try env.scoringService.availablePoints()
        } catch {
            errors.show(error)
        }
    }
    
    // MARK: - Actions
    
    func toggle(_ habit: Habit) {
        switch habit.trackingMode {
        case .simple:
            toggleSimple(habit)
        case .measurable:
            incrementMeasurable(habit)
        }
    }
    
    private func toggleSimple(_ habit: Habit) {
        do {
            let wasCompleted = completedHabitIDs.contains(habit.id)
            _ = try env.habitService.toggle(habit, on: selectedDate)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                if wasCompleted {
                    completedHabitIDs.remove(habit.id)
                    Haptics.impact(.light)
                } else {
                    completedHabitIDs.insert(habit.id)
                    Haptics.success()
                }
            }
            reloadPoints()
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }

    func incrementMeasurable(_ habit: Habit) {
        do {
            _ = try env.habitService.increment(habit, on: selectedDate)
            let progress = try env.habitService.currentProgress(habit, on: selectedDate)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                habitProgress[habit.id] = progress
                if progress.progress >= 1.0 {
                    completedHabitIDs.insert(habit.id)
                    Haptics.success()
                } else {
                    Haptics.impact(.light)
                }
            }
            reloadPoints()
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }

    func delete(_ habit: Habit) {
        Task {
            do {
                try await env.archiveHabit(habit)
                withAnimation { habits.removeAll { $0.id == habit.id } }
            } catch { errors.show(error) }
        }
    }
    
    func streak(for habit: Habit) -> Int {
        (try? env.habitService.currentStreak(for: habit, asOf: selectedDate)) ?? 0
    }
    
    func move(_ offsets: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: offsets, toOffset: destination)
        habits = reordered
        try? env.habitRepo.reorder(reordered)
    }
    
    func changeDate(to newDate: Date) {
        selectedDate = Calendar.app.startOfDay(newDate)
        load()
    }
    
    func decrementMeasurable(_ habit: Habit) {
        do {
            _ = try env.habitService.decrement(habit, on: selectedDate)
            let progress = try env.habitService.currentProgress(habit, on: selectedDate)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                habitProgress[habit.id] = progress
                if progress.progress < 1.0 {
                    completedHabitIDs.remove(habit.id)
                }
            }
            reloadPoints()
            Haptics.impact(.light)
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }

    /// Setzt den Wert direkt (z.B. aus einem Textfeld).
    func setMeasurableValue(_ habit: Habit, value: Double) {
        do {
            _ = try env.habitService.setValue(habit, value: value, on: selectedDate)
            let progress = try env.habitService.currentProgress(habit, on: selectedDate)
            withAnimation {
                habitProgress[habit.id] = progress
                if progress.progress >= 1.0 { completedHabitIDs.insert(habit.id) }
                else { completedHabitIDs.remove(habit.id) }
            }
            reloadPoints()
        } catch { errors.show(error) }
    }

    private func reloadPoints() {
        pointsToday = (try? env.habitService.pointsEarned(on: selectedDate)) ?? pointsToday
        availablePoints = (try? env.scoringService.availablePoints()) ?? availablePoints
    }

}
