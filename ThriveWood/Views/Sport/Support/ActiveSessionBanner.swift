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
    @State private var pulse = false
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
                    Circle()
                        .stroke(.white.opacity(pulse ? 0.4 : 0.15), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulse ? 1.0 : 0.9)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .symbolEffect(.pulse, options: .repeating)
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
                    .contentTransition(.numericText())
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
            .shadow(color: Color.blue.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(BounceButtonStyle())
        .onReceive(timer) { now = $0 }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
