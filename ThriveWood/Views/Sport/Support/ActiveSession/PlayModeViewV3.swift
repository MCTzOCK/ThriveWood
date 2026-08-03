//
//  PlayModeViewV3.swift
//  ThriveWood
//
//  BentoUI-Play-Mode: horizontales Paging durch Übungen (BentoCarousel statt
//  fehleranfälligem Custom-Drag), pro Karte Set-Navigation, Inline-Rest-Timer,
//  große Eingaben, Abhaken/Wieder-öffnen.
//

import SwiftUI

struct PlayModeViewV3: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.bentoTheme) private var theme

    let vm: ActiveSessionViewModel
    let rest: RestTimer
    let accentColor: Color
    let onClose: () -> Void

    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.groups.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: "tray").font(.largeTitle).foregroundStyle(.white.opacity(0.4))
                    Text(verbatim: "Keine Übungen")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                VStack(spacing: 0) {
                    topBar
                    TabView(selection: $currentIndex) {
                        ForEach(Array(vm.groups.enumerated()), id: \.element.id) { index, group in
                            ExercisePlayCardV3(
                                group: group,
                                unit: vm.session.weightUnit,
                                accentColor: accentColor,
                                rest: rest,
                                exerciseIndex: index + 1,
                                totalExercises: vm.groups.count,
                                canGoBack: index > 0,
                                canGoForward: index < vm.groups.count - 1,
                                onBack: { goTo(index - 1) },
                                onForward: { goTo(index + 1) },
                                onComplete: { set in vm.toggleComplete(set) },
                                onAddSet: { vm.addSet(for: group.exercise) }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(reduceMotion ? nil : theme.motion.snappy, value: vm.groups.count)
                }
            }
        }
        .statusBarHidden(true)
        .onAppear { currentIndex = min(currentIndex, max(0, vm.groups.count - 1)) }
        .onDisappear { vm.flushSave() }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var topBar: some View {
        HStack {
            Button { onClose(); dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                    Text(verbatim: "Schließen")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(BounceButtonStyle())
            Spacer()
            pageDots
            Spacer()
            Color.clear.frame(width: 90, height: 36)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.sm)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<vm.groups.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? accentColor : Color.white.opacity(0.25))
                    .frame(width: i == currentIndex ? 24 : 8, height: 4)
                    .animation(reduceMotion ? nil : theme.motion.snappy, value: currentIndex)
            }
        }
    }

    private func goTo(_ index: Int) {
        let clamped = max(0, min(index, vm.groups.count - 1))
        withAnimation(reduceMotion ? nil : theme.motion.snappy) { currentIndex = clamped }
        Haptics.selection()
    }
}

// MARK: - ExercisePlayCardV3

private struct ExercisePlayCardV3: View {
    let group: ActiveSessionViewModel.Group
    let unit: WeightUnit
    let accentColor: Color
    let rest: RestTimer
    let exerciseIndex: Int
    let totalExercises: Int
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onComplete: (SetEntry) -> Void
    let onAddSet: () -> Void

    @Environment(\.bentoTheme) private var theme

    @State private var viewSetIndex: Int = 0
    @State private var restWasRunning: Bool = false

    private var sets: [SetEntry] { group.sets }
    private var exercise: Exercise { group.exercise }

    private var currentSet: SetEntry? {
        guard viewSetIndex < sets.count else { return nil }
        return sets[viewSetIndex]
    }

