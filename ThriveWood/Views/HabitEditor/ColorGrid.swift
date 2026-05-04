//
//  ColorGrid.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//



import SwiftUI

struct ColorGrid: View {
    @Binding var selection: HabitColor
    private let columns = [GridItem(.adaptive(minimum: 40), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(HabitColor.allCases) { c in
                Button {
                    Haptics.selection()
                    selection = c
                } label: {
                    ZStack {
                        Circle().fill(c.color).frame(width: 36, height: 36)
                        if selection == c {
                            Circle().strokeBorder(Color.primary, lineWidth: 2).frame(width: 42, height: 42)
                            Image(systemName: "checkmark")
                                .font(.caption.bold()).foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.rawValue)
            }
        }
        .padding(.vertical, 4)
    }
}