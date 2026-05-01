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
    
    @State private var trackingMode: HabitTrackingMode = .simple
    @State private var targetValue: Double = 2000
    @State private var incrementValue: Double = 200
    @State private var unitLabel: String = "ml"
    @State private var selectedUnit: HabitUnit = .milliliters
    
    @State private var didHydrate = false
    
    private let iconOptions: [String] = [
        // MARK: - Gesundheit & Körperpflege
        "heart.fill", "brain.head.profile", "pills.fill", "cross.case.fill",
        "eye.fill", "ear.fill", "lungs.fill", "comb.fill",
        "shower.fill", "bathtub.fill", "hands.sparkles.fill", "drop.fill",

        // MARK: - Fitness & Sport
        "figure.run", "figure.walk", "figure.yoga", "figure.pool.swim",
        "dumbbell.fill", "bicycle", "tennis.racket", "soccerball",
        "basketball.fill", "volleyball.fill", "skis", "snowboard",
        "medal.fill", "trophy.fill", "stopwatch.fill",

        // MARK: - Ernährung & Trinken
        "cup.and.saucer.fill", "fork.knife", "carrot.fill", "takeoutbag.and.cup.and.straw.fill",
        "wineglass.fill", "mug.fill", "birthday.cake.fill", "refrigerator.fill",
        
        // MARK: - Schlaf & Erholung
        "bed.double.fill", "moon.fill", "moon.stars.fill", "moon.zzz.fill",
        "sun.max.fill", "cloud.sun.fill", "sparkles", "wind",

        // MARK: - Lernen & Bildung
        "book.fill", "text.book.closed.fill", "graduationcap.fill",
        "pencil", "highlighter", "character.book.closed.fill", "globe",
        "lightbulb.fill", "magnifyingglass", "brain",

        // MARK: - Arbeit & Produktivität
        "briefcase.fill", "folder.fill", "tray.fill", "calendar",
        "clock.fill", "laptopcomputer", "display", "keyboard",
        "printer.fill", "paperclip", "list.bullet.clipboard.fill",

        // MARK: - Finanzen & Sparen
        "eurosign.circle.fill", "banknote.fill", "creditcard.fill",
        "chart.pie.fill", "chart.xyaxis.line", "bag.fill", "cart.fill",

        // MARK: - Hobbys, Kunst & Freizeit
        "music.note", "guitars.fill", "headphones", "mic.fill",
        "camera.fill", "paintbrush.fill", "paintbrush.pointed.fill",
        "gamecontroller.fill", "puzzlepiece.fill", "tv.fill", "film.fill",
        "ticket.fill", "popcorn.fill", "theatermasks.fill",

        // MARK: - Natur & Garten
        "leaf.fill", "tree.fill", "pawprint.fill", "cat.fill", "dog.fill",
        "bird.fill", "fish.fill", "ant.fill", "ladybug.fill", "camera.macro",

        // MARK: - Haushalt & Alltag
        "house.fill", "trash.fill", "hammer.fill", "wrench.and.screwdriver.fill",
        "washer.fill", "tshirt.fill", "shoe.fill", "key.fill", "lock.fill",

        // MARK: - Soziales & Kommunikation
        "person.fill", "person.2.fill", "person.3.fill", "message.fill",
        "bubble.left.and.bubble.right.fill", "phone.fill", "envelope.fill",
        "video.fill", "hand.thumbsup.fill", "heart.text.square.fill",

        // MARK: - Reisen & Transport
        "airplane", "car.fill", "bus.fill", "tram.fill", "train.side.front.car",
        "sailboat.fill", "tent.fill", "map.fill", "location.fill", "suitcase.fill",
        
        "x.circle.fill"
    ]
    
    private var isEditing: Bool { habit != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                trackingModeSection
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
        trackingMode = habit.trackingMode
        targetValue = habit.targetValue
        incrementValue = habit.incrementValue
        unitLabel = habit.unitLabel
        selectedUnit = HabitUnit.allCases.first { $0.rawValue == habit.unitLabel } ?? .custom
        
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
                    habit.trackingMode = trackingMode
                    habit.targetValue = trackingMode == .measurable ? targetValue : 1
                    habit.incrementValue = trackingMode == .measurable ? incrementValue : 1
                    habit.unitLabel = trackingMode == .measurable ? unitLabel : ""
                    
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
                        sortOrder: Int.max,
                        trackingMode: trackingMode,
                        targetValue: trackingMode == .measurable ? targetValue : 1,
                        incrementValue: trackingMode == .measurable ? incrementValue : 1,
                        unitLabel: trackingMode == .measurable ? unitLabel : ""
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
    
    private var trackingModeSection: some View {
        Section {
            Picker("Tracking", selection: $trackingMode.animation()) {
                ForEach(HabitTrackingMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: trackingMode) { _, newMode in
                if newMode == .simple {
                    targetValue = 1; incrementValue = 1; unitLabel = ""
                } else if targetValue <= 1 {
                    applyPreset(.water)
                }
            }
            
            if trackingMode == .measurable {
                measurableConfig
            }
        } header: {
            Text("Tracking-Modus")
        } footer: {
            Text(trackingMode == .simple
                 ? "Einmal antippen = erledigt."
                 : "Fortschritt wird schrittweise gezählt. Punkte werden anteilig vergeben."
            )
        }
    }
    
    @ViewBuilder
    private var measurableConfig: some View {
        // Vorlagen
        VStack(alignment: .leading, spacing: 8) {
            Text("Vorlage wählen").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MeasurablePreset.allCases) { preset in
                        Button {
                            Haptics.selection()
                            applyPreset(preset)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: preset.icon).font(.caption)
                                Text(preset.label).font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                Capsule().fill(
                                    isPresetActive(preset)
                                    ? Color.accentColor : Color(.tertiarySystemFill)
                                )
                            )
                            .foregroundStyle(isPresetActive(preset) ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        
        // Zielwert
        HStack {
            Text("Tagesziel").font(.subheadline)
            Spacer()
            TextField("0", value: $targetValue, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
            Text(unitLabel).font(.subheadline).foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
        }
        
        // Schrittgröße
        HStack {
            Text("Pro Schritt").font(.subheadline)
            Spacer()
            TextField("0", value: $incrementValue, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
            Text(unitLabel).font(.subheadline).foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
        }
        
        // Einheit
        HStack {
            Text("Einheit").font(.subheadline)
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
                Text("Eigene Einheit").font(.subheadline)
                Spacer()
                TextField("z.B. Portionen", text: $unitLabel)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(.roundedBorder)
            }
        }
        
        // Vorschau
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "info.circle").foregroundStyle(.tint)
            let steps = targetValue > 0 && incrementValue > 0
            ? Int(ceil(targetValue / incrementValue)) : 0
            Text("\(steps) Schritte à \(formatValue(incrementValue)) \(unitLabel) bis zum Ziel")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    
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
    
    
}


enum MeasurablePreset: String, CaseIterable, Identifiable {
    case water, reading, exercise, meditation, steps, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .water:      "Wasser"
        case .reading:    "Lesen"
        case .exercise:   "Bewegung"
        case .meditation: "Meditation"
        case .steps:      "Schritte"
        case .custom:     "Eigene"
        }
    }
    var icon: String {
        switch self {
        case .water: "drop.fill"
        case .reading: "book.fill"
        case .exercise: "figure.walk"
        case .meditation: "brain.head.profile"
        case .steps: "shoeprints.fill"
        case .custom: "slider.horizontal.3"
        }
    }
    var target: Double {
        switch self {
        case .water: 2000
        case .reading: 30
        case .exercise: 30
        case .meditation: 20
        case .steps: 10000
        case .custom: 10
        }
    }
    var increment: Double {
        switch self {
        case .water: 200
        case .reading: 5
        case .exercise: 5
        case .meditation: 5
        case .steps: 1000
        case .custom: 1
        }
    }
    var unit: HabitUnit {
        switch self {
        case .water: .milliliters
        case .reading: .pages
        case .exercise: .minutes
        case .meditation: .minutes
        case .steps: .steps
        case .custom: .custom
        }
    }
}
