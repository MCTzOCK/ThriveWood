//
//  GymExerciseListView.swift
//  ThriveWood
//


import SwiftUI

struct GymExerciseListView: View {
    @Environment(AppEnvironment.self) private var env
    @Bindable var gym: Gym

    @State private var showingLibrary = false
    @State private var errors = ErrorState()

    private var groupedByZone: [(GymZone?, [GymExercise])] {
        let groups = Dictionary(grouping: gym.gymExercises) { $0.zone }
        var result: [(GymZone?, [GymExercise])] = []
        for zone in GymZone.allCases {
            if let list = groups[zone], !list.isEmpty {
                result.append((zone, list.sorted { $0.order < $1.order }))
            }
        }
        if let unassigned = groups[nil], !unassigned.isEmpty {
            result.append((nil, unassigned.sorted { $0.order < $1.order }))
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                if gym.gymExercises.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedByZone, id: \.0?.rawValue) { zone, exercises in
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            HStack {
                                if let zone {
                                    Image(systemName: zone.icon)
                                        .foregroundStyle(Color(hex: zone.colorHex) ?? .accentColor)
                                    Text(zone.label).font(.headline)
                                } else {
                                    Image(systemName: "questionmark.folder.fill")
                                        .foregroundStyle(.secondary)
                                    Text("Ohne Zone").font(.headline)
                                }
                                Spacer()
                                Text("\(exercises.count)").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, Theme.Spacing.l)

                            ForEach(exercises) { ge in
                                GymExerciseRow(gymExercise: ge) {
                                    removeExercise(ge)
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                        }
                    }
                }

                Button {
                    showingLibrary = true
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, Theme.Spacing.l)
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .sheet(isPresented: $showingLibrary) {
            GymExercisePicker(gym: gym)
        }
        .errorAlert(errors)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Keine Übungen")
                .font(.headline)
            Text("Füge Übungen hinzu, die in diesem Gym verfügbar sind.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func removeExercise(_ ge: GymExercise) {
        do { try env.gymService.removeExercise(ge, from: gym) }
        catch { errors.show(error) }
    }
}


struct GymExerciseRow: View {
    let gymExercise: GymExercise
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: gymExercise.exercise?.iconSystemName ?? "dumbbell.fill")
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(gymExercise.exercise?.name ?? "Unbekannt")
                    .font(.subheadline.weight(.semibold))
                if let zone = gymExercise.zone {
                    HStack(spacing: 4) {
                        Image(systemName: zone.icon)
                        Text(zone.label)
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: { Haptics.impact(.light); onRemove() }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}


struct GymExercisePicker: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Bindable var gym: Gym

    @State private var exercises: [Exercise] = []
    @State private var search: String = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedZone: GymZone?
    @State private var errors = ErrorState()

    private var existingIDs: Set<UUID> {
        Set(gym.gymExercises.compactMap { $0.exercise?.id })
    }

    private var filtered: [Exercise] {
        exercises.filter { e in
            let matchesSearch = search.isEmpty || e.name.localizedCaseInsensitiveContains(search)
            let matchesCategory = selectedCategory == nil || e.category == selectedCategory
            let notAlreadyAdded = !existingIDs.contains(e.id)
            return matchesSearch && matchesCategory && notAlreadyAdded
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                zonePicker
                List {
                    ForEach(filtered) { e in
                        Button {
                            addExercise(e)
                        } label: {
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: e.iconSystemName)
                                    .foregroundStyle(.tint)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.name).font(.subheadline.weight(.semibold))
                                    Text(e.category.id).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $search)
            .navigationTitle("Übung hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .errorAlert(errors)
            .onAppear(perform: load)
        }
    }

    private var zonePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Ohne Zone", isSelected: selectedZone == nil) {
                    selectedZone = nil
                }
                ForEach(GymZone.allCases) { zone in
                    Chip(title: zone.label, isSelected: selectedZone == zone) {
                        selectedZone = zone
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
        }
    }

    private struct Chip: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        var body: some View {
            Button {
                Haptics.selection(); action()
            } label: {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .buttonStyle(.plain)
        }
    }

    private func load() {
        do { exercises = try env.exerciseRepo.fetchAll() }
        catch { errors.show(error) }
    }

    private func addExercise(_ exercise: Exercise) {
        do {
            try env.gymService.addExercise(exercise, to: gym, zone: selectedZone)
            Haptics.success()
        } catch { errors.show(error) }
    }
}
