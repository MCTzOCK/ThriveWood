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
    let onComplete: () async -> Void

    @State private var phase: Phase = .ready
    @State private var importing = false
    @State private var result: BackupService.ImportResult?
    @State private var error: Error?
    @State private var showConfirmation = false
    @State private var pendingURL: URL?

    enum Phase { case ready, previewing, importing, done, failed }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(phase == .done ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: phase == .done ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(phase == .done ? Color.green.gradient : Color.orange.gradient)
                }

                VStack(spacing: Theme.Spacing.s) {
                    switch phase {
                    case .ready, .previewing:
                        Text("Backup einspielen").font(.title2.bold())
                        Text("Wähle eine ThriveWood-Backup-Datei (.json). Bestehende Daten werden ergänzt – nicht überschrieben.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    case .importing:
                        Text("Importiere…").font(.title2.bold())
                        ProgressView().padding(.top, 4)
                    case .done:
                        Text("Import abgeschlossen!").font(.title2.bold())
                    case .failed:
                        Text("Import fehlgeschlagen").font(.title2.bold()).foregroundStyle(.red)
                    }
                }

                if let result, phase == .done {
                    importResultCard(result)
                }

                if let error, phase == .failed {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                        Text(error.localizedDescription).font(.caption)
                    }
                    .padding(Theme.Spacing.m)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Color.red.opacity(0.1)))
                }

                Spacer()

                switch phase {
                case .ready, .previewing:
                    Button { importing = true } label: {
                        Label("Datei auswählen", systemImage: "folder.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.orange.gradient))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                case .importing:
                    EmptyView()
                case .done:
                    Button {
                        Task { await onComplete() }
                        dismiss()
                    } label: {
                        Text("Fertig")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.green.gradient))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                case .failed:
                    Button { importing = true } label: {
                        Label("Andere Datei wählen", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.orange.gradient))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                Spacer().frame(height: Theme.Spacing.l)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.json]
            ) { fileResult in
                Task { await handleFile(fileResult) }
            }
        }
    }

    private func importResultCard(_ r: BackupService.ImportResult) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            resultRow("Habits", count: r.habits, icon: "checklist")
            resultRow("Abhakungen", count: r.completions, icon: "checkmark.circle")
            resultRow("Bäume", count: r.trees, icon: "tree.fill")
            resultRow("Übungen", count: r.exercises, icon: "dumbbell.fill")
            resultRow("Workouts", count: r.workouts, icon: "figure.strengthtraining.traditional")
            resultRow("Sessions", count: r.sessions, icon: "calendar")
            resultRow("Sätze", count: r.sets, icon: "number")
            Divider()
            HStack {
                Text("Gesamt importiert").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(r.total)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.green)
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func resultRow(_ label: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.secondary)
            Text(label).font(.subheadline)
            Spacer()
            Text(count > 0 ? "+\(count)" : "–")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(count > 0 ? .green : .secondary)
        }
    }

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
