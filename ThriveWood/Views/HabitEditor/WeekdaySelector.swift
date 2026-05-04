//
//  WeekdaySelector.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct WeekdaySelector: View {
    @Binding var selection: Set<Weekday>

    private let ordered: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ordered) { day in
                let isOn = selection.contains(day)
                Button {
                    Haptics.selection()
                    if isOn { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(dayShort(day))
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .fill(isOn ? Color.green : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dayShort(_ d: Weekday) -> String {
        var cal = Calendar.app
        let symbols = cal.veryShortWeekdaySymbols // [Sun, Mon, ...]
        return symbols[d.rawValue - 1]
    }
}
