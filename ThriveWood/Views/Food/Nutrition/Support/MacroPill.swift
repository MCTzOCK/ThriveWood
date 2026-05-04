//
//  MacroPill.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct MacroPill: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        Text("\(Int(value))\(label)")
            .font(.caption2.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
