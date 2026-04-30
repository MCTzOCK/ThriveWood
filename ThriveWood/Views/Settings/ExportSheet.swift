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
    @Environment(\.dismiss) private var dismiss

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
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                icon
                title
                if let summary, phase == .done { summaryCard(summary) }
                if let error, phase == .failed { errorBanner(error) }
                actions
                Spacer()
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    // MARK: Icon

    @ViewBuilder
    private var icon: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.12))
                .frame(width: 120, height: 120)
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(iconColor.gradient)
                .symbolEffect(.bounce, value: phase == .done)
        }
    }

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

    // MARK: Title

    @ViewBuilder
    private var title: some View {
        VStack(spacing: Theme.Spacing.s) {
            switch phase {
            case .ready:
                Text("Daten exportieren").font(.title2.bold())
                Text("Erstelle ein vollständiges JSON-Backup aller deiner Daten.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            case .exporting:
                Text("Exportiere…").font(.title2.bold())
                ProgressView().padding(.top, 4)
            case .done:
                Text("Export fertig!").font(.title2.bold())
                Text(fileSize).font(.subheadline).foregroundStyle(.secondary)
            case .failed:
                Text("Export fehlgeschlagen").font(.title2.bold()).foregroundStyle(.red)
            }
        }
    }

    // MARK: Summary

    private func summaryCard(_ s: ExportSummary) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            summaryRow("Habits", count: s.habits, icon: "checklist")
            summaryRow("Abhakungen", count: s.completions, icon: "checkmark.circle")
            summaryRow("Bäume", count: s.trees, icon: "tree.fill")
            summaryRow("Übungen", count: s.exercises, icon: "dumbbell.fill")
            summaryRow("Workouts", count: s.workouts, icon: "figure.strengthtraining.traditional")
            summaryRow("Sessions", count: s.sessions, icon: "calendar")
            summaryRow("Sätze", count: s.sets, icon: "number")
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func summaryRow(_ label: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.secondary)
            Text(label).font(.subheadline)
            Spacer()
            Text("\(count)").font(.subheadline.monospacedDigit().weight(.semibold))
        }
    }

    private func errorBanner(_ error: Error) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(error.localizedDescription).font(.caption)
        }
        .padding(Theme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Color.red.opacity(0.1)))
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        switch phase {
        case .ready:
            Button { Task { await generate() } } label: {
                Label("Export starten", systemImage: "arrow.down.doc.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.blue.gradient))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

        case .exporting:
            EmptyView()

        case .done:
            if let url {
                ShareLink(item: url) {
                    Label("Backup teilen", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.green.gradient))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            Button { phase = .ready; url = nil; summary = nil } label: {
                Text("Neuen Export erstellen")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

        case .failed:
            Button { Task { await generate() } } label: {
                Label("Erneut versuchen", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.blue.gradient))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
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

            summary = ExportSummary(
                habits: habits.count,
                completions: completions.count,
                trees: trees.count,
                exercises: exercises.count,
                workouts: workouts.count,
                sessions: sessions.count,
                sets: sets.count
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
