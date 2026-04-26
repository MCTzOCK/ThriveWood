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
            pointsToday = try env.habitService.pointsEarned(on: selectedDate)
            dailyGoal = try env.profileRepo.currentProfile().dailyPointGoal
            availablePoints = try env.scoringService.availablePoints()
        } catch {
            errors.show(error)
        }
    }
    
    // MARK: - Actions
    
    func toggle(_ habit: Habit) {
        do {
            let wasCompleted = completedHabitIDs.contains(habit.id)
            _ = try env.habitService.toggle(habit, on: selectedDate)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                if wasCompleted {
                    completedHabitIDs.remove(habit.id)
                    pointsToday -= habit.points.rawValue
                    Haptics.impact(.light)
                } else {
                    completedHabitIDs.insert(habit.id)
                    pointsToday += habit.points.rawValue
                    Haptics.success()
                }
            }
            availablePoints = try env.scoringService.availablePoints()
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
}
