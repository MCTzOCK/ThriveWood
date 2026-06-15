//
//  GymEquipmentListView.swift
//  ThriveWood
//


import SwiftUI

struct GymEquipmentListView: View {
    @Environment(AppEnvironment.self) private var env
    @Bindable var gym: Gym

    @State private var showingAddSheet = false
    @State private var editingEquipment: GymEquipment?
    @State private var errors = ErrorState()

    private var groupedByFloor: [(Int, [GymEquipment])] {
        let groups = Dictionary(grouping: gym.equipment) { $0.floorIndex }
        return groups.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                if gym.equipment.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedByFloor, id: \.0) { floorIndex, equipmentList in
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            HStack {
                                let planName = gym.floorPlan(for: floorIndex)?.floorName ?? "Stock \(floorIndex + 1)"
                                Image(systemName: "building.2")
                                Text(planName).font(.headline)
                                Spacer()
                                Text("\(equipmentList.count) Geräte").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, Theme.Spacing.l)

                            ForEach(equipmentList.sorted { $0.name < $1.name }) { eq in
                                EquipmentRow(equipment: eq) {
                                    editingEquipment = eq
                                } onDelete: {
                                    removeEquipment(eq)
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                            }
                        }
                    }
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Gerät hinzufügen", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, Theme.Spacing.l)
            }
            .padding(.vertical, Theme.Spacing.l)
        }
        .sheet(isPresented: $showingAddSheet) {
            EquipmentCatalogSheet(gym: gym)
        }
        .sheet(item: $editingEquipment) { eq in
            EquipmentEditorSheet(gym: gym, editing: eq)
        }
        .errorAlert(errors)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Keine Geräte")
                .font(.headline)
            Text("Füge Geräte hinzu und ordne ihnen Übungen zu.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func removeEquipment(_ eq: GymEquipment) {
        do { try env.gymService.removeEquipment(eq, from: gym) }
        catch { errors.show(error) }
    }
}


struct EquipmentRow: View {
    let equipment: GymEquipment
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: { Haptics.selection(); onTap() }) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: equipment.iconSystemName)
                        .foregroundStyle(.white)
                        .font(.callout)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(equipment.name).font(.subheadline.weight(.semibold))
                    HStack(spacing: 8) {
                        if !equipment.exerciseAssignments.isEmpty {
                            Text("\(equipment.exerciseAssignments.count) Übungen")
                        }
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { Haptics.impact(.light); onDelete() }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.m)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Equipment Catalog (add from existing + create new)

