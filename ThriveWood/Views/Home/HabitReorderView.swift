//
//  HabitReorderView.swift
//  ThriveWood
//

import SwiftUI

struct HabitReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HomeViewModel
    @State private var selectedGroupID: UUID?

    var body: some View {
        NavigationStack {
            List {
                groupReorderSection
                habitReorderSection
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reihenfolge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var groupReorderSection: some View {
        Section("Gruppen") {
            ForEach(vm.groups) { group in
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(group.color.gradient)
                            .frame(width: 24, height: 24)
                        Image(systemName: group.iconSystemName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Text(group.title)
                }
            }
            .onMove { from, to in
                vm.moveGroup(from: from, to: to)
            }
        }
    }

    @ViewBuilder
    private var habitReorderSection: some View {
        Section {
            Picker("Gruppe", selection: $selectedGroupID) {
                Text("Ohne Gruppe").tag(nil as UUID?)
                ForEach(vm.groups) { group in
                    Text(group.title).tag(group.id as UUID?)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Habits in Gruppe")
        }

        Section(sectionTitle) {
            if currentHabits.isEmpty {
                Text("Keine Habits")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(currentHabits) { habit in
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(habit.color.gradient)
                                .frame(width: 24, height: 24)
                            Image(systemName: habit.iconSystemName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Text(habit.title)
                    }
                }
                .onMove { from, to in
                    if let groupID = selectedGroupID,
                       let group = vm.groups.first(where: { $0.id == groupID }) {
                        vm.moveHabitInGroup(from: from, to: to, in: group)
                    }
                }
            }
        }
    }

    private var currentHabits: [Habit] {
        if let groupID = selectedGroupID,
           let group = vm.groups.first(where: { $0.id == groupID }) {
            return group.habitIDs.compactMap { id in
                vm.habits.first { $0.id == id }
            }
        } else {
            let groupedIDs = Set(vm.groups.flatMap(\.habitIDs))
            return vm.habits.filter { !groupedIDs.contains($0.id) }
        }
    }

    private var sectionTitle: String {
        if let groupID = selectedGroupID,
           let group = vm.groups.first(where: { $0.id == groupID }) {
            return group.title
        }
        return "Ohne Gruppe"
    }
}
