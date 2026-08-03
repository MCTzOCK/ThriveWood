//
//  EditSessionSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//


import SwiftUI

struct EditSessionSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession

    @State private var draftStart: Date
    @State private var draftEnd: Date
    @State private var draftRPE: Int
    @State private var draftNotes: String
    @State private var showingAddExercise = false
    @State private var showingReplaceExercise: Exercise? = nil
    @State private var errors = ErrorState()

    init(session: WorkoutSession) {
        self.session = session
        _draftStart = State(initialValue: session.startedAt)
        _draftEnd = State(initialValue: session.endedAt ?? session.startedAt)
        _draftRPE = State(initialValue: session.perceivedExertion ?? 5)
        _draftNotes = State(initialValue: session.notes)
    }

    private var sortedExercises: [(Exercise, [SetEntry])] {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        if let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }), !plan.isEmpty {
            var result: [(Exercise, [SetEntry])] = []
            for slot in plan {
                guard let ex = slot.exercise else { continue }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty { result.append((ex, sets)) }
            }
            let unique = Set(session.sets.compactMap { $0.exercise })
            for ex in unique.sorted(by: { $0.name < $1.name }) {
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                if !sets.isEmpty && !plan.contains(where: { $0.exercise?.id == ex.id }) {
                    result.append((ex, sets))
                }
            }
            return result
        }
        let unique = Set(session.sets.compactMap { $0.exercise })
        return unique.sorted { $0.name < $1.name }.map { ex in
            (ex, (groups[ex.id] ?? []).sorted { $0.order < $1.order })
        }
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                timeSection
                rpeSection
                exercisesSection
                notesSection
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                save()
                dismiss()
            }
        }
        .bentoSheet(
            isPresented: $showingAddExercise,
            title: Text("Übung hinzufügen"),
            detents: [.large]
        ) {
            ExerciseLibraryView(onSelect: { ex in
                addExercise(ex)
            }, asSheet: false, onlyFor: nil)
        }
        .bentoSheet(
            isPresented: Binding(
                get: { showingReplaceExercise != nil },
                set: { if !$0 { showingReplaceExercise = nil } }
            ),
            title: Text("Übung ersetzen"),
            detents: [.large]
        ) {
            if let original = showingReplaceExercise {
                ReplaceExerciseSheet(
                    originalExercise: original,
                    trackingType: original.trackingType,
                    onSelect: { replacement in
                        replaceExercise(original, with: replacement)
                    }
                )
            }
        }
        .errorAlert(errors)
    }

    // MARK: - Time

    private var timeSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Zeit"))
                DatePicker("Start", selection: $draftStart, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                DatePicker("Ende", selection: $draftEnd, in: draftStart...Date.now, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    // MARK: - RPE

    private var rpeSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Anstrengung (RPE)"))
                VStack {
                    HStack {
                        Text("RPE").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(draftRPE)/10").font(.headline.monospacedDigit())
                    }
                    Slider(value: Binding(
                        get: { Double(draftRPE) },
                        set: { draftRPE = Int($0) }
                    ), in: 1...10, step: 1)
                }
            }
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Übungen"))
                ForEach(Array(sortedExercises.enumerated()), id: \.offset) { _, pair in
                    EditableExerciseBlock(
                        exercise: pair.0,
                        sets: pair.1,
                        unit: session.weightUnit,
                        onAddSet: { addSet(for: pair.0) },
                        onDeleteSet: { deleteSet($0) },
                        onRemoveExercise: { removeExercise(pair.0) },
                        onReplaceExercise: { showingReplaceExercise = pair.0 }
                    )
                }
                Button {
                    showingAddExercise = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Übung hinzufügen")
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Notizen"))
                TextField("Wie war's?", text: $draftNotes, axis: .vertical)
                    .lineLimit(3...10)
            }
        }
    }

    // MARK: - Actions

    private func save() {
        session.startedAt = draftStart
        session.endedAt = draftEnd
        session.perceivedExertion = draftRPE
        session.notes = draftNotes
        try? env.sessionRepo.update(session)
        Haptics.success()
    }

    private func addSet(for exercise: Exercise) {
        let existing = session.sets.filter { $0.exercise?.id == exercise.id }
        let last = existing.max(by: { $0.order < $1.order })
        let newOrder = (existing.map(\.order).max() ?? -1) + 1
        let set = SetEntry(
            order: newOrder, exercise: exercise, session: session,
            reps: last?.reps, weight: last?.weight,
            durationSeconds: last?.durationSeconds,
            distanceMeters: last?.distanceMeters
        )
        session.sets.append(set)
        try? env.sessionRepo.update(session)
        Haptics.selection()
    }

    private func deleteSet(_ set: SetEntry) {
        session.sets.removeAll { $0.id == set.id }
        reorderSets(for: set.exercise)
        try? env.sessionRepo.update(session)
    }

    private func removeExercise(_ exercise: Exercise) {
        session.sets.removeAll { $0.exercise?.id == exercise.id }
        try? env.sessionRepo.update(session)
        Haptics.impact(.light)
    }

    private func replaceExercise(_ original: Exercise, with replacement: Exercise) {
        guard replacement.trackingType == original.trackingType else { return }
        for set in session.sets where set.exercise?.id == original.id {
            set.exercise = replacement
        }
        try? env.sessionRepo.update(session)
        Haptics.success()
    }

    private func addExercise(_ exercise: Exercise) {
        let newSet = SetEntry(
            order: 0, exercise: exercise, session: session
        )
        session.sets.append(newSet)
        try? env.sessionRepo.update(session)
        Haptics.selection()
    }

    private func reorderSets(for exercise: Exercise?) {
        guard let exercise else { return }
        var idx = 0
        for set in session.sets.filter({ $0.exercise?.id == exercise.id }).sorted(by: { $0.order < $1.order }) {
            set.order = idx
            idx += 1
        }
    }
}

