//
//  WorkoutSummaryImage.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//


import SwiftUI

// MARK: - Design Enum

enum SummaryDesign: Int, CaseIterable, Identifiable {
    case dark = 0
    case minimal = 1
    case bold = 2
    case compact = 3
    case gradient = 4
    case statsCard = 5
    case neon = 6
    case statsOnly = 7

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .dark: "Dark"
        case .minimal: "Minimal"
        case .bold: "Bold"
        case .compact: "Compact"
        case .gradient: "Gradient"
        case .statsCard: "Stats"
        case .neon: "Neon"
        case .statsOnly: "Numbers"
        }
    }

    var showsExercises: Bool {
        switch self {
        case .dark, .minimal, .bold, .compact, .gradient, .neon: true
        case .statsCard, .statsOnly: false
        }
    }
}

// MARK: - Shared Data

struct SummaryData {
    let session: WorkoutSession
    let sortedExercises: [(Exercise, [SetEntry])]
    let totalVolumeKg: Double
    let totalReps: Int
    let totalDistanceKm: Double
    let activeDurationSeconds: Int
    let completedSets: Int
    let totalSets: Int

    var workoutColor: HabitColor { session.workout?.color ?? .blue }

    var durationText: String {
        guard let dur = session.durationSeconds else { return "–" }
        return Self.formatDuration(dur)
    }

    var exerciseCount: Int { sortedExercises.count }

    func exerciseSummary(_ pair: (Exercise, [SetEntry])) -> String {
        let completed = pair.1.filter(\.isCompleted)
        switch pair.0.trackingType {
        case .repsWeight:
            let vol = completed.reduce(0.0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
            return vol > 0 ? "\(Int(vol)) kg" : ""
        case .reps:
            let total = completed.reduce(0) { $0 + ($1.reps ?? 0) }
            return total > 0 ? "\(total) Reps" : ""
        case .duration:
            let total = completed.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return total > 0 ? Self.formatDuration(total) : ""
        case .distanceDuration:
            let d = completed.reduce(0.0) { $0 + ($1.distanceMeters ?? 0) } / 1000
            return d > 0 ? String(format: "%.1f km", d) : ""
        }
    }

    static func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : (m > 0 ? "\(m) min" : "\(seconds) s")
    }
}

// MARK: - Design Router

struct WorkoutSummaryImage: View {
    let data: SummaryData
    let design: SummaryDesign

    var body: some View {
        switch design {
        case .dark: DarkDesign(data: data)
        case .minimal: MinimalDesign(data: data)
        case .bold: BoldDesign(data: data)
        case .compact: CompactDesign(data: data)
        case .gradient: GradientDesign(data: data)
        case .statsCard: StatsCardDesign(data: data)
        case .neon: NeonDesign(data: data)
        case .statsOnly: StatsOnlyDesign(data: data)
        }
    }
}

// MARK: - Dark Design

private struct DarkDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 20)
            stats
            if !data.sortedExercises.isEmpty {
                Divider().padding(.horizontal, 20)
                exerciseList
            }
            footer
        }
        .frame(width: 400)
        .background(
            ZStack {
                Color.groupedBackground
                LinearGradient(colors: [color.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(data.workoutColor.gradient).frame(width: 48, height: 48)
                    Image(systemName: "dumbbell.fill").font(.title3).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.session.workout?.name ?? "Freies Training")
                        .font(.title3.bold()).foregroundStyle(.primary)
                    Text(data.session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: Theme.Spacing.s) {
                PillBadge(icon: "clock.fill", text: data.durationText, tint: color)
                PillBadge(icon: "checkmark.circle.fill", text: "\(data.completedSets) Sätze", tint: .green)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl).padding(.top, Theme.Spacing.xl).padding(.bottom, Theme.Spacing.m)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            if data.totalVolumeKg > 0 { statItem(value: "\(Int(data.totalVolumeKg))", unit: "kg", label: "Volumen", tint: .purple) }
            if data.totalReps > 0 { statItem(value: "\(data.totalReps)", unit: "", label: "Reps", tint: .orange) }
            if data.totalDistanceKm > 0 { statItem(value: String(format: "%.1f", data.totalDistanceKm), unit: "km", label: "Distanz", tint: .teal) }
            if data.activeDurationSeconds > 0 { statItem(value: SummaryData.formatDuration(data.activeDurationSeconds), unit: "", label: "Aktive Zeit", tint: .pink) }
        }
        .padding(.vertical, Theme.Spacing.m)
    }

    private func statItem(value: String, unit: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value).font(.title3.bold().monospacedDigit())
                if !unit.isEmpty { Text(unit).font(.caption.weight(.semibold)).foregroundStyle(.secondary) }
            }
            .foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: pair.0.iconSystemName)
                        .font(.caption).foregroundStyle(color)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(color.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pair.0.name).font(.caption.weight(.semibold)).foregroundStyle(.primary)
                        if !data.exerciseSummary(pair).isEmpty {
                            Text(data.exerciseSummary(pair)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(pair.1.filter(\.isCompleted).count)/\(pair.1.count)")
                        .font(.caption2.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.m)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("ThriveWood").font(.caption2.weight(.semibold)).foregroundStyle(color.opacity(0.6))
        }
        .padding(Theme.Spacing.m)
    }
}

