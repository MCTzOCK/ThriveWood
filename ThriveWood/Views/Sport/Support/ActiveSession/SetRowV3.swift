//
//  SetRowV3.swift
//  ThriveWood
//
//  Eine einzelne Satz-Zeile für ActiveSessionViewV3. BentoUI-gestylt,
//  typespezifische Eingaben (Gewicht/Reps, Reps, Dauer, Distanz+Dauer),
//  Assist-Toggle, Tracker-Play, Löschen.
//

import SwiftUI

struct SetRowV3: View {
    let index: Int
    @Bindable var set_: SetEntry
    let unit: WeightUnit
    let accentColor: Color
    let onTap: () -> Void
    let onDelete: () -> Void
    var onStartTracker: (() -> Void)? = nil

    @Environment(\.bentoTheme) private var theme

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var distanceText: String = ""
    @State private var assistedText: String = ""
    @State private var hasSynced: Bool = false
    @State private var showAssisted: Bool = false

    private var type: ExerciseTrackingType { set_.exercise?.trackingType ?? .repsWeight }

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            checkCircle
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                inputsRow
                if showAssisted {
                    assistedRow
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            Spacer(minLength: 0)
            trackerButton
            deleteButton
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                .fill(set_.isCompleted ? theme.colors.success.opacity(0.08) : Color.clear)
        )
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: set_.isCompleted)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: showAssisted)
        .onAppear { syncFromModel() }
        .onChange(of: set_.weight) { _, _ in if !hasSynced { syncFromModel() } }
        .onChange(of: set_.reps) { _, _ in if !hasSynced { syncFromModel() } }
        .onChange(of: set_.assistedReps) { _, _ in if !hasSynced { syncFromModel() } }
        .onChange(of: set_.distanceMeters) { _, _ in if !hasSynced { syncFromModel() } }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Check

    private var checkCircle: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(set_.isCompleted ? theme.colors.success : theme.colors.outline, lineWidth: 2)
                    .frame(width: 30, height: 30)
                if set_.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.colors.success)
                } else {
                    Text(verbatim: "\(index)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                }
            }
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Inputs

    @ViewBuilder
    private var inputsRow: some View {
        HStack(spacing: theme.spacing.xs) {
            switch type {
            case .repsWeight:
                labeledField(text: $weightText, label: "Gewicht", suffix: unit.rawValue, keyboard: .decimalPad, width: 58)
                    .onChange(of: weightText) { _, newValue in
                        hasSynced = true
                        if newValue.isEmpty { set_.weight = nil }
                        else if let parsed = Double(newValue.replacingOccurrences(of: ",", with: ".")) { set_.weight = parsed }
                        hasSynced = false
                    }
                labeledField(text: $repsText, label: "Reps", suffix: "Wdh", keyboard: .numberPad, width: 58)
                    .onChange(of: repsText) { _, newValue in
                        hasSynced = true
                        set_.reps = newValue.isEmpty ? nil : Int(newValue)
                        hasSynced = false
                    }
            case .reps:
                labeledField(text: $repsText, label: "Reps", suffix: "Wdh", keyboard: .numberPad, width: 58)
                    .onChange(of: repsText) { _, newValue in
                        hasSynced = true
                        set_.reps = newValue.isEmpty ? nil : Int(newValue)
                        hasSynced = false
                    }
            case .duration:
                durationField(seconds: Binding(get: { set_.durationSeconds ?? 0 }, set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
            case .distanceDuration:
                labeledField(text: $distanceText, label: "Distanz", suffix: "km", keyboard: .decimalPad, width: 58)
                    .onChange(of: distanceText) { _, newValue in
                        hasSynced = true
                        if newValue.isEmpty { set_.distanceMeters = nil }
                        else { set_.distanceMeters = (Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000 }
                        hasSynced = false
                    }
                durationField(seconds: Binding(get: { set_.durationSeconds ?? 0 }, set: { set_.durationSeconds = $0 == 0 ? nil : $0 }))
            }

            if type == .repsWeight {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { showAssisted.toggle() }
                    if !showAssisted { set_.assistedReps = nil; assistedText = "" }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAssisted ? "person.2.fill" : "person.2")
                            .font(.caption2)
                        Text(verbatim: "Assist")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(showAssisted ? Color.orange : theme.colors.onSurfaceMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                            .fill(showAssisted ? Color.orange.opacity(0.12) : theme.colors.surfaceSecondary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var assistedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text(verbatim: "Assisted Reps")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.orange)
            Spacer(minLength: 0)
            TextField("0", text: $assistedText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                .font(.caption.weight(.semibold).monospacedDigit())
                .onChange(of: assistedText) { _, newValue in
                    hasSynced = true
                    set_.assistedReps = newValue.isEmpty ? nil : Int(newValue)
                    hasSynced = false
                }
            Text(verbatim: "Wdh")
                .font(.caption2.weight(.medium))
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Tracker / Delete

    @ViewBuilder
    private var trackerButton: some View {
        if let onStartTracker, !set_.isCompleted {
            Button(action: onStartTracker) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(BounceButtonStyle())
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.caption)
                .foregroundStyle(theme.colors.danger.opacity(0.6))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Field helpers

    @ViewBuilder
    private func labeledField(text: Binding<String>, label: String, suffix: String, keyboard: UIKeyboardType, width: CGFloat = 60) -> some View {
        VStack(spacing: 2) {
            TextField("0", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .frame(width: width)
                .font(.subheadline.weight(.semibold).monospacedDigit())
            HStack(spacing: 2) {
                Text(verbatim: label)
                    .font(.system(size: 9, weight: .medium))
                if !suffix.isEmpty {
                    Text(verbatim: "· \(suffix)")
                        .font(.system(size: 9))
                }
            }
            .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, theme.spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                .fill(theme.colors.surfaceSecondary)
        )
    }

    private func durationField(seconds: Binding<Int>) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                TextField("0", value: Binding(
                    get: { seconds.wrappedValue / 60 },
                    set: { seconds.wrappedValue = $0 * 60 + (seconds.wrappedValue % 60) }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Text(verbatim: ":").font(.caption.weight(.bold)).foregroundStyle(theme.colors.onSurfaceMuted)
                TextField("00", value: Binding(
                    get: { seconds.wrappedValue % 60 },
                    set: { seconds.wrappedValue = (seconds.wrappedValue / 60) * 60 + min(59, max(0, $0)) }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            Text(verbatim: "Dauer · min")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, theme.spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                .fill(theme.colors.surfaceSecondary)
        )
    }

    // MARK: - Sync

    private func syncFromModel() {
        weightText = set_.weight.map { $0.clean } ?? ""
        repsText = set_.reps.map { String($0) } ?? ""
        distanceText = set_.distanceMeters.map { String(format: "%.2f", $0 / 1000).replacingOccurrences(of: ".", with: ",") } ?? ""
        assistedText = set_.assistedReps.map { String($0) } ?? ""
        showAssisted = (set_.assistedReps ?? 0) > 0
    }
}
