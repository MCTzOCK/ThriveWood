//
//  WorkoutSummaryImage.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//


import SwiftUI

struct WorkoutSummaryImage: View {
    let session: WorkoutSession
    let sortedExercises: [(Exercise, [SetEntry])]
    let totalVolumeKg: Double
    let totalReps: Int
    let totalDistanceKm: Double
    let activeDurationSeconds: Int
    let completedSets: Int
    let totalSets: Int

    private var workoutColor: HabitColor { session.workout?.color ?? .blue }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().padding(.horizontal, 20)
            statsSection
            if !sortedExercises.isEmpty {
                Divider().padding(.horizontal, 20)
                exercisesSection
            }
            footerSection
        }
        .frame(width: 400)
        .background(
            ZStack {
                Color(.systemGroupedBackground)
                LinearGradient(
                    colors: [workoutColor.color.opacity(0.08), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(workoutColor.color.opacity(0.2), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(workoutColor.gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.workout?.name ?? "Freies Training")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: Theme.Spacing.s) {
                if let dur = session.durationSeconds {
                    PillBadge(icon: "clock.fill", text: formattedDuration(dur), tint: workoutColor.color)
                }
                PillBadge(icon: "checkmark.circle.fill", text: "\(completedSets) Sätze", tint: .green)
            }
        }
        .padding(Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.m)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            if totalVolumeKg > 0 {
                statItem(value: "\(Int(totalVolumeKg))", unit: "kg", label: "Volumen", tint: .purple)
            }
            if totalReps > 0 {
                statItem(value: "\(totalReps)", unit: "", label: "Reps", tint: .orange)
            }
            if totalDistanceKm > 0 {
                statItem(value: String(format: "%.1f", totalDistanceKm), unit: "km", label: "Distanz", tint: .teal)
            }
            if activeDurationSeconds > 0 {
                statItem(value: formattedDuration(activeDurationSeconds), unit: "", label: "Aktive Zeit", tint: .pink)
            }
        }
        .padding(.vertical, Theme.Spacing.m)
    }

    private func statItem(value: String, unit: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value).font(.title3.bold().monospacedDigit())
                if !unit.isEmpty {
                    Text(unit).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ForEach(Array(sortedExercises.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: pair.0.iconSystemName)
                        .font(.caption)
                        .foregroundStyle(workoutColor.color)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(workoutColor.color.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pair.0.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(exerciseSummary(pair))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(pair.1.filter(\.isCompleted).count)/\(pair.1.count)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.m)
    }

    private func exerciseSummary(_ pair: (Exercise, [SetEntry])) -> String {
        let completed = pair.1.filter(\.isCompleted)
        switch pair.0.trackingType {
        case .repsWeight:
            let vol = completed.reduce(0.0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
            return vol > 0 ? "\(Int(vol)) kg Vol." : ""
        case .reps:
            let total = completed.reduce(0) { $0 + ($1.reps ?? 0) }
            return total > 0 ? "\(total) Reps" : ""
        case .duration:
            let total = completed.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return total > 0 ? formattedDuration(total) : ""
        case .distanceDuration:
            let d = completed.reduce(0.0) { $0 + ($1.distanceMeters ?? 0) } / 1000
            return d > 0 ? String(format: "%.2f km", d) : ""
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Spacer()
            Text("ThriveWood")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(workoutColor.color.opacity(0.6))
        }
        .padding(Theme.Spacing.m)
    }

    // MARK: - Helpers

    private func formattedDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0
            ? String(format: "%dh %dm", h, m)
            : (m > 0 ? "\(m) min" : "\(s) s")
    }
}

private struct PillBadge: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.15)))
    }
}

// MARK: - Share Sheet

struct WorkoutSummaryShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
