//
//  HabitStreakWidgetView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import SwiftUI
import WidgetKit
import AppIntents

struct HabitStreakWidgetView: View {
    let entry: HabitStreakEntry
    @Environment(\.widgetFamily) var family

    private var habitColor: Color {
        HabitColor(rawValue: entry.habitColor)?.color ?? .green
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(habitColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: entry.completedToday ? 1 : entry.progress)
                    .stroke(habitColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Image(systemName: entry.habitIcon)
                    .font(.title3)
                    .foregroundStyle(habitColor)
            }
            Text(entry.habitTitle).font(.caption.weight(.semibold)).lineLimit(1)
            HStack(spacing: 3) {
                Image(systemName: "flame.fill").font(.caption).foregroundStyle(.orange)
                Text("\(entry.streak)")
                    .font(.title3.bold().monospacedDigit())
            }
        }
        .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(habitColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: entry.completedToday ? 1 : entry.progress)
                    .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Image(systemName: entry.habitIcon).font(.title2).foregroundStyle(habitColor)
                    if entry.completedToday {
                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.green)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.habitTitle).font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(entry.streak) Tage Streak")
                        .font(.subheadline.weight(.semibold))
                }
                Text(entry.completedToday ? "Heute erledigt ✓" : "Noch offen")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}
