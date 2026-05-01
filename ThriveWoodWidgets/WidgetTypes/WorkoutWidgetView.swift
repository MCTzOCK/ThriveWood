//
//  WorkoutWidgetView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.05.26.
//


import SwiftUI
import WidgetKit
import AppIntents

struct WorkoutWidgetView: View {
    let entry: WorkoutEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundStyle(.blue)
                Text("Training").font(.headline)
            }
            if let last = entry.sessions.first {
                Text(last.name).font(.caption.weight(.semibold)).lineLimit(1)
                Text(last.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.caption2).foregroundStyle(.secondary)
                Text("\(last.duration / 60) min")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.blue)
            } else {
                Text("Noch kein Workout")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundStyle(.blue)
                Text("Letzte Trainings").font(.headline)
                Spacer()
            }
            if entry.sessions.isEmpty {
                Text("Noch keine Workouts absolviert.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(entry.sessions.prefix(3).enumerated()), id: \.offset) { _, s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name).font(.caption.weight(.semibold)).lineLimit(1)
                            Text(s.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(s.duration / 60)m")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(.blue)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}
