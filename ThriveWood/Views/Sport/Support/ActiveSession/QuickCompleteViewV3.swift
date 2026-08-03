//
//  QuickCompleteViewV3.swift
//  ThriveWood
//
//  BentoUI-Quick-Complete: vollbild overlay zum schnellen Eintragen der
//  Satz-Werte und direkten Abhaken. Große 40pt Eingaben je Tracking-Typ.
//

import SwiftUI

struct QuickCompleteViewV3: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    let set: SetEntry
    let exercise: Exercise?
    let unit: WeightUnit
    let accentColor: Color
    let onConfirm: (_ reps: Int?, _ weight: Double?, _ durationSeconds: Int?, _ distanceMeters: Double?) -> Void
    let onCancel: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var durationMinutes: String = ""
    @State private var durationSeconds: String = ""
    @State private var distanceText: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps, durationMin, durationSec, distance }

    private var type: ExerciseTrackingType { exercise?.trackingType ?? .repsWeight }

    var body: some View {
        ZStack {
            theme.colors.background.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator
                header
                Spacer()
                inputFields
                Spacer()
                actionButtons
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, 30)
        }
        .statusBarHidden(true)
        .onAppear {
            setupDefaults()
            focusedField = firstField
        }
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(theme.colors.onSurfaceMuted.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: theme.spacing.xs) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: exercise?.iconSystemName ?? "dumbbell")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            Text(exercise?.name ?? "Satz")
                .font(.title3.bold())
                .foregroundStyle(theme.colors.onSurface)
            Text(verbatim: "Satz eintragen & abschließen")
                .font(.subheadline)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .padding(.top, theme.spacing.sm)
    }

    @ViewBuilder
    private var inputFields: some View {
        VStack(spacing: 20) {
            switch type {
            case .repsWeight:
                HStack(spacing: 16) {
                    bigInputField(text: $weightText, label: "Gewicht", suffix: unit.rawValue, placeholder: "0", field: .weight)
                    Text(verbatim: "×").font(.title.weight(.bold)).foregroundStyle(theme.colors.onSurfaceMuted.opacity(0.4))
                    bigInputField(text: $repsText, label: "Reps", suffix: "Wdh", placeholder: "0", field: .reps)
                }
            case .reps:
                bigInputField(text: $repsText, label: "Reps", suffix: "Wdh", placeholder: "0", field: .reps)
                    .frame(maxWidth: 240)
            case .duration:
                HStack(spacing: 12) {
                    bigInputField(text: $durationMinutes, label: "Minuten", suffix: "min", placeholder: "0", field: .durationMin)
                    bigInputField(text: $durationSeconds, label: "Sekunden", suffix: "s", placeholder: "0", field: .durationSec)
                }
            case .distanceDuration:
                HStack(spacing: 16) {
                    bigInputField(text: $distanceText, label: "Distanz", suffix: "km", placeholder: "0,00", field: .distance)
                    Text(verbatim: "+").font(.title.weight(.bold)).foregroundStyle(theme.colors.onSurfaceMuted.opacity(0.4))
                    HStack(spacing: 12) {
                        bigInputField(text: $durationMinutes, label: "Min", suffix: "", placeholder: "0", field: .durationMin)
                        bigInputField(text: $durationSeconds, label: "Sek", suffix: "", placeholder: "0", field: .durationSec)
                    }
                }
            }
        }
    }

    private func bigInputField(text: Binding<String>, label: String, suffix: String, placeholder: String, field: Field) -> some View {
        VStack(spacing: 8) {
            TextField(placeholder, text: text)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(theme.colors.onSurface)
                .multilineTextAlignment(.center)
                .keyboardType(field == .distance ? .decimalPad : .numberPad)
                .focused($focusedField, equals: field)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                        .fill(theme.colors.surfaceSecondary)
                )
            HStack(spacing: 3) {
                Text(verbatim: label)
                    .font(.caption.weight(.semibold))
                if !suffix.isEmpty {
                    Text(verbatim: "· \(suffix)")
                        .font(.caption2)
                        .foregroundStyle(theme.colors.onSurfaceMuted.opacity(0.6))
                }
            }
            .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        VStack(spacing: theme.spacing.sm) {
            Button {
                let values = collectValues()
                onConfirm(values.reps, values.weight, values.durationSeconds, values.distanceMeters)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text(verbatim: "Speichern & Abhaken")
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                        .fill(accentColor)
                )
            }
            .buttonStyle(BounceButtonStyle())

            Button {
                onCancel()
            } label: {
                Text(verbatim: "Abbrechen")
                    .font(.body.weight(.medium))
                    .foregroundStyle(theme.colors.onSurfaceMuted.opacity(0.6))
                    .padding(.vertical, 8)
            }
        }
    }

    private var firstField: Field? {
        switch type {
        case .repsWeight: .weight
        case .reps: .reps
        case .duration: .durationMin
        case .distanceDuration: .distance
        }
    }

    private func setupDefaults() {
        if let w = set.weight { weightText = w.clean }
        if let r = set.reps { repsText = String(r) }
        let totalSec = set.durationSeconds ?? 0
        durationMinutes = totalSec > 0 ? String(totalSec / 60) : ""
        durationSeconds = totalSec > 0 ? String(totalSec % 60) : ""
        if let d = set.distanceMeters { distanceText = String(format: "%.2f", d / 1000).replacingOccurrences(of: ".", with: ",") }
    }

    private func collectValues() -> (reps: Int?, weight: Double?, durationSeconds: Int?, distanceMeters: Double?) {
        switch type {
        case .repsWeight:
            return (
                reps: repsText.isEmpty ? nil : Int(repsText),
                weight: weightText.isEmpty ? nil : Double(weightText.replacingOccurrences(of: ",", with: ".")),
                durationSeconds: nil,
                distanceMeters: nil
            )
        case .reps:
            return (reps: repsText.isEmpty ? nil : Int(repsText), weight: nil, durationSeconds: nil, distanceMeters: nil)
        case .duration:
            let min = Int(durationMinutes) ?? 0
            let sec = Int(durationSeconds) ?? 0
            let total = min * 60 + sec
            return (reps: nil, weight: nil, durationSeconds: total == 0 ? nil : total, distanceMeters: nil)
        case .distanceDuration:
            let min = Int(durationMinutes) ?? 0
            let sec = Int(durationSeconds) ?? 0
            let total = min * 60 + sec
            return (
                reps: nil,
                weight: nil,
                durationSeconds: total == 0 ? nil : total,
                distanceMeters: distanceText.isEmpty ? nil : (Double(distanceText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000
            )
        }
    }
}
