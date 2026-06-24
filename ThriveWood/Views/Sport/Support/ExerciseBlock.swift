//
//  ExerciseBlock.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct ExerciseBlock: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let topSet: SetEntry?
    let recommendation: SetRecommendation?
    let isCollapsed: Bool
    let aiService: AIService?
    let onAddSet: () -> Void
    let onComplete: (SetEntry) -> Void
    let onDelete: (SetEntry) -> Void
    let removeExercise: () -> Void
    let showDetails: () -> Void
    var onStartTracker: ((SetEntry) -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var onToggleCollapse: (() -> Void)? = nil
    var onApplyRecommendation: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {

                if let onToggleCollapse {
                    Button(action: onToggleCollapse) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: exercise.iconSystemName)
                    .foregroundStyle(.tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))
                Text(exercise.name).font(.headline)
                Spacer()
                Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button(action: showDetails) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                
                Button(action: removeExercise) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)

                if onMoveUp != nil || onMoveDown != nil {
                    VStack(spacing: 2) {
                        if let onMoveUp {
                            Button(action: onMoveUp) {
                                Image(systemName: "chevron.up")
                                    .font(.caption.weight(.bold))
                                    .frame(width: 24, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        if let onMoveDown {
                            Button(action: onMoveDown) {
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .frame(width: 24, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !isCollapsed {
                if let topSet, topSet.volumeValue > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                        Text(topSet.summaryText)
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
                }

                if let recommendation, let aiService {
                    SetRecommendationBadge(
                        recommendation: recommendation,
                        unit: unit,
                        exerciseName: exercise.name,
                        aiService: aiService,
                        onApply: {
                            Haptics.selection()
                            onApplyRecommendation?()
                        }
                    )
                }

                HStack {
                    Text("#").frame(width: 24, alignment: .leading)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

                ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                    SetRow(index: idx + 1, set_: set, unit: unit, onComplete: { onComplete(set) }, onDelete: { onDelete(set) }, onStartTracker: onStartTracker.map { _ in { onStartTracker?(set) } })
                }

                Button(action: onAddSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Satz hinzufügen")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .fill(Color.accentColor.opacity(0.10))
                    )
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
