//
//  DailySummaryCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct DailySummaryCard: View {
    let points: Int
    let goal: Int
    let progress: Double
    let availablePoints: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            ProgressRing(progress: progress)
                .frame(width: 72, height: 72)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(points)").font(.title2.bold())
                        Text("/\(goal)").font(.caption2).foregroundStyle(.secondary)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tagesziel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(progress >= 1 ? "Ziel erreicht! 🌱" : "Weiter so!")
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill").foregroundStyle(.tint)
                    Text("\(availablePoints) Punkte verfügbar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(colors: [.accentColor, .mint, .accentColor],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
    }
}