// MARK: - Minimal Design

private struct MinimalDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Theme.Spacing.m) {
                Text(data.session.workout?.name ?? "Freies Training")
                    .font(.title2.bold().italic())
                Text(data.session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: Theme.Spacing.l) {
                    if let dur = data.session.durationSeconds {
                        miniStat(label: "Dauer", value: SummaryData.formatDuration(dur))
                    }
                    miniStat(label: "Sätze", value: "\(data.completedSets)/\(data.totalSets)")
                    if data.totalVolumeKg > 0 {
                        miniStat(label: "Volumen", value: "\(Int(data.totalVolumeKg)) kg")
                    }
                }
            }
            .padding(Theme.Spacing.xl)

            if !data.sortedExercises.isEmpty {
                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1).padding(.horizontal, Theme.Spacing.l)
                VStack(spacing: 8) {
                    ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                        HStack {
                            Text(pair.0.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(pair.1.filter(\.isCompleted).count)×")
                                .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                            if !data.exerciseSummary(pair).isEmpty {
                                Text(data.exerciseSummary(pair)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
            }

            HStack {
                Spacer()
                Text("ThriveWood").font(.caption2).foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.bottom, Theme.Spacing.m)
        }
        .frame(width: 400)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
        .environment(\.colorScheme, .light)
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.monospacedDigit()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Bold Design

private struct BoldDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                data.workoutColor.gradient
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(data.session.workout?.name ?? "Freies Training")
                        .font(.title.bold()).foregroundStyle(.white)
                    Text(data.session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    HStack(spacing: Theme.Spacing.l) {
                        if let dur = data.session.durationSeconds {
                            boldStat(value: SummaryData.formatDuration(dur), label: "Dauer")
                        }
                        boldStat(value: "\(data.completedSets)", label: "Sätze")
                        if data.totalVolumeKg > 0 {
                            boldStat(value: "\(Int(data.totalVolumeKg))", label: "kg")
                        }
                        if data.totalReps > 0 {
                            boldStat(value: "\(data.totalReps)", label: "Reps")
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.xl)
            }

            if !data.sortedExercises.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: Theme.Spacing.m) {
                            ZStack {
                                Circle().fill(color.opacity(0.12)).frame(width: 28, height: 28)
                                Image(systemName: pair.0.iconSystemName).font(.caption2).foregroundStyle(color)
                            }
                            Text(pair.0.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(pair.1.filter(\.isCompleted).count)/\(pair.1.count)")
                                .font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
                            if !data.exerciseSummary(pair).isEmpty {
                                Text(data.exerciseSummary(pair)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.l)
            }

            HStack {
                Spacer()
                Text("ThriveWood").font(.caption2.weight(.semibold)).foregroundStyle(color.opacity(0.5))
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.bottom, Theme.Spacing.m)
        }
        .frame(width: 400)
        .background(Color.groupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    private func boldStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Compact Design

private struct CompactDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            exerciseGrid
            Divider()
            bottomBar
        }
        .frame(width: 400)
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.15), lineWidth: 1.5))
        .environment(\.colorScheme, .dark)
    }

    private var headerBar: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle().fill(data.workoutColor.gradient).frame(width: 40, height: 40)
                Image(systemName: "dumbbell.fill").font(.callout).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(data.session.workout?.name ?? "Freies Training").font(.headline)
                Text(data.session.startedAt.formatted(.dateTime.day().month(.abbreviated))).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(data.durationText).font(.headline.monospacedDigit())
                Text("\(data.completedSets)/\(data.totalSets) Sätze").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m)
    }

    private var exerciseGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 6) {
                    Image(systemName: pair.0.iconSystemName).font(.caption2).foregroundStyle(color)
                    Text(pair.0.name).font(.caption.weight(.semibold)).lineLimit(1)
                    Spacer(minLength: 0)
                    Text("\(pair.1.filter(\.isCompleted).count)/\(pair.1.count)")
                        .font(.caption2.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cardBackground))
            }
        }
        .padding(.horizontal, Theme.Spacing.m).padding(.vertical, Theme.Spacing.s)
    }

    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.l) {
            if data.totalVolumeKg > 0 {
                Text("\(Int(data.totalVolumeKg)) kg").font(.caption.weight(.semibold)).foregroundStyle(.purple)
            }
            if data.totalReps > 0 {
                Text("\(data.totalReps) Reps").font(.caption.weight(.semibold)).foregroundStyle(.orange)
            }
            if data.totalDistanceKm > 0 {
                Text(String(format: "%.1f km", data.totalDistanceKm)).font(.caption.weight(.semibold)).foregroundStyle(.teal)
            }
            Spacer()
            Text("ThriveWood").font(.caption2.weight(.semibold)).foregroundStyle(color.opacity(0.5))
        }
        .padding(Theme.Spacing.m)
    }
}

