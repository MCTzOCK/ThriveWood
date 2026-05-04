//
//  ExerciseLibraryView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Exercise) -> Void

    @State private var exercises: [Exercise] = []
    @State private var search: String = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var showingNew = false
    @State private var errors = ErrorState()

    private var filtered: [Exercise] {
        exercises.filter { e in
            let matchesSearch = search.isEmpty || e.name.localizedCaseInsensitiveContains(search)
            let matchesCategory = selectedCategory == nil || e.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    private var grouped: [(MuscleGroup, [Exercise])] {
        let groups = Dictionary(grouping: filtered) { $0.primaryMuscleGroups.first ?? .fullBody }
        return groups.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips
                List {
                    ForEach(grouped, id: \.0) { muscle, list in
                        Section(muscle.id.capitalized) {
                            ForEach(list) { e in
                                Button {
                                    Haptics.selection()
                                    onSelect(e)
                                    dismiss()
                                } label: {
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: e.iconSystemName)
                                            .foregroundStyle(.blue)
                                            .frame(width: 32)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(e.name).font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(e.category.id.capitalized)
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Übungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                ExerciseEditorView { new in
                    do { try env.exerciseRepo.create(new); load() }
                    catch { errors.show(error) }
                }
            }
            .errorAlert(errors)
            .onAppear(perform: load)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Alle", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases) { c in
                    Chip(title: c.id,
                         isSelected: selectedCategory == c) {
                        selectedCategory = c
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
        }
    }

    private func load() {
        do { exercises = try env.exerciseRepo.fetchAll() }
        catch { errors.show(error) }
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
                        Capsule().fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .buttonStyle(.plain)
        }
    }
}
