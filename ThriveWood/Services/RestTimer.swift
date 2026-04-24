//
//  RestTimer.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class RestTimer {
    private(set) var secondsRemaining: Int = 0
    private(set) var totalSeconds: Int = 0
    private(set) var isRunning: Bool = false

    private var timer: Timer?
    private var endDate: Date?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(totalSeconds)
    }

    func start(seconds: Int) {
        stop()
        totalSeconds = seconds
        secondsRemaining = seconds
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        isRunning = true
        Haptics.impact(.light)

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func add(_ seconds: Int) {
        guard isRunning, let endDate else { return }
        self.endDate = endDate.addingTimeInterval(TimeInterval(seconds))
        totalSeconds += seconds
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endDate = nil
        secondsRemaining = 0
        totalSeconds = 0
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        secondsRemaining = remaining
        if remaining == 0 {
            Haptics.success()
            stop()
        }
    }

    var formatted: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