// MARK: - Gradient Design (stats only, no exercises)

private struct GradientDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [color, color.opacity(0.6), Color.groupedBackground],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                VStack(spacing: Theme.Spacing.l) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.white.opacity(0.2)))

                    Text(data.session.workout?.name ?? "Freies Training")
                        .font(.title2.bold()).foregroundStyle(.white)

                    HStack(spacing: Theme.Spacing.m) {
                        if let dur = data.session.durationSeconds {
                            gStat(value: SummaryData.formatDuration(dur), label: "Dauer")
                        }
                        gStat(value: "\(data.completedSets)/\(data.totalSets)", label: "Sätze")
                        if data.totalVolumeKg > 0 {
                            gStat(value: "\(Int(data.totalVolumeKg)) kg", label: "Volumen")
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
            }

            if !data.sortedExercises.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: Theme.Spacing.m) {
                            Text(pair.0.name).font(.caption.weight(.semibold))
                            Spacer()
                            Text("\(pair.1.filter(\.isCompleted).count)×")
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            if !data.exerciseSummary(pair).isEmpty {
                                Text(data.exerciseSummary(pair)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.m)
            }

            HStack {
                Spacer()
                Text("ThriveWood").font(.caption2.weight(.semibold)).foregroundStyle(color.opacity(0.5))
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.bottom, Theme.Spacing.m)
        }
        .frame(width: 400)
        .background(Color.groupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    private func gStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.bold().monospacedDigit()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Card Design (no exercises, large stats)

private struct StatsCardDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(data.workoutColor.gradient).frame(width: 52, height: 52)
                    Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.session.workout?.name ?? "Freies Training")
                        .font(.title2.bold()).foregroundStyle(.primary)
                    Text(data.session.startedAt.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.xl).padding(.top, Theme.Spacing.xl)

            if let dur = data.session.durationSeconds {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").font(.caption2).foregroundStyle(color)
                    Text(SummaryData.formatDuration(dur))
                        .font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(color)
                }
                .padding(.horizontal, Theme.Spacing.xl).padding(.top, Theme.Spacing.s)
            }

            let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: cols, spacing: 12) {
                if data.totalVolumeKg > 0 {
                    bigStatTile(icon: "scalemass.fill", value: "\(Int(data.totalVolumeKg))", unit: "kg", label: "Volumen", tint: .purple)
                }
                if data.totalReps > 0 {
                    bigStatTile(icon: "number", value: "\(data.totalReps)", unit: "", label: "Reps", tint: .orange)
                }
                if data.totalDistanceKm > 0 {
                    bigStatTile(icon: "location.fill", value: String(format: "%.1f", data.totalDistanceKm), unit: "km", label: "Distanz", tint: .teal)
                }
                if data.activeDurationSeconds > 0 {
                    bigStatTile(icon: "timer", value: SummaryData.formatDuration(data.activeDurationSeconds), unit: "", label: "Aktive Zeit", tint: .pink)
                }
                bigStatTile(icon: "checkmark.circle.fill", value: "\(data.completedSets)", unit: "/\(data.totalSets)", label: "Sätze", tint: .green)
                bigStatTile(icon: "dumbbell.fill", value: "\(data.exerciseCount)", unit: "", label: "Übungen", tint: color)
            }
            .padding(Theme.Spacing.l)

            HStack {
                Spacer()
                Text("ThriveWood").font(.caption2.weight(.semibold)).foregroundStyle(color.opacity(0.6))
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.bottom, Theme.Spacing.m)
        }
        .frame(width: 400)
        .background(
            ZStack {
                Color.groupedBackground
                LinearGradient(colors: [color.opacity(0.05), .clear], startPoint: .top, endPoint: .center)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.opacity(0.15), lineWidth: 1))
        .environment(\.colorScheme, .dark)
    }

    private func bigStatTile(icon: String, value: String, unit: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.callout).foregroundStyle(tint)
                .padding(8).background(Circle().fill(tint.opacity(0.15)))
            HStack(spacing: 2) {
                Text(value).font(.title2.bold().monospacedDigit())
                if !unit.isEmpty { Text(unit).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary) }
            }
            .foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous).fill(Color.cardBackground))
    }
}

// MARK: - Neon Design

private struct NeonDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 64, height: 64)
                    Image(systemName: "dumbbell.fill")
                        .font(.title).foregroundStyle(color)
                        .shadow(color: color.opacity(0.6), radius: 8)
                }
                Text(data.session.workout?.name ?? "Freies Training")
                    .font(.title.bold()).foregroundStyle(color)
                    .shadow(color: color.opacity(0.4), radius: 6)
                Text(data.session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline).foregroundStyle(.secondary)

                HStack(spacing: Theme.Spacing.xl) {
                    if let dur = data.session.durationSeconds {
                        neonStat(value: SummaryData.formatDuration(dur), label: "Dauer")
                    }
                    neonStat(value: "\(data.completedSets)", label: "Sätze")
                    if data.totalVolumeKg > 0 {
                        neonStat(value: "\(Int(data.totalVolumeKg))", label: "kg")
                    }
                }
            }
            .padding(Theme.Spacing.xl)

            if !data.sortedExercises.isEmpty {
                Rectangle().fill(color.opacity(0.2)).frame(height: 1).padding(.horizontal, Theme.Spacing.l)

                VStack(spacing: 6) {
                    ForEach(Array(data.sortedExercises.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: pair.0.iconSystemName)
                                .font(.caption).foregroundStyle(color)
                                .shadow(color: color.opacity(0.5), radius: 4)
                            Text(pair.0.name).font(.caption.weight(.semibold)).foregroundStyle(.primary)
                            Spacer()
                            Text("\(pair.1.filter(\.isCompleted).count)/\(pair.1.count)")
                                .font(.caption2.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
                            if !data.exerciseSummary(pair).isEmpty {
                                Text(data.exerciseSummary(pair)).font(.caption2).foregroundStyle(color.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.l)
            }

            HStack {
                Spacer()
                Text("ThriveWood").font(.caption2.weight(.bold)).foregroundStyle(color)
                    .shadow(color: color.opacity(0.4), radius: 4)
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.bottom, Theme.Spacing.m)
        }
        .frame(width: 400)
        .background(
            ZStack {
                Color.black
                RadialGradient(colors: [color.opacity(0.15), .clear], center: .top, startRadius: 0, endRadius: 400)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.opacity(0.4), lineWidth: 1.5))
        .environment(\.colorScheme, .dark)
    }

    private func neonStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 6)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stats Only Design (no exercises, minimal numbers)

private struct StatsOnlyDesign: View {
    let data: SummaryData
    private var color: Color { data.workoutColor.color }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: 4) {
                Text(data.session.workout?.name ?? "Freies Training")
                    .font(.largeTitle.bold()).foregroundStyle(color)
                Text(data.session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()))
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if let dur = data.session.durationSeconds {
                Text(SummaryData.formatDuration(dur))
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(color)
            }

            HStack(spacing: 0) {
                if data.totalVolumeKg > 0 {
                    numStat(value: "\(Int(data.totalVolumeKg))", unit: "kg", tint: .purple)
                }
                if data.totalReps > 0 {
                    numStat(value: "\(data.totalReps)", unit: "Reps", tint: .orange)
                }
                if data.totalDistanceKm > 0 {
                    numStat(value: String(format: "%.1f", data.totalDistanceKm), unit: "km", tint: .teal)
                }
                if data.activeDurationSeconds > 0 {
                    numStat(value: SummaryData.formatDuration(data.activeDurationSeconds), unit: "", tint: .pink)
                }
            }

            HStack(spacing: Theme.Spacing.l) {
                circleStat(value: data.completedSets, label: "Sätze", tint: .green)
                circleStat(value: data.exerciseCount, label: "Übungen", tint: color)
            }

            Text("ThriveWood")
                .font(.caption.weight(.semibold)).foregroundStyle(color.opacity(0.4))
        }
        .padding(Theme.Spacing.xxl)
        .frame(width: 400)
        .background(
            ZStack {
                Color.groupedBackground
                LinearGradient(colors: [color.opacity(0.06), .clear], startPoint: .center, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(color.opacity(0.1), lineWidth: 1))
        .environment(\.colorScheme, .dark)
    }

    private func numStat(value: String, unit: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title.bold().monospacedDigit()).foregroundStyle(tint)
            if !unit.isEmpty {
                Text(unit).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func circleStat(value: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(tint.opacity(0.2), lineWidth: 3).frame(width: 56, height: 56)
                Text("\(value)").font(.title3.bold().monospacedDigit()).foregroundStyle(tint)
            }
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PillBadge: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.15)))
    }
}

#if os(iOS)
struct WorkoutSummaryShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif