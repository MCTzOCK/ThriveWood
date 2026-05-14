//
//  SupplementCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct SupplementCard: View {
    let supplement: Supplement
    let entries: [SupplementEntry]
    let date: Date
    let isEditable: Bool  // ← NEU
    let onToggle: (Int) -> Void
    let onEdit: () -> Void
    
    private func isTaken(dose: Int) -> Bool {
        entries.contains { $0.doseNumber == dose && !$0.skipped }
    }
    
    private func isSkipped(dose: Int) -> Bool {
        entries.contains { $0.doseNumber == dose && $0.skipped }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                        .fill(supplement.color.gradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: supplement.iconSystemName)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(supplement.name)
                        .font(.headline)
                    Text(supplement.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isEditable {
                    Button(action: onEdit) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            
            HStack(spacing: Theme.Spacing.s) {
                ForEach(1...supplement.timesPerDay, id: \.self) { dose in
                    Button {
                        onToggle(dose)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                if isSkipped(dose: dose) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                } else {
                                    Image(systemName: isTaken(dose: dose) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(isTaken(dose: dose) ? supplement.color.color : .secondary)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            
                            if supplement.timesPerDay > 1, dose <= supplement.reminderTimes.count {
                                Text(supplement.reminderTimes[dose - 1].formatted(.dateTime.hour().minute()))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                                .fill(backgroundColor(for: dose))
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(isEditable ? 1 : 0.7)
                }
            }
            if !isEditable {
                let taken = (1...supplement.timesPerDay).filter { isTaken(dose: $0) }.count
                let total = supplement.timesPerDay
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: taken == total ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(taken == total ? .green : .secondary)
                    Text("\(taken)/\(total) eingenommen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .padding(.horizontal)
    }
    
    private func backgroundColor(for dose: Int) -> Color {
        if isSkipped(dose: dose) {
            return Color.orange.opacity(0.1)
        } else if isTaken(dose: dose) {
            return supplement.color.color.opacity(0.1)
        } else {
            return Color(.tertiarySystemFill)
        }
    }
    
}
