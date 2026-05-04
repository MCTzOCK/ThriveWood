//
//  MuscleCell.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI


struct MuscleCell: View {
    let muscle: MuscleGroup
    let rank: MuscleRank
    let isSelected: Bool
    let shape: CellShape
    let height: CGFloat
    
    enum CellShape {
        case standard, shoulder, arm, forearm, leg
    }
    
    var body: some View {
        ZStack {
            // Hintergrund-Shape
            cellBackground
            
            // Inhalt
            VStack(spacing: 2) {
                if isSelected {
                    Image(systemName: rank.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(muscle.shortLabel)
                    .font(.system(size: isSelected ? 10 : 9, weight: .semibold))
                    .foregroundStyle(rank == .untrained ? .secondary : Color(.white))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(height: height)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .shadow(
            color: isSelected ? rank.glowColor.opacity(0.7) : rank.glowColor.opacity(0.3),
            radius: isSelected ? 10 : 3
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
    
    @ViewBuilder
    private var cellBackground: some View {
        switch shape {
        case .shoulder:
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 20, bottomLeading: 6, bottomTrailing: 6, topTrailing: 20)
            )
            .fill(fillStyle)
            .overlay(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 20, bottomLeading: 6, bottomTrailing: 6, topTrailing: 20)
                )
                .stroke(strokeColor, lineWidth: isSelected ? 2 : 0.5)
            )
            
        case .arm:
            Capsule()
                .fill(fillStyle)
                .overlay(Capsule().stroke(strokeColor, lineWidth: isSelected ? 2 : 0.5))
            
        case .forearm:
            Capsule()
                .fill(fillStyle)
                .overlay(Capsule().stroke(strokeColor, lineWidth: isSelected ? 2 : 0.5))
            
        case .leg:
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 6, bottomLeading: 16, bottomTrailing: 16, topTrailing: 6)
            )
            .fill(fillStyle)
            .overlay(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 6, bottomLeading: 16, bottomTrailing: 16, topTrailing: 6)
                )
                .stroke(strokeColor, lineWidth: isSelected ? 2 : 0.5)
            )
            
        case .standard:
            RoundedRectangle(cornerRadius: 8)
                .fill(fillStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: isSelected ? 2 : 0.5)
                )
        }
    }
    
    private var fillStyle: some ShapeStyle {
        if rank == .untrained {
            return AnyShapeStyle(Color(.systemGray5))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [rank.accentColor, rank.primaryColor, rank.secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var strokeColor: Color {
        isSelected ? .white : rank.primaryColor.opacity(rank == .untrained ? 0.2 : 0.5)
    }
}
