//
//  SessionMuscleMapView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 12.06.26.
//

import SwiftUI

struct SessionMuscleMapView: View {
    let volumes: [MuscleGroup: Double]
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var showFront: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let svgWidth: CGFloat = 35.0
    private let svgHeight: CGFloat = 93.0
    private let mapHeight: CGFloat = 340.0

    private var maxVolume: Double {
        max(volumes.values.max() ?? 1, 1)
    }

    static func mapGroup(for muscle: MuscleGroup) -> MuscleGroup {
        switch muscle {
        case .frontDelts, .sideDelts, .rotatorCuff: return .shoulders
        case .upperChest: return .chest
        case .upperBack, .rhomboids: return .traps
        case .midBack: return .lats
        case .rearShoulders: return .rearDelts
        case .abductors: return .glutes
        default: return muscle
        }
    }

    var body: some View {
        let helpers = AnatomicMuscleHelpers()
        let defs = showFront ? helpers.FRONT_MUSCLES : helpers.BACK_MUSCLES
        let vbOriginX: CGFloat = showFront ? 0 : 37
        let mapWidth = mapHeight * (svgWidth / svgHeight)
        let scale = mapHeight / svgHeight
        let zones = groupedZones(from: defs)

        VStack(spacing: Theme.Spacing.s) {
            ZStack {
                ForEach(zones, id: \.muscle.rawValue) { group in
                    let p = group.path(scale: scale, vbOriginX: vbOriginX)
                    let isSelected = selectedMuscle == group.muscle
                    p.fill(muscleColor(for: group.muscle))
                        .overlay(
                            p.stroke(
                                isSelected ? Color.white : Color.black.opacity(0.12),
                                lineWidth: isSelected ? 2.5 : 0.8
                            )
                        )
                        .scaleEffect(isSelected ? 1.02 : 1.0)
                        .onTapGesture {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMuscle = selectedMuscle == group.muscle ? nil : group.muscle
                            }
                        }
                }

                if let sel = selectedMuscle {
                    labelOverlay(for: sel, zones: zones, scale: scale, vbOriginX: vbOriginX)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMuscle)
            .frame(width: mapWidth, height: mapHeight)
            .frame(maxWidth: .infinity)

            if let sel = selectedMuscle, let vol = volumes[sel], vol > 0 {
                HStack(spacing: Theme.Spacing.s) {
                    Circle()
                        .fill(muscleColor(for: sel))
                        .frame(width: 12, height: 12)
                    Text(sel.label)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(formatVolume(vol))
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Theme.Spacing.m)
            }

            legend
        }
    }

    private func muscleColor(for muscle: MuscleGroup) -> Color {
        let v = volumes[muscle] ?? 0
        let isSelected = selectedMuscle == muscle

        guard v > 0 else {
            if isSelected { return Color(.systemGray3) }
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
        }

        let fraction = v / maxVolume
        let baseColor: Color
        switch fraction {
        case 0.67...1.0: baseColor = .red
        case 0.34..<0.67: baseColor = .orange
        default: baseColor = .teal
        }

        return isSelected ? baseColor.opacity(0.85) : baseColor.opacity(0.55)
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.m) {
            legendItem(
                color: colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                label: "—"
            )
            legendItem(color: .teal.opacity(0.55), label: "Niedrig")
            legendItem(color: .orange.opacity(0.55), label: "Mittel")
            legendItem(color: .red.opacity(0.55), label: "Hoch")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 100 {
            return "\(Int(v)) kg"
        } else if v >= 1 {
            return String(format: "%.1f kg", v)
        } else {
            return String(format: "%.2f", v)
        }
    }

    // MARK: - Label Overlay

    private func labelCenter(for muscle: MuscleGroup, zones: [MuscleGroupZone], scale: CGFloat, vbOriginX: CGFloat) -> CGPoint? {
        var combined = Path()
        for group in zones where group.muscle == muscle {
            combined.addPath(group.path(scale: scale, vbOriginX: vbOriginX))
        }
        let bbox = combined.boundingRect
        guard !bbox.isEmpty else { return nil }
        return CGPoint(x: bbox.midX, y: bbox.midY)
    }

