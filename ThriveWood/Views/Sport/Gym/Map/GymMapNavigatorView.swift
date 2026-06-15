//
//  GymMapNavigatorView.swift
//  ThriveWood
//


import SwiftUI

struct GymMapNavigatorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    let gym: Gym
    let currentExerciseID: UUID?
    let nextExerciseID: UUID?

    @State private var selectedFloor: Int = 0

    private var currentEquipment: GymEquipment? {
        guard let currentExerciseID else { return nil }
        return gym.equipment.first { eq in
            eq.exerciseAssignments.contains { $0.exercise?.id == currentExerciseID }
        }
    }

    private var nextEquipment: GymEquipment? {
        guard let nextExerciseID else { return nil }
        return gym.equipment.first { eq in
            eq.exerciseAssignments.contains { $0.exercise?.id == nextExerciseID }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nextStationBanner
                GymFloorPlanView(
                    gym: gym,
                    isReadOnly: true,
                    highlightEquipmentID: currentEquipment?.id,
                    nextEquipmentID: nextEquipment?.id
                )
            }
            .background(Color(.systemBackground))
            .navigationTitle("Gym Karte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onAppear {
                if let eq = currentEquipment { selectedFloor = eq.floorIndex }
            }
        }
    }

    @ViewBuilder
    private var nextStationBanner: some View {
        if let next = nextEquipment,
           let nextExID = nextExerciseID,
           let nextEx = env.gymService.allExercises(in: gym).first(where: { $0.id == nextExID }) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "arrow.turn.up.right")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nächste Station")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(nextEx.name)
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
                Text(next.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.tertiarySystemFill)))
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .background(.bar)
        } else if currentEquipment == nil {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Kein Gerät zugeordnet – du kannst Geräte im Gym-Editor zuweisen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .background(.bar)
        }
    }
}
