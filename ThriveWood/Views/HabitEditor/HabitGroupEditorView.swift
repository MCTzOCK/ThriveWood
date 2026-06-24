//
//  HabitGroupEditorView.swift
//  ThriveWood
//

import SwiftUI

struct HabitGroupEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let group: HabitGroup?

    @State private var title: String = ""
    @State private var icon: String = "folder.fill"
    @State private var color: HabitColor = .green
    @State private var errors = ErrorState()
    @State private var didHydrate = false


    private var isEditing: Bool { group != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                appearanceSection
                if isEditing { deleteSection }
            }
            .navigationTitle(isEditing ? "Gruppe bearbeiten" : "Neue Gruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save)
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .errorAlert(errors)
            .onAppear {
                guard !didHydrate else { return }
                didHydrate = true
                hydrate()
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name", text: $title)
                .textInputAutocapitalization(.sentences)
        }
    }

    private var appearanceSection: some View {
        Section("Darstellung") {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Text(title.isEmpty ? "Vorschau" : title)
                    .font(.headline)
            }

            NavigationLink {
                IconPicker(selection: $icon, options: HabitEditorView.iconOptions, tint: color.color)
            } label: {
                LabeledContent("Symbol") { Image(systemName: icon) }
            }

            ColorGrid(selection: $color)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                guard let group else { return }
                try? env.deleteGroup(group)
                dismiss()
            } label: {
                Label("Gruppe löschen", systemImage: "trash")
            }
        }
    }

    private func hydrate() {
        guard let group else { return }
        title = group.title
        icon = group.iconSystemName
        color = group.color
    }

    private func save() {
        do {
            if let group {
                group.title = title.trimmingCharacters(in: .whitespaces)
                group.iconSystemName = icon
                group.color = color
                try env.saveGroup(group, isNew: false)
            } else {
                let new = HabitGroup(
                    title: title.trimmingCharacters(in: .whitespaces),
                    iconSystemName: icon,
                    color: color,
                    sortOrder: Int.max
                )
                try env.saveGroup(new, isNew: true)
            }
            Haptics.success()
            dismiss()
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }
}
