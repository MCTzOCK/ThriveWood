//
//  WeekdayRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.05.26.
//
import SwiftUI


struct WeekdayRow: View {
    let day: TrainingsPlanDay
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Weekday Badge
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    VStack(spacing: 0) {
                        Text(day.weekday.shortLabel)
                            .font(.caption2.weight(.bold))
                        if day.weekday == .today {
                            Circle()
                                .fill(badgeColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .foregroundStyle(badgeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.weekday.label)
                        .font(.subheadline.weight(.medium))
                    
                    Text(day.displayName)
                        .font(.caption)
                        .foregroundStyle(day.workout == nil ? .orange : .secondary)
                    
                    if !day.notes.isEmpty {
                        Text(day.notes)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if day.workout == nil || day.isRestDay {
                    Image(systemName: "bed.double.fill")
                        .foregroundStyle(.orange)
                } else if day.workout != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "circle.dashed")
                        .foregroundStyle(.gray)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var badgeColor: Color {
        if day.weekday == .today {
            return .blue
        } else if day.isRestDay {
            return .orange
        } else if day.workout != nil {
            return .green
        } else {
            return .gray
        }
    }
}
