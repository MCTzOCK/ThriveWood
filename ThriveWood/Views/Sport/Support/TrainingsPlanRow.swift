//
//  TrainingsPlanRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//
import SwiftUI


struct TrainingsPlanRow: View {
    let plan: TrainingsPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: plan.color) ?? .blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "calendar")
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.name)
                            .font(.subheadline.weight(.medium))
                        
                        if plan.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Text("\(plan.trainingDaysPerWeek)x/Woche • \(plan.totalExercises) Übungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