// MARK: - Editable Exercise Block

private struct EditableExerciseBlock: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let unit: WeightUnit
    let onAddSet: () -> Void
    let onDeleteSet: (SetEntry) -> Void
    let onRemoveExercise: () -> Void
    let onReplaceExercise: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: exercise.iconSystemName)
                    .foregroundStyle(.tint)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))
                Text(exercise.name).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(sets.filter(\.isCompleted).count)/\(sets.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                EditableSetRow(index: idx + 1, set: set, unit: unit, type: exercise.trackingType, onDelete: { onDeleteSet(set) })
            }

            HStack(spacing: Theme.Spacing.s) {
                Button(action: onAddSet) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Satz")
                    }
                    .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)

                Button(action: onReplaceExercise) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Ersetzen")
                    }
                    .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(role: .destructive, action: onRemoveExercise) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Entfernen")
                    }
                    .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Editable Set Row

private struct EditableSetRow: View {
    let index: Int
    @Bindable var set: SetEntry
    let unit: WeightUnit
    let type: ExerciseTrackingType
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            setInputs

            Spacer(minLength: 0)

            Button {
                set.isCompleted.toggle()
                set.completedAt = set.isCompleted ? .now : nil
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.callout)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var setInputs: some View {
        switch type {
        case .repsWeight:
            numberField(
                value: Binding(get: { set.weight ?? 0 }, set: { set.weight = $0 == 0 ? nil : $0 }),
                placeholder: "0", suffix: unit.rawValue, width: 70, decimal: true)
            numberField(
                value: Binding(get: { Double(set.reps ?? 0) }, set: { set.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps", width: 70, decimal: false)

        case .reps:
            numberField(
                value: Binding(get: { Double(set.reps ?? 0) }, set: { set.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps", width: 100, decimal: false)

        case .duration:
            durationField(seconds: Binding(get: { set.durationSeconds ?? 0 }, set: { set.durationSeconds = $0 == 0 ? nil : $0 }))

        case .distanceDuration:
            numberField(
                value: Binding(get: { (set.distanceMeters ?? 0) / 1000 }, set: { set.distanceMeters = $0 == 0 ? nil : $0 * 1000 }),
                placeholder: "0", suffix: "km", width: 80, decimal: true)
            durationField(seconds: Binding(get: { set.durationSeconds ?? 0 }, set: { set.durationSeconds = $0 == 0 ? nil : $0 }))
        }
    }

    @ViewBuilder
    private func numberField(
        value: Binding<Double>,
        placeholder: String,
        suffix: String,
        width: CGFloat,
        decimal: Bool
    ) -> some View {
        HStack(spacing: 4) {
            if decimal {
                FlexibleNumberField(value: value, placeholder: placeholder, decimal: true)
            } else {
                TextField(placeholder, value: value, format: .number.precision(.fractionLength(0...0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
            }
            Text(suffix).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(width: width)
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.tertiarySystemFill)))
    }

    private func durationField(seconds: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            TextField("0", value: Binding(
                get: { seconds.wrappedValue / 60 },
                set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 32)
            Text(":").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            TextField("00", value: Binding(
                get: { seconds.wrappedValue % 60 },
                set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 32)
            Text("min").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.tertiarySystemFill)))
    }
}

// MARK: - Replace Exercise Sheet

private struct ReplaceExerciseSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let originalExercise: Exercise
    let trackingType: ExerciseTrackingType
    let onSelect: (Exercise) -> Void

    @State private var exercises: [Exercise] = []
    @State private var search: String = ""

    private var compatible: [Exercise] {
        exercises.filter { $0.trackingType == trackingType && $0.id != originalExercise.id }
    }

    private var filtered: [Exercise] {
        compatible.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List(filtered) { exercise in
            Button {
                onSelect(exercise)
                dismiss()
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: exercise.iconSystemName)
                        .foregroundStyle(.tint)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name).font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(exercise.trackingType.label)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.tint)
                }
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $search)
        .overlay {
            if compatible.isEmpty {
                ContentUnavailableView(
                    "Keine kompatiblen Übungen",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Es gibt keine Übungen mit dem Tracking-Typ \"\(trackingType.label)\".")
                )
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        exercises = (try? env.exerciseRepo.fetchAll()) ?? []
    }
}
