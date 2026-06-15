//
//  GymCard.swift
//  ThriveWood
//


import SwiftUI

struct GymCard: View {
    let gym: Gym
    let onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.selection(); onTap() }) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s)
                        .fill(gym.color.gradient)
                        .frame(width: 54, height: 54)
                    Image(systemName: gym.iconSystemName)
                        .foregroundStyle(.white)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(gym.name).font(.headline).lineLimit(1)
                    HStack(spacing: 10) {
                        if !gym.gymExercises.isEmpty {
                            Label("\(gym.gymExercises.count)", systemImage: "list.bullet")
                        }
                        if !gym.equipment.isEmpty {
                            Label("\(gym.equipment.count)", systemImage: "dumbbell.fill")
                        }
                        if !gym.floorPlans.isEmpty {
                            Label("\(gym.floorPlans.count)", systemImage: "building.2")
                        }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                    if !gym.address.isEmpty {
                        Text(gym.address).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.Spacing.m)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
