//
//  Extensions.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation

extension Calendar {
    /// App-weiter Kalender (konfigurierbar für Wochenstart via UserProfile).
    static var app: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
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

