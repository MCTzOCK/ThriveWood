//
//  MuscleGroupGrid.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct MuscleGroupGrid: View {
    @Binding var selection: Set<MuscleGroup>
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(MuscleGroup.allCases) { group in
                let isOn = selection.contains(group)
                Button {
                    Haptics.selection()
                    if isOn { selection.remove(group) } else { selection.insert(group) }
                } label: {
                    Text(group.label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            Capsule().fill(isOn ? Color.blue : Color.tertiaryFill)
                        )
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}
