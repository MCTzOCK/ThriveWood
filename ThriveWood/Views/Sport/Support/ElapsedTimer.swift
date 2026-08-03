//
//  ElapsedTimer.swift
//  ThriveWood
//
//  Created by Ben Siebert on 27.05.26.
//

import SwiftUI
import Combine

struct ElapsedTimer: View {
    let sessionStartedAt: Date
    @State private var now = Date.now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsed: String {
        let s = Int(now.timeIntervalSince(sessionStartedAt))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }

    var body: some View {
        Text(elapsed)
            .font(.headline.monospacedDigit())
            .foregroundStyle(.tint)
            .contentTransition(.numericText())
            .animation(.snappy, value: elapsed)
            .onReceive(timer) { now = $0 }
    }
}
