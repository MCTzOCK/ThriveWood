//
//  GymEditorView.swift
//  ThriveWood
//


import SwiftUI

struct GymEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let gym: Gym?

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var color: HabitColor = .blue
    @State private var icon: String = "building.2.fill"
    @State private var address: String = ""
    @State private var errors = ErrorState()

    private var isEditing: Bool { gym != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let iconOptions = [
        "building.2.fill", "house.fill", "dumbbell.fill",
        "figure.strengthtraining.traditional", "location.fill",
        "sportscourt.fill", "star.fill", "heart.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Notiz (optional)", text: $details, axis: .vertical).lineLimit(1...3)
                    TextField("Adresse (optional)", text: $address)
                    ColorGrid(selection: $color)
                }

                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.m) {
                            ForEach(iconOptions, id: \.self) { iconName in
                                Button {
                                    Haptics.selection()
                                    icon = iconName
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                                            .fill(icon == iconName ? Color.accentColor : Color(.tertiarySystemFill))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: iconName)
                                            .foregroundStyle(icon == iconName ? .white : .primary)
                                            .font(.title3)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            guard let gym else { return }
                            do { try env.gymService.archiveGym(gym); dismiss() }
                            catch { errors.show(error) }
                        } label: {
                            Label("Archivieren", systemImage: "archivebox")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Gym bearbeiten" : "Neues Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save)
                        .disabled(!isValid).fontWeight(.semibold)
                }
            }
            .errorAlert(errors)
            .onAppear(perform: hydrate)
        }
    }

    private func hydrate() {
        if let gym {
            name = gym.name
            details = gym.details
            color = gym.color
            icon = gym.iconSystemName
            address = gym.address
        }
    }

    private func save() {
        do {
            if let gym {
                gym.name = name.trimmingCharacters(in: .whitespaces)
                gym.details = details
                gym.color = color
                gym.iconSystemName = icon
                gym.address = address
                try env.gymService.updateGym(gym)
            } else {
                _ = try env.gymService.createGym(
                    name: name.trimmingCharacters(in: .whitespaces),
                    details: details,
                    color: color,
                    iconSystemName: icon,
                    address: address
                )
            }
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
    }
}
