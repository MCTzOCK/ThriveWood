//
//  ActivePlanCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//

import SwiftUI

struct ActivePlanCard: View {
    let plan: TrainingsPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color(hex: plan.color) ?? .green)
                        .frame(width: 12, height: 12)
                    
                    Text(plan.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                if !plan.details.isEmpty {
                    Text(plan.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    Label("\(plan.trainingDaysPerWeek)x/Woche", systemImage: "calendar")
                    Label("\(plan.totalExercises) Übungen", systemImage: "dumbbell.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // Wochenübersicht
                HStack(spacing: 4) {
                    ForEach(plan.sortedDays) { day in
                        VStack(spacing: 4) {
                            Text(day.weekday.shortLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            Circle()
                                .fill(dayColor(day))
                                .frame(width: 8, height: 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func dayColor(_ day: TrainingsPlanDay) -> Color {
        if day.isRestDay {
            return .gray.opacity(0.3)
        } else if day.workout != nil {
            return Color(hex: plan.color) ?? .green
        } else {
            return .gray.opacity(0.15)
        }
    }
}
