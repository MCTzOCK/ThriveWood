//
//  PRRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 19.05.26.
//
import SwiftUI


struct PRRow: View {
    let exercise: Exercise
    let topSet: SetEntry

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: exercise.iconSystemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Text(exercise.trackingType.label)
                    if let date = topSet.completedAt {
                        Text("·")
                        Text(date, format: .dateTime.day().month(.abbreviated))
                    }
                }
                .font(.caption)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.caption2)
                Text(topSet.summaryText)
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.orange.opacity(0.15)))
            .foregroundStyle(.orange)
        }
        .padding(.vertical, 2)
    }
}
