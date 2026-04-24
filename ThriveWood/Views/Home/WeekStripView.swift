//
//  WeekStripView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.app

    private var days: [Date] {
        let today = calendar.startOfDay()
        return (-3...3).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    date: day,
                    isSelected: calendar.isSameDay(day, selectedDate),
                    isToday: calendar.isSameDay(day, .now)
                )
                .onTapGesture {
                    Haptics.selection()
                    selectedDate = day
                }
            }
        }
    }

    private struct DayCell: View {
        let date: Date
        let isSelected: Bool
        let isToday: Bool

        private var weekdayShort: String {
            date.formatted(.dateTime.weekday(.short))
        }
        private var dayNumber: String {
            date.formatted(.dateTime.day())
        }

        var body: some View {
            VStack(spacing: 6) {
                Text(weekdayShort)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text(dayNumber)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                Circle()
                    .fill(isToday ? Color.green : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(isSelected ? Color.green : Color(.secondarySystemGroupedBackground))
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
