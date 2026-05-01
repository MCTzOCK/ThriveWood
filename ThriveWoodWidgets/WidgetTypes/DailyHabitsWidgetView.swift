//
//  DailyHabitsWidgetView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//



import SwiftUI
import WidgetKit
import AppIntents

struct DailyHabitsWidgetView: View {
    let entry: DailyHabitsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        case .systemLarge:  largeView
        default:            smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "leaf.fill").foregroundStyle(.green)
                Text("Heute").font(.headline)
            }
            Text("\(entry.pointsEarned)/\(entry.pointsGoal)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text("Punkte")
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            ProgressView(value: min(1, Double(entry.pointsEarned) / max(1, Double(entry.pointsGoal))))
                .tint(.green)
        }
        .padding()
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Links: Punkte
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "leaf.fill").foregroundStyle(.green)
                    Text("Heute").font(.headline)
                }
                Text("\(entry.pointsEarned)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("von \(entry.pointsGoal) Punkten")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rechts: Habit-Liste
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.habits.prefix(4), id: \.habit.id) { item in
                    Button(intent: ToggleHabitIntent(habitID: item.habit.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.completed ? .green : .secondary)
                                .contentTransition(.symbolEffect(.replace))
                            Text(item.habit.title)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(item.completed)
                                .foregroundStyle(item.completed ? .secondary : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    // MARK: Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundStyle(.green)
                        Text("Heute").font(.headline)
                    }
                    Text("\(entry.pointsEarned)/\(entry.pointsGoal) Punkte")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.habits.filter(\.completed).count)/\(entry.habits.count)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.green)
            }

            ProgressView(value: min(1, Double(entry.pointsEarned) / max(1, Double(entry.pointsGoal))))
                .tint(.green)

            ForEach(entry.habits.prefix(6), id: \.habit.id) { item in
                Button(intent: ToggleHabitIntent(habitID: item.habit.id)) {
                    HStack(spacing: 10) {
                        Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.completed ? .green : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.habit.title).font(.subheadline).lineLimit(1)
                                .foregroundStyle(item.completed ? .secondary : .primary)
                            if item.streak > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                                    Text("\(item.streak) Tage").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        if item.habit.isMeasurable {
                            Text("\(Int(item.progress * 100))%")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(item.completed ? .green : .secondary)
                        }
                        Text("+\(item.habit.pointsRaw)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}
