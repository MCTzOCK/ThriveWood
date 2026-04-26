//
//  HabitEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct HabitEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    
    // Nil → neuer Habit
    let habit: Habit?
    
    // Form-State
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
    
    @State private var errors = ErrorState()
    @State private var isSaving = false
    
    private let iconOptions: [String] = [
        "leaf.fill","drop.fill","flame.fill","figure.run","book.fill",
        "moon.fill","sun.max.fill","heart.fill","brain.head.profile",
        "cup.and.saucer.fill","dumbbell.fill","bed.double.fill","pencil",
        "music.note","fork.knife","pills.fill","camera.fill"
    ]
    
    private var isEditing: Bool { habit != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                appearanceSection
                pointsSection
                scheduleSection
                reminderSection
                if isEditing { deleteSection }
            }
            .navigationTitle(isEditing ? "Habit bearbeiten" : "Neuer Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save)
                        .disabled(!isValid || isSaving)
                        .fontWeight(.semibold)
                }
            }
            .errorAlert(errors)
            .onAppear(perform: hydrate)
        }
    }
    
    // MARK: - Sections
    
    private var detailsSection: some View {
        Section("Details") {
            TextField("Titel", text: $title)
                .textInputAutocapitalization(.sentences)
            TextField("Beschreibung (optional)", text: $details, axis: .vertical)
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
                    Text(title.isEmpty ? "Vorschau" : title)
                        .font(.headline)
                    Text("\(points.rawValue) Punkte • \(frequencyLabel)")
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
    
    private var pointsSection: some View {
        Section {
            Picker("Schwierigkeit", selection: $points) {
                ForEach(HabitPoints.allCases) { p in Text(p.label).tag(p) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Punkte")
        } footer: {
            Text("Punkte werden bei jedem Abhaken gutgeschrieben und lassen deinen Wald wachsen.")
        }
    }
    
    private var scheduleSection: some View {
        Section("Zeitplan") {
            Picker("Frequenz", selection: $frequency) {
                Text("Täglich").tag(HabitFrequency.daily)
                Text("Bestimmte Tage").tag(HabitFrequency.custom)
            }
            .pickerStyle(.segmented)
            
            if frequency != .daily {
                WeekdaySelector(selection: $selectedWeekdays)
            }
        }
    }
    
    private var reminderSection: some View {
        Section("Erinnerung") {
            Toggle("Tägliche Erinnerung", isOn: $remindersOn.animation())
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
                DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                guard let habit else { return }
                do { try env.habitRepo.archive(habit); dismiss() }
                catch { errors.show(error) }
            } label: {
                Label("Habit archivieren", systemImage: "archivebox")
            }
        }
    }
    
    private var frequencyLabel: String {
        switch frequency {
        case .daily: "täglich"
        case .weekly: "wöchentlich"
        case .custom: "\(selectedWeekdays.count) Tage/Woche"
        }
    }
    
    // MARK: - Logic
    
    private func hydrate() {
        guard let habit else { return }
        title = habit.title
        details = habit.details
        icon = habit.iconSystemName
        color = habit.color
        points = habit.points
        frequency = habit.frequency
        selectedWeekdays = Set(habit.activeWeekdays.compactMap(Weekday.init(rawValue:)))
        remindersOn = habit.reminderTime != nil
        if let t = habit.reminderTime { reminderTime = t }
    }
    
    private func save() {
        isSaving = true
        defer { isSaving = false }
        Task {
            do {
                let weekdays = Array(selectedWeekdays).sorted { $0.rawValue < $1.rawValue }
                let reminder: Date? = remindersOn ? reminderTime : nil
                
                if let habit {
                    habit.title = title.trimmingCharacters(in: .whitespaces)
                    habit.details = details
                    habit.iconSystemName = icon
                    habit.color = color
                    habit.points = points
                    habit.frequency = frequency
                    habit.activeWeekdays = weekdays.map(\.rawValue)
                    habit.reminderTime = reminder
                    try await env.saveHabit(habit, isNew: false)
                } else {
                    let new = Habit(
                        title: title.trimmingCharacters(in: .whitespaces),
                        details: details,
                        iconSystemName: icon,
                        color: color,
                        points: points,
                        frequency: frequency,
                        activeWeekdays: weekdays,
                        reminderTime: reminder,
                        sortOrder: Int.max
                    )
                    try await env.saveHabit(new, isNew: true)
                }
                Haptics.success()
                dismiss()
            } catch {
                Haptics.warning()
                errors.show(error)
            }
        }
    }
}
