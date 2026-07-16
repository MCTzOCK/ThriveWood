//
//  ActivePlanCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//

import SwiftUI

struct ActivePlanCard: View {
    let plan: TrainingsPlan
    let onTap: () -> Void

    private var planColor: Color {
        Color(hex: plan.color) ?? .green
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.s) {
                    Circle()
                        .fill(planColor)
                        .frame(width: 12, height: 12)

                    Text(plan.name)
                        .font(Theme.Typography.headline)

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(Theme.Typography.body)
                }

                if !plan.details.isEmpty {
                    Text(plan.details)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: Theme.Spacing.l) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(Theme.Typography.caption2)
                        Text("\(plan.trainingDaysPerWeek)x/Woche")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(Theme.Typography.caption2)
                        Text("\(plan.totalExercises)")
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(plan.sortedDays) { day in
                        VStack(spacing: 4) {
                            Text(day.weekday.shortLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)

                            Circle()
                                .fill(dayColor(day))
                                .frame(width: 8, height: 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(planColor.opacity(0.06))
            )
        }
        .buttonStyle(PressScaleStyle())
    }

    private func dayColor(_ day: TrainingsPlanDay) -> Color {
        if day.isRestDay {
            return .gray.opacity(0.3)
        } else if day.workout != nil {
            return planColor
        } else {
            return .gray.opacity(0.15)
        }
    }
}