    @ViewBuilder
    private func labelOverlay(for muscle: MuscleGroup, zones: [MuscleGroupZone], scale: CGFloat, vbOriginX: CGFloat) -> some View {
        if let pos = labelCenter(for: muscle, zones: zones, scale: scale, vbOriginX: vbOriginX) {
            Text(muscle.shortLabel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 2)
                .position(pos)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Grouping SVG paths by MuscleGroup

    private struct MuscleGroupZone {
        let muscle: MuscleGroup
        let svgPaths: [String]

        func path(scale: CGFloat, vbOriginX: CGFloat) -> Path {
            var result = Path()
            for svgPath in svgPaths {
                let parsed = AnatomicMuscleMapView.parseSVGPath(
                    svgPath: svgPath, scale: scale, vbOriginX: vbOriginX)
                result.addPath(parsed)
            }
            return result
        }
    }

    private func groupedZones(from defs: [AMH_MuscleDef]) -> [MuscleGroupZone] {
        var map: [MuscleGroup: [String]] = [:]
        for d in defs {
            guard let group = svgIdToMuscleGroup(d.id) else { continue }
            if map[group] == nil { map[group] = [] }
            map[group]!.append(d.path)
        }
        return map.map { muscle, paths in
            MuscleGroupZone(muscle: muscle, svgPaths: paths)
        }.sorted { $0.muscle.rawValue < $1.muscle.rawValue }
    }

    private func svgIdToMuscleGroup(_ id: String) -> MuscleGroup? {
        switch id {
        case "shoulder-front-left", "shoulder-front-right", "shoulder-side-left", "shoulder-side-right":
            return .shoulders
        case "chest-upper-left", "chest-lower-left", "chest-upper-right", "chest-lower-right":
            return .chest
        case "biceps-left", "biceps-right":
            return .biceps
        case "forearm-left", "forearm-right", "forearm-flexors-left", "forearm-flexors-right",
             "forearm-extensors-left", "forearm-extensors-right":
            return .forearms
        case "abs-upper-left", "abs-lower-left", "abs-upper-right", "abs-lower-right":
            return .core
        case "obliques-left", "obliques-right":
            return .obliques
        case "serratus-anterior-left", "serratus-anterior-right":
            return .serratus
        case "hip-flexor-left", "hip-flexor-right":
            return .hipFlexors
        case "quads-left", "quads-right":
            return .quads
        case "adductors-left", "adductors-right":
            return .adductors
        case "tibialis-anterior-left", "tibialis-anterior-right":
            return .tibialis
        case "neck-left", "neck-right":
            return .neck
        case "traps-upper-left", "traps-mid-left", "traps-lower-left",
             "traps-upper-right", "traps-mid-right", "traps-lower-right":
            return .traps
        case "lats-upper-left", "lats-mid-left", "lats-lower-left",
             "lats-upper-right", "lats-mid-right", "lats-lower-right":
            return .lats
        case "deltoid-rear-left", "deltoid-rear-right":
            return .rearDelts
        case "lower-back-erectors-left", "lower-back-erectors-right",
             "lower-back-ql-left", "lower-back-ql-right":
            return .lowerBack
        case "triceps-long-left", "triceps-lateral-left",
             "triceps-long-right", "triceps-lateral-right":
            return .triceps
        case "gluteus-maximus-left", "gluteus-medius-left",
             "gluteus-maximus-right", "gluteus-medius-right":
            return .glutes
        case "hamstrings-medial-left", "hamstrings-lateral-left",
             "hamstrings-medial-right", "hamstrings-lateral-right":
            return .hamstrings
        case "calves-gastroc-medial-left", "calves-gastroc-lateral-left", "calves-soleus-left",
             "calves-gastroc-medial-right", "calves-gastroc-lateral-right", "calves-soleus-right":
            return .calves
        case "nape":
            return .neck
        case "spine":
            return .lowerBack
        default:
            return nil
        }
    }
}
