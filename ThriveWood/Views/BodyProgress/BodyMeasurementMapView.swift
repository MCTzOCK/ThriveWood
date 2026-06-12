//
//  BodyMeasurementMapView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 12.06.26.
//

import SwiftUI

enum MeasurementZone: String, CaseIterable {
    case neck
    case shoulders
    case chest
    case biceps
    case forearms
    case waist
    case hip
    case thighs
    case calves

    var label: String {
        switch self {
        case .neck: return "Nacken"
        case .shoulders: return "Schultern"
        case .chest: return "Brust"
        case .biceps: return "Oberarm"
        case .forearms: return "Unterarm"
        case .waist: return "Taille"
        case .hip: return "Hüfte"
        case .thighs: return "Oberschenkel"
        case .calves: return "Wade"
        }
    }

    var shortLabel: String {
        switch self {
        case .neck: return "Nk"
        case .shoulders: return "Sch"
        case .chest: return "Br"
        case .biceps: return "OA"
        case .forearms: return "UA"
        case .waist: return "Tai"
        case .hip: return "Hüf"
        case .thighs: return "OS"
        case .calves: return "Wd"
        }
    }

    var tint: Color {
        switch self {
        case .neck: return .mint
        case .shoulders: return .indigo
        case .chest: return .green
        case .biceps: return .orange
        case .forearms: return .teal
        case .waist: return .purple
        case .hip: return .pink
        case .thighs: return .blue
        case .calves: return .cyan
        }
    }

    var chartMetric: ChartMetric {
        switch self {
        case .neck: return .neck
        case .shoulders: return .shoulders
        case .chest: return .chest
        case .biceps: return .biceps
        case .forearms: return .forearms
        case .waist: return .waist
        case .hip: return .hip
        case .thighs: return .thighs
        case .calves: return .calves
        }
    }
}

struct BodyMeasurementMapView: View {
    let entry: BodyProgressEntry
    @Binding var selectedZone: MeasurementZone?
    @Binding var showFront: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let svgWidth: CGFloat = 35.0
    private let svgHeight: CGFloat = 93.0
    private let mapHeight: CGFloat = 380.0

