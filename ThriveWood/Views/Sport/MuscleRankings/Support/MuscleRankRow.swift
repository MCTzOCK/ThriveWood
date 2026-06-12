//
//  MuscleRankRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MuscleRankRow: View {
    let data: MuscleRankingData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(data.rank.gradient)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: data.rank.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.muscleGroup.label)
                        .font(.subheadline.weight(.medium))
                    Text(data.rank.label)
                        .font(.caption)
                        .foregroundStyle(data.rank.primaryColor)
                }
                
                Spacer()
                
                Text("\(Int(data.totalVolume)) kg")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? data.rank.primaryColor.opacity(0.1) : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}
