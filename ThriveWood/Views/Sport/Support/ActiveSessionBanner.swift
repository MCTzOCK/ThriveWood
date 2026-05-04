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
                    Circle().fill(.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout läuft").font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(session.workout?.name ?? "Freies Training")
                        .font(.headline).foregroundStyle(.white)
                }
                Spacer()
                Text(elapsed).font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(colors: [.blue, .indigo],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
            .shadow(color: .blue.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .onReceive(timer) { now = $0 }
    }
}

