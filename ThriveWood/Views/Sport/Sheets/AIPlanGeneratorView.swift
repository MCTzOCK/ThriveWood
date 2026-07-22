//
//  AIPlanGeneratorView.swift
//  ThriveWood
//

import SwiftUI
import FoundationModels

@Generable
struct AIGeneratedPlan {
    @Guide(description: "Name des Trainingsplans")
    var name: String

    @Guide(description: "Kurze Beschreibung des Plans, max 1 Satz")
    var planDescription: String

    @Guide(description: "Liste der Workouts, eins pro Trainingstag")
    var workouts: [AIGeneratedWorkout]
}

@Generable
struct AIGeneratedWorkout {
    @Guide(description: "Name des Workouts, z.B. Push Day, Pull Day, Beine")
    var name: String

    @Guide(description: "Wochentag als Zahl: 1=Montag, 2=Dienstag, ..., 7=Sonntag", .range(1...7))
    var day: Int

    @Guide(description: "Übungen in diesem Workout, verwende NUR Namen aus der bereitgestellten Liste")
    var exercises: [AIGeneratedExercise]
}

@Generable
struct AIGeneratedExercise {
    @Guide(description: "Exakter Name der Übung aus der Bibliothek des Nutzers")
    var name: String

    @Guide(description: "Anzahl Arbeitssätze", .range(1...6))
    var sets: Int

    @Guide(description: "Anzahl Wiederholungen pro Satz", .range(1...30))
    var reps: Int
}

