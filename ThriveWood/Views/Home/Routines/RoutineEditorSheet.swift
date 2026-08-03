//
//  RoutineEditorSheet.swift
//  ThriveWood
//
//  Erstellen / Bearbeiten einer HabitRoutine. Multiselect der aktiven
//  Habits (geordnete habitIDs), Name, Icon, Farbe.
//

import SwiftUI

struct RoutineEditorSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    let routine: HabitRoutine?
    var onSaved: () -> Void = {}

    @State private var title: String = ""
    @State private var icon: String = "sun.max.fill"
    @State private var color: HabitColor = .orange
    @State private var selectedHabitIDs: [UUID] = []
    @State private var availableHabits: [Habit] = []
    @State private var errors = ErrorState()
    @State private var didHydrate = false

    private var isEditing: Bool { routine != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && !selectedHabitIDs.isEmpty }

    private let iconOptions: [String] = [
        "sun.max.fill", "moon.stars.fill", "cup.and.saucer.fill",
        "figure.walk", "leaf.fill", "book.fill",
        "dumbbell.fill", "drop.fill", "heart.fill",
        "brain.head.profile.fill", "sparkles"
    ]

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: theme.spacing.lg) {
                detailsCard
                habitsCard
                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text(isEditing ? "Speichern" : "Routine erstellen"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                save()
            }
            .disabled(!isValid)
        }
        .errorAlert(errors)
        .onAppear { hydrate() }
    }

    // MARK: - Details

    private var detailsCard: some View {
        BentoCard(style: .outlined, padding: .lg, radius: .large) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(title: Text("Details"))

                BentoTextField(
                    label: Text("Name"),
                    text: $title,
                    prompt: Text("z. B. Morgenroutine"),
                    leadingSystemImage: "textformat",
                    required: true,
                    maximumLength: 40
                )

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    BentoText(verbatim: "Symbol", style: .caption, color: theme.colors.onSurfaceMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(iconOptions, id: \.self) { name in
                                Button {
                                    Haptics.selection()
                                    icon = name
                                } label: {
                                    Image(systemName: name)
                                        .font(.body)
                                        .frame(width: 44, height: 44)
                                        .foregroundStyle(icon == name ? theme.colors.onAccent : theme.colors.onSurface)
                                        .background(
                                            RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                                                .fill(icon == name ? color.color : theme.colors.surfaceSecondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                                                .stroke(icon == name ? Color.clear : theme.colors.outlineSubtle, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    BentoText(verbatim: "Farbe", style: .caption, color: theme.colors.onSurfaceMuted)
                    BentoFlowLayout(spacing: theme.spacing.xs) {
                        ForEach(HabitColor.allCases) { c in
                            Circle()
                                .fill(c.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().strokeBorder(.white, lineWidth: color == c ? 3 : 0)
                                )
                                .scaleEffect(color == c ? 1.1 : 1)
                                .onTapGesture {
                                    Haptics.selection()
                                    color = c
                                }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Habits

    private var habitsCard: some View {
        BentoCard(style: .outlined, padding: .lg, radius: .large) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(
                    title: Text("Habits"),
                    subtitle: Text("\(selectedHabitIDs.count) ausgewählt")
                )

                if availableHabits.isEmpty {
                    BentoEmptyState(
                        systemImage: "leaf.circle.fill",
                        title: Text("Keine Habits verfügbar"),
                        message: Text("Erstelle zuerst Habits, bevor du eine Routine anlegst.")
                    )
                    .padding(.vertical, theme.spacing.sm)
                } else {
                    VStack(spacing: theme.spacing.xs) {
                        ForEach(availableHabits) { habit in
                            habitPickerRow(habit)
                        }
                    }
                }

                if !selectedHabitIDs.isEmpty {
                    BentoDivider()
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        BentoText(verbatim: "REIHENFOLGE", style: .overline, color: theme.colors.onSurfaceMuted)
                        ForEach(Array(selectedHabitIDs.enumerated()), id: \.element) { index, id in
                            if let habit = availableHabits.first(where: { $0.id == id }) {
                                HStack(spacing: theme.spacing.sm) {
                                    Text(verbatim: "\(index + 1)")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(theme.colors.onSurfaceMuted)
                                        .frame(width: 20)
                                    Image(systemName: habit.iconSystemName)
                                        .foregroundStyle(habit.color.color)
                                    BentoText(verbatim: habit.title, style: .body)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func habitPickerRow(_ habit: Habit) -> some View {
        let isSelected = selectedHabitIDs.contains(habit.id)
        Button {
            Haptics.selection()
            if isSelected {
                selectedHabitIDs.removeAll { $0 == habit.id }
            } else {
                selectedHabitIDs.append(habit.id)
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.colors.accent : theme.colors.surfaceSecondary)
                        .frame(width: 28, height: 28)
                    Image(systemName: isSelected ? "checkmark" : "")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(theme.colors.onAccent)
                }
                Image(systemName: habit.iconSystemName)
                    .foregroundStyle(habit.color.color)
                    .frame(width: 24)
                BentoText(verbatim: habit.title, style: .body)
                Spacer()
            }
            .padding(.vertical, theme.spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func hydrate() {
        guard !didHydrate else { return }
        didHydrate = true
        availableHabits = (try? env.habitRepo.fetchAll(includeArchived: false)) ?? []
        if let routine {
            title = routine.title
            icon = routine.iconSystemName
            color = routine.color
            selectedHabitIDs = routine.habitIDs
        }
    }

    private func save() {
        do {
            if let routine {
                routine.title = title.trimmingCharacters(in: .whitespaces)
                routine.iconSystemName = icon
                routine.color = color
                routine.habitIDs = selectedHabitIDs
                try env.routineRepo.update(routine)
            } else {
                let count = (try? env.routineRepo.fetchAll().count) ?? 0
                let new = HabitRoutine(
                    title: title.trimmingCharacters(in: .whitespaces),
                    iconSystemName: icon,
                    color: color,
                    habitIDs: selectedHabitIDs,
                    sortOrder: count
                )
                try env.routineRepo.create(new)
            }
            Haptics.success()
            onSaved()
            dismiss()
        } catch {
            errors.show(error)
        }
    }
}