    var body: some View {
        let helpers = AnatomicMuscleHelpers()
        let defs = showFront ? helpers.FRONT_MUSCLES : helpers.BACK_MUSCLES
        let vbOriginX: CGFloat = showFront ? 0 : 37
        let mapWidth = mapHeight * (svgWidth / svgHeight)
        let scale = mapHeight / svgHeight
        let zones = groupedZones(from: defs)

        VStack(spacing: Theme.Spacing.s) {
            ZStack {
                ForEach(zones, id: \.zone.rawValue) { group in
                    let p = group.path(scale: scale, vbOriginX: vbOriginX)
                    let isSelected = selectedZone == group.zone
                    let hasData = zoneHasData(group.zone)

                    p.fill(zoneColor(for: group.zone))
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
                                selectedZone = selectedZone == group.zone ? nil : group.zone
                            }
                        }
                }

                if let sel = selectedZone {
                    labelOverlay(for: sel, zones: zones, scale: scale, vbOriginX: vbOriginX)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedZone)
            .frame(width: mapWidth, height: mapHeight)

            Picker("", selection: $showFront) {
                Text("Vorne").tag(true)
                Text("Hinten").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }

    // MARK: - Data Lookup

    private func zoneHasData(_ zone: MeasurementZone) -> Bool {
        valueText(for: zone) != nil
    }

    private func valueText(for zone: MeasurementZone) -> String? {
        switch zone {
        case .neck:
            if let v = entry.neckCm { return String(format: "%.1f", v) }
        case .shoulders:
            if let v = entry.shoulderCm { return String(format: "%.1f", v) }
        case .chest:
            if let v = entry.chestCm { return String(format: "%.1f", v) }
        case .biceps:
            if let l = entry.leftBicepCm { return String(format: "%.1f / %.1f", l, entry.rightBicepCm ?? l) }
            if let r = entry.rightBicepCm { return String(format: "%.1f", r) }
        case .forearms:
            if let l = entry.leftForearmCm { return String(format: "%.1f / %.1f", l, entry.rightForearmCm ?? l) }
            if let r = entry.rightForearmCm { return String(format: "%.1f", r) }
        case .waist:
            if let v = entry.waistCm { return String(format: "%.1f", v) }
        case .hip:
            if let v = entry.hipCm { return String(format: "%.1f", v) }
        case .thighs:
            if let l = entry.leftThighCm { return String(format: "%.1f / %.1f", l, entry.rightThighCm ?? l) }
            if let r = entry.rightThighCm { return String(format: "%.1f", r) }
        case .calves:
            if let l = entry.leftCalfCm { return String(format: "%.1f / %.1f", l, entry.rightCalfCm ?? l) }
            if let r = entry.rightCalfCm { return String(format: "%.1f", r) }
        }
        return nil
    }

    // MARK: - Colors

    private func zoneColor(for zone: MeasurementZone) -> Color {
        let isSelected = selectedZone == zone
        let hasData = zoneHasData(zone)
        let tint = zone.tint

        if isSelected {
            return hasData ? tint.opacity(0.8) : tint.opacity(0.5)
        }
        if hasData {
            return tint.opacity(0.4)
        }
        return (colorScheme == .dark ? Color.white : Color.black).opacity(0.06)
    }

    // MARK: - Label Overlay

    private func labelCenter(for zone: MeasurementZone, zones: [MeasurementZoneGroup], scale: CGFloat, vbOriginX: CGFloat) -> CGPoint? {
        var combined = Path()
        for group in zones where group.zone == zone {
            combined.addPath(group.path(scale: scale, vbOriginX: vbOriginX))
        }
        let bbox = combined.boundingRect
        guard !bbox.isEmpty else { return nil }
        return CGPoint(x: bbox.midX, y: bbox.midY)
    }

    @ViewBuilder
    private func labelOverlay(for zone: MeasurementZone, zones: [MeasurementZoneGroup], scale: CGFloat, vbOriginX: CGFloat) -> some View {
        if let pos = labelCenter(for: zone, zones: zones, scale: scale, vbOriginX: vbOriginX) {
            VStack(spacing: 1) {
                if let val = valueText(for: zone) {
                    Text(val)
                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                    Text(zone.shortLabel)
                        .font(.system(size: 7, weight: .semibold))
                } else {
                    Text(zone.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.7), radius: 2)
            .position(pos)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - SVG ID → MeasurementZone

    private func svgIdToMeasurementZone(_ id: String) -> MeasurementZone? {
        switch id {
        case "neck-left", "neck-right", "nape":
            return .neck
        case "shoulder-front-left", "shoulder-front-right", "shoulder-side-left", "shoulder-side-right",
             "deltoid-rear-left", "deltoid-rear-right",
             "traps-upper-left", "traps-mid-left", "traps-lower-left",
             "traps-upper-right", "traps-mid-right", "traps-lower-right":
            return .shoulders
        case "chest-upper-left", "chest-lower-left", "chest-upper-right", "chest-lower-right",
             "lats-upper-left", "lats-mid-left", "lats-lower-left",
             "lats-upper-right", "lats-mid-right", "lats-lower-right":
            return .chest
        case "biceps-left", "biceps-right",
             "triceps-long-left", "triceps-lateral-left",
             "triceps-long-right", "triceps-lateral-right":
            return .biceps
        case "forearm-left", "forearm-right", "forearm-flexors-left", "forearm-flexors-right",
             "forearm-extensors-left", "forearm-extensors-right":
            return .forearms
        case "abs-upper-left", "abs-lower-left", "abs-upper-right", "abs-lower-right",
             "obliques-left", "obliques-right", "serratus-anterior-left", "serratus-anterior-right",
             "spine", "lower-back-erectors-left", "lower-back-erectors-right",
             "lower-back-ql-left", "lower-back-ql-right":
            return .waist
        case "hip-flexor-left", "hip-flexor-right",
             "gluteus-maximus-left", "gluteus-maximus-right", "gluteus-medius-left", "gluteus-medius-right":
            return .hip
        case "quads-left", "quads-right", "adductors-left", "adductors-right",
             "hamstrings-medial-left", "hamstrings-lateral-left", "hamstrings-medial-right", "hamstrings-lateral-right":
            return .thighs
        case "tibialis-anterior-left", "tibialis-anterior-right",
             "calves-gastroc-medial-left", "calves-gastroc-lateral-left", "calves-soleus-left",
             "calves-gastroc-medial-right", "calves-gastroc-lateral-right", "calves-soleus-right":
            return .calves
        default:
            return nil
        }
    }

    // MARK: - Grouping

    private struct MeasurementZoneGroup {
        let zone: MeasurementZone
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

    private func groupedZones(from defs: [AMH_MuscleDef]) -> [MeasurementZoneGroup] {
        var map: [MeasurementZone: [String]] = [:]
        for d in defs {
            guard let zone = svgIdToMeasurementZone(d.id) else { continue }
            if map[zone] == nil { map[zone] = [] }
            map[zone]!.append(d.path)
        }
        return map.map { zone, paths in
            MeasurementZoneGroup(zone: zone, svgPaths: paths)
        }.sorted { $0.zone.rawValue < $1.zone.rawValue }
    }
}