//
//  HabitRowView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let streak: Int
    let progress: (value: Double, target: Double, progress: Double)?
    let onToggle: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(Theme.Typography.headline)
                    .strikethrough(isCompleted && !habit.isMeasurable, color: .secondary)
                    .foregroundStyle(isCompleted && !habit.isMeasurable ? .secondary : .primary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.s) {
                    pointsBadge
                    if streak > 0 { streakBadge }
                    if habit.isMeasurable, let p = progress {
                        measurableLabel(p)
                    }
                }
            }
            Spacer(minLength: 0)

            if habit.isMeasurable {
                measurableControls
            } else {
                simpleToggleButton
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(habit.title)
        .accessibilityValue(accessibilityValueText)
    }

    private var settingsButton: some View {
        Button {
            onEdit()
        } label: {
            Image(systemName: "ellipsis")
                .font(Theme.Typography.caption.weight(.bold))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(.tertiarySystemFill)))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var iconBadge: some View {
        ZStack {
            if habit.isMeasurable, let p = progress {
                Circle()
                    .stroke(habit.color.color.opacity(0.15), lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: p.progress)
                    .stroke(habit.color.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: p.progress)
            }
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(habit.color.color)
                .frame(width: habit.isMeasurable ? 36 : 44,
                       height: habit.isMeasurable ? 36 : 44)
            Image(systemName: habit.iconSystemName)
                .font(habit.isMeasurable ? Theme.Typography.callout.weight(.semibold) : Theme.Typography.title3.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private func measurableLabel(_ p: (value: Double, target: Double, progress: Double)) -> some View {
        HStack(spacing: 2) {
            Text(formatValue(p.value))
                .font(Theme.Typography.caption.weight(.bold).monospacedDigit())
            Text("/ \(formatValue(p.target)) \(abbreviatedUnit)")
                .font(Theme.Typography.caption)
        }
        .foregroundStyle(p.progress >= 1 ? .primary : .secondary)
    }

    private var abbreviatedUnit: String {
        switch habit.unitLabel {
        case "Milliliter": "ml"
        case "Liter": "l"
        case "Gläser": "Gl."
        case "Schritte": "Sch."
        case "Minuten": "min"
        case "Stunden": "Std"
        case "Seiten": "S."
        case "Kapseln": "Kap."
        default: habit.unitLabel
        }
    }

    private var measurableControls: some View {
        HStack(spacing: 8) {
            settingsButton
            Button {
                onDecrement()
            } label: {
                Image(systemName: "minus")
                    .font(Theme.Typography.caption.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(BounceButtonStyle())
            .disabled(progress?.value == 0 || progress == nil)

            Button {
                onIncrement()
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.accentColor : habit.color.color)
                        .frame(width: 34, height: 34)
                    Image(systemName: isCompleted ? "checkmark" : "plus")
                        .font(Theme.Typography.callout.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(BounceButtonStyle())
        }
    }

    private var simpleToggleButton: some View {
        HStack(spacing: 8) {
            settingsButton
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(isCompleted ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 34, height: 34)
                    if isCompleted {
                        Circle().fill(Color.accentColor).frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(Theme.Typography.body.weight(.bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(BounceButtonStyle())
            .animation(Theme.Animation.spring, value: isCompleted)
        }
    }

    private var pointsBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "leaf.fill").font(Theme.Typography.caption2)
            Text("\(habit.points.rawValue)").font(Theme.Typography.caption.weight(.semibold))
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
    }

    private var streakBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill").font(Theme.Typography.caption2)
            Text("\(streak)").font(Theme.Typography.caption.weight(.semibold))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.orange.opacity(0.12)))
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }

    private var accessibilityValueText: String {
        if habit.isMeasurable, let p = progress {
            "\(formatValue(p.value)) von \(formatValue(p.target)) \(habit.unitLabel)"
        } else {
            isCompleted ? "Erledigt" : "Offen"
        }
    }
}
