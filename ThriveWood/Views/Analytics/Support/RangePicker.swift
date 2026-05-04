//
//  RangePicker.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI

struct RangePicker: View {
    @Binding var range: AnalyticsRange

    var body: some View {
        Picker("Zeitraum", selection: $range) {
            ForEach(AnalyticsRange.allCases) { r in
                Text(r.rawValue).tag(r)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: range) { _, _ in Haptics.selection() }
    }
}
