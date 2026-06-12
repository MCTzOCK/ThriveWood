//
//  NotificationService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Categories / Actions
    
    enum Category {
        static let habitReminder = "HABIT_REMINDER"
    }
    enum Action {
        static let complete = "HABIT_COMPLETE"
        static let snooze   = "HABIT_SNOOZE"
    }
    enum UserInfoKey {
        static let habitID = "habitID"
    }
    
    // MARK: - Setup (einmalig beim App-Start)
    
    func bootstrap() {
        center.delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
    }
    
    private func registerCategories() {
        let complete = UNNotificationAction(
            identifier: Action.complete,
            title: "Erledigt ✓",
            options: [.authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: Action.snooze,
            title: "In 15 Min erinnern",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Category.habitReminder,
            actions: [complete, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }
    
    // MARK: - Authorization
    
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    /// Fragt erst bei Bedarf nach. Gibt zurück, ob aktuell erlaubt.
    @discardableResult
    func ensureAuthorized() async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                await refreshAuthorizationStatus()
                return granted
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Plant alle nötigen Trigger für einen Habit (löscht zuerst alte).
    func scheduleReminders(for habit: Habit) async throws {
        try await cancelReminders(for: habit)
        guard let time = habit.reminderTime else { return }
        guard await ensureAuthorized() else { return }
        
        let content = makeContent(for: habit)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let weekdays = scheduledWeekdays(for: habit)
        
        if weekdays.isEmpty {
            // Täglich
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(
                identifier: identifier(for: habit, weekday: nil),
                content: content,
                trigger: trigger
            )
            try await center.add(req)
        } else {
            // Pro aktiver Wochentag ein eigener Trigger
            for weekday in weekdays {
                var dc = comps
                dc.weekday = weekday   // 1 = Sonntag
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(
                    identifier: identifier(for: habit, weekday: weekday),
                    content: content,
                    trigger: trigger
                )
                try await center.add(req)
            }
        }
    }
    
    func cancelReminders(for habit: Habit) async throws {
        let pending = await center.pendingNotificationRequests()
        let prefix = "habit-\(habit.id.uuidString)"
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    /// Snooze: einmaliger Trigger nach `minutes`.
    func snooze(habitID: UUID, title: String, minutes: Int = 15) async throws {
        guard await ensureAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = "Erinnerung verschoben 🌱"
        content.sound = .default
        content.categoryIdentifier = Category.habitReminder
        content.userInfo = [UserInfoKey.habitID: habitID.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60), repeats: false
        )
        let req = UNNotificationRequest(
            identifier: "habit-\(habitID.uuidString)-snooze-\(UUID().uuidString)",
            content: content, trigger: trigger
        )
        try await center.add(req)
    }
    
    /// Plant alle Habits neu (nach Wechsel der Notification-Settings o.ä.)
    func rescheduleAll(_ habits: [Habit]) async throws {
        center.removeAllPendingNotificationRequests()
        for habit in habits where !habit.isArchived {
            try await scheduleReminders(for: habit)
        }
    }
    
    // MARK: - Helpers
    
    private func identifier(for habit: Habit, weekday: Int?) -> String {
        if let weekday { "habit-\(habit.id.uuidString)-wd\(weekday)" }
        else { "habit-\(habit.id.uuidString)-daily" }
    }
    
    private func makeContent(for habit: Habit) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = habit.title
        content.body  = habit.details.isEmpty
        ? "Zeit für deinen Habit 🌱"
        : habit.details
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Category.habitReminder
        content.userInfo = [UserInfoKey.habitID: habit.id.uuidString]
        return content
    }
    
    private func scheduledWeekdays(for habit: Habit) -> [Int] {
        switch habit.frequency {
        case .daily: return []
        case .weekly, .custom: return habit.activeWeekdays
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        #if os(iOS)
        return [.banner, .sound, .badge]
        #else
        return [.banner, .sound]
        #endif
    }
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let idString = userInfo[UserInfoKey.habitID] as? String,
              let habitID = UUID(uuidString: idString) else { return }
        
        NotificationRouter.shared.handle(
            actionID: response.actionIdentifier,
            habitID: habitID,
            title: response.notification.request.content.title
        )
    }
    
    func scheduleDaily(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Notification scheduling failed: \(error)")
        }
    }

    func cancelNotifications(for prefix: String) {
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

}
