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

    @Bindable var session: WorkoutSession

    @State private var isEditing = false
    @State private var showEditSession = false
    @State private var draftNotes: String = ""
    @State private var draftRPE: Int = 7
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
        ScrollView {
            ZStack {
                VStack(spacing: Theme.Spacing.l) {
                    headerCard
                    statsGrid
                    if !sortedExercises.isEmpty { exerciseBreakdown }
                    if let pr = heaviestSet { highlightCard(pr) }
                    if !newPRs.isEmpty { prSection }
                    if !muscleVolumes.isEmpty { muscleMapSection }
                    notesCard
                    Spacer(minLength: 40)
                }
                .padding(.vertical, Theme.Spacing.l)
                .padding(.horizontal, Theme.Spacing.l)
                
                if successHUDVisible {
                    SuccessHUD(message: "Gespeichert!")
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.workout?.name ?? "Freies Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .errorAlert(errors)
        .onAppear { loadPRs() }
        .sheet(isPresented: $showEditSession) {
            EditSessionSheet(session: session)
                .onDisappear { loadPRs() }
        }
        .sheet(isPresented: $showShareImage) {
            WorkoutSummaryImageSheet(session: session)
        }
        .sheet(isPresented: $showPhotoShare) {
            WorkoutPhotoShareSheet(session: session)
        }
        .confirmationDialog(
            "Workout löschen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) { delete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Trainingseinheit wird unwiderruflich entfernt.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showEditSession = true
                } label: { Label("Workout bearbeiten", systemImage: "pencil.and.list.clipboard") }

                /*Button {
                    draftNotes = session.notes
                    draftRPE = session.perceivedExertion ?? 7
                    isEditing = true
                } label: { Label("Notizen bearbeiten", systemImage: "pencil") }*/

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
                
                if aiAvailable == .available{
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
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(workoutColor.gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.startedAt.formatted(.dateTime
                        .weekday(.wide).day().month(.wide).year()))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timeRange)
                        .font(.title3.bold())
                }
                Spacer()
            }

            if let rpe = session.perceivedExertion {
                rpeBar(rpe: rpe)
            }
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private var workoutColor: HabitColor { session.workout?.color ?? .blue }

    private var timeRange: String {
        let start = session.startedAt.formatted(.dateTime.hour().minute())
        let end = session.endedAt?.formatted(.dateTime.hour().minute()) ?? "läuft"
        let dur = formattedDuration(session.durationSeconds)
        return "\(start) – \(end)  ·  \(dur)"
    }

    private func rpeBar(rpe: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Anstrengung (RPE)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(rpe)/10")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(rpeColor(rpe))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .orange, .red],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(rpe) / 10)
                }
            }
            .frame(height: 6)
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 0...4: .green
        case 5...6: .yellow
        case 7...8: .orange
        default:    .red
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12),
                       GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            StatTile(icon: "checkmark.circle.fill", tint: .green,
                     value: "\(completedSets)/\(totalSets)", label: "Sätze")
            StatTile(icon: "dumbbell.fill", tint: .blue,
                     value: "\(sortedExercises.count)", label: "Übungen")

            if totalVolumeKg > 0 {
                StatTile(icon: "scalemass.fill", tint: .purple,
                         value: "\(Int(totalVolumeKg)) kg", label: "Volumen")
            }
            if totalReps > 0 {
                StatTile(icon: "number", tint: .orange,
                         value: "\(totalReps)", label: "Wiederholungen")
            }
            if totalDistanceKm > 0 {
                StatTile(icon: "location.fill", tint: .teal,
                         value: String(format: "%.2f km", totalDistanceKm), label: "Distanz")
            }
            if activeDurationSeconds > 0 {
                StatTile(icon: "timer", tint: .pink,
                         value: formattedDuration(activeDurationSeconds), label: "Aktive Zeit")
            }
        }
    }

    // MARK: - Highlight (PR)

    private func highlightCard(_ pr: (Exercise, SetEntry)) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .padding(12)
                .background(Circle().fill(Color.yellow.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Schwerster Satz heute")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(pr.0.name).font(.subheadline.weight(.semibold))
                Text(pr.1.summaryText)
                    .font(.headline)
                    .foregroundStyle(.yellow)
            }
            Spacer()
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Übungen").font(.headline)
            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(sortedExercises.enumerated()), id: \.offset) { _, pair in
                    ExerciseSummaryCard(exercise: pair.0, sets: pair.1)
                }
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text("Notizen").font(.headline)
                Spacer()
                Button {
                    draftNotes = session.notes
                    draftRPE = session.perceivedExertion ?? 7
                    isEditing = true
                } label: {
                    Image(systemName: "pencil").foregroundStyle(.tint)
                }
            }
            if session.notes.isEmpty {
                Text("Keine Notizen").font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text(session.notes).font(.subheadline)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .sheet(isPresented: $isEditing) {
            EditNotesSheet(notes: $draftNotes, rpe: $draftRPE) {
                session.notes = draftNotes
                session.perceivedExertion = draftRPE
                try? env.sessionRepo.update(session)
                Haptics.success()
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - PR Section

    private var prSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                Text("Neue PRs")
                    .font(.headline)
            }
            VStack(spacing: Theme.Spacing.s) {
                ForEach(newPRs, id: \.newPR.id) { pr in
                    prCard(pr)
                }
            }
        }
    }

    private func prCard(_ pr: (exercise: Exercise, newPR: SetEntry, previousPR: SetEntry)) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: pr.exercise.iconSystemName)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.orange.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exercise.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Text(pr.previousPR.summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(pr.newPR.summaryText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.orange)
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }

    // MARK: - Muscle Map

    private var muscleMapSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("Muskeln").font(.headline)
                Spacer()
                Picker("", selection: $muscleMapShowFront) {
                    Text("Vorne").tag(true)
                    Text("Hinten").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            SessionMuscleMapView(
                volumes: muscleVolumes,
                selectedMuscle: $selectedMapMuscle,
                showFront: $muscleMapShowFront
            )
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
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
