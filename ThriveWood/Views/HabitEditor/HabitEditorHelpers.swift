//
//  IconPicker.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct IconPicker: View {
    @Binding var selection: String
    let options: [String]
    let tint: Color
    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { name in
                    Button { Haptics.selection(); selection = name } label: {
                        Image(systemName: name)
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .fill(selection == name ? tint.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .strokeBorder(selection == name ? tint : .clear, lineWidth: 2)
                            )
                            .foregroundStyle(selection == name ? tint : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Symbol wählen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorGrid: View {
    @Binding var selection: HabitColor
    private let columns = [GridItem(.adaptive(minimum: 40), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(HabitColor.allCases) { c in
                Button {
                    Haptics.selection()
                    selection = c
                } label: {
                    ZStack {
                        Circle().fill(c.color).frame(width: 36, height: 36)
                        if selection == c {
                            Circle().strokeBorder(Color.primary, lineWidth: 2).frame(width: 42, height: 42)
                            Image(systemName: "checkmark")
                                .font(.caption.bold()).foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.rawValue)
            }
        }
        .padding(.vertical, 4)
    }
}

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
