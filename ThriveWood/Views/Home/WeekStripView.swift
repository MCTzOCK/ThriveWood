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

    @State private var weekOffset: Int = 0
    @GestureState private var dragOffset: CGFloat = 0

    private var weekStart: Date {
        let today = calendar.startOfDay()
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) ?? currentWeekStart
    }

    private var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var monthLabel: String {
        let first = days.first ?? .now
        let last = days.last ?? .now
        let firstMonth = first.formatted(.dateTime.month(.abbreviated))
        let lastMonth = last.formatted(.dateTime.month(.abbreviated))
        let year = first.formatted(.dateTime.year())

        if firstMonth == lastMonth {
            return "\(firstMonth) \(year)"
        }
        return "\(firstMonth) – \(lastMonth) \(year)"
    }

    private var isCurrentWeek: Bool { weekOffset == 0 }

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            header
            weekStrip
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { changeWeek(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(monthLabel)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
                if !isCurrentWeek {
                    Button {
                        jumpToToday()
                    } label: {
                        Text("Heute")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.accentColor))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCurrentWeek)

            Spacer()

            Button { changeWeek(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isFutureBlocked ? .tertiary : .secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
            }
            .buttonStyle(.plain)
            .disabled(isFutureBlocked)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    date: day,
                    isSelected: calendar.isSameDay(day, selectedDate),
                    isToday: calendar.isSameDay(day, .now),
                    isFuture: day > calendar.startOfDay()
                )
                .onTapGesture {
                    guard day <= calendar.startOfDay() else { return }
                    Haptics.selection()
                    selectedDate = day
                }
            }
        }
        .offset(x: dragOffset)
        .gesture(swipeGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: weekOffset)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width * 0.3
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    changeWeek(by: -1)
                } else if value.translation.width < -threshold && !isFutureBlocked {
                    changeWeek(by: 1)
                }
            }
    }

    // MARK: - Actions

    private func changeWeek(by delta: Int) {
        Haptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            weekOffset += delta
        }
        // Wenn die ausgewählte Date nicht in der neuen Woche liegt, auf den
        // nähesten Tag in der neuen Woche setzen
        let newDays = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart(for: weekOffset + delta - delta))
        }
        // Setze auf den gleichen Wochentag in der neuen Woche
        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
        if let matchingDay = days.first(where: { calendar.component(.weekday, from: $0) == selectedWeekday }) {
            let capped = min(matchingDay, calendar.startOfDay())
            selectedDate = capped
        }
    }

    private func jumpToToday() {
        Haptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            weekOffset = 0
            selectedDate = calendar.startOfDay()
        }
    }

    private func weekStart(for offset: Int) -> Date {
        let today = calendar.startOfDay()
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) ?? currentWeekStart
    }

    /// Verhindere Navigation in die Zukunft.
    private var isFutureBlocked: Bool {
        guard let lastDay = days.last else { return true }
        return lastDay >= calendar.startOfDay()
    }

    // MARK: - Day Cell

    private struct DayCell: View {
        let date: Date
        let isSelected: Bool
        let isToday: Bool
        let isFuture: Bool

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
                    .foregroundStyle(foregroundPrimary ? .white : .secondary)
                Text(dayNumber)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                Circle()
                    .fill(isToday ? (isSelected ? Color.white : Color.accentColor) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            )
            .opacity(isFuture ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(isFuture ? "Zukünftiges Datum" : "")
        }

        private var foregroundPrimary: Bool { isSelected && !isFuture }
    }
}