struct EquipmentCatalogSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Bindable var gym: Gym

    @State private var showingNewEquipment = false
    @State private var search: String = ""
    @State private var errors = ErrorState()

    private var uniqueEquipment: [GymEquipment] {
        var seen = Set<String>()
        var result: [GymEquipment] = []
        for eq in gym.equipment.sorted(by: { $0.name < $1.name }) {
            let key = eq.name.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                result.append(eq)
            }
        }
        if search.isEmpty { return result }
        return result.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingNewEquipment = true
                    } label: {
                        Label("Neues Gerät erstellen", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }

                if !uniqueEquipment.isEmpty {
                    Section("Vorhandene Geräte") {
                        ForEach(uniqueEquipment) { eq in
                            Button {
                                do {
                                    let dup = try env.gymService.addEquipment(
                                        name: eq.name,
                                        type: eq.equipmentType,
                                        floorIndex: 0,
                                        zone: eq.zone,
                                        icon: eq.iconSystemName,
                                        to: gym
                                    )
                                    for assignment in eq.exerciseAssignments.sorted(by: { $0.order < $1.order }) {
                                        if let ex = assignment.exercise {
                                            try env.gymService.assignExercise(ex, to: dup, in: gym)
                                        }
                                    }
                                    Haptics.success()
                                } catch { errors.show(error) }
                            } label: {
                                HStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: eq.iconSystemName)
                                        .foregroundStyle(.tint)
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(eq.name).font(.subheadline.weight(.semibold))
                                        if !eq.exerciseAssignments.isEmpty {
                                            Text("\(eq.exerciseAssignments.count) Übungen").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Gerät suchen")
            .navigationTitle("Gerät hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewEquipment) {
                EquipmentEditorSheet(gym: gym)
            }
            .errorAlert(errors)
        }
    }
}


// MARK: - Equipment Editor (simplified: name + icon + exercises only)

struct EquipmentEditorSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Bindable var gym: Gym
    var editing: GymEquipment?

    @State private var name: String = ""
    @State private var icon: String = "dumbbell.fill"
    @State private var floorIndex: Int = 0
    @State private var showingExercisePicker = false
    @State private var selectedExercises: [Exercise] = []
    @State private var errors = ErrorState()

    private var isEditing: Bool { editing != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let iconOptions = [
        "dumbbell.fill", "figure.seated.seated", "square.stack.3d.up.fill",
        "arrow.up.and.down.text.horizontal", "figure.run", "bicycle",
        "figure.rowing", "rectangle.flat.fill", "arrow.up.arrow.down",
        "gearshape.2.fill", "figure.leg.press", "line.horizontal.3",
        "figure.strengthtraining.traditional", "figure.stretching",
        "heart.fill", "scalemass.fill", "circle.hexagon.fill",
        "wrench.and.screwdriver.fill", "cable.coil", "bolt.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Gerät") {
                    TextField("Name", text: $name)
                    if gym.floorPlans.count > 1 {
                        Picker("Stockwerk", selection: $floorIndex) {
                            ForEach(Array(gym.sortedFloorPlans.enumerated()), id: \.offset) { idx, plan in
                                Text(plan.floorName).tag(idx)
                            }
                        }
                    }
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
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(icon == iconName ? Color.accentColor : Color(.tertiarySystemFill))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: iconName)
                                            .foregroundStyle(icon == iconName ? .white : .primary)
                                            .font(.callout)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }

                Section {
                    if selectedExercises.isEmpty {
                        Text("Keine Übungen zugewiesen").foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedExercises) { ex in
                            HStack(spacing: Theme.Spacing.m) {
                                Image(systemName: ex.iconSystemName)
                                    .foregroundStyle(.tint)
                                    .frame(width: 28)
                                Text(ex.name).font(.subheadline)
                                Spacer()
                                Button {
                                    selectedExercises.removeAll { $0.id == ex.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Übung zuweisen", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Übungen an diesem Gerät")
                }
            }
            .navigationTitle(isEditing ? "Gerät bearbeiten" : "Neues Gerät")
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
            .sheet(isPresented: $showingExercisePicker) {
                EquipmentExercisePicker(selectedExercises: $selectedExercises, gym: gym)
            }
            .errorAlert(errors)
            .onAppear(perform: hydrate)
        }
    }

    private func hydrate() {
        if let editing {
            name = editing.name
            icon = editing.iconSystemName
            floorIndex = editing.floorIndex
            selectedExercises = editing.exerciseAssignments.compactMap { $0.exercise }
        }
    }

    private func save() {
        do {
            if let editing {
                editing.name = name
                editing.iconSystemName = icon
                editing.floorIndex = floorIndex
                editing.exerciseAssignments.removeAll()
                for (i, ex) in selectedExercises.enumerated() {
                    let ee = EquipmentExercise(order: i, exercise: ex, equipment: editing)
                    editing.exerciseAssignments.append(ee)
                }
                try env.gymService.updateEquipment(editing, in: gym)
            } else {
                let eq = try env.gymService.addEquipment(
                    name: name, type: .other, floorIndex: floorIndex, icon: icon,
                    to: gym
                )
                for ex in selectedExercises {
                    try env.gymService.assignExercise(ex, to: eq, in: gym)
                }
            }
            Haptics.success()
            dismiss()
        } catch { errors.show(error) }
    }
}


struct EquipmentExercisePicker: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [Exercise]
    let gym: Gym

    @State private var exercises: [Exercise] = []
    @State private var search: String = ""
    @State private var errors = ErrorState()

    private var filtered: [Exercise] {
        exercises.filter { e in
            let matchesSearch = search.isEmpty || e.name.localizedCaseInsensitiveContains(search)
            let notSelected = !selectedExercises.contains(where: { $0.id == e.id })
            return matchesSearch && notSelected
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { e in
                    Button {
                        Haptics.selection()
                        selectedExercises.append(e)
                    } label: {
                        HStack(spacing: Theme.Spacing.m) {
                            Image(systemName: e.iconSystemName)
                                .foregroundStyle(.tint).frame(width: 32)
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
            .searchable(text: $search)
            .navigationTitle("Übung zuweisen")
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

    private func load() {
        do { exercises = try env.exerciseRepo.fetchAll() }
        catch { errors.show(error) }
    }
}
