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
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.s) {
                    pointsBadge
                    if streak > 0 { streakBadge }
                    if !habit.details.isEmpty {
                        Text(habit.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
            toggleButton
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(habit.title)
        .accessibilityValue(isCompleted ? "Erledigt" : "Offen")
        .accessibilityAddTraits(.isButton)
        .onTapGesture { onToggle() }
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                .fill(habit.color.gradient)
                .frame(width: 44, height: 44)
            Image(systemName: habit.iconSystemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var pointsBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "leaf.fill").font(.caption2)
            Text("\(habit.points.rawValue)").font(.caption.weight(.semibold))
        }
        .foregroundStyle(.green)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.green.opacity(0.12)))
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

    private var toggleButton: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .strokeBorder(isCompleted ? Color.green : Color.secondary.opacity(0.4), lineWidth: 2)
                    .frame(width: 30, height: 30)
                if isCompleted {
                    Circle().fill(Color.green).frame(width: 30, height: 30)
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
