//
//  ActiveSessionBanner.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//

import SwiftUI
import Combine

struct ActiveSessionBanner: View {
    let session: WorkoutSession
    let onTap: () -> Void

    @State private var now: Date = .now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsed: String {
        let s = Int(now.timeIntervalSince(session.startedAt))
        let m = s / 60, sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle().fill(.white.opacity(0.2)).frame(width: 48, height: 48)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .shadow(color: .green.opacity(0.5), radius: 3)
                        Text("Läuft jetzt")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text(session.workout?.name ?? "Freies Training")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(elapsed)
                    .font(Theme.Typography.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.indigo.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(BounceButtonStyle())
        .onReceive(timer) { now = $0 }
    }
}
