//
//  BentoEditHabitSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 01.08.26.
//

import SwiftUI

struct BentoEditHabitSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var icon: String = "leaf.fill"
    @State private var color: HabitColor = .green
    @State private var points: HabitPoints = .low
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedWeekdays: Set<Weekday> = Set(Weekday.allCases)
    @State private var remindersOn: Bool = false
    @State private var reminderTime: Date = Calendar.app.date(
        bySettingHour: 9, minute: 0, second: 0, of: .now
    ) ?? .now

    @State private var trackingMode: HabitTrackingMode = .simple
    @State private var targetValue: Double = 2000
    @State private var incrementValue: Double = 200
    @State private var unitLabel: String = "ml"
    @State private var selectedUnit: HabitUnit = .milliliters

    @State private var errors = ErrorState()
    @State private var isSaving = false
    @State private var showingIconPicker = false
    @State private var didHydrate = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                previewCard
                detailsCard
                trackingCard
                appearanceCard
                pointsCard
                scheduleCard
                reminderCard
                deleteCard
            }
            .padding(.horizontal, theme.spacing.value(.md))
            .padding(.bottom, theme.spacing.value(.xl))
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            BentoButton(
                Text("Änderungen speichern"),
                systemImage: "checkmark.circle.fill",
                variant: .primary,
                expands: true,
                isLoading: isSaving
            ) {
                save()
            }
            .disabled(!isValid)
            .padding(.horizontal, theme.spacing.value(.md))
            .padding(.vertical, theme.spacing.value(.sm))
            .background(theme.colors.background)
        }
        .errorAlert(errors)
        .bentoSheet(
            isPresented: $showingIconPicker,
            title: Text("Symbol wählen"),
            subtitle: Text("Tippe auf ein Symbol"),
            detents: [.medium, .large]
        ) {
            BentoIconPickerSheet(
                selection: $icon,
                options: HabitEditorView.iconOptions,
                tint: color.color
            )
        }
        .onAppear {
            guard !didHydrate else { return }
            didHydrate = true
            hydrate()
        }
    }

    // MARK: - Preview

    private var previewCard: some View {
        BentoCard(style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    BentoText("\(title.isEmpty ? "Vorschau" : title)", style: .headline)
                    BentoText(
                        "\(points.rawValue) Punkte · \(frequencyLabel)",
                        style: .caption,
                        color: theme.colors.onSurfaceMuted
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Details

    private var detailsCard: some View {
        BentoSection(title: Text("Details")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoTextField(
                        label: Text("Titel"),
                        text: $title,
                        prompt: Text("z.B. Wasser trinken"),
                        required: true
                    )
                    BentoTextArea(
                        label: Text("Beschreibung"),
                        text: $details,
                        prompt: Text("Optional"),
                        minimumHeight: 90
                    )
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceCard: some View {
        BentoSection(title: Text("Darstellung")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoActionRow(
                        title: Text("Symbol"),
                        systemImage: icon,
                        tone: .neutral
                    ) {
                        showingIconPicker = true
                    }

                    BentoDivider()

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        BentoText("Farbe", style: .caption, color: theme.colors.onSurfaceMuted)
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: theme.spacing.xs),
                                count: 6
                            ),
                            spacing: theme.spacing.xs
                        ) {
                            ForEach(HabitColor.allCases) { c in
                                Circle()
                                    .fill(c.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if c == color {
                                            Circle()
                                                .strokeBorder(theme.colors.onSurface, lineWidth: theme.borders.strong)
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .contentShape(Circle())
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
    }

    // MARK: - Points

    private var pointsCard: some View {
        BentoSection(title: Text("Punkte"), subtitle: Text("Bei jedem Abhaken gutgeschrieben")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.xs) {
                    ForEach(HabitPoints.allCases) { p in
                        let isSelected = points == p
                        Button {
                            Haptics.selection()
                            points = p
                        } label: {
                            HStack {
                                BentoText("\(p.label)", style: .callout)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.colors.accent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(theme.colors.onSurfaceMuted)
                                }
                            }
                            .padding(.vertical, theme.spacing.xs)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleCard: some View {
        BentoSection(title: Text("Zeitplan")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoSegmentedPicker(
                        options: [HabitFrequency.daily, .custom],
                        selection: $frequency
                    ) { freq in
                        Text(freq == .daily ? "Täglich" : "Bestimmte Tage")
                    }

                    if frequency == .custom {
                        VStack(spacing: theme.spacing.xs) {
                            ForEach(Weekday.allCases) { day in
                                let isSelected = selectedWeekdays.contains(day)
                                Button {
                                    Haptics.selection()
                                    if isSelected {
                                        selectedWeekdays.remove(day)
                                    } else {
                                        selectedWeekdays.insert(day)
                                    }
                                } label: {
                                    HStack {
                                        BentoText("\(day.fullLabel)", style: .body)
                                        Spacer()
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.onSurfaceMuted)
                                    }
                                    .padding(.vertical, theme.spacing.xxs)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(theme.motion.snappy, value: frequency)
            }
        }
    }

    // MARK: - Reminder

    private var reminderCard: some View {
        BentoSection(title: Text("Erinnerung")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoToggleRow(
                        Text("Tägliche Erinnerung"),
                        isOn: $remindersOn.animation(theme.motion.snappy)
                    )
                    .onChange(of: remindersOn) { _, newValue in
                        guard newValue else { return }
                        Task {
                            let granted = await env.notificationService.ensureAuthorized()
                            if !granted {
                                remindersOn = false
                                errors.message = "Bitte erlaube Mitteilungen in den iOS-Einstellungen."
                                errors.isPresented = true
                            }
                        }
                    }

                    if remindersOn {
                        BentoDatePickerField(
                            Text("Uhrzeit"),
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(theme.motion.snappy, value: remindersOn)
            }
        }
    }

    // MARK: - Tracking

    private var trackingCard: some View {
        BentoSection(title: Text("Tracking-Modus"), subtitle: Text(
            trackingMode == .simple
            ? "Einmal antippen = erledigt."
            : "Fortschritt wird schrittweise gezählt."
        )) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                VStack(spacing: theme.spacing.md) {
                    BentoSegmentedPicker(
                        options: HabitTrackingMode.allCases,
                        selection: $trackingMode.animation(theme.motion.snappy)
                    ) { mode in
                        Text(mode.label)
                    }
                    .onChange(of: trackingMode) { _, newMode in
                        if newMode == .simple {
                            targetValue = 1; incrementValue = 1; unitLabel = ""
                        } else if targetValue <= 1 {
                            applyPreset(.water)
                        }
                    }

                    if trackingMode == .measurable {
                        measurableConfig
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(theme.motion.snappy, value: trackingMode)
            }
        }
    }

    @ViewBuilder
    private var measurableConfig: some View {
        VStack(spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                BentoText("Vorlage wählen", style: .caption, color: theme.colors.onSurfaceMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.xs) {
                        ForEach(MeasurablePreset.allCases) { preset in
                            let active = isPresetActive(preset)
                            Button {
                                Haptics.selection()
                                applyPreset(preset)
                            } label: {
                                HStack(spacing: theme.spacing.xxs) {
                                    Image(systemName: preset.icon).font(.caption)
                                    BentoText("\(preset.label)", style: .caption)
                                }
                                .padding(.horizontal, theme.spacing.sm)
                                .padding(.vertical, theme.spacing.xxs)
                                .background(
                                    Capsule().fill(
                                        active ? theme.colors.accent : theme.colors.surfaceSecondary
                                    )
                                )
                                .foregroundStyle(active ? theme.colors.onAccent : theme.colors.onSurface)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                BentoText("Tagesziel", style: .body)
                Spacer()
                TextField("0", value: $targetValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                BentoText("\(unitLabel)", style: .body, color: theme.colors.onSurfaceMuted)
                    .frame(width: 50, alignment: .leading)
            }

            HStack {
                BentoText("Pro Schritt", style: .body)
                Spacer()
                TextField("0", value: $incrementValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                BentoText("\(unitLabel)", style: .body, color: theme.colors.onSurfaceMuted)
                    .frame(width: 50, alignment: .leading)
            }

            HStack {
                BentoText("Einheit", style: .body)
                Spacer()
                Picker("", selection: $selectedUnit) {
                    ForEach(HabitUnit.allCases) { u in
                        Text(u == .custom ? "Eigene" : u.rawValue).tag(u)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedUnit) { _, u in
                    if u != .custom { unitLabel = u.rawValue }
                }
            }

            if selectedUnit == .custom {
                HStack {
                    BentoText("Eigene Einheit", style: .body)
                    Spacer()
                    TextField("z.B. Portionen", text: $unitLabel)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            }

            if targetValue > 0 && incrementValue > 0 {
                let steps = Int(ceil(targetValue / incrementValue))
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(theme.colors.accent)
                    BentoText(
                        "\(steps) Schritte à \(formatValue(incrementValue)) \(unitLabel) bis zum Ziel",
                        style: .caption,
                        color: theme.colors.onSurfaceMuted
                    )
                }
            }
        }
    }

    // MARK: - Delete

    private var deleteCard: some View {
        BentoSection(title: Text("Habit")) {
            BentoCard(style: .outlined, padding: .md, radius: .large) {
                BentoButton(
                    Text("Habit archivieren"),
                    systemImage: "archivebox",
                    variant: .destructive,
                    expands: true
                ) {
                    archive()
                }
            }
        }
    }

    // MARK: - Hydrate

    private func hydrate() {
        title = habit.title
        details = habit.details
        icon = habit.iconSystemName
        color = habit.color
        points = habit.points
        frequency = habit.frequency
        selectedWeekdays = Set(habit.activeWeekdays.compactMap(Weekday.init(rawValue:)))
        remindersOn = habit.reminderTime != nil
        if let t = habit.reminderTime { reminderTime = t }
        trackingMode = habit.trackingMode
        targetValue = habit.targetValue
        incrementValue = habit.incrementValue
        unitLabel = habit.unitLabel
        selectedUnit = HabitUnit.allCases.first { $0.rawValue == habit.unitLabel } ?? .custom
    }

    // MARK: - Presets

    private func applyPreset(_ preset: MeasurablePreset) {
        targetValue = preset.target
        incrementValue = preset.increment
        selectedUnit = preset.unit
        unitLabel = preset.unit == .custom ? "" : preset.unit.rawValue
    }

    private func isPresetActive(_ preset: MeasurablePreset) -> Bool {
        targetValue == preset.target
        && incrementValue == preset.increment
        && selectedUnit == preset.unit
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", v)
        : String(format: "%.1f", v)
    }

    // MARK: - Helpers

    private var frequencyLabel: String {
        switch frequency {
        case .daily: "täglich"
        case .weekly: "wöchentlich"
        case .custom: "\(selectedWeekdays.count) Tage/Woche"
        }
    }

    // MARK: - Save

    func save() {
        guard isValid, !isSaving else { return }
        isSaving = true
        Task {
            do {
                let weekdays = Array(selectedWeekdays).sorted { $0.rawValue < $1.rawValue }
                let reminder: Date? = remindersOn ? reminderTime : nil

                habit.title = title.trimmingCharacters(in: .whitespaces)
                habit.details = details
                habit.iconSystemName = icon
                habit.color = color
                habit.points = points
                habit.frequency = frequency
                habit.activeWeekdays = weekdays.map(\.rawValue)
                habit.reminderTime = reminder
                habit.trackingMode = trackingMode
                habit.targetValue = trackingMode == .measurable ? targetValue : 1
                habit.incrementValue = trackingMode == .measurable ? incrementValue : 1
                habit.unitLabel = trackingMode == .measurable ? unitLabel : ""

                try await env.saveHabit(habit, isNew: false)
                Haptics.success()
                dismiss()
            } catch {
                Haptics.warning()
                errors.show(error)
            }
            isSaving = false
        }
    }

    func archive() {
        Task {
            do {
                try env.habitRepo.archive(habit)
                Haptics.success()
                dismiss()
            } catch {
                Haptics.warning()
                errors.show(error)
            }
        }
    }
}
