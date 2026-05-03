//
//  SupplementService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import Foundation
import SwiftData
import WidgetKit
import Combine
 
@MainActor
@Observable
final class SupplementService: ObservableObject {
    private let supplementRepo: SupplementRepository
    private let entryRepo: SupplementEntryRepository
    private let notificationService: NotificationService

    var lastUpdate: Date = .now  // ← Trigger für View-Updates

    init(
        supplementRepo: SupplementRepository,
        entryRepo: SupplementEntryRepository,
        notificationService: NotificationService
    ) {
        self.supplementRepo = supplementRepo
        self.entryRepo = entryRepo
        self.notificationService = notificationService
    }

    // MARK: - Supplement Management

    func allSupplements(includeArchived: Bool = false) throws -> [Supplement] {
        try supplementRepo.fetchAll(includeArchived: includeArchived)
    }

    func supplementsDue(on date: Date) throws -> [Supplement] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let all = try allSupplements()
        
        return all.filter { s in
            guard !s.isArchived else { return false }
            
            switch s.frequency {
            case .daily:
                return true
            case .custom:
                return s.activeWeekdays.contains(weekday)
            case .weekly:
                return s.activeWeekdays.first == weekday
            }
        }
    }

    // Convenience für heute:
    func supplementsDueToday() throws -> [Supplement] {
        try supplementsDue(on: .now)
    }

    // Entries für beliebigen Tag:
    func entries(on date: Date) throws -> [SupplementEntry] {
        try entryRepo.entries(on: date)
    }


    func create(_ supplement: Supplement) async throws {
        let all = try supplementRepo.fetchAll(includeArchived: false)
        supplement.sortOrder = (all.map(\.sortOrder).max() ?? -1) + 1

        try supplementRepo.create(supplement)
        await scheduleNotifications(for: supplement)
        
        // Trigger UI update
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    func update(_ supplement: Supplement) async throws {
        try supplementRepo.update(supplement)
        await scheduleNotifications(for: supplement)
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    func archive(_ supplement: Supplement) throws {
        try supplementRepo.archive(supplement)
        notificationService.cancelNotifications(for: "supplement-\(supplement.id.uuidString)")
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Tracking

    func toggleDose(_ supplement: Supplement, doseNumber: Int, on date: Date = .now) throws {
        // Sicherheitscheck: Nur heutiges Datum erlauben
        guard Calendar.current.isDateInToday(date) else {
            throw SupplementError.cannotModifyPastEntries
        }
        
        if let existing = try entryRepo.entry(for: supplement, on: date, dose: doseNumber) {
            try entryRepo.delete(existing)
        } else {
            let entry = SupplementEntry(
                supplement: supplement,
                day: date,
                doseNumber: doseNumber
            )
            try entryRepo.add(entry)
        }
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    func skipDose(_ supplement: Supplement, doseNumber: Int, on date: Date = .now) throws {
        if let existing = try entryRepo.entry(for: supplement, on: date, dose: doseNumber) {
            existing.skipped = true
        } else {
            let entry = SupplementEntry(
                supplement: supplement,
                day: date,
                doseNumber: doseNumber,
                skipped: true
            )
            try entryRepo.add(entry)
        }
        lastUpdate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    func isDoseTaken(_ supplement: Supplement, doseNumber: Int, on date: Date = .now) throws -> Bool {
        guard let entry = try entryRepo.entry(for: supplement, on: date, dose: doseNumber) else {
            return false
        }
        return !entry.skipped
    }

    func isDoseSkipped(_ supplement: Supplement, doseNumber: Int, on date: Date = .now) throws -> Bool {
        guard let entry = try entryRepo.entry(for: supplement, on: date, dose: doseNumber) else {
            return false
        }
        return entry.skipped
    }

    func todayProgress(for supplement: Supplement) throws -> (taken: Int, total: Int) {
        let entries = try entryRepo.entries(on: .now)
            .filter { $0.supplement?.id == supplement.id && !$0.skipped }
        return (entries.count, supplement.timesPerDay)
    }

    func todayEntries() throws -> [SupplementEntry] {
        try entryRepo.entries(on: .now)
    }

    // MARK: - Notifications

    private func scheduleNotifications(for supplement: Supplement) async {
        let baseID = "supplement-\(supplement.id.uuidString)"
        notificationService.cancelNotifications(for: baseID)

        guard !supplement.reminderTimes.isEmpty else { return }

        for (index, time) in supplement.reminderTimes.enumerated() {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let id = "\(baseID)-\(index)"

            await notificationService.scheduleDaily(
                id: id,
                title: "💊 \(supplement.name)",
                body: "Zeit für deine \(supplement.dosage) Dosis",
                hour: components.hour ?? 9,
                minute: components.minute ?? 0
            )
        }
    }

    func rescheduleAllNotifications() async {
        guard let supplements = try? allSupplements() else { return }
        for supplement in supplements {
            await scheduleNotifications(for: supplement)
        }
    }
    
    func debugCreateTestSupplement() throws {
        let test = Supplement(
            name: "Test Vitamin",
            dosage: "1 Kapsel",
            details: "Debug test",
            iconSystemName: "pills.fill",
            color: .blue,
            frequency: .daily,
            activeWeekdays: Weekday.allCases,
            timesPerDay: 1,
            reminderTimes: []
        )
        try supplementRepo.create(test)
        print("DEBUG: Test supplement created with ID: \(test.id)")
        
        // Verify
        let all = try supplementRepo.fetchAll(includeArchived: false)
        print("DEBUG: Total supplements after create: \(all.count)")
    }
}
