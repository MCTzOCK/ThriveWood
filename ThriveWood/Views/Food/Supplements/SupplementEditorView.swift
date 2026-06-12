//
//  SupplementEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 02.05.26.
//


import SwiftUI

struct SupplementEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let supplement: Supplement?

    @State private var name = ""
    @State private var dosage = ""
    @State private var details = ""
    @State private var icon = "pills.fill"
    @State private var color: HabitColor = .blue
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedWeekdays: Set<Weekday> = Set(Weekday.allCases)
    @State private var timesPerDay = 1
    @State private var reminderTimes: [Date] = [
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    ]
    @State private var isSaving = false
    @State private var didHydrate = false

    private let iconOptions = [
        "pills.fill", "pill.fill", "cross.vial.fill", "leaf.fill",
        "drop.fill", "heart.fill", "brain.head.profile", "figure.run",
        "moon.fill", "sun.max.fill", "bolt.fill", "flame.fill"
    ]

    private var isEditing: Bool { supplement != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !dosage.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                appearanceSection
                scheduleSection
                reminderSection

                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Supplement bearbeiten" : "Neues Supplement")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isSaving)
                }
            }
            .onAppear {
                guard !didHydrate else { return }
                didHydrate = true
                hydrate()
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name (z.B. Vitamin D)", text: $name)
            TextField("Dosierung (z.B. 5000 IU)", text: $dosage)
            TextField("Notizen (optional)", text: $details, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    private var appearanceSection: some View {
        Section("Darstellung") {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Vorschau" : name)
                        .font(.headline)
                    Text(dosage.isEmpty ? "Dosierung" : dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                IconPicker(selection: $icon, options: iconOptions, tint: color.color)
            } label: {
                LabeledContent("Symbol") { Image(systemName: icon) }
            }

            ColorGrid(selection: $color)
        }
    }

    private var scheduleSection: some View {
        Section("Zeitplan") {
            Picker("Frequenz", selection: $frequency) {
                Text("Täglich").tag(HabitFrequency.daily)
                Text("Bestimmte Tage").tag(HabitFrequency.custom)
            }
            .pickerStyle(.segmented)

            if frequency == .custom {
                WeekdaySelector(selection: $selectedWeekdays)
            }

            Stepper("Einnahmen pro Tag: \(timesPerDay)", value: $timesPerDay, in: 1...5)
                .onChange(of: timesPerDay) { _, newValue in
                    adjustReminderTimes(to: newValue)
                }
        }
    }

    private var reminderSection: some View {
        Section("Erinnerungen") {
            ForEach(0..<timesPerDay, id: \.self) { index in
                DatePicker(
                    "Einnahme \(index + 1)",
                    selection: Binding(
                        get: { reminderTimes.indices.contains(index) ? reminderTimes[index] : .now },
                        set: { if reminderTimes.indices.contains(index) { reminderTimes[index] = $0 } }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                guard let supplement else { return }
                try? env.supplementService.archive(supplement)
                dismiss()
            } label: {
                Label("Supplement archivieren", systemImage: "archivebox")
            }
        }
    }

    // MARK: - Logic

    private func hydrate() {
        guard let supplement else { return }
        name = supplement.name
        dosage = supplement.dosage
        details = supplement.details
        icon = supplement.iconSystemName
        color = supplement.color
        frequency = supplement.frequency
        selectedWeekdays = Set(supplement.activeWeekdays.compactMap(Weekday.init(rawValue:)))
        timesPerDay = supplement.timesPerDay
        reminderTimes = supplement.reminderTimes
    }

    private func adjustReminderTimes(to count: Int) {
        while reminderTimes.count < count {
            let lastTime = reminderTimes.last ?? .now
            let newTime = Calendar.current.date(byAdding: .hour, value: 4, to: lastTime) ?? lastTime
            reminderTimes.append(newTime)
        }
        while reminderTimes.count > count {
            reminderTimes.removeLast()
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let weekdays = Array(selectedWeekdays).sorted { $0.rawValue < $1.rawValue }

            if let supplement {
                supplement.name = name.trimmingCharacters(in: .whitespaces)
                supplement.dosage = dosage
                supplement.details = details
                supplement.iconSystemName = icon
                supplement.color = color
                supplement.frequency = frequency
                supplement.activeWeekdays = weekdays.map(\.rawValue)
                supplement.timesPerDay = timesPerDay
                supplement.reminderTimes = reminderTimes

                try await env.supplementService.update(supplement)
            } else {
                let new = Supplement(
                    name: name.trimmingCharacters(in: .whitespaces),
                    dosage: dosage,
                    details: details,
                    iconSystemName: icon,
                    color: color,
                    frequency: frequency,
                    activeWeekdays: weekdays,
                    timesPerDay: timesPerDay,
                    reminderTimes: reminderTimes
                )
                try await env.supplementService.create(new)
            }
            Haptics.success()
            dismiss()
        } catch {
            Haptics.warning()
            print(error)
        }
    }
}
