//
//  Extensions.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import Foundation
import SwiftUI

extension Calendar {
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

final class AppCalendarConfig: @unchecked Sendable {
    static let shared = AppCalendarConfig()
    private init() {}

    private(set) var firstWeekday: Int = 2

    func update(weekStartsOn: Weekday) {
        firstWeekday = weekStartsOn.rawValue
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }

    func errorAlert(_ state: ErrorState) -> some View {
        modifier(ErrorAlertModifier(state: state))
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
