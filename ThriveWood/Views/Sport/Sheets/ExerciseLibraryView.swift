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
    let asSheet: Bool
    let onlyFor: MuscleGroup?
    var onlyIDs: Set<UUID>? = nil

    @State private var exercises: [Exercise] = []
    @State private var search: String = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var showingNew = false
    @State private var errors = ErrorState()

    private var filtered: [Exercise] {
        exercises.filter { e in
            let matchesSearch = search.isEmpty || e.name.localizedCaseInsensitiveContains(search)
            let matchesCategory = selectedCategory == nil || e.category == selectedCategory
            let matchesIDs = onlyIDs == nil || onlyIDs!.contains(e.id)
            if onlyFor != nil {
                return matchesSearch && matchesCategory && matchesIDs && (
                    e.primaryMuscleGroups.contains(onlyFor!) ||
                    e.secondaryMuscleGroups.contains(onlyFor!)
                )
            }
            return matchesSearch && matchesCategory && matchesIDs
        }
    }

    private var grouped: [(MuscleGroup, [Exercise])] {
        let groups = Dictionary(grouping: filtered) { $0.primaryMuscleGroups.first ?? .fullBody }
        return groups.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        BentoScreen(scrolls: false, showsIndicators: false, horizontalPadding: .none, verticalPadding: .none) {
            VStack(spacing: 0) {
                BentoPageHeader(
                    eyebrow: Text("BIBLIOTHEK"),
                    title: Text("Übungen"),
                    subtitle: Text("\(filtered.count) Übungen gefunden")
                ) {
                    if !asSheet {
                        BentoIconButton(
                            systemImage: "chevron.left",
                            accessibilityLabel: Text("Zurück"),
                            variant: .secondary,
                            size: .medium
                        ) {
                            dismiss()
                        }
                    }
                    BentoIconButton(
                        systemImage: "plus",
                        accessibilityLabel: Text("Neue Übung"),
                        variant: .primary
                    ) {
                        showingNew = true
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)

                categoryChips

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        ForEach(grouped, id: \.0) { muscle, list in
                            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                                BentoText(verbatim: muscle.label.uppercased(), style: .overline, color: .secondary)
                                    .padding(.horizontal, Theme.Spacing.l)

                                VStack(spacing: Theme.Spacing.xs) {
                                    ForEach(list) { e in
                                        Button {
                                            Haptics.selection()
                                            onSelect(e)
                                            if asSheet || onlyFor == nil {
                                                dismiss()
                                            }
                                        } label: {
                                            BentoCard(style: .outlined, padding: .md) {
                                                HStack(spacing: Theme.Spacing.m) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                                                            .fill(Color.accentColor.opacity(0.12))
                                                            .frame(width: 40, height: 40)
                                                        Image(systemName: e.iconSystemName)
                                                            .foregroundStyle(Color.accentColor)
                                                    }
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(e.name)
                                                            .font(Theme.Typography.subheadline.weight(.semibold))
                                                            .foregroundStyle(.primary)
                                                        BentoText(verbatim: e.category.id.capitalized, style: .caption, color: .secondary)
                                                    }
                                                    Spacer()
                                                    Image(systemName: asSheet ? "plus.circle.fill" : "info.circle.fill")
                                                        .foregroundStyle(Color.accentColor)
                                                }
                                            }
                                        }
                                        .buttonStyle(PressScaleStyle())
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Übungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(asSheet ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if asSheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .bentoSheet(
            isPresented: $showingNew,
            title: Text("Neue Übung"),
            detents: [.large]
        ) {
            ExerciseEditorView { new in
                do { try env.exerciseRepo.create(new); load() }
                catch { errors.show(error) }
            }
        }
        .errorAlert(errors)
        .onAppear(perform: load)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                BentoChip(
                    Text("Alle"),
                    isSelected: selectedCategory == nil
                ) {
                    Haptics.selection()
                    selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases) { c in
                    BentoChip(
                        Text(c.id),
                        isSelected: selectedCategory == c
                    ) {
                        Haptics.selection()
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
}
