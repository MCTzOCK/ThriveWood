//
//  Extensions.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation

extension Calendar {
    /// App-weiter Kalender. Liest den Wochenbeginn aus dem aktuellen UserProfile.
    /// Fallback: Montag.
    static var app: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.firstWeekday = AppCalendarConfig.shared.firstWeekday
        return cal
    }

    func startOfDay(_ date: Date = .now) -> Date { startOfDay(for: date) }

    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        isDate(a, inSameDayAs: b)
    }

    func daysBetween(_ from: Date, _ to: Date) -> Int {
        let f = startOfDay(for: from)
        let t = startOfDay(for: to)
        return dateComponents([.day], from: f, to: t).day ?? 0
    }
}

/// Globaler, leichtgewichtiger Config-Container.
/// Wird von AppEnvironment beim Start und bei Profil-Änderungen aktualisiert.
final class AppCalendarConfig: @unchecked Sendable {
    static let shared = AppCalendarConfig()
    private init() {}

    private(set) var firstWeekday: Int = 2 // Montag = 2 (Calendar-Standard)

    func update(weekStartsOn: Weekday) {
        firstWeekday = weekStartsOn.rawValue
    }
}
