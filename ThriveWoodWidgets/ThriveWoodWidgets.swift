//
//  ThriveWoodWidgets.swift
//  ThriveWoodWidgets
//
//  Created by Ben Siebert on 01.05.26.
//

import WidgetKit
import SwiftUI

// MARK: - Widget 1: Daily Habits

struct DailyHabitsWidget: Widget {
    let kind = "DailyHabitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyHabitsProvider()) { entry in
            DailyHabitsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tagesübersicht")
        .description("Deine heutigen Habits und Punkte auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget 2: Habit Streak (Configurable)

struct HabitStreakWidget: Widget {
    let kind = "HabitStreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectHabitIntent.self,
                               provider: HabitStreakProvider()) { entry in
            HabitStreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit Streak")
        .description("Verfolge den Streak eines einzelnen Habits.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget 3: Forest

struct ForestWidget: Widget {
    let kind = "ForestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForestProvider()) { entry in
            ForestWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Mein Wald")
        .description("Sieh, wie dein Wald wächst.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget 4: Workouts

struct WorkoutWidget: Widget {
    let kind = "WorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            WorkoutWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Letzte Trainings")
        .description("Deine letzten Workout-Sessions.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

