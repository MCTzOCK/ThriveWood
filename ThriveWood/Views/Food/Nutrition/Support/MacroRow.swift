//
//  MacroRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MacroRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    let unit: String

    private var progress: Double { min(1, value / max(1, goal)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))/\(Int(goal))\(unit)")
                    .font(.caption.monospacedDigit())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
