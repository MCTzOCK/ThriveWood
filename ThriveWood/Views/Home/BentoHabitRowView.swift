//
//  BentoHabitRowView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.08.26.
//

import SwiftUI

struct BentoHabitRowView: View {
    @Environment(\.bentoTheme) private var theme

    let habit: Habit
    let isCompleted: Bool
    let streak: Int
    let progress: (value: Double, target: Double, progress: Double)?
    let onToggle: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onEdit: () -> Void
    /// `false` blendet den Bearbeiten-Button (Ellipsis) aus — z. B. in der
    /// Routine-Ansicht, wo Habits nicht editierbar sind.
    var showsEditButton: Bool = true

    var body: some View {
        BentoCard(
            background: isCompleted ? habit.color.color.opacity(0.55) : habit.color.color,
            foreground: .white,
            style: .flat,
            padding: .md,
            radius: .large
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                headerRow
                titleSection
                Spacer(minLength: 0)
                bottomRow
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        }
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { onEdit() }
            Button("Archivieren", systemImage: "archivebox", role: .destructive) { onEdit() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(habit.title)
        .accessibilityValue(accessibilityValueText)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            iconBadge
            Spacer()
            if showsEditButton {
                editButton
            }
        }
    }

    private var iconBadge: some View {
        ZStack {
            if habit.isMeasurable, let p = progress {
                Circle()
                    .stroke(theme.colors.background.opacity(0.25), lineWidth: 3)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: p.progress)
                    .stroke(theme.colors.background, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: p.progress)
            }

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.colors.background.opacity(0.2))
                .frame(width: habit.isMeasurable ? 32 : 36, height: habit.isMeasurable ? 32 : 36)

            Image(systemName: habit.iconSystemName)
                .font(habit.isMeasurable
                    ? .system(size: 14, weight: .bold)
                    : .system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.background)
        }
    }

    private var editButton: some View {
        BentoIconButton(systemImage: "ellipsis", accessibilityLabel: Text("Bearbeiten"), variant: .secondary, size: .small) {
            onEdit()
        }/*
        Button {
            onEdit()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
          */
    }

    // MARK: - Title

    @ViewBuilder
    private var titleSection: some View {
        Text(habit.title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(theme.colors.background)
            .strikethrough(isCompleted && !habit.isMeasurable, color: theme.colors.background.opacity(0.7))
            .lineLimit(2)
            .multilineTextAlignment(.leading)

        if habit.isMeasurable, let p = progress {
            BentoText(
                "\(formatValue(p.value)) / \(formatValue(p.target)) \(abbreviatedUnit)",
                style: .caption,
                color: theme.colors.background.opacity(0.85)
            )
        }
    }

    // MARK: - Bottom

    private var bottomRow: some View {
        HStack(spacing: 6) {
            BentoBadge(
                Text("\(habit.points.rawValue)"),
                tone: .neutral,
                systemImage: "leaf.fill"
            )
            if streak > 0 {
                BentoBadge(
                    Text("\(streak)"),
                    tone: .warning,
                    systemImage: "flame.fill"
                )
            }

            Spacer()

            if habit.isMeasurable {
                measurableControls
            } else {
                toggleButton
            }
        }
    }

    // MARK: - Toggle

    private var toggleButton: some View {
        Button(action: onToggle) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(theme.colors.background)
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(habit.color.color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .strokeBorder(theme.colors.background.opacity(0.6), lineWidth: 2)
                        .frame(width: 32, height: 32)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isCompleted)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Measurable

    private var measurableControls: some View {
        HStack(spacing: 6) {
            Button {
                onDecrement()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(theme.colors.background.opacity(0.2)))
            }
            .buttonStyle(BounceButtonStyle())
            .disabled(progress?.value == 0 || progress == nil)

            Button {
                onIncrement()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.colors.background)
                        .frame(width: 32, height: 32)
                    Image(systemName: isCompleted ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(habit.color.color)
                }
            }
            .buttonStyle(BounceButtonStyle())
        }
    }

    // MARK: - Helpers

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
