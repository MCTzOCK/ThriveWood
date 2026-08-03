//
//  RangePicker.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI

struct RangePicker: View {
    @Binding var range: AnalyticsRange
    @Environment(\.bentoTheme) private var theme

    var body: some View {
        BentoCard(style: .outlined, padding: .xs, radius: .large) {
            BentoSegmentedPicker(options: AnalyticsRange.allCases, selection: $range) { range in
                Text(range.rawValue)
            }
        }
        .onChange(of: range) { _, _ in Haptics.selection() }
    }
}