//
//  ExportSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 30.04.26.
//


import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.bentoTheme) private var theme

    @State private var phase: Phase = .ready
    @State private var url: URL?
    @State private var fileSize: String = ""
    @State private var summary: ExportSummary?
    @State private var error: Error?

    enum Phase { case ready, exporting, done, failed }

    struct ExportSummary {
        let habits: Int
        let completions: Int
        let trees: Int
        let exercises: Int
        let workouts: Int
        let sessions: Int
        let sets: Int
        let supplements: Int
        let supplementEntries: Int
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor.gradient)
                    .symbolEffect(.bounce, value: phase == .done)
            }
            .padding(.top, Theme.Spacing.m)

            phaseHeader

            if let summary, phase == .done {
                summaryCard(summary)
            }

            if let error, phase == .failed {
                BentoCallout(
                    kind: .error,
                    title: Text("Export fehlgeschlagen"),
                    message: Text(error.localizedDescription)
                )
            }

            actions
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Icon

    private var iconName: String {
        switch phase {
        case .ready: "tray.and.arrow.up.fill"
        case .exporting: "arrow.triangle.2.circlepath"
        case .done: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch phase {
        case .ready: .blue
        case .exporting: .blue
        case .done: .green
        case .failed: .red
        }
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        VStack(spacing: Theme.Spacing.s) {
            switch phase {
            case .ready:
                BentoText("Daten exportieren", style: .title2)
                BentoText(
                    "Erstelle ein vollständiges JSON-Backup aller deiner Daten.",
                    style: .callout,
                    color: theme.colors.onBackground
                )
                .multilineTextAlignment(.center)
            case .exporting:
                BentoText("Exportiere…", style: .title2)
                BentoSpinner(size: 28)
            case .done:
                BentoText("Export fertig!", style: .title2)
                BentoText(verbatim: fileSize, style: .callout, color: .secondary)
            case .failed:
                BentoText("Export fehlgeschlagen", style: .title2, color: .red)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Summary

    private func summaryCard(_ s: ExportSummary) -> some View {
        BentoCard(padding: .lg, radius: .large) {
            VStack(spacing: Theme.Spacing.s) {
                summaryRow("Habits", count: s.habits, icon: "checklist")
                summaryRow("Abhakungen", count: s.completions, icon: "checkmark.circle")
                summaryRow("Bäume", count: s.trees, icon: "tree.fill")
                summaryRow("Übungen", count: s.exercises, icon: "dumbbell.fill")
                summaryRow("Workouts", count: s.workouts, icon: "figure.strengthtraining.traditional")
                summaryRow("Sessions", count: s.sessions, icon: "calendar")
                summaryRow("Sätze", count: s.sets, icon: "number")
                summaryRow("Supplements", count: s.supplements, icon: "pills.fill")
                summaryRow("Supplement-Einträge", count: s.supplementEntries, icon: "pills")
            }
        }
    }

    private func summaryRow(_ label: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            BentoText(verbatim: label, style: .body)
            Spacer()
            Text(verbatim: "\(count)")
                .monospacedDigit()
                .bentoTextStyle(.body)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        switch phase {
        case .ready:
            BentoButton(
                Text("Export starten"),
                systemImage: "arrow.down.doc.fill",
                variant: .primary,
                expands: true
            ) { Task { await generate() } }

        case .exporting:
            EmptyView()

        case .done:
            VStack(spacing: Theme.Spacing.s) {
                if let url {
                    ShareLink(item: url) {
                        Label("Backup teilen", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.m)
                            .background(Capsule().fill(Color.green))
                            .foregroundStyle(.white)
                    }
                }
            }

        case .failed:
            BentoButton(
                Text("Erneut versuchen"),
                systemImage: "arrow.clockwise",
                variant: .primary,
                expands: true
            ) { Task { await generate() } }
        }
    }

    // MARK: - Logic

    private func generate() async {
        phase = .exporting
        error = nil
        do {
            let data = try await env.backupService.exportAll()

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            fileSize = formatter.string(fromByteCount: Int64(data.count))

            let dateStr = Date.now.formatted(.dateTime
                .year().month(.twoDigits).day(.twoDigits)
                .hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "/", with: "-")
            let filename = "ThriveWood-Backup-\(dateStr).json"
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tmp)
            url = tmp

            // Summary direkt über die Repos statt nochmal JSON parsen
            let habits = (try? env.habitRepo.fetchAll(includeArchived: true)) ?? []
            let completions = (try? env.completionRepo.allCompletions()) ?? []
            let forest = try? env.forestRepo.currentForest()
            let trees = forest.flatMap { try? env.treeRepo.fetchAll(in: $0) } ?? []
            let exercises = (try? env.exerciseRepo.fetchAll())?.filter { !$0.isBuiltIn } ?? []
            let workouts = (try? env.workoutRepo.fetchAll(includeArchived: true)) ?? []
            let sessions = (try? env.sessionRepo.fetchAll()) ?? []
            let sets = sessions.flatMap(\.sets)
            let supplements = (try? env.supplementRepo.fetchAll(includeArchived: true)) ?? []
            let supplementEntries = (try? env.supplementEntryRepo.fetchAll()) ?? []

            summary = ExportSummary(
                habits: habits.count,
                completions: completions.count,
                trees: trees.count,
                exercises: exercises.count,
                workouts: workouts.count,
                sessions: sessions.count,
                sets: sets.count,
                supplements: supplements.count,
                supplementEntries: supplementEntries.count
            )

            phase = .done
            Haptics.success()
        } catch {
            self.error = error
            phase = .failed
            Haptics.warning()
        }
    }

}
