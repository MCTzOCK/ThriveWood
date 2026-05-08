//
//  ThriveWoodWidgetsBundle.swift
//  ThriveWoodWidgets
//
//  Created by Ben Siebert on 01.05.26.
//

import WidgetKit
import SwiftUI

@main
struct ThriveWoodWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyHabitsWidget()
        HabitStreakWidget()
        ForestWidget()
        WorkoutWidget()
        WorkoutLiveActivity()
    }
}
