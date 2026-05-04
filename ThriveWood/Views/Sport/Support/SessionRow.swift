//
//  SessionRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct SessionRow: View {
    let session: WorkoutSession
    
    private var duration: String {
        guard let sec = session.durationSeconds else { return "–" }
        return "\(sec / 60) min"
    }
    private var totalVolume: Double {
        session.sets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "calendar")
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workout?.name ?? "Freies Training")
                    .font(.subheadline.weight(.semibold))
                Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration).font(.subheadline.weight(.semibold))
                Text("\(Int(totalVolume)) kg")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
