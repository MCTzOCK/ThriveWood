//
//  SetRow.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI

struct SetRow: View {
    let index: Int
    @Bindable var set_: SetEntry
    let unit: WeightUnit
    let onComplete: () -> Void
    let onDelete: () -> Void

    private var type: ExerciseTrackingType {
        set_.exercise?.trackingType ?? .repsWeight
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            indexBadge
            inputs
            Spacer(minLength: 0)
            completeButton
            deleteButton
        }
        .animation(.snappy, value: set_.isCompleted)
    }

    private var indexBadge: some View {
        Text("\(index)")
            .font(.callout.weight(.bold).monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 24, alignment: .leading)
    }

    @ViewBuilder
    private var inputs: some View {
        switch type {
        case .repsWeight:
            numberField(
                value: Binding(
                    get: { set_.weight ?? 0 },
                    set: { set_.weight = $0 == 0 ? nil : $0 }),
                placeholder: "0", suffix: unit.rawValue,
                width: 80, decimal: true)
            numberField(
                value: Binding(
                    get: { Double(set_.reps ?? 0) },
                    set: { set_.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps",
                width: 80, decimal: false)

        case .reps:
            numberField(
                value: Binding(
                    get: { Double(set_.reps ?? 0) },
                    set: { set_.reps = Int($0) == 0 ? nil : Int($0) }),
                placeholder: "0", suffix: "Reps",
                width: 110, decimal: false)

        case .duration:
            durationField(
                seconds: Binding(
                    get: { set_.durationSeconds ?? 0 },
                    set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))

        case .distanceDuration:
            numberField(
                value: Binding(
                    get: { (set_.distanceMeters ?? 0) / 1000 },
                    set: { set_.distanceMeters = $0 == 0 ? nil : $0 * 1000 }),
                placeholder: "0,00", suffix: "km",
                width: 90, decimal: true)
            durationField(
                seconds: Binding(
                    get: { set_.durationSeconds ?? 0 },
                    set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
        }
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            Image(systemName: set_.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set_.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Field Helpers

    @ViewBuilder
    private func numberField(
        value: Binding<Double>,
        placeholder: String,
        suffix: String,
        width: CGFloat,
        decimal: Bool
    ) -> some View {
        if decimal {
            HStack(spacing: 4) {
                FlexibleNumberField(
                    value: value,
                    placeholder: placeholder,
                    decimal: true
                )
                Text(suffix)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: width)
            .padding(.vertical, 6).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
        } else {
            HStack(spacing: 4) {
                TextField(placeholder, value: value, format: .number.precision(.fractionLength(0...0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                Text(suffix).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6).padding(.horizontal, 8)
            .frame(width: width)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
        }
    }

    private func durationField(seconds: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            TextField("0", value: Binding(
                get: { seconds.wrappedValue / 60 },
                set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 36)
            Text(":").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
            TextField("00", value: Binding(
                get: { seconds.wrappedValue % 60 },
                set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 36)
            Text("min").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
    }
}
