//
//  WorkoutLiveActivity.swift
//  ThriveWood
//
//  Created by Ben Siebert on 08.05.26.
//


import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner View
            WorkoutLockScreenView(context: context)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 4) {
                    Image(systemName: context.attributes.workoutIcon)
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(formatTime(context.state.elapsedSeconds))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white)
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                if context.state.isResting {
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(context.state.restSecondsRemaining ?? 0)s")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(.orange)
                    }
                } else {
                    Text("\(context.state.completedSets)/\(context.state.totalSets)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.green)
                }
            } minimal: {
                // MARK: - Minimal (wenn 2 Activities aktiv)
                ZStack {
                    Circle()
                        .strokeBorder(.green.opacity(0.3), lineWidth: 2)
                    Circle()
                        .trim(
                            from: 0,
                            to: CGFloat(context.state.completedSets) / max(1, CGFloat(context.state.totalSets))
                        )
                        .stroke(.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                }
            }
        }
    }
    
    // MARK: - Expanded Regions
    
    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: context.attributes.workoutIcon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(formatTime(context.state.elapsedSeconds))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(context.state.completedSets)/\(context.state.totalSets)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.green)
            Text("Sets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func expandedCenter(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(spacing: 2) {
            Text(context.attributes.workoutName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(context.state.currentExerciseName)
                .font(.headline)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(context.state.isResting ? Color.orange : Color.green)
                        .frame(
                            width: geo.size.width * (CGFloat(context.state.completedSets) / max(1, CGFloat(context.state.totalSets)))
                        )
                }
            }
            .frame(height: 6)
            
            HStack {
                // Übung X von Y
                Text("Übung \(context.state.currentExerciseIndex)/\(context.state.totalExercises)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Rest-Timer oder letzter Satz
                if context.state.isResting, let rest = context.state.restSecondsRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text("Pause \(rest)s")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.orange)
                } else if let lastSet = context.state.lastSetInfo {
                    Text(lastSet)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Lock Screen View

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: context.attributes.workoutIcon)
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(context.attributes.workoutName)
                            .font(.subheadline.weight(.semibold))
                        Text(context.state.currentExerciseName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Timer
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatTime(context.state.elapsedSeconds))
                        .font(.title3.monospacedDigit().weight(.bold))
                    Text("Übung \(context.state.currentExerciseIndex)/\(context.state.totalExercises)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress
            HStack(spacing: 12) {
                // Sets Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sets")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(context.state.completedSets)/\(context.state.totalSets)")
                            .font(.caption.monospacedDigit().weight(.bold))
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15))
                            Capsule()
                                .fill(context.state.isResting ? Color.orange : Color.green)
                                .frame(
                                    width: geo.size.width * CGFloat(context.state.completedSets) / max(1, CGFloat(context.state.totalSets))
                                )
                        }
                    }
                    .frame(height: 6)
                }
                
                // Rest Timer Badge
                if context.state.isResting, let rest = context.state.restSecondsRemaining {
                    VStack(spacing: 2) {
                        Image(systemName: "timer")
                            .font(.title3)
                        Text("\(rest)s")
                            .font(.caption.monospacedDigit().weight(.black))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.2))
                    )
                }
            }
            
            // Letzter Satz Info
            if let lastSet = context.state.lastSetInfo {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Letzter Satz: \(lastSet)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.7))
        .activitySystemActionForegroundColor(.white)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