struct AIPlanGeneratorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var goal = 0
    @State private var daysPerWeek = 3
    @State private var experience = 0
    @State private var split = 0
    @State private var equipment = 0
    @State private var isLoading = false
    @State private var generatedPlan: AIGeneratedPlan?
    @State private var errorMessage: String?
    @State private var exerciseLibrary: [Exercise] = []
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var exerciseSearchText: String = ""

    private let goals = ["Muskelaufbau", "Fettverbrennung", "Kraftsteigerung", "Ausdauer", "Allgemeine Fitness"]
    private let goalIcons = ["dumbbell.fill", "flame.fill", "scalemass.fill", "figure.run", "heart.fill"]
    private let experiences = ["Anfänger", "Fortgeschritten", "Erfahren"]
    private let splits = ["Oberkörper / Unterkörper", "Push / Pull / Beine", "Ganzkörper", "Keine Präferenz"]
    private let equipmentOptions = ["Vollausgestattetes Gym", "Hanteln & Bank", "Nur Kurzhanteln", "Körpergewicht"]

    private var totalSteps: Int { 6 }

    private var filteredExercises: [Exercise] {
        guard !exerciseSearchText.isEmpty else { return exerciseLibrary }
        return exerciseLibrary.filter { $0.name.localizedCaseInsensitiveContains(exerciseSearchText) }
    }

    private var selectedExercises: [Exercise] {
        exerciseLibrary.filter { selectedExerciseIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            if let generatedPlan {
                resultView(generatedPlan)
            } else {
                stepContent
                Spacer()
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                navButtons
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("KI Plan-Generator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Schließen") { dismiss() }
            }
        }
        .task {
            exerciseLibrary = (try? env.exerciseRepo.fetchAll()) ?? []
            if selectedExerciseIDs.isEmpty && !exerciseLibrary.isEmpty {
                selectedExerciseIDs = Set(exerciseLibrary.map(\.id))
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.purple : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            Text("Schritt \(step + 1) von \(totalSteps)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: goalStep
        case 1: daysStep
        case 2: experienceStep
        case 3: splitStep
        case 4: equipmentStep
        case 5: exerciseSelectionStep
        default: EmptyView()
        }
    }

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.purple.opacity(0.12)).frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.purple)
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }

    private var goalStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "target", title: "Was ist dein Ziel?", subtitle: "Worauf möchtest du dich fokussieren?")
            VStack(spacing: 10) {
                ForEach(Array(goals.enumerated()), id: \.offset) { idx, goal_ in
                    optionCard(
                        title: goal_,
                        icon: goalIcons[idx],
                        isSelected: goal == idx,
                        color: .purple
                    ) {
                        withAnimation(.snappy) { goal = idx }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var daysStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "calendar", title: "Wie oft pro Woche?", subtitle: "Wie viele Tage möchtest du trainieren?")
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(2...7, id: \.self) { days in
                        Button {
                            withAnimation(.snappy) { daysPerWeek = days }
                            Haptics.selection()
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(days)")
                                    .font(.title2.bold().monospacedDigit())
                                Text(days == 1 ? "Tag" : "Tage")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(daysPerWeek == days ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(daysPerWeek == days ? Color.purple : Color(.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                Text("Empfohlen: 3-4 Tage für Anfänger, 4-6 für Fortgeschrittene")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var experienceStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "chart.bar.fill", title: "Wie erfahren bist du?", subtitle: "Dein Trainings-Level hilft bei der Übungsauswahl")
            VStack(spacing: 10) {
                ForEach(Array(experiences.enumerated()), id: \.offset) { idx, exp in
                    optionCard(
                        title: exp,
                        subtitle: ["Weniger als 1 Jahr", "1-3 Jahre", "Mehr als 3 Jahre"][idx],
                        icon: ["leaf.fill", "flame.fill", "bolt.fill"][idx],
                        isSelected: experience == idx,
                        color: [.green, .orange, .red][idx]
                    ) {
                        withAnimation(.snappy) { experience = idx }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var splitStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "rectangle.split.3x1", title: "Welcher Split?", subtitle: "Wie möchtest du dein Training aufteilen?")
            VStack(spacing: 10) {
                ForEach(Array(splits.enumerated()), id: \.offset) { idx, sp in
                    optionCard(
                        title: sp,
                        icon: ["arrow.up.arrow.down", "arrow.triangle.branch", "person.fill", "questionmark"][idx],
                        isSelected: split == idx,
                        color: .blue
                    ) {
                        withAnimation(.snappy) { split = idx }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var equipmentStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "shippingbox.fill", title: "Was steht zur Verfügung?", subtitle: "Welche Geräte hast du beim Training?")
            VStack(spacing: 10) {
                ForEach(Array(equipmentOptions.enumerated()), id: \.offset) { idx, eq in
                    optionCard(
                        title: eq,
                        icon: ["building.2.fill", "dumbbell.fill", "figure.strengthtraining.traditional", "figure.mixed.cardio"][idx],
                        isSelected: equipment == idx,
                        color: .teal
                    ) {
                        withAnimation(.snappy) { equipment = idx }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var exerciseSelectionStep: some View {
        VStack(spacing: 16) {
            stepHeader(
                icon: "list.bullet.below.rectangle",
                title: "Verfügbare Übungen",
                subtitle: "Wähle aus welchen Übungen die KI den Plan erstellen soll"
            )

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Suchen...", text: $exerciseSearchText)
                    .textFieldStyle(.plain)
                if !exerciseSearchText.isEmpty {
                    Button { exerciseSearchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 20)

            HStack {
                Text("\(selectedExerciseIDs.count) ausgewählt")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
                Spacer()
                Button {
                    selectAllExercises()
                } label: {
                    Text("Alle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                }
                Button {
                    selectedExerciseIDs.removeAll()
                    Haptics.selection()
                } label: {
                    Text("Keine")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            toggleExerciseSelection(exercise)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: exercise.iconSystemName)
                                    .font(.body)
                                    .foregroundStyle(selectedExerciseIDs.contains(exercise.id) ? .purple : .secondary)
                                    .frame(width: 24)
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedExerciseIDs.contains(exercise.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.purple)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary.opacity(0.3))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedExerciseIDs.contains(exercise.id) ? Color.purple.opacity(0.06) : Color(.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func toggleExerciseSelection(_ exercise: Exercise) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
        Haptics.selection()
    }

    private func selectAllExercises() {
        if selectedExerciseIDs.count == exerciseLibrary.count {
            selectedExerciseIDs.removeAll()
        } else {
            selectedExerciseIDs = Set(exerciseLibrary.map(\.id))
        }
        Haptics.selection()
    }

    private func optionCard(title: String, subtitle: String? = nil, icon: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(isSelected ? color.opacity(0.2) : Color(.tertiarySystemFill)).frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? color : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(color)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Nav Buttons

    private var navButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation(.snappy) { step -= 1 }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }

            if step < totalSteps - 1 {
                Button {
                    withAnimation(.snappy) { step += 1 }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple)
                    )
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                Button {
                    generatePlan()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isLoading ? "Generiere..." : "Plan erstellen")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple)
                    )
                }
                .buttonStyle(BounceButtonStyle())
                .disabled(isLoading || selectedExerciseIDs.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Result

    private func resultView(_ plan: AIGeneratedPlan) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.green.opacity(0.12)).frame(width: 56, height: 56)
                        Image(systemName: "checkmark")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.green)
                    }
                    Text("Plan erstellt!")
                        .font(.headline)
                }
                .padding(.top, 12)

                VStack(spacing: 16) {
                    HStack {
                        Text(plan.name)
                            .font(.title3.weight(.bold))
                        Spacer()
                        Button {
                            savePlan(plan)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Speichern")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green))
                        }
                        .buttonStyle(BounceButtonStyle())
                    }

                    if !plan.planDescription.isEmpty {
                        Text(plan.planDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(Array(plan.workouts.enumerated()), id: \.offset) { _, workout in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                ZStack {
                                    Circle().fill(Color.purple.opacity(0.12)).frame(width: 32, height: 32)
                                    Text("\(workout.day)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.purple)
                                }
                                Text(workout.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(workout.exercises.count) Übungen")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { _, ex in
                                HStack(spacing: 8) {
                                    Circle().fill(Color(.tertiarySystemFill)).frame(width: 6, height: 6)
                                    Text(ex.name)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(ex.sets) × \(ex.reps)")
                                        .font(.caption2.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(.purple)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.tertiarySystemFill))
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                Button {
                    withAnimation(.snappy) {
                        generatedPlan = nil
                        step = 0
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Neu generieren")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Generation

    private func generatePlan() {
        guard env.aiService.isAvailable() else {
            errorMessage = "KI ist auf diesem Gerät nicht verfügbar. Aktiviere Apple Intelligence in den Einstellungen."
            return
        }

        guard !selectedExercises.isEmpty else {
            errorMessage = "Bitte wähle mindestens eine Übung aus."
            return
        }

        isLoading = true
        errorMessage = nil
        generatedPlan = nil

        let exerciseNames = selectedExercises.map(\.name)
        let recentSessions = (try? env.sessionRepo.fetchAll()) ?? []
        let recentVolume = recentSessions.flatMap(\.sets).filter(\.isCompleted).count

        let splitDescription: String
        switch split {
        case 0: splitDescription = "Oberkörper / Unterkörper Split"
        case 1: splitDescription = "Push / Pull / Beine Split"
        case 2: splitDescription = "Ganzkörper-Training jeden Tag"
        default: splitDescription = "Keine spezielle Präferenz, wähle den besten Split"
        }

        let prompt = """
        Erstelle einen \(daysPerWeek)-tägigen Trainingsplan.
        Ziel: \(goals[goal])
        Erfahrung: \(experiences[experience])
        Split: \(splitDescription)
        Verfügbare Geräte: \(equipmentOptions[equipment])
        Bisher absolvierte Sätze: \(recentVolume)

        Verwende AUSSCHLIESSLICH Übungen aus dieser Liste der Bibliothek des Nutzers:
        \(exerciseNames.joined(separator: ", "))

        Erstelle genau \(daysPerWeek) Workouts, verteilt auf die Tage 1 bis \(daysPerWeek).
        Verwende 4-6 Übungen pro Workout.
        """

        Task {
            do {
                let session = LanguageModelSession(model: SystemLanguageModel.default)
                let response = try await session.respond(
                    to: prompt,
                    generating: AIGeneratedPlan.self
                )
                let plan = response.content

                guard !plan.workouts.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "Der generierte Plan enthält keine Workouts."
                        self.isLoading = false
                    }
                    return
                }

                await MainActor.run {
                    self.generatedPlan = plan
                    self.isLoading = false
                    Haptics.success()
                }
            } catch let error as LanguageModelSession.GenerationError {
                await MainActor.run {
                    self.errorMessage = generationErrorMessage(error)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Fehler: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func generationErrorMessage(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .guardrailViolation:
            return "Die Anfrage wurde vom Sicherheitssystem blockiert."
        case .exceededContextWindowSize:
            return "Zu viele Übungen in der Bibliothek — der Kontext ist voll."
        case .concurrentRequests:
            return "Es läuft bereits eine Anfrage."
        case .unsupportedLanguageOrLocale:
            return "Sprache wird nicht unterstützt."
        case .assetsUnavailable:
            return "KI-Modelle sind noch nicht heruntergeladen."
        case .refusal:
            return "KI hat die Anfrage abgelehnt. Versuche es mit anderen Optionen."
        case .rateLimited:
            return "Zu viele Anfragen, bitte warte einen Moment."
        case .decodingFailure:
            return "Die Antwort konnte nicht strukturiert werden. Versuche es erneut."
        default:
            return "Unbekannter Fehler bei der Generierung."
        }
    }

    private func savePlan(_ plan: AIGeneratedPlan) {
        let exerciseMap = Dictionary(uniqueKeysWithValues: selectedExercises.compactMap { ex in
            (ex.name.lowercased(), ex)
        })

        do {
            let trainingsPlan = try env.trainingsPlanRepo.create(
                name: plan.name,
                details: plan.planDescription,
                color: "#9C27B0"
            )

            for workoutDef in plan.workouts {
                let workout = Workout(name: workoutDef.name, color: .purple, estimatedDurationMinutes: 60)
                for exDef in workoutDef.exercises {
                    let exercise = exerciseMap[exDef.name.lowercased()]
                    guard let exercise else {
                        let matched = selectedExercises.first { $0.name.localizedCaseInsensitiveContains(exDef.name) }
                        guard let matched else { continue }
                        let slot = WorkoutExercise(
                            order: workout.exercises.count,
                            exercise: matched,
                            workout: workout,
                            targetSets: exDef.sets,
                            targetReps: exDef.reps
                        )
                        workout.exercises.append(slot)
                        continue
                    }
                    let slot = WorkoutExercise(
                        order: workout.exercises.count,
                        exercise: exercise,
                        workout: workout,
                        targetSets: exDef.sets,
                        targetReps: exDef.reps
                    )
                    workout.exercises.append(slot)
                }

                let dayIndex = max(1, min(7, workoutDef.day))
                if let weekday = TPWeekday(rawValue: dayIndex) {
                    try env.trainingsPlanRepo.assignWorkout(workout, to: weekday, in: trainingsPlan)
                }
            }

            Haptics.success()
            dismiss()
        } catch {
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
