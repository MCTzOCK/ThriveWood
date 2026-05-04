//
//  NutrientField.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct NutrientField: View {
    let label: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}
