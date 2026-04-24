//
//  WorkoutVolumeCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 23.04.26.
//


import SwiftUI
import Charts

struct WorkoutVolumeCard: View {
    let samples: [WorkoutVolumeSample]

    private var totalVolume: Double { samples.reduce(0) { $0 + $1.totalVolume } }
    private var totalMinutes: Int { samples.reduce(0) { $0 + $1.totalDuration } / 60 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Training").font(.headline)
                    Text("Volumen pro Tag (kg × Reps)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(totalVolume)) kg")
                        .font(.subheadline.weight(.bold))
                    Text("\(totalMinutes) min")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Chart(samples) { s in
                BarMark(
                    x: .value("Tag", s.date, unit: .day),
                    y: .value("Volumen", s.totalVolume)
                )
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .indigo],
                                   startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
        }
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
