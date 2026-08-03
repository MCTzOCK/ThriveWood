//
//  ExerciseCardV3.swift
//  ThriveWood
//
//  Eine Übungskarte für ActiveSessionViewV3. Header mit Progress-Ring und
//  Ellipsis-Menü (Details / Nach oben / Nach unten / Entfernen), optionales
//  Empfehlungs-Badge, Set-Liste, Footer mit + Satz / Duplikat.
//

import SwiftUI

struct ExerciseCardV3: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let topSetSummary: String?
    let accentColor: Color
    var recommendation: SetRecommendation?
    var aiService: AIService?

    let onAddSet: () -> Void
    let onDuplicate: () -> Void
    let onComplete: (SetEntry) -> Void
    let onDelete: (SetEntry) -> Void
    let onShowDetails: () -> Void
    let onStartTracker: (SetEntry) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onRemove: () -> Void
    let onApplyRecommendation: (() -> Void)?

    @Environment(\.bentoTheme) private var theme

    private var completed: Int { sets.filter(\.isCompleted).count }
    private var allDone: Bool { completed == sets.count && !sets.isEmpty }
    private var progress: Double { sets.isEmpty ? 0 : Double(completed) / Double(sets.count) }

    var body: some View {
        BentoCard(style: .outlined, padding: .none, radius: .large) {
            VStack(spacing: 0) {
                cardHeader
                if let recommendation, let aiService, let onApplyRecommendation {
                    SetRecommendationBadge(
                        recommendation: recommendation,
                        unit: unit,
                        exerciseName: exercise.name,
                        aiService: aiService,
                        onApply: onApplyRecommendation
                    )
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.bottom, theme.spacing.sm)
                }
                if let topSetSummary {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(verbatim: "Top: \(topSetSummary)")
                            .font(.caption2)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Spacer()
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.bottom, theme.spacing.sm)
                }
                Divider().opacity(0.5)
                setList
                Divider().opacity(0.5)
                footer
            }
        }
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: exercise.iconSystemName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.colors.onSurface)
                    .lineLimit(1)
                Text(verbatim: "\(completed) / \(sets.count) Sätzen")
                    .font(.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }

            Spacer()

            // Progress-Ring
            BentoProgressRing(
                progress: progress,
                tone: allDone ? .success : .accent,
                size: 36,
                lineWidth: 4
            )

            ellipsisMenu
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture { onShowDetails() }
    }

    private var ellipsisMenu: some View {
        Menu {
            Button {
                onShowDetails()
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            if let onMoveUp {
                Button {
                    onMoveUp()
                } label: {
                    Label("Nach oben", systemImage: "arrow.up")
                }
            }
            if let onMoveDown {
                Button {
                    onMoveDown()
                } label: {
                    Label("Nach unten", systemImage: "arrow.down")
                }
            }
            Divider()
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Übung entfernen", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Set List

    private var setList: some View {
        VStack(spacing: 0) {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                SetRowV3(
                    index: index + 1,
                    set_: set,
                    unit: unit,
                    accentColor: accentColor,
                    onTap: { onComplete(set) },
                    onDelete: { onDelete(set) },
                    onStartTracker: set.exercise?.trackingType == .duration || set.exercise?.trackingType == .distanceDuration
                        ? { onStartTracker(set) }
                        : nil
                )
                if index < sets.count - 1 {
                    Divider().opacity(0.3).padding(.horizontal, theme.spacing.md)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: theme.spacing.sm) {
            BentoButton(
                Text("+ Satz"),
                systemImage: "plus",
                variant: .secondary,
                size: .small,
                expands: true
            ) {
                onAddSet()
            }
            BentoButton(
                Text("Duplikat"),
                systemImage: "plus.square.on.square",
                variant: .ghost,
                size: .small,
                expands: true
            ) {
                onDuplicate()
            }
        }
        .padding(theme.spacing.md)
    }
}
