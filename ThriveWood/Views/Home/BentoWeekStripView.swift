//
//  BentoWeekStripView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.08.26.
//

import SwiftUI

struct BentoWeekStripView: View {
    @Binding var selectedDate: Date
    @Environment(\.bentoTheme) private var theme
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
        VStack(spacing: theme.spacing.sm) {
            header
            weekStrip
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            BentoIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: Text("Vorherige Woche"),
                variant: .secondary,
                size: .small
            ) {
                changeWeek(by: -1)
            }

            Spacer()

            VStack(spacing: theme.spacing.xxs) {
                BentoText("\(monthLabel)", style: .callout)
                    .contentTransition(.numericText())

                if !isCurrentWeek {
                    Button {
                        jumpToToday()
                    } label: {
                        BentoBadge(Text("Heute"), tone: .accent)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(theme.motion.snappy, value: isCurrentWeek)

            Spacer()

            BentoIconButton(
                systemImage: "chevron.right",
                accessibilityLabel: Text("Nächste Woche"),
                variant: .secondary,
                size: .small
            ) {
                changeWeek(by: 1)
            }
            .opacity(isFutureBlocked ? 0.4 : 1)
            .disabled(isFutureBlocked)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(days, id: \.self) { day in
                BentoDayCell(
                    date: day,
                    isSelected: calendar.isSameDay(day, selectedDate),
                    isToday: calendar.isSameDay(day, .now),
                    isFuture: day > calendar.startOfDay(),
                    theme: theme
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
        .animation(theme.motion.snappy, value: weekOffset)
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
        withAnimation(theme.motion.snappy) {
            weekOffset += delta
        }
        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
        if let matchingDay = days.first(where: { calendar.component(.weekday, from: $0) == selectedWeekday }) {
            let capped = min(matchingDay, calendar.startOfDay())
            selectedDate = capped
        }
    }

    private func jumpToToday() {
        Haptics.selection()
        withAnimation(theme.motion.snappy) {
            weekOffset = 0
            selectedDate = calendar.startOfDay()
        }
    }

    /// Verhindere Navigation in die Zukunft.
    private var isFutureBlocked: Bool {
        guard let lastDay = days.last else { return true }
        return lastDay >= calendar.startOfDay()
    }
}

// MARK: - Day Cell

private struct BentoDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let theme: BentoTheme

    private var weekdayShort: String {
        date.formatted(.dateTime.weekday(.short))
    }
    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    private var cellBackground: Color {
        if isSelected { return theme.colors.accent }
        return theme.colors.surfaceSecondary
    }

    private var foregroundColor: Color {
        if isSelected { return theme.colors.onAccent }
        return theme.colors.onSurface
    }

    var body: some View {
        VStack(spacing: theme.spacing.xxs) {
            BentoText(verbatim: weekdayShort, style: .caption, color: foregroundColor)
            BentoText(verbatim: dayNumber, style: .headline, color: foregroundColor)
            Circle()
                .fill(isToday ? (isSelected ? theme.colors.onAccent : theme.colors.accent) : .clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.sm)
        .background(
            RoundedRectangle(
                cornerRadius: theme.radii.medium,
                style: .continuous
            )
            .fill(cellBackground)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(
                    cornerRadius: theme.radii.medium,
                    style: .continuous
                )
                .strokeBorder(theme.colors.outline, lineWidth: theme.borders.thin)
            }
        }
        .opacity(isFuture ? 0.5 : 1)
        .animation(theme.motion.fast, value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isFuture ? Text("Zukünftiges Datum") : Text(""))
    }
}
