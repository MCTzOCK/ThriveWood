//
//  ImportSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 30.04.26.
//


import SwiftUI
import UniformTypeIdentifiers

struct ImportSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme
    let onComplete: () async -> Void

    @State private var phase: Phase = .ready
    @State private var importing = false
    @State private var result: BackupService.ImportResult?
    @State private var error: Error?

    enum Phase { case ready, previewing, importing, done, failed }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor.gradient)
            }
            .padding(.top, Theme.Spacing.m)

            phaseHeader

            if let result, phase == .done {
                importResultCard(result)
            }

            if let error, phase == .failed {
                BentoCallout(
                    kind: .error,
                    title: Text("Import fehlgeschlagen"),
                    message: Text(error.localizedDescription)
                )
            }

            phaseActions
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.json]
        ) { fileResult in
            Task { await handleFile(fileResult) }
        }
    }

    // MARK: - Icon

    private var iconName: String {
        phase == .done ? "checkmark.circle.fill" : "tray.and.arrow.down.fill"
    }

    private var iconColor: Color {
        switch phase {
        case .failed: .red
        case .done: .green
        default: .orange
        }
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        VStack(spacing: Theme.Spacing.s) {
            switch phase {
            case .ready, .previewing:
                BentoText("Backup einspielen", style: .title2)
                BentoText(
                    "Wähle eine ThriveWood-Backup-Datei (.json). Bestehende Daten werden ergänzt – nicht überschrieben.",
                    style: .callout,
                    color: theme.colors.onBackground
                )
                .multilineTextAlignment(.center)
            case .importing:
                BentoText("Importiere…", style: .title2)
                BentoSpinner(size: 28)
            case .done:
                BentoText("Import abgeschlossen!", style: .title2)
            case .failed:
                BentoText("Import fehlgeschlagen", style: .title2, color: .red)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result Card

    private func importResultCard(_ r: BackupService.ImportResult) -> some View {
        BentoCard(padding: .lg, radius: .large) {
            VStack(spacing: Theme.Spacing.s) {
                resultRow("Habits", count: r.habits, icon: "checklist")
                resultRow("Abhakungen", count: r.completions, icon: "checkmark.circle")
                resultRow("Bäume", count: r.trees, icon: "tree.fill")
                resultRow("Übungen", count: r.exercises, icon: "dumbbell.fill")
                resultRow("Workouts", count: r.workouts, icon: "figure.strengthtraining.traditional")
                resultRow("Sessions", count: r.sessions, icon: "calendar")
                resultRow("Sätze", count: r.sets, icon: "number")
                resultRow("Supplements", count: r.supplements, icon: "pills.fill")
                resultRow("Supplement-Einträge", count: r.supplementEntries, icon: "cross.case.fill")
                BentoDivider()
                HStack {
                    BentoText("Gesamt importiert", style: .bodyStrong)
                    Spacer()
                    Text(verbatim: "\(r.total)")
                        .monospacedDigit()
                        .bentoTextStyle(.bodyStrong, color: .green)
                }
            }
        }
    }

    private func resultRow(_ label: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            BentoText(verbatim: label, style: .body)
            Spacer()
            Text(verbatim: count > 0 ? "+\(count)" : "–")
                .monospacedDigit()
                .bentoTextStyle(.body, color: count > 0 ? .green : .secondary)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var phaseActions: some View {
        switch phase {
        case .ready, .previewing:
            BentoButton(
                Text("Datei auswählen"),
                systemImage: "folder.fill",
                variant: .primary,
                expands: true
            ) { importing = true }

        case .importing:
            EmptyView()

        case .done:
            BentoButton(
                Text("Fertig"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                Task { await onComplete() }
                dismiss()
            }

        case .failed:
            BentoButton(
                Text("Andere Datei wählen"),
                systemImage: "arrow.clockwise",
                variant: .primary,
                expands: true
            ) { importing = true }
        }
    }

    // MARK: - Logic

    private func handleFile(_ fileResult: Result<URL, Error>) async {
        do {
            let url = try fileResult.get()
            guard url.startAccessingSecurityScopedResource() else {
                throw BackupError.corruptedData
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)

            // Validierung: ist es überhaupt ein ThriveWood-Backup?
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let test = try decoder.decode(ThriveWoodBackup.self, from: data)
            guard test.version <= ThriveWoodBackup.currentVersion else {
                throw BackupError.unsupportedVersion(test.version)
            }

            phase = .importing
            let importResult = try await env.backupService.importAll(data)
            result = importResult
            phase = .done
            Haptics.success()
        } catch {
            self.error = error
            phase = .failed
            Haptics.warning()
        }
    }
}