    private var completed: Int { sets.filter(\.isCompleted).count }
    private var allDone: Bool { completed == sets.count && !sets.isEmpty }
    private var progress: Double { sets.isEmpty ? 0 : Double(completed) / Double(sets.count) }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            Spacer()
            if rest.isRunning {
                inlineRestTimer
            } else if let set = currentSet {
                currentSetView(set)
            } else if allDone {
                doneView
            } else {
                emptyView
            }
            Spacer()
            setNavButtons
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .onAppear { viewSetIndex = sets.firstIndex { !$0.isCompleted } ?? 0 }
        .onChange(of: rest.isRunning) { _, isRunning in
            if restWasRunning && !isRunning { advanceToNextSet() }
            restWasRunning = isRunning
        }
    }

    private func advanceToNextSet() {
        let nextIncomplete = sets.firstIndex { !$0.isCompleted }
        if let next = nextIncomplete, next != viewSetIndex {
            withAnimation(.snappy) { viewSetIndex = next }
        } else if viewSetIndex < sets.count - 1 {
            withAnimation(.snappy) { viewSetIndex += 1 }
        } else if totalExercises > exerciseIndex {
            onForward()
        }
    }

    private var cardHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: exercise.iconSystemName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            Text(exercise.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Text(verbatim: "\(exerciseIndex) / \(totalExercises)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                if !sets.isEmpty {
                    Text(verbatim: "·").font(.caption).foregroundStyle(.white.opacity(0.3))
                    Text(verbatim: "\(completed)/\(sets.count) Sätze")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(allDone ? theme.colors.success : .white.opacity(0.6))
                }
            }
            if !sets.isEmpty { progressBar }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(allDone ? theme.colors.success : accentColor)
                    .frame(width: geo.size.width * progress)
                    .animation(reduceMotion ? nil : theme.motion.snappy, value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 40)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var inlineRestTimer: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(.white.opacity(0.2), lineWidth: 6).frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: rest.progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(verbatim: rest.formatted)
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text(verbatim: "Pause")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            HStack(spacing: 12) {
                Button { rest.add(15); Haptics.selection() } label: {
                    Text(verbatim: "+15s")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.white.opacity(0.15)))
                }
                .buttonStyle(BounceButtonStyle())

                Button { rest.stop(); Haptics.impact(.light) } label: {
                    Text(verbatim: "Überspringen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(accentColor.opacity(0.15)))
                }
                .buttonStyle(BounceButtonStyle())
            }
            Text(verbatim: "Satz \(viewSetIndex + 1) · als nächstes")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private func currentSetView(_ set: SetEntry) -> some View {
        VStack(spacing: 28) {
            HStack(spacing: 8) {
                Text(verbatim: "Satz \(viewSetIndex + 1)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                if set.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(theme.colors.success)
                }
            }

            PlaySetInputsV3(setEntry: set, unit: unit, accentColor: accentColor)

            if set.isCompleted {
                Button { onComplete(set) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                        Text(verbatim: "Wieder öffnen")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                            .fill(.white.opacity(0.12))
                    )
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                Button { onComplete(set) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text(verbatim: "Abhaken")
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
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(theme.colors.success.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(theme.colors.success)
            }
            Text(verbatim: "Übung abgeschlossen")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Button { onAddSet() } label: {
                Label("Satz hinzufügen", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(accentColor.opacity(0.15)))
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.4))
            Text(verbatim: "Keine Sätze")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))
            Button { onAddSet() } label: {
                Label("Satz hinzufügen", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
        }
    }

    private var setNavButtons: some View {
        HStack(spacing: 16) {
            Button {
                if viewSetIndex > 0 {
                    withAnimation(.snappy) { viewSetIndex -= 1 }
                    Haptics.selection()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text(verbatim: "Satz \(max(1, viewSetIndex))")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewSetIndex > 0 ? .white : .white.opacity(0.15))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Capsule().fill(viewSetIndex > 0 ? .white.opacity(0.1) : Color.clear))
            }
            .disabled(viewSetIndex == 0)
            .buttonStyle(BounceButtonStyle())

            Spacer()

            Text(verbatim: "\(viewSetIndex + 1) / \(sets.count)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Button {
                if viewSetIndex < sets.count - 1 {
                    withAnimation(.snappy) { viewSetIndex += 1 }
                    Haptics.selection()
                } else { onForward() }
            } label: {
                HStack(spacing: 5) {
                    Text(verbatim: viewSetIndex < sets.count - 1 ? "Satz \(viewSetIndex + 2)" : "Weiter")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Capsule().fill(accentColor.opacity(0.15)))
            }
            .buttonStyle(BounceButtonStyle())
        }
    }
}

// MARK: - Play Set Inputs

private struct PlaySetInputsV3: View {
    @Bindable var setEntry: SetEntry
    let unit: WeightUnit
    let accentColor: Color

    @Environment(\.bentoTheme) private var theme

    @State private var assistedText: String = ""
    @State private var showAssisted: Bool = false

    private var type: ExerciseTrackingType { setEntry.exercise?.trackingType ?? .repsWeight }

    var body: some View {
        switch type {
        case .repsWeight: repsWeightInputs
        case .reps: repsOnlyInputs
        case .duration: durationInputs
        case .distanceDuration: distanceDurationInputs
        }
    }

