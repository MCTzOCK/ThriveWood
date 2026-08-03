//
//  SelectedMuscleCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct SelectedMuscleCard: View {
    let data: MuscleRankingData
    let onClose: () -> Void

    @Environment(\.bentoTheme) private var theme

    /// Maps the muscle rank to a matching BentoTone for progress / accents.
    private var rankTone: BentoTone {
        switch data.rank {
        case .untrained, .bronze, .silver: .neutral
        case .gold: .warning
        case .platinum: .info
        case .diamond: .blue
        case .champion: .danger
        case .legend: .accent
        }
    }

    var body: some View {
        BentoCard(style: .elevated, padding: .lg, radius: .large) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(data.rank.gradient)
                            .frame(width: 56, height: 56)

                        Image(systemName: data.rank.icon)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        BentoText(verbatim: data.muscleGroup.label, style: .title3)
                        BentoText(
                            verbatim: data.rank.label,
                            style: .bodyStrong,
                            color: data.rank.primaryColor
                        )
                    }

                    Spacer()

                    BentoIconButton(
                        systemImage: "xmark.circle.fill",
                        accessibilityLabel: Text("Schließen"),
                        variant: .ghost,
                        action: onClose
                    )
                    .tint(data.rank.primaryColor)
                }

                // Progress
                if data.rank != .legend {
                    VStack(alignment: .leading, spacing: 8) {
                        BentoProgressBar(
                            progress: data.progressToNext,
                            tone: rankTone,
                            height: 10,
                            label: Text("Fortschritt")
                        )

                        if let volumeToNext = data.rank.volumeToNext(currentVolume: Int(data.totalVolume)),
                           let next = MuscleRank(rawValue: data.rank.rawValue + 1) {
                            BentoText(
                                verbatim: "Noch \(volumeToNext) kg bis \(next.label)",
                                style: .caption,
                                color: theme.colors.onSurfaceMuted
                            )
                        }
                    }
                }

                // Stats
                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "sets",
                        title: Text("Sets"),
                        value: Text(verbatim: "\(data.totalSets)")
                    ),
                    BentoStatValue(
                        id: "volume",
                        title: Text("Volumen"),
                        value: Text(verbatim: formatVolume(data.totalVolume))
                    ),
                    BentoStatValue(
                        id: "last",
                        title: Text("Zuletzt"),
                        value: Text(verbatim: formatDate(data.lastWorked))
                    )
                ])
            }
        }
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }

    private func formatDate(_ d: Date?) -> String {
        guard let d else { return "—" }
        let days = Calendar.current.dateComponents([.day], from: d, to: .now).day ?? 0
        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "\(days)d"
    }
}
