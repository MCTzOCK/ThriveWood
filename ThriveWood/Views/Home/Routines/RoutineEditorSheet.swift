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
    /// Routine-Zielwerte pro messbarem Habit (UUID -> Wert).
    @State private var habitTargets: [UUID: Double] = [:]
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
                                    if habit.isMeasurable, let target = habitTargets[habit.id], target > 0 {
                                        BentoBadge(
                                            Text(verbatim: "\(formatValue(target)) \(habit.unitLabel)".trimmingCharacters(in: .whitespaces)),
                                            tone: .neutral
                                        )
                                    }
                                    reorderButtons(for: index, total: selectedHabitIDs.count)
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
        VStack(spacing: 0) {
            Button {
                Haptics.selection()
                if isSelected {
                    selectedHabitIDs.removeAll { $0 == habit.id }
                    habitTargets.removeValue(forKey: habit.id)
                } else {
                    selectedHabitIDs.append(habit.id)
                    // Messbare Habits starten per Default beim Tagesziel als Vorschlag.
                    if habit.isMeasurable, habitTargets[habit.id] == nil {
                        habitTargets[habit.id] = habit.targetValue
                    }
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
                    VStack(alignment: .leading, spacing: 2) {
                        BentoText(verbatim: habit.title, style: .body)
                        if habit.isMeasurable {
                            BentoText(
                                verbatim: "Tagesziel: \(formatValue(habit.targetValue)) \(habit.unitLabel)".trimmingCharacters(in: .whitespaces),
                                style: .caption,
                                color: theme.colors.onSurfaceMuted
                            )
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, theme.spacing.xs)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected && habit.isMeasurable {
                routineTargetRow(habit: habit)
                    .padding(.leading, 28 + theme.spacing.md + 24 + theme.spacing.md)
                    .padding(.trailing, theme.spacing.xs)
            }
        }
    }

    @ViewBuilder
    private func routineTargetRow(habit: Habit) -> some View {
        let binding = Binding<Double>(
            get: { habitTargets[habit.id] ?? habit.targetValue },
            set: { habitTargets[habit.id] = max(0, $0) }
        )
        HStack(spacing: theme.spacing.sm) {
            BentoText("Ziel in dieser Routine", style: .caption, color: theme.colors.onSurfaceMuted)
            Spacer()
            TextField("0", value: binding, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(.vertical, 4)
                .padding(.horizontal, theme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                        .fill(theme.colors.surfaceSecondary)
                )
            BentoText(verbatim: habit.unitLabel, style: .body, color: theme.colors.onSurfaceMuted)
                .frame(width: 50, alignment: .leading)
        }
        .padding(.vertical, theme.spacing.xs)
    }

    private func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    @ViewBuilder
    private func reorderButtons(for index: Int, total: Int) -> some View {
        HStack(spacing: 2) {
            BentoIconButton(
                systemImage: "chevron.up",
                accessibilityLabel: Text("Nach oben"),
                variant: .secondary,
                size: .small
            ) {
                move(from: index, to: index - 1)
            }
            .disabled(index == 0)
            .opacity(index == 0 ? 0.35 : 1)

            BentoIconButton(
                systemImage: "chevron.down",
                accessibilityLabel: Text("Nach unten"),
                variant: .secondary,
                size: .small
            ) {
                move(from: index, to: index + 1)
            }
            .disabled(index == total - 1)
            .opacity(index == total - 1 ? 0.35 : 1)
        }
    }

    /// Verschiebt den Eintrag an `from` an Position `to` in `selectedHabitIDs`.
    private func move(from: Int, to: Int) {
        guard selectedHabitIDs.indices.contains(from),
              to >= 0, to <= selectedHabitIDs.count else { return }
        var arr = selectedHabitIDs
        let item = arr.remove(at: from)
        // Beim Remove rutscht alles nach; bei to > from ist die Zielposition
        // um 1 niedriger als gedacht.
        let insertIndex = to > from ? to - 1 : to
        arr.insert(item, at: max(0, min(insertIndex, arr.count)))
        Haptics.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedHabitIDs = arr
        }
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
            habitTargets = routine.habitTargets
        }
    }

    private func save() {
        do {
            if let routine {
                routine.title = title.trimmingCharacters(in: .whitespaces)
                routine.iconSystemName = icon
                routine.color = color
                routine.habitIDs = selectedHabitIDs
                routine.habitTargets = habitTargets
                try env.routineRepo.update(routine)
            } else {
                let count = (try? env.routineRepo.fetchAll().count) ?? 0
                let new = HabitRoutine(
                    title: title.trimmingCharacters(in: .whitespaces),
                    iconSystemName: icon,
                    color: color,
                    habitIDs: selectedHabitIDs,
                    habitTargets: habitTargets,
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
