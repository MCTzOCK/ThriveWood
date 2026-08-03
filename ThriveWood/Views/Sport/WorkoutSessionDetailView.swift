//
//  WorkoutSessionDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import Foundation
import SwiftUI
import Charts
import FoundationModels


struct WorkoutSessionDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    @Bindable var session: WorkoutSession

    @State private var showEditSession = false
    @State private var draftNotes: String = ""
    @State private var draftRPE: Int = 7
    @State private var showEditNotes = false
    @State private var showDeleteConfirm = false
    @State private var errors = ErrorState()
    @State private var successHUDVisible = false
    @State private var aiAvailable = SystemLanguageModel.default.availability
    @State private var newPRs: [(exercise: Exercise, newPR: SetEntry, previousPR: SetEntry)] = []
    @State private var showShareImage = false
    @State private var showPhotoShare = false
    @State private var muscleMapShowFront = true
    @State private var selectedMapMuscle: MuscleGroup?

    // MARK: - Derived

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

    private var totalSets: Int { session.sets.count }
    private var completedSets: Int { session.sets.filter(\.isCompleted).count }

    private var totalVolumeKg: Double {
        session.sets
            .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
            .reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }

    private var totalReps: Int {
        session.sets
            .filter {
                guard let t = $0.exercise?.trackingType else { return false }
                return (t == .reps || t == .repsWeight) && $0.isCompleted
            }
            .reduce(0) { $0 + ($1.reps ?? 0) }
    }

    private var totalDistanceKm: Double {
        session.sets
            .filter { $0.exercise?.trackingType == .distanceDuration && $0.isCompleted }
            .reduce(0) { $0 + ($1.distanceMeters ?? 0) } / 1000
    }

    private var activeDurationSeconds: Int {
        session.sets
            .filter { $0.exercise?.trackingType == .duration && $0.isCompleted }
            .reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private func normalizedVolume(for set: SetEntry) -> Double {
        guard let type = set.exercise?.trackingType else { return 0 }
        switch type {
        case .repsWeight:       return (set.weight ?? 0) * Double(set.reps ?? 0)
        case .reps:             return Double(set.reps ?? 0) * 60.0
        case .duration:         return Double(set.durationSeconds ?? 0) * 0.5
        case .distanceDuration: return (set.distanceMeters ?? 0) * 0.05
        }
    }

    private var muscleVolumes: [MuscleGroup: Double] {
        var result: [MuscleGroup: Double] = [:]
        for set in session.sets where set.isCompleted {
            guard let exercise = set.exercise else { continue }
            let vol = normalizedVolume(for: set)
            for muscle in exercise.primaryMuscleGroups {
                let mapped = SessionMuscleMapView.mapGroup(for: muscle)
                result[mapped, default: 0] += vol
            }
            for muscle in exercise.secondaryMuscleGroups {
                let mapped = SessionMuscleMapView.mapGroup(for: muscle)
                result[mapped, default: 0] += vol * 0.5
            }
        }
        return result
    }

    private var heaviestSet: (Exercise, SetEntry)? {
        let candidates = session.sets
            .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
        guard let max = candidates.max(by: {
            ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0)
        }),
              let ex = max.exercise else { return nil }
        return (ex, max)
    }

    // MARK: - Body

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            ZStack {
                VStack(spacing: theme.spacing.lg) {
                    BentoPageHeader(
                        eyebrow: Text("SESSION"),
                        title: Text(session.workout?.name ?? "Freies Training"),
                        subtitle: Text(timeRange)
                    ) {
                        BentoIconButton(
                            systemImage: "chevron.left",
                            accessibilityLabel: Text("Zurück"),
                            variant: .secondary,
                            size: .medium
                        ) {
                            dismiss()
                        }

                        Menu {
                            Button {
                                showEditSession = true
                            } label: { Label("Workout bearbeiten", systemImage: "pencil.and.list.clipboard") }

                            Button {
                                showShareImage = true
                            } label: { Label("Zusammenfassung teilen", systemImage: "photo.on.rectangle.angled") }

                            Button {
                                showPhotoShare = true
                            } label: { Label("Bild mit Keyfacts teilen", systemImage: "photo.badge.plus") }

                            ShareLink(item: shareText) {
                                Label("Als Text teilen", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                Task {
                                    try? await env.healthService.save(session: session)
                                }
                                withAnimation(.spring()) {
                                    successHUDVisible = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.spring()) {
                                        successHUDVisible = false
                                    }
                                }
                            } label: {
                                Label("In Health speichern", systemImage: "heart.text.square")
                            }

                            if aiAvailable == .available {
                                NavigationLink {
                                    WorkoutAnalysisView(session: session)
                                } label: {
                                    Label("KI-Analyse", systemImage: "sparkles")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: { Label("Löschen", systemImage: "trash") }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body)
                                .frame(width: 48, height: 48)
                                .foregroundStyle(theme.colors.onSurface)
                                .background(theme.colors.surfaceSecondary, in: Circle())
                                .overlay(
                                    Circle().stroke(theme.colors.outlineSubtle, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Menü")
                    }

                    headerCard
                    statsGrid
                    if !sortedExercises.isEmpty { exerciseBreakdown }
                    if let pr = heaviestSet { highlightCard(pr) }
                    if !newPRs.isEmpty { prSection }
                    if !muscleVolumes.isEmpty { muscleMapSection }
                    notesCard

                    Spacer(minLength: theme.spacing.xxl)
                }

                if successHUDVisible {
                    SuccessHUD(message: "Gespeichert!")
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .navigationTitle(session.workout?.name ?? "Freies Training")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(errors)
        .onAppear { loadPRs() }
        .bentoSheet(
            isPresented: $showEditSession,
            title: Text("Session bearbeiten"),
            detents: [.large]
        ) {
            EditSessionSheet(session: session)
                .onDisappear { loadPRs() }
        }
        .bentoSheet(
            isPresented: $showShareImage,
            title: Text("Zusammenfassung"),
            detents: [.large]
        ) {
            WorkoutSummaryImageSheet(session: session)
        }
        .bentoSheet(
            isPresented: $showPhotoShare,
            title: Text("Keyfacts-Bild"),
            detents: [.large]
        ) {
            WorkoutPhotoShareSheet(session: session)
        }
        .bentoSheet(
            isPresented: $showEditNotes,
            title: Text("Notizen"),
            subtitle: Text("Notiz & Anstrengung"),
            detents: [.medium]
        ) {
            EditNotesSheet(notes: $draftNotes, rpe: $draftRPE) {
                session.notes = draftNotes
                session.perceivedExertion = draftRPE
                try? env.sessionRepo.update(session)
                Haptics.success()
            }
        }
        .bentoDialog(
            isPresented: $showDeleteConfirm,
            systemImage: "trash.fill",
            title: Text("Workout löschen?"),
            message: Text("Diese Trainingseinheit wird unwiderruflich entfernt."),
            actions: [
                BentoDialogAction(title: Text("Löschen"), variant: .destructive, role: .destructive) { delete() },
                BentoDialogAction(title: Text("Abbrechen"), role: .cancel) {}
            ]
        )
    }

    // MARK: - Header

    private var headerCard: some View {
        BentoCard(tone: .accent, style: .elevated, padding: .lg, radius: .extraLarge) {
            VStack(spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.md) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 56, height: 56)
                        Image(systemName: "dumbbell.fill")
                            .font(.title2)
                            .foregroundStyle(theme.colors.onAccent)
                            .symbolEffect(.bounce, value: session.id)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        BentoText(
                            verbatim: session.startedAt.formatted(.dateTime
                                .weekday(.wide).day().month(.wide).year()),
                            style: .callout,
                            color: theme.colors.onAccent.opacity(0.85)
                        )
                        BentoText(verbatim: timeRange, style: .title3, color: theme.colors.onAccent)
                    }
                    Spacer()
                }

                if let rpe = session.perceivedExertion {
                    rpeBar(rpe: rpe)
                }
            }
        }
    }

    private var timeRange: String {
        let start = session.startedAt.formatted(.dateTime.hour().minute())
        let end = session.endedAt?.formatted(.dateTime.hour().minute()) ?? "läuft"
        let dur = formattedDuration(session.durationSeconds)
        return "\(start) – \(end)  ·  \(dur)"
    }

    @ViewBuilder
    private func rpeBar(rpe: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                BentoText(verbatim: "Anstrengung (RPE)", style: .caption, color: theme.colors.onAccent.opacity(0.85))
                Spacer()
                Text("\(rpe)/10")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(theme.colors.onAccent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .orange, .red],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(rpe) / 10)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        BentoAdaptiveGrid(minimumItemWidth: 150) {
            BentoMetricTile(
                title: Text("Sätze"),
                value: Text("\(completedSets)/\(totalSets)"),
                systemImage: "checkmark.circle.fill",
                tone: .green
            )
            BentoMetricTile(
                title: Text("Übungen"),
                value: Text("\(sortedExercises.count)"),
                systemImage: "dumbbell.fill",
                tone: .blue
            )

            if totalVolumeKg > 0 {
                BentoMetricTile(
                    title: Text("Volumen"),
                    value: Text("\(Int(totalVolumeKg)) kg"),
                    systemImage: "scalemass.fill",
                    tone: .blue
                )
            }
            if totalReps > 0 {
                BentoMetricTile(
                    title: Text("Wiederholungen"),
                    value: Text("\(totalReps)"),
                    systemImage: "number",
                    tone: .warning
                )
            }
            if totalDistanceKm > 0 {
                BentoMetricTile(
                    title: Text("Distanz"),
                    value: Text(String(format: "%.2f km", totalDistanceKm)),
                    systemImage: "location.fill",
                    tone: .info
                )
            }
            if activeDurationSeconds > 0 {
                BentoMetricTile(
                    title: Text("Aktive Zeit"),
                    value: Text(formattedDuration(activeDurationSeconds)),
                    systemImage: "timer",
                    tone: .pink
                )
            }
        }
    }

    // MARK: - Highlight (PR)

    private func highlightCard(_ pr: (Exercise, SetEntry)) -> some View {
        BentoCard(tone: .warning, style: .elevated, padding: .lg, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .symbolEffect(.bounce, value: pr.0.id)
                VStack(alignment: .leading, spacing: 2) {
                    BentoText(verbatim: "Schwerster Satz heute", style: .caption)
                    BentoText(verbatim: pr.0.name, style: .headline)
                    BentoText(verbatim: pr.1.summaryText, style: .bodyStrong)
                }
                Spacer()
            }
        }
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            BentoSectionHeader(
                title: Text("Übungen"),
                subtitle: Text("\(sortedExercises.count) ausgeführt")
            )
            VStack(spacing: theme.spacing.sm) {
                ForEach(Array(sortedExercises.enumerated()), id: \.offset) { _, pair in
                    ExerciseSummaryCard(exercise: pair.0, sets: pair.1)
                }
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        BentoSection(title: Text("Notizen")) {
            BentoCard(style: .outlined, padding: .lg, radius: .large) {
                HStack(alignment: .top) {
                    if session.notes.isEmpty {
                        BentoText("Keine Notizen", style: .callout, color: theme.colors.onSurfaceMuted)
                    } else {
                        BentoText(verbatim: session.notes, style: .body)
                    }
                    Spacer()
                    BentoIconButton(
                        systemImage: "pencil",
                        accessibilityLabel: Text("Bearbeiten"),
                        variant: .ghost,
                        size: .small
                    ) {
                        draftNotes = session.notes
                        draftRPE = session.perceivedExertion ?? 7
                        showEditNotes = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - PR Section

    private var prSection: some View {
        BentoSection(title: Text("Neue PRs"), subtitle: Text("\(newPRs.count) persönliche Rekorde")) {
            VStack(spacing: theme.spacing.sm) {
                ForEach(newPRs, id: \.newPR.id) { pr in
                    prCard(pr)
                }
            }
        }
    }

    private func prCard(_ pr: (exercise: Exercise, newPR: SetEntry, previousPR: SetEntry)) -> some View {
        BentoCard(tone: .warning, style: .outlined, padding: .md, radius: .large) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: pr.exercise.iconSystemName)
                        .font(.callout)
                }

                VStack(alignment: .leading, spacing: 2) {
                    BentoText(verbatim: pr.exercise.name, style: .headline)
                    HStack(spacing: 4) {
                        Text(pr.previousPR.summaryText)
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Text(pr.newPR.summaryText)
                            .font(.caption.weight(.bold))
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.title3)
            }
        }
    }

    // MARK: - Muscle Map

    private var muscleMapSection: some View {
        BentoSection(title: Text("Muskeln")) {
            BentoCard(style: .outlined, padding: .lg, radius: .large) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        Spacer()
                        BentoSegmentedPicker(options: [true, false], selection: $muscleMapShowFront) { front in
                            Text(front ? "Vorne" : "Hinten")
                        }
                        .frame(width: 180)
                    }
                    SessionMuscleMapView(
                        volumes: muscleVolumes,
                        selectedMuscle: $selectedMapMuscle,
                        showFront: $muscleMapShowFront
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func delete() {
        do {
            try env.sessionRepo.delete(session)
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
    }

    private func loadPRs() {
        newPRs = env.workoutService.getNewPRs(in: session)
    }

    private var shareText: String {
        var lines: [String] = []
        lines.append("🏋️ \(session.workout?.name ?? "Freies Training")")
        lines.append(session.startedAt.formatted(.dateTime.day().month().year().hour().minute()))
        if let dur = session.durationSeconds { lines.append("Dauer: \(formattedDuration(dur))") }
        lines.append("Sätze: \(completedSets)/\(totalSets)")
        if totalVolumeKg > 0 { lines.append("Volumen: \(Int(totalVolumeKg)) kg") }
        if totalDistanceKm > 0 { lines.append(String(format: "Distanz: %.2f km", totalDistanceKm)) }
        lines.append("")
        for (ex, sets) in sortedExercises {
            lines.append("• \(ex.name)")
            for (i, s) in sets.enumerated() where s.isCompleted {
                lines.append("   \(i + 1). \(s.summaryText)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func formattedDuration(_ seconds: Int?) -> String {
        guard let seconds else { return "–" }
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0
            ? String(format: "%dh %dmin", h, m)
            : (m > 0 ? "\(m) min" : "\(s) s")
    }
}
