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
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.accentColor.opacity(0.25), radius: 4, x: 0, y: 2)
                Image(systemName: "calendar")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workout?.name ?? "Freies Training")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration)
                    .font(Theme.Typography.subheadline.weight(.semibold).monospacedDigit())
                Text("\(Int(totalVolume)) kg")
                    .font(Theme.Typography.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Theme.Shadow.card, radius: 8, x: 0, y: 2)
    }
}
