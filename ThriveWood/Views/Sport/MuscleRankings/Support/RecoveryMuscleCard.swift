//
//  RecoveryMuscleCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.06.26.
//

import SwiftUI

struct RecoveryMuscleCard: View {
    let data: MuscleRecoveryData
    let onClose: () -> Void

    @Environment(\.bentoTheme) private var theme

    private var stateColor: Color {
        switch data.state {
        case .recovered: .green
        case .warning: .orange
        case .needsRest: .red
        }
    }

    private var stateLabel: String {
        switch data.state {
        case .recovered: "Erholt"
        case .warning: "Nah am Limit"
        case .needsRest: "Pause empfohlen"
        }
    }

    private var stateTone: BentoTone {
        switch data.state {
        case .recovered: .success
        case .warning: .warning
        case .needsRest: .danger
        }
    }

    var body: some View {
        BentoCard(style: .elevated, padding: .lg, radius: .large) {
            VStack(spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(stateColor.gradient)
                            .frame(width: 56, height: 56)

                        Image(systemName: data.stateIcon)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        BentoText(verbatim: data.muscleGroup.label, style: .title3)
                        BentoText(
                            verbatim: stateLabel,
                            style: .bodyStrong,
                            color: stateColor
                        )
                    }

                    Spacer()

                    BentoIconButton(
                        systemImage: "xmark.circle.fill",
                        accessibilityLabel: Text("Schließen"),
                        variant: .ghost,
                        action: onClose
                    )
                }

                if data.needsRest || data.isWarning {
                    BentoCallout(
                        kind: data.needsRest ? .error : .warning,
                        title: Text(verbatim: data.restReasonText),
                        message: data.recommendedRestDays > 0
                            ? Text(verbatim: "\(data.recommendedRestDays) Tag\(data.recommendedRestDays == 1 ? "" : "e") Pause empfohlen")
                            : nil
                    )
                }

                BentoStatStrip(values: [
                    BentoStatValue(
                        id: "volume",
                        title: Text("Volumen / 7d"),
                        value: Text(verbatim: formatVolume(data.weeklyVolume))
                    ),
                    BentoStatValue(
                        id: "lastRest",
                        title: Text("Letzte Pause"),
                        value: Text(verbatim: data.daysSinceLastWorked.map { "\($0)d" } ?? "—")
                    ),
                    BentoStatValue(
                        id: "streak",
                        title: Text("Tage direkt"),
                        value: Text(verbatim: "\(data.consecutiveTrainingDays)")
                    )
                ])
            }
        }
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))"
    }
}
