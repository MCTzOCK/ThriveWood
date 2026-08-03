//
//  TrainingsPlanRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//
import SwiftUI

struct TrainingsPlanRow: View {
    let plan: TrainingsPlan
    let onTap: () -> Void

    private var planColor: Color {
        Color(hex: plan.color) ?? .blue
    }

    var body: some View {
        Button(action: onTap) {
            BentoCard(style: .outlined, padding: .md) {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                            .fill(planColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: plan.isRotationPlan ? "arrow.triangle.2.circlepath" : "calendar")
                            .font(Theme.Typography.body)
                            .foregroundStyle(planColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Text(plan.name)
                                .font(Theme.Typography.subheadline.weight(.semibold))
                                .lineLimit(1)

                            if plan.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(.green)
                                    .symbolEffect(.bounce, value: plan.isActive)
                            }
                        }

                        HStack(spacing: Theme.Spacing.m) {
                            if plan.isRotationPlan {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(Theme.Typography.caption)
                                    Text("Nächstes: \(plan.nextRotationLabel)")
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(Theme.Typography.caption)
                                    Text("\(plan.trainingDaysPerWeek)x/Woche")
                                }
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(Theme.Typography.caption)
                                Text("\(plan.totalExercises)")
                                    .contentTransition(.numericText())
                            }
                        }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }
}
