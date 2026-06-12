//
//  BodyProgressDetailView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI

struct BodyProgressDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: BodyProgressEntry
    let env: AppEnvironment
    let onRefresh: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var selectedPhotoIndex: Int = 0
    @State private var showDeleteConfirmation = false

    private var unit: String { entry.measurementUnitRaw == "in" ? "in" : "cm" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    photoSection
                    bodyCompositionSection
                    measurementsSection
                    notesSection
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .background(Color.groupedBackground)
            .navigationTitle(entry.date.formatted(.dateTime.day().month(.wide).year()))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button { onEdit() } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteConfirmation = true } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Eintrag wirklich löschen?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { onDelete() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieser Eintrag wird unwiderruflich gelöscht, inklusive aller Fotos.")
            }
        }
    }

    // MARK: - Photos

    private var photoSection: some View {
        Group {
            if !entry.photoPaths.isEmpty {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(entry.photoPaths.enumerated()), id: \.offset) { index, path in
                        if let image = loadImage(path) {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        } else {
                            RoundedRectangle(cornerRadius: Theme.Radius.m)
                                .fill(Color.tertiaryFill)
                                .overlay { Image(systemName: "photo").font(.title).foregroundStyle(.secondary) }
                                .tag(index)
                        }
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                #else
                .tabViewStyle(.automatic)
                #endif
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                .padding(.horizontal, Theme.Spacing.l)
            } else {
                VStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Keine Fotos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
                .cardStyle()
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
    }

    // MARK: - Body Composition

    private var bodyCompositionSection: some View {
        let hasData = entry.weightKg != nil || entry.bodyFatPercentage != nil || entry.muscleMassKg != nil || entry.waterPercentage != nil

        return Group {
            if hasData {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text("Körperzusammensetzung")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.m) {
                        if let w = entry.weightKg {
                            detailTile(icon: "scalemass.fill", tint: .blue, label: "Gewicht", value: String(format: "%.1f %@", w, entry.weightUnitRaw == "kg" ? "kg" : "lbs"))
                        }
                        if let bf = entry.bodyFatPercentage {
                            detailTile(icon: "chart.pie.fill", tint: .orange, label: "Körperfett", value: String(format: "%.1f%%", bf))
                        }
                        if let mm = entry.muscleMassKg {
                            detailTile(icon: "figure.arm", tint: .green, label: "Muskelmasse", value: String(format: "%.1f kg", mm))
                        }
                        if let wa = entry.waterPercentage {
                            detailTile(icon: "drop.fill", tint: .cyan, label: "Wasser", value: String(format: "%.1f%%", wa))
                        }
                    }
                }
                .padding(Theme.Spacing.l)
                .cardStyle()
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
    }

    private func detailTile(icon: String, tint: Color, label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.subheadline.bold().monospacedDigit())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(tint.opacity(0.08)))
    }

    // MARK: - Measurements

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

        return Group {
            if !filled.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text("Körpermaße")
                        .font(.headline)

                    ForEach(filled, id: \.0) { label, icon, value in
                        HStack {
                            Image(systemName: icon).font(.callout).foregroundStyle(.secondary).frame(width: 24)
                            Text(label).font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f %@", value!, unit))
                                .font(.subheadline.bold().monospacedDigit())
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }
                .padding(Theme.Spacing.l)
                .cardStyle()
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Group {
            if !entry.notes.isEmpty || entry.onPump || entry.energyLevel != nil {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text("Notizen")
                        .font(.headline)

                    HStack(spacing: Theme.Spacing.m) {
                        if entry.onPump {
                            Label("Pump", systemImage: "flame.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                                .padding(.horizontal, Theme.Spacing.s)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.red.opacity(0.1)))
                        }
                        if let e = entry.energyLevel {
                            Label(String(repeating: "⚡️", count: e), systemImage: "bolt.fill")
                                .font(.subheadline)
                                .padding(.horizontal, Theme.Spacing.s)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.yellow.opacity(0.1)))
                        }
                    }

                    if !entry.notes.isEmpty {
                        Text(entry.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Theme.Spacing.l)
                .cardStyle()
                .padding(.horizontal, Theme.Spacing.l)
            }
        }
    }

    private func loadImage(_ path: String) -> PlatformImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(path)
        return PlatformImage.fromFile(at: url.path)
    }
}