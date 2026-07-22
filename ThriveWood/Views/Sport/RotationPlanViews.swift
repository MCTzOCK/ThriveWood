//
//  RotationPlanViews.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

// MARK: - Rotation Plan List View

struct RotationPlanListView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var plans: [RotationTrainingsPlan] = []
    @State private var showCreateSheet = false
    @State private var selectedPlan: RotationTrainingsPlan?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                if let activePlan = plans.first(where: \.isActive) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Aktiver Rotationsplan")
                            .font(Theme.Typography.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, Theme.Spacing.l)

                        Button {
                            selectedPlan = activePlan
                        } label: {
                            RotationPlanCard(plan: activePlan)
                        }
                        .buttonStyle(BounceButtonStyle())
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Alle Rotationsplaene")
                        .font(Theme.Typography.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, Theme.Spacing.l)

                    if plans.isEmpty {
                        PremiumEmptyState(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Keine Rotationsplaene",
                            message: "Erstelle einen A/B/C-Plan, bei dem sich Workouts fortlaufend abwechseln.",
                            actionTitle: "Plan erstellen"
                        ) {
                            showCreateSheet = true
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.xl)
                    } else {
                        VStack(spacing: Theme.Spacing.s) {
                            ForEach(plans) { plan in
                                Button {
                                    selectedPlan = plan
                                } label: {
                                    RotationPlanRow(plan: plan)
                                }
                                .buttonStyle(PressScaleStyle())
                                .contextMenu {
                                    if !plan.isActive {
                                        Button {
                                            setActive(plan)
                                        } label: {
                                            Label("Aktivieren", systemImage: "checkmark.circle")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        deletePlan(plan)
                                    } label: {
                                        Label("Loeschen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rotation")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateRotationPlanSheet(onCreate: {
                Task { await load() }
            })
        }
        .sheet(item: $selectedPlan) { plan in
            NavigationStack {
                RotationPlanDetailView(plan: plan)
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            plans = try env.rotationPlanService.fetchAll()
        } catch {
            print("Load error: \(error)")
        }
    }

    private func setActive(_ plan: RotationTrainingsPlan) {
        do {
            try env.rotationPlanService.setActivePlan(plan)
            Haptics.success()
            Task { await load() }
        } catch {
            print("Set active error: \(error)")
        }
    }

    private func deletePlan(_ plan: RotationTrainingsPlan) {
        do {
            try env.rotationPlanService.deletePlan(plan)
            Haptics.success()
            Task { await load() }
        } catch {
            print("Delete error: \(error)")
        }
    }
}

// MARK: - Rotation Plan Card (Active Plan)

struct RotationPlanCard: View {
    let plan: RotationTrainingsPlan

    private var planColor: Color {
        Color(hex: plan.color) ?? .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(planColor)

                Text(plan.name)
                    .font(Theme.Typography.headline)

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(Theme.Typography.body)
            }

            if !plan.details.isEmpty {
                Text(plan.details)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: Theme.Spacing.l) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(Theme.Typography.caption2)
                    Text("\(plan.sequenceCount) Workouts")
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(Theme.Typography.caption2)
                    Text("\(plan.completedRotations) Rotationen")
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(.secondary)

            if plan.sequenceCount > 0 {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Naechstes: \(plan.nextWorkoutLabel)")
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(planColor)

                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(Array(plan.sortedEntries.enumerated()), id: \.element.id) { idx, entry in
                            VStack(spacing: 2) {
                                Text(entry.label.isEmpty ? String(Character(UnicodeScalar(65 + idx)!)) : entry.label)
                                    .font(Theme.Typography.caption2.weight(.bold))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle().fill(idx == plan.currentWorkoutIndex % plan.sequenceCount ? planColor : Color(.tertiarySystemFill))
                                    )
                                    .foregroundStyle(idx == plan.currentWorkoutIndex % plan.sequenceCount ? .white : .primary)
                            }
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(planColor.opacity(0.06))
        )
    }
}

// MARK: - Rotation Plan Row

struct RotationPlanRow: View {
    let plan: RotationTrainingsPlan

    private var planColor: Color {
        Color(hex: plan.color) ?? .blue
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(planColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(Theme.Typography.body)
                    .foregroundStyle(planColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(plan.name)
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if plan.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: Theme.Spacing.m) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(Theme.Typography.caption2)
                        Text("\(plan.sequenceCount) Workouts")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(Theme.Typography.caption2)
                        Text("Naechstes: \(plan.nextWorkoutLabel)")
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Theme.Typography.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}

// MARK: - Create Rotation Plan Sheet

struct CreateRotationPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    var onCreate: () -> Void

    @State private var name = ""
    @State private var details = ""
    @State private var selectedColor = "#4CAF50"
    @State private var workoutCount = 3

    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#FFEB3B", "#795548"
    ]

    private var defaultLabels: [String] {
        (0..<workoutCount).map { idx in
            String(Character(UnicodeScalar(65 + idx)!))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Beschreibung (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Farbe") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .gray)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    Haptics.selection()
                                }
                        }
                    }
                }

                Section("Workout-Anzahl") {
                    Stepper("\(workoutCount) Workouts", value: $workoutCount, in: 2...6)
                    Text("Die Workouts werden mit \(defaultLabels.joined(separator: ", ")) beschriftet. Du kannst sie nach dem Erstellen mit konkreten Workout-Vorlagen verknuepfen.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Ein Rotationsplan rotiert Workouts fortlaufend, unabhaengig von festen Wochentagen. Beispiel: 3 Workouts (A, B, C) bedeuten, dass du immer A, dann B, dann C, dann wieder A trainierst – egal an welchem Wochentag.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Neuer Rotationsplan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") { create() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func create() {
        do {
            let plan = try env.rotationPlanService.createPlan(
                name: name,
                details: details,
                color: selectedColor
            )
            for label in defaultLabels {
                try env.rotationPlanService.addWorkout(nil, label: label, to: plan)
            }
            Haptics.success()
            dismiss()
            onCreate()
        } catch {
            print("Create error: \(error)")
        }
    }
}

// MARK: - Rotation Plan Detail View

struct RotationPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    let plan: RotationTrainingsPlan

    @State private var availableWorkouts: [Workout] = []
    @State private var showingEdit = false
    @State private var showingWorkoutPicker = false
    @State private var selectedEntry: RotationPlanEntry?

    private var planColor: Color {
        Color(hex: plan.color) ?? .green
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.l) {
                headerCard
                sequenceSection
                actionsSection
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 60)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditRotationPlanSheet(plan: plan)
        }
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerSheet(workouts: availableWorkouts) { workout in
                if let entry = selectedEntry {
                    entry.workout = workout
                    try? env.rotationPlanService.updatePlan(plan, name: plan.name, details: plan.details, color: plan.color)
                }
            }
        }
        .task { await loadWorkouts() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(Theme.Typography.title3)
                    if !plan.details.isEmpty {
                        Text(plan.details)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if plan.isActive {
                    PillBadge(text: "Aktiv", icon: "checkmark.circle.fill", color: .green)
                }
            }

            HStack(spacing: Theme.Spacing.l) {
                VStack(spacing: 2) {
                    Text("\(plan.sequenceCount)")
                        .font(Theme.Typography.title3.monospacedDigit())
                    Text("Workouts")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(plan.completedRotations)")
                        .font(Theme.Typography.title3.monospacedDigit())
                    Text("Rotationen")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text(plan.nextWorkoutLabel)
                        .font(Theme.Typography.title3)
                        .foregroundStyle(planColor)
                    Text("Als naechstes")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var sequenceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Workout-Sequenz")
                .font(Theme.Typography.headline)
                .padding(.horizontal, Theme.Spacing.l)

            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(plan.sortedEntries.enumerated()), id: \.element.id) { idx, entry in
                    rotationEntryRow(idx: idx, entry: entry)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private func rotationEntryRow(idx: Int, entry: RotationPlanEntry) -> some View {
        let isNext = idx == plan.currentWorkoutIndex % max(plan.sequenceCount, 1)

        return HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(isNext ? planColor : Color(.tertiarySystemFill))
                    .frame(width: 36, height: 36)
                Text(entry.label.isEmpty ? String(Character(UnicodeScalar(65 + idx)!)) : entry.label)
                    .font(Theme.Typography.subheadline.weight(.bold))
                    .foregroundStyle(isNext ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.workout?.name ?? "Kein Workout zugewiesen")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                if isNext {
                    Text("Naechstes Training")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(planColor)
                }
            }

            Spacer()

            Button {
                selectedEntry = entry
                showingWorkoutPicker = true
            } label: {
                Image(systemName: entry.workout == nil ? "plus.circle" : "square.and.pencil")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Aktionen")
                .font(Theme.Typography.headline)
                .padding(.horizontal, Theme.Spacing.l)

            VStack(spacing: Theme.Spacing.s) {
                if !plan.isActive {
                    Button {
                        try? env.rotationPlanService.setActivePlan(plan)
                        Haptics.success()
                    } label: {
                        Label("Als aktiv setzen", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, Theme.Spacing.l)
                }

                Button {
                    try? env.rotationPlanService.advance(plan)
                    Haptics.impact()
                } label: {
                    Label("Naechstes Workout", systemImage: "arrow.forward.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, Theme.Spacing.l)

                Button(role: .destructive) {
                    try? env.rotationPlanService.reset(plan)
                    Haptics.impact()
                } label: {
                    Label("Rotation zuruecksetzen", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
    }

    private func loadWorkouts() async {
        availableWorkouts = (try? env.workoutService.allWorkouts()) ?? []
    }
}

// MARK: - Edit Rotation Plan Sheet

struct EditRotationPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    let plan: RotationTrainingsPlan

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var selectedColor: String = "#4CAF50"

    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#FFEB3B", "#795548"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Beschreibung", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Farbe") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .gray)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    Haptics.selection()
                                }
                        }
                    }
                }
            }
            .navigationTitle("Plan bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            name = plan.name
            details = plan.details
            selectedColor = plan.color
        }
    }

    private func save() {
        try? env.rotationPlanService.updatePlan(
            plan,
            name: name,
            details: details,
            color: selectedColor
        )
        Haptics.success()
        dismiss()
    }
}

// MARK: - Workout Picker Sheet

struct WorkoutPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let workouts: [Workout]
    let onSelect: (Workout) -> Void

    var body: some View {
        NavigationStack {
            List(workouts) { w in
                Button {
                    onSelect(w)
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(w.color.color)
                        Text(w.name)
                            .font(Theme.Typography.subheadline)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Workout waehlen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
