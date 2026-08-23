//
//  UnioSettingsSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.08.26.
//
//  Einstellungen für die Unio-Integration: aktivieren, aktualisieren
//  und löschen des vollständigen Datenexports (siehe Unio/UnioKit.md).
//

import SwiftUI

struct UnioSettingsSection: View {
    @AppStorage(ThriveWoodUnio.enabledKey) private var enabled = true
    @State private var summary: ThriveWoodUnio.ExportSummary?
    @State private var isRefreshing = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.teal)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.teal.opacity(0.12)))
                Text("Unio")
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            HStack(spacing: Theme.Spacing.m) {
                unioIconBadge(icon: "square.and.arrow.up.on.square.fill", color: .teal)
                Text("Daten für Unio bereitstellen")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $enabled)
                    .labelsHidden()
                    .tint(.teal)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)

            if enabled {
                if let summary {
                    infoRow(
                        icon: "clock.arrow.circlepath",
                        title: "Letzter Export",
                        value: summary.exportedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    infoRow(
                        icon: "number",
                        title: "Exportierte Datensätze",
                        value: "\(summary.recordCount)"
                    )
                } else {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "tray")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                        Text("Noch kein Export vorhanden. Er wird mit der nächsten Änderung oder beim Wechsel in den Hintergrund erstellt.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }

                Button {
                    refreshNow()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise").foregroundStyle(.blue)
                        }
                        Text("Export jetzt aktualisieren")
                            .font(Theme.Typography.subheadline)
                        Spacer()
                    }
                }
                .buttonStyle(PressScaleStyle())
                .disabled(isRefreshing)
                .padding(.horizontal, Theme.Spacing.l)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill").foregroundStyle(.red)
                        Text("Unio-Integration deaktivieren & Daten löschen")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(PressScaleStyle())
                .padding(.horizontal, Theme.Spacing.l)
            }

            Text("Unio ist eine eigene App, die deine Daten aus verschiedenen Tracker-Apps einliest, vergleicht und Zusammenhänge erkennt. Der Export bleibt auf deinem Gerät in einer gemeinsamen App Group und enthält deine analytisch relevanten Daten (Habits, Training, Ernährung, Körperwerte). Notiz-Felder werden als sensibel markiert.")
                .font(Theme.Typography.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.l)
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Theme.Spacing.l)
        .task { await reloadSummary() }
        .onChange(of: enabled) { _, isEnabled in
            if isEnabled {
                ThriveWoodUnio.scheduleExport()
            } else {
                Task {
                    try? await ThriveWoodUnio.removeExport()
                    await MainActor.run { summary = nil }
                }
            }
        }
        .confirmationDialog(
            "Unio-Export löschen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Integration deaktivieren & löschen", role: .destructive) {
                deleteExport()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Der Unio-Export von ThriveWood wird entfernt. Deine Daten in ThriveWood bleiben vollständig erhalten.")
        }
        .alert("Export fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Rows

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
                .font(Theme.Typography.body)
            Spacer()
            Text(value)
                .font(Theme.Typography.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func unioIconBadge(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                .fill(color)
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(Theme.Typography.callout.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func refreshNow() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task {
            defer { isRefreshing = false }

            do {
                try await ThriveWoodUnio.publishFullExport()
                await reloadSummary()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteExport() {
        Task {
            enabled = false
            try? await ThriveWoodUnio.removeExport()
            await MainActor.run { summary = nil }
        }
    }

    private func reloadSummary() async {
        summary = await ThriveWoodUnio.loadExportSummary()
    }
}