    @ViewBuilder
    private var repsWeightInputs: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                bigInput(
                    text: Binding(
                        get: { setEntry.weight.map { $0.clean } ?? "" },
                        set: { setEntry.weight = $0.isEmpty ? nil : Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ),
                    label: "Gewicht",
                    suffix: unit.rawValue,
                    keyboard: .decimalPad
                )
                Text(verbatim: "×").font(.title.weight(.bold)).foregroundStyle(.white.opacity(0.3))
                bigInput(
                    text: Binding(
                        get: { setEntry.reps.map { String($0) } ?? "" },
                        set: { setEntry.reps = $0.isEmpty ? nil : Int($0) }
                    ),
                    label: "Reps",
                    suffix: "Wdh",
                    keyboard: .numberPad
                )
            }
            if showAssisted {
                bigInput(
                    text: Binding(
                        get: { assistedText },
                        set: {
                            assistedText = $0
                            setEntry.assistedReps = $0.isEmpty ? nil : Int($0)
                        }
                    ),
                    label: "Assisted Reps",
                    suffix: "Wdh",
                    keyboard: .numberPad
                )
                .frame(maxWidth: 240)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Button {
                withAnimation(.snappy) {
                    showAssisted.toggle()
                    if !showAssisted { setEntry.assistedReps = nil; assistedText = "" }
                }
                Haptics.selection()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: showAssisted ? "person.2.fill" : "person.2")
                    Text(verbatim: showAssisted ? "Assisted aktiv" : "Assisted Reps")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(showAssisted ? .orange : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(showAssisted ? Color.orange.opacity(0.2) : .white.opacity(0.1)))
            }
        }
        .onAppear {
            assistedText = setEntry.assistedReps.map { String($0) } ?? ""
            showAssisted = (setEntry.assistedReps ?? 0) > 0
        }
    }

    private var repsOnlyInputs: some View {
        bigInput(
            text: Binding(
                get: { setEntry.reps.map { String($0) } ?? "" },
                set: { setEntry.reps = $0.isEmpty ? nil : Int($0) }
            ),
            label: "Reps",
            suffix: "Wdh",
            keyboard: .numberPad
        )
        .frame(maxWidth: 260)
    }

    private var durationInputs: some View {
        HStack(spacing: 16) {
            bigInput(
                text: Binding(
                    get: { setEntry.durationSeconds.map { String($0 / 60) } ?? "" },
                    set: {
                        let m = Int($0) ?? 0
                        let s = (setEntry.durationSeconds ?? 0) % 60
                        setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                    }
                ),
                label: "Minuten",
                suffix: "min",
                keyboard: .numberPad
            )
            bigInput(
                text: Binding(
                    get: { setEntry.durationSeconds.map { String($0 % 60) } ?? "" },
                    set: {
                        let s = Int($0) ?? 0
                        let m = (setEntry.durationSeconds ?? 0) / 60
                        setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                    }
                ),
                label: "Sekunden",
                suffix: "s",
                keyboard: .numberPad
            )
        }
    }

    private var distanceDurationInputs: some View {
        VStack(spacing: 20) {
            bigInput(
                text: Binding(
                    get: { setEntry.distanceMeters.map { String(format: "%.2f", $0 / 1000).replacingOccurrences(of: ".", with: ",") } ?? "" },
                    set: { setEntry.distanceMeters = $0.isEmpty ? nil : (Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000 }
                ),
                label: "Distanz",
                suffix: "km",
                keyboard: .decimalPad
            )
            .frame(maxWidth: 260)
            HStack(spacing: 16) {
                bigInput(
                    text: Binding(
                        get: { setEntry.durationSeconds.map { String($0 / 60) } ?? "" },
                        set: {
                            let m = Int($0) ?? 0
                            let s = (setEntry.durationSeconds ?? 0) % 60
                            setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                        }
                    ),
                    label: "Min",
                    suffix: "",
                    keyboard: .numberPad
                )
                bigInput(
                    text: Binding(
                        get: { setEntry.durationSeconds.map { String($0 % 60) } ?? "" },
                        set: {
                            let s = Int($0) ?? 0
                            let m = (setEntry.durationSeconds ?? 0) / 60
                            setEntry.durationSeconds = (m * 60 + s) == 0 ? nil : (m * 60 + s)
                        }
                    ),
                    label: "Sek",
                    suffix: "",
                    keyboard: .numberPad
                )
            }
        }
    }

    @ViewBuilder
    private func bigInput(text: Binding<String>, label: String, suffix: String, keyboard: UIKeyboardType) -> some View {
        VStack(spacing: 8) {
            TextField("0", text: text)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .keyboardType(keyboard)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                        .fill(.white.opacity(0.1))
                )
            HStack(spacing: 3) {
                Text(verbatim: label).font(.caption.weight(.semibold))
                if !suffix.isEmpty {
                    Text(verbatim: "· \(suffix)").font(.caption2).foregroundStyle(.white.opacity(0.6))
                }
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
