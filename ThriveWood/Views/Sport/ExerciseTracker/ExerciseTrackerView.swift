//
//  ExerciseTrackerView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI

struct ExerciseTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var tracker: ExerciseTrackerService
    let exercise: Exercise
    let onComplete: (Int, Double?) -> Void

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                header
                Spacer()
                metrics
                Spacer()
                controls
                Spacer().frame(height: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .statusBarHidden(true)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, Color(red: 0.08, green: 0.08, blue: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.s) {
            Image(systemName: exercise.iconSystemName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
            Text(exercise.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(trackingLabel)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var trackingLabel: String {
        switch tracker.trackingType {
        case .duration: "Zeitgesteuerte Übung"
        case .distanceDuration: "Distanz & Zeit Tracking"
        default: ""
        }
    }

    // MARK: - Metrics

    @ViewBuilder
    private var metrics: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            timerDisplay

            if tracker.trackingType == .distanceDuration {
                distanceDisplay
                paceDisplay
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(tracker.formattedElapsed)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Zeit")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
        }
    }

    private var distanceDisplay: some View {
        VStack(spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tracker.formattedDistance)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.teal)
                Text("km")
                    .font(.title3)
                    .foregroundStyle(.teal.opacity(0.7))
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            Text("Distanz")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
        }
    }

    private var paceDisplay: some View {
        HStack(spacing: Theme.Spacing.m) {
            Label {
                Text(tracker.formattedPace + " /km")
                    .font(.body.monospacedDigit())
            } icon: {
                Image(systemName: "speedometer")
                    .foregroundStyle(.orange)
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(.white.opacity(0.1)))
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        if !tracker.isTracking {
            startButton
        } else if tracker.isPaused {
            HStack(spacing: Theme.Spacing.l) {
                resumeButton
                finishButton
            }
        } else {
            HStack(spacing: Theme.Spacing.l) {
                pauseButton
                finishButton
            }
        }
    }

    private var startButton: some View {
        Button(action: { tracker.start(trackingType: tracker.trackingType) }) {
            Label("Start", systemImage: "play.fill")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.l)
                .background(Capsule().fill(.green))
        }
    }

    private var pauseButton: some View {
        Button(action: { tracker.pause() }) {
            Image(systemName: "pause.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(.orange))
        }
    }

    private var resumeButton: some View {
        Button(action: { tracker.resume() }) {
            Image(systemName: "play.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(.green))
        }
    }

    private var finishButton: some View {
        Button(action: finish) {
            Label("Fertig", systemImage: "checkmark")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.l)
                .background(Capsule().fill(.blue))
        }
    }

    // MARK: - Actions

    private func finish() {
        let seconds = tracker.elapsedSeconds
        let distance = tracker.trackingType == .distanceDuration ? tracker.distanceMeters : nil
        tracker.stop()
        onComplete(seconds, distance)
        dismiss()
    }
}