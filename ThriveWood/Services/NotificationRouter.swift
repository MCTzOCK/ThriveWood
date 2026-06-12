//
//  NotificationRouter.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import Foundation
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    /// Wird vom Root gesetzt, sobald das Environment existiert.
    weak var env: AppEnvironment?

    /// Optionaler Deep-Link-State für die UI (z.B. zum Tab-Wechsel).
    var pendingHabitID: UUID?

    func handle(actionID: String, habitID: UUID, title: String) {
        guard let env else {
            // Falls App noch nicht ready → später aufgreifen
            pendingHabitID = habitID
            return
        }

        switch actionID {
        case NotificationService.Action.complete:
            completeHabit(habitID, in: env)

        case NotificationService.Action.snooze:
            Task {
                try? await env.notificationService.snooze(
                    habitID: habitID, title: title, minutes: 15
                )
            }

        case UNNotificationDefaultActionIdentifier:
            // Tap auf Notification → Home-Tab + Habit hervorheben
            pendingHabitID = habitID

        default:
            break
        }
    }

    private func completeHabit(_ id: UUID, in env: AppEnvironment) {
        do {
            guard let habit = try env.habitRepo.fetch(id: id) else { return }
            if try !env.habitService.isCompleted(habit) {
                _ = try env.habitService.toggle(habit)
                Haptics.success()
            }
        } catch {
            // bewusst leise – kommt aus dem System-Action-Handler
        }
    }
}
