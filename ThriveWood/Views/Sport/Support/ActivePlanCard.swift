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

                    Image(systemName: plan.isRotationPlan ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill")
                        .foregroundStyle(plan.isRotationPlan ? planColor : .green)
                        .font(Theme.Typography.body)
                        .symbolEffect(.pulse, options: .repeating)
                }

                if !plan.details.isEmpty {
                    Text(plan.details)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: Theme.Spacing.l) {
                    HStack(spacing: 4) {
                        Image(systemName: plan.isRotationPlan ? "arrow.triangle.2.circlepath" : "calendar")
                            .font(Theme.Typography.caption2)
                        Text(plan.isRotationPlan ? "Rotation \(plan.rotationCount)x" : "\(plan.trainingDaysPerWeek)x/Woche")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(Theme.Typography.caption2)
                        Text("\(plan.totalExercises)")
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

                if plan.isRotationPlan {
                    rotationDots
                } else {
                    weekDots
                }
            }
            .padding(Theme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .fill(planColor.opacity(0.06))
            )
            .shadow(color: planColor.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(PressScaleStyle())
    }

    private var rotationDots: some View {
        HStack(spacing: 4) {
            ForEach(plan.rotationSequence) { day in
                let idx = plan.rotationSequence.firstIndex { $0.id == day.id } ?? 0
                let isCurrent = plan.currentRotationIndex % max(plan.rotationCount, 1) == idx
                VStack(spacing: 4) {
                    Text(day.label.isEmpty ? String(Character(UnicodeScalar(65 + idx)!)) : day.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(slotColor(day, isCurrent: isCurrent))
                        .frame(width: 8, height: 8)
                        .overlay(
                            isCurrent ? Circle().strokeBorder(planColor, lineWidth: 1.5) : nil
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekDots: some View {
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
    }

    private func slotColor(_ day: TrainingsPlanDay, isCurrent: Bool) -> Color {
        if day.workout != nil {
            return planColor
        }
        return .gray.opacity(0.15)
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
