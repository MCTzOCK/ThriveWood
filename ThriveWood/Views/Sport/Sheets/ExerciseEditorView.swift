//
//  ExerciseEditorView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Exercise) -> Void

    // MARK: - Form-State
    @State private var name: String = ""
    @State private var details: String = ""
    @State private var category: ExerciseCategory = .strength
    @State private var trackingType: ExerciseTrackingType = .repsWeight
    @State private var primary: Set<MuscleGroup> = []
    @State private var secondary: Set<MuscleGroup> = []
    @State private var icon: String = "dumbbell.fill"
    @State private var hasManuallyChangedTracking = false

    private let iconOptions: [String] = [
        "dumbbell.fill", "figure.strengthtraining.traditional",
        "figure.strengthtraining.functional", "figure.core.training",
        "figure.pullup", "figure.run", "figure.outdoor.cycle",
        "figure.rower", "figure.jumprope", "figure.pool.swim",
        "figure.stairs", "figure.mixed.cardio", "figure.flexibility",
        "figure.yoga", "figure.cooldown", "heart.fill", "flame.fill"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !primary.isEmpty
    }

    var body: some View {
        BentoScreen(scrolls: true, showsIndicators: false, horizontalPadding: .sm, verticalPadding: .sm) {
            VStack(spacing: Theme.Spacing.l) {
                detailsSection
                trackingSection
                muscleSection
                appearanceSection
                previewSection

                Spacer(minLength: 40)
            }
        }
        .bentoActionBar {
            BentoButton(
                Text("Speichern"),
                systemImage: "checkmark",
                variant: .primary,
                expands: true
            ) {
                save()
            }
            .disabled(!isValid)
        }
        .onChange(of: category) { _, newCategory in
            guard !hasManuallyChangedTracking else { return }
            trackingType = defaultTracking(for: newCategory)
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Details"))

                BentoTextField(
                    label: Text("Name"),
                    text: $name,
                    prompt: Text("Name"),
                    capitalization: .sentences
                )

                BentoTextArea(
                    label: Text("Beschreibung (optional)"),
                    text: $details,
                    prompt: Text("Beschreibung (optional)"),
                    minimumHeight: 90
                )

                Picker("Kategorie", selection: $category) {
                    ForEach(ExerciseCategory.allCases) { c in
                        Text(c.id).tag(c)
                    }
                }
            }
        }
    }

    private var trackingSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Wie wird getrackt?"))

                Picker("Tracking-Methode", selection: $trackingType) {
                    ForEach(ExerciseTrackingType.allCases) { t in
                        HStack {
                            Image(systemName: trackingIcon(t))
                            Text(t.label)
                        }.tag(t)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: trackingType) { _, _ in
                    hasManuallyChangedTracking = true
                    Haptics.selection()
                }

                Text(trackingHint(trackingType))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var muscleSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Muskelgruppen"))

                DisclosureGroup("Hauptmuskeln (\(primary.count))") {
                    MuscleGroupGrid(selection: $primary)
                }
                DisclosureGroup("Sekundärmuskeln (\(secondary.count))") {
                    MuscleGroupGrid(selection: $secondary)
                }

                if primary.isEmpty {
                    Text("Mindestens eine Hauptmuskelgruppe wählen.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var appearanceSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Symbol"))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(iconOptions, id: \.self) { name in
                            Button {
                                Haptics.selection()
                                icon = name
                            } label: {
                                Image(systemName: name)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(icon == name
                                                  ? Color.blue.opacity(0.18)
                                                  : Color(.tertiarySystemFill))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(icon == name ? Color.blue : .clear, lineWidth: 2)
                                    )
                                    .foregroundStyle(icon == name ? .blue : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var previewSection: some View {
        BentoCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                BentoSectionHeader(title: Text("Vorschau"))

                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue.gradient))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "Übungsname" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        HStack(spacing: 6) {
                            Text(category.id)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            Text(trackingType.label)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
                                .foregroundStyle(.blue)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Logic

    private func save() {
        let new = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            trackingType: trackingType,
            primaryMuscleGroups: Array(primary),
            secondaryMuscleGroups: Array(secondary),
            iconSystemName: icon,
            isBuiltIn: false
        )
        Haptics.success()
        onSave(new)
        dismiss()
    }

    private func defaultTracking(for category: ExerciseCategory) -> ExerciseTrackingType {
        switch category {
        case .strength:     .repsWeight
        case .cardio:       .distanceDuration
        case .plyometrics:  .reps
        case .mobility:     .duration
        case .stretching:   .duration
        case .balance:      .duration
        case .other:        .repsWeight
        }
    }

    private func trackingIcon(_ type: ExerciseTrackingType) -> String {
        switch type {
        case .repsWeight:       "scalemass.fill"
        case .reps:             "number"
        case .duration:         "timer"
        case .distanceDuration: "location.fill"
        }
    }

    private func trackingHint(_ type: ExerciseTrackingType) -> String {
        switch type {
        case .repsWeight:
            "Klassisches Krafttraining – Gewicht und Wiederholungen werden pro Satz erfasst."
        case .reps:
            "Bodyweight-Übungen wie Liegestütze oder Klimmzüge – nur Wiederholungen."
        case .duration:
            "Zeitbasiert wie Plank, Yoga oder Dehnen – pro Satz wird die Dauer erfasst."
        case .distanceDuration:
            "Cardio wie Laufen oder Radfahren – Distanz und Zeit werden erfasst."
        }
    }
}

// MARK: - MuscleGroup Grid


