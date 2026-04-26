//
//  WorkoiutSessionDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//

import Foundation
import SwiftUI
import Charts


struct WorkoutSessionDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession

    @State private var isEditing = false
    @State private var draftNotes: String = ""
    @State private var draftRPE: Int = 7
    @State private var showDeleteConfirm = false
    @State private var errors = ErrorState()

    // MARK: - Derived

    private var sortedExercises: [(Exercise, [SetEntry])] {
        let groups = Dictionary(grouping: session.sets) { $0.exercise?.id ?? UUID() }
        // Wenn ein Plan existiert: Reihenfolge des Plans übernehmen
        if let plan = session.workout?.exercises.sorted(by: { $0.order < $1.order }), !plan.isEmpty {
            return plan.compactMap { slot in
                guard let ex = slot.exercise else { return nil }
                let sets = (groups[ex.id] ?? []).sorted { $0.order < $1.order }
                guard !sets.isEmpty else { return nil }
                return (ex, sets)
            }
        }
        // Sonst alphabetisch
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

    private var heaviestSet: (Exercise, SetEntry)? {
        let candidates = session.sets
            .filter { $0.exercise?.trackingType == .repsWeight && $0.isCompleted }
        guard let max = candidates.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }),
              let ex = max.exercise else { return nil }
        return (ex, max)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                headerCard
                statsGrid
                if !sortedExercises.isEmpty { exerciseBreakdown }
                if let pr = heaviestSet { highlightCard(pr) }
                notesCard
                Spacer(minLength: 40)
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.horizontal, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.workout?.name ?? "Freies Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .errorAlert(errors)
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
                    draftNotes = session.notes
                    draftRPE = session.perceivedExertion ?? 7
                    isEditing = true
                } label: { Label("Notizen bearbeiten", systemImage: "pencil") }

                ShareLink(item: shareText) {
                    Label("Teilen", systemImage: "square.and.arrow.up")
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
                    Image(systemName: "pencil").foregroundStyle(.blue)
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

    // MARK: - Actions

    private func delete() {
        do {
            try env.sessionRepo.delete(session)
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
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

// MARK: - StatTile

private struct StatTile: View {
    let icon: String; let tint: Color; let value: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(tint)
                .padding(8)
                .background(Circle().fill(tint.opacity(0.15)))
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}
