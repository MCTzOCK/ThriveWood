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
                    .font(.headline)
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
            Image(systemName: "gear")
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.tertiaryFill))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon

    private var iconBadge: some View {
        ZStack {
            if habit.isMeasurable, let p = progress {
                // Progress-Ring als Icon-Rahmen
                Circle()
                    .stroke(habit.color.color.opacity(0.15), lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: p.progress)
                    .stroke(habit.color.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: p.progress)
            }
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(habit.color.gradient)
                .frame(width: habit.isMeasurable ? 36 : 44,
                       height: habit.isMeasurable ? 36 : 44)
            Image(systemName: habit.iconSystemName)
                .font(habit.isMeasurable ? .callout.weight(.semibold) : .title3.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Measurable Label

    private func measurableLabel(_ p: (value: Double, target: Double, progress: Double)) -> some View {
        HStack(spacing: 2) {
            Text(formatValue(p.value))
                .font(.caption.weight(.bold).monospacedDigit())
            Text("/ \(formatValue(p.target)) \(habit.unitLabel)")
                .font(.caption)
        }
        .foregroundStyle(p.progress >= 1 ? .primary : .secondary)
    }

    // MARK: - Measurable Controls (+ / - Buttons)

    private var measurableControls: some View {
        HStack(spacing: 8) {
            settingsButton
            Button {
                onDecrement()
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.tertiaryFill))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(progress?.value == 0 || progress == nil)

            Button {
                onIncrement()
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.accentColor : habit.color.color)
                        .frame(width: 34, height: 34)
                    Image(systemName: isCompleted ? "checkmark" : "plus")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Simple Toggle

    private var simpleToggleButton: some View {
        HStack(spacing: 8) {
            settingsButton
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(isCompleted ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 30, height: 30)
                    if isCompleted {
                        Circle().fill(Color.accentColor).frame(width: 30, height: 30)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        }
    }

    // MARK: - Badges (unverändert)

    private var pointsBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "leaf.fill").font(.caption2)
            Text("\(habit.points.rawValue)").font(.caption.weight(.semibold))
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
    }

    private var streakBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill").font(.caption2)
            Text("\(streak)").font(.caption.weight(.semibold))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.orange.opacity(0.12)))
    }

    // MARK: - Helpers

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
