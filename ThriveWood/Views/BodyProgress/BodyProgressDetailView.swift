//
//  BodyProgressDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI

struct BodyProgressDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme
    let entry: BodyProgressEntry
    let env: AppEnvironment
    let onRefresh: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var selectedPhotoIndex: Int = 0
    @State private var showDeleteConfirmation = false

    private var unit: String { entry.measurementUnitRaw == "in" ? "in" : "cm" }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            BentoPageHeader(
                eyebrow: Text("EINTRAG"),
                title: Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
            ) {
                BentoIconButton(
                    systemImage: "xmark",
                    accessibilityLabel: Text("Schließen"),
                    variant: .secondary
                ) {
                    dismiss()
                }

                Menu {
                    Button { onEdit() } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(theme.colors.onSurface)
                        .background(theme.colors.surfaceSecondary, in: Circle())
                        .overlay(Circle().stroke(theme.colors.outlineSubtle, lineWidth: 1))
                }
                .accessibilityLabel("Menü")
            }

            photoSection
            bodyCompositionSection
            measurementsSection
            notesSection

            Spacer(minLength: theme.spacing.xxl)
        }
        .bentoDialog(
            isPresented: $showDeleteConfirmation,
            systemImage: "trash.fill",
            title: Text("Eintrag wirklich löschen?"),
            message: Text("Dieser Eintrag wird unwiderruflich gelöscht, inklusive aller Fotos."),
            actions: [
                BentoDialogAction(title: Text("Löschen"), variant: .destructive, role: .destructive) { onDelete() },
                BentoDialogAction(title: Text("Abbrechen"), role: .cancel) {}
            ]
        )
    }

    // MARK: - Photos

    private var photoSection: some View {
        Group {
            if !entry.photoPaths.isEmpty {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(entry.photoPaths.enumerated()), id: \.offset) { index, path in
                        if let image = loadImage(path) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        } else {
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(theme.colors.surfaceSecondary)
                                .overlay {
                                    Image(systemName: "photo").font(.title).foregroundStyle(theme.colors.onSurfaceMuted)
                                }
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
            } else {
                BentoCard(style: .outlined, padding: .xl, radius: .large) {
                    VStack(spacing: theme.spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        BentoText("Keine Fotos", style: .callout, color: theme.colors.onSurfaceMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Body Composition

    @ViewBuilder
    private var bodyCompositionSection: some View {
        let hasData = entry.weightKg != nil || entry.bodyFatPercentage != nil || entry.muscleMassKg != nil || entry.waterPercentage != nil

        if hasData {
            BentoSection(title: Text("Körperzusammensetzung")) {
                BentoAdaptiveGrid(minimumItemWidth: 150) {
                    if let w = entry.weightKg {
                        BentoMetricTile(
                            title: Text("Gewicht"),
                            value: Text(verbatim: String(format: "%.1f %@", w, entry.weightUnitRaw == "kg" ? "kg" : "lbs")),
                            systemImage: "scalemass.fill",
                            tone: .blue
                        )
                    }
                    if let bf = entry.bodyFatPercentage {
                        BentoMetricTile(
                            title: Text("Körperfett"),
                            value: Text(verbatim: String(format: "%.1f%%", bf)),
                            systemImage: "chart.pie.fill",
                            tone: .warning
                        )
                    }
                    if let mm = entry.muscleMassKg {
                        BentoMetricTile(
                            title: Text("Muskelmasse"),
                            value: Text(verbatim: String(format: "%.1f kg", mm)),
                            systemImage: "figure.arm",
                            tone: .green
                        )
                    }
                    if let wa = entry.waterPercentage {
                        BentoMetricTile(
                            title: Text("Wasser"),
                            value: Text(verbatim: String(format: "%.1f%%", wa)),
                            systemImage: "drop.fill",
                            tone: .info
                        )
                    }
                }
            }
        }
    }

    // MARK: - Measurements

    @ViewBuilder
    private var measurementsSection: some View {
        let measurements: [(String, String, Double?)] = [
            ("Körpergröße", "ruler", entry.heightCm),
            ("Brust", "figure.strengthtraining.traditional", entry.chestCm),
            ("Taille", "ruler", entry.waistCm),
            ("Hüfte", "figure.stand", entry.hipCm),
            ("Schultern", "arrow.up.and.down.text.horizontal", entry.shoulderCm),
            ("Nacken", "person.bust", entry.neckCm),
            ("Oberarm L", "figure.arm", entry.leftBicepCm),
            ("Oberarm R", "figure.arm", entry.rightBicepCm),
            ("Unterarm L", "hand.raised", entry.leftForearmCm),
            ("Unterarm R", "hand.raised", entry.rightForearmCm),
            ("Oberschenkel L", "figure.walk", entry.leftThighCm),
            ("Oberschenkel R", "figure.walk", entry.rightThighCm),
            ("Wade L", "figure.run", entry.leftCalfCm),
            ("Wade R", "figure.run", entry.rightCalfCm),
        ]
        let filled = measurements.filter { $0.2 != nil }

        if !filled.isEmpty {
            BentoSection(title: Text("Körpermaße"), subtitle: Text("in \(unit)")) {
                BentoCard(style: .outlined, padding: .md, radius: .large) {
                    VStack(spacing: 0) {
                        ForEach(Array(filled.enumerated()), id: \.element.0) { idx, item in
                            HStack(spacing: theme.spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(theme.colors.accent.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: item.1)
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.accent)
                                }
                                BentoText(verbatim: item.0, style: .body)
                                Spacer()
                                Text(verbatim: String(format: "%.1f %@", item.2!, unit))
                                    .font(Theme.Typography.subheadline.weight(.semibold).monospacedDigit())
                            }
                            .padding(.vertical, theme.spacing.xs)

                            if idx < filled.count - 1 {
                                BentoDivider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if !entry.notes.isEmpty || entry.onPump || entry.energyLevel != nil {
            BentoSection(title: Text("Notizen")) {
                BentoCard(style: .outlined, padding: .lg, radius: .large) {
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        if entry.onPump || entry.energyLevel != nil {
                            BentoFlowLayout(spacing: theme.spacing.xs) {
                                if entry.onPump {
                                    BentoBadge(Text("Pump"), tone: .danger, systemImage: "flame.fill")
                                }
                                if let e = entry.energyLevel {
                                    BentoBadge(
                                        Text(verbatim: String(repeating: "⚡️", count: e)),
                                        tone: .warning,
                                        systemImage: "bolt.fill"
                                    )
                                }
                            }
                        }

                        if !entry.notes.isEmpty {
                            BentoText(verbatim: entry.notes, style: .body, color: theme.colors.onSurfaceMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func loadImage(_ path: String) -> UIImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }
}
