//
//  NotificationService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorizationIfNeeded() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleReminder(for habit: Habit) async throws {
        guard let time = habit.reminderTime else { return }
        try await cancelReminder(for: habit)

        let content = UNMutableNotificationContent()
        content.title = habit.title
        content.body  = "Zeit für deinen Habit 🌱"
        content.sound = .default

        let comps = Calendar.app.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }

    func cancelReminder(for habit: Habit) async throws {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    }
}
