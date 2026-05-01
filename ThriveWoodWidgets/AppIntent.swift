//
//  AppIntent.swift
//  ThriveWoodWidgets
//
//  Created by Ben Siebert on 01.05.26.
//
import AppIntents
import WidgetKit
import SwiftData

// MARK: - Habit Entity für Widget-Konfiguration

struct HabitEntity: AppEntity {
    var id: String
    var title: String
    var icon: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: icon))
    }

    static var defaultQuery = HabitEntityQuery()
}

struct HabitEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let habits = WidgetDataProvider.shared.habitsDueToday()
        return habits.filter { identifiers.contains($0.id.uuidString) }.map {
            HabitEntity(id: $0.id.uuidString, title: $0.title, icon: $0.iconSystemName)
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        WidgetDataProvider.shared.habitsDueToday().map {
            HabitEntity(id: $0.id.uuidString, title: $0.title, icon: $0.iconSystemName)
        }
    }

    @MainActor
    func defaultResult() async -> HabitEntity? {
        try? await suggestedEntities().first
    }
}

// MARK: - Konfigurierender Intent

struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Habit auswählen"
    static var description = IntentDescription("Wähle einen Habit für das Widget.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    var habitID: String { habit?.id ?? "" }
}

// MARK: - Interaktiver Intent (Habit abhaken)

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Habit abhaken"
    static var description = IntentDescription("Hakt einen Habit als erledigt ab.")

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}
    init(habitID: UUID) { self.habitID = habitID.uuidString }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else { return .result() }

        let context = ModelContext(SharedModelContainer.shared)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard let habit = habits.first(where: { $0.id == uuid }) else { return .result() }

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let completions = (try? context.fetch(FetchDescriptor<HabitCompletion>())) ?? []
        let existing = completions.first {
            $0.habit?.id == uuid && cal.isDate($0.day, inSameDayAs: today)
        }

        if habit.trackingMode == .simple {
            if let existing {
                context.delete(existing)
            } else {
                let c = HabitCompletion(habit: habit, day: today)
                context.insert(c)
            }
        } else {
            if let existing {
                existing.currentValue = min(existing.currentValue + habit.incrementValue,
                                            habit.targetValue * 1.5)
                existing.completedAt = .now
                existing.recalculatePoints()
            } else {
                let c = HabitCompletion(habit: habit, day: today, currentValue: habit.incrementValue)
                c.recalculatePoints()
                context.insert(c)
            }
        }

        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
