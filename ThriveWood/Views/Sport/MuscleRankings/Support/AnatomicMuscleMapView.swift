//
//  AnatomicMuscleMapView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 19.05.26.
//

import SwiftUI

struct AnatomicMuscleMapView: View {
    let rankings: [MuscleRankingData]
    let recoveryData: [MuscleRecoveryData]?
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var showFront: Bool

    @Environment(\.colorScheme) private var colorScheme
    
    private let svgWidth: CGFloat = 35.0
    private let svgHeight: CGFloat = 93.0
    private let mapHeight: CGFloat = 380.0

    private func rank(for muscle: MuscleGroup) -> MuscleRank {
        rankings.first(where: { $0.muscleGroup == muscle })?.rank ?? .untrained
    }

    var body: some View {
        let helpers = AnatomicMuscleHelpers()
        let defs = showFront ? helpers.FRONT_MUSCLES : helpers.BACK_MUSCLES
        let vbOriginX: CGFloat = showFront ? 0 : 37
        let mapWidth = mapHeight * (svgWidth / svgHeight)
        let scale = mapHeight / svgHeight
        let zones = groupedZones(from: defs)

        ZStack {
            ForEach(zones, id: \.muscle.rawValue) { group in
                let p = group.path(scale: scale, vbOriginX: vbOriginX)
                let strokeColor: Color = {
                    if let recoveryData = recoveryData {
                        let rd = recoveryData.first(where: { $0.muscleGroup == group.muscle })
                        if let rd = rd {
                            switch rd.state {
                            case .needsRest: return .red
                            case .warning: return .orange
                            case .recovered: return selectedMuscle == group.muscle ? .white : Color.black.opacity(0.15)
                            }
                        }
                        return selectedMuscle == group.muscle ? .white : Color.black.opacity(0.15)
                    }
                    return selectedMuscle == group.muscle ? Color.white : Color.black.opacity(0.15)
                }()
                let strokeW: CGFloat = selectedMuscle == group.muscle ? 2.5 : 0.8
                p.fill(zoneColor(for: group.muscle))
                    .overlay(
                        p.stroke(strokeColor, lineWidth: strokeW)
                    )
                    .scaleEffect(selectedMuscle == group.muscle ? 1.02 : 1.0)
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
    }

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
            VStack(spacing: 1) {
                if let recoveryData = recoveryData,
                   let rd = recoveryData.first(where: { $0.muscleGroup == muscle }) {
                    Image(systemName: rd.stateIcon)
                        .font(.system(size: 12, weight: .bold))
                    Text(muscle.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                } else {
                    Image(systemName: rank(for: muscle).icon)
                        .font(.system(size: 12, weight: .bold))
                    Text(muscle.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.7), radius: 2)
            .position(pos)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func zoneColor(for muscle: MuscleGroup) -> Color {
        if let recoveryData = recoveryData {
            let data = recoveryData.first(where: { $0.muscleGroup == muscle })
            if data == nil || data!.weeklyVolume == 0 {
                return muscle == selectedMuscle ? Color.green.opacity(0.75) : Color.green.opacity(0.2)
            }
            let state = data!.state
            switch state {
            case .recovered:
                return muscle == selectedMuscle ? Color.green.opacity(0.75) : Color.green.opacity(0.35)
            case .warning:
                return muscle == selectedMuscle ? Color.orange.opacity(0.85) : Color.orange.opacity(0.55)
            case .needsRest:
                return muscle == selectedMuscle ? Color.red.opacity(0.85) : Color.red.opacity(0.6)
            }
        }

        let r = rank(for: muscle)
        if muscle == selectedMuscle { return r.primaryColor.opacity(0.85) }
        if r == .untrained { return (
            colorScheme == .dark ? Color.white : Color.black
        ).opacity(0.55) }
        return r.primaryColor.opacity(0.5)
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

    // MARK: - SVG ID → MuscleGroup mapping

    private func svgIdToMuscleGroup(_ id: String) -> MuscleGroup? {
        switch id {
        case "shoulder-front-left", "shoulder-front-right", "shoulder-side-left", "shoulder-side-right":
            return .shoulders
        case "chest-upper-left", "chest-lower-left", "chest-upper-right", "chest-lower-right":
            return .chest
        case "biceps-left", "biceps-right":
            return .biceps
        case "forearm-left", "forearm-right", "forearm-flexors-left", "forearm-flexors-right", "forearm-extensors-left", "forearm-extensors-right":
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
        case "traps-upper-left", "traps-mid-left", "traps-lower-left", "traps-upper-right", "traps-mid-right", "traps-lower-right":
            return .traps
        case "lats-upper-left", "lats-mid-left", "lats-lower-left", "lats-upper-right", "lats-mid-right", "lats-lower-right":
            return .lats
        case "deltoid-rear-left", "deltoid-rear-right":
            return .rearDelts
        case "lower-back-erectors-left", "lower-back-erectors-right", "lower-back-ql-left", "lower-back-ql-right":
            return .lowerBack
        case "triceps-long-left", "triceps-lateral-left", "triceps-long-right", "triceps-lateral-right":
            return .triceps
        case "gluteus-maximus-left", "gluteus-medius-left", "gluteus-maximus-right", "gluteus-medius-right":
            return .glutes
        case "hamstrings-medial-left", "hamstrings-lateral-left", "hamstrings-medial-right", "hamstrings-lateral-right":
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

    // MARK: - SVG Path Parsing

    static func parseSVGPath(svgPath: String, scale: CGFloat, vbOriginX: CGFloat) -> Path {
        let tokens = tokenizeSVG(svgPath: svgPath)
        var path = Path()
        var currentX: CGFloat = 0, currentY: CGFloat = 0
        var subpathStartX: CGFloat = 0, subpathStartY: CGFloat = 0
        var i = 0

        func tx(_ x: CGFloat) -> CGFloat { (x - vbOriginX) * scale }
        func ty(_ y: CGFloat) -> CGFloat { y * scale }

        while i < tokens.count {
            guard let cmd = tokens[i].first, cmd.isLetter else { i += 1; continue }
            i += 1

            switch cmd {
            case "M", "m":
                let rel = cmd == "m"
                if rel { currentX += CGFloat(tokens[i].floatValue ?? 0) } else { currentX = CGFloat(tokens[i].floatValue ?? 0) }
                i += 1
                if rel { currentY += CGFloat(tokens[i].floatValue ?? 0) } else { currentY = CGFloat(tokens[i].floatValue ?? 0) }
                i += 1
                path.move(to: CGPoint(x: tx(currentX), y: ty(currentY)))
                subpathStartX = currentX; subpathStartY = currentY
                while i < tokens.count && !tokens[i].first!.isLetter {
                    if rel { currentX += CGFloat(tokens[i].floatValue ?? 0) } else { currentX = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    if rel { currentY += CGFloat(tokens[i].floatValue ?? 0) } else { currentY = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    path.addLine(to: CGPoint(x: tx(currentX), y: ty(currentY)))
                }
            case "L", "l":
                let rel = cmd == "l"
                while i < tokens.count && !tokens[i].first!.isLetter {
                    if rel { currentX += CGFloat(tokens[i].floatValue ?? 0) } else { currentX = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    if rel { currentY += CGFloat(tokens[i].floatValue ?? 0) } else { currentY = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    path.addLine(to: CGPoint(x: tx(currentX), y: ty(currentY)))
                }
            case "H", "h":
                let rel = cmd == "h"
                while i < tokens.count && !tokens[i].first!.isLetter {
                    if rel { currentX += CGFloat(tokens[i].floatValue ?? 0) } else { currentX = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    path.addLine(to: CGPoint(x: tx(currentX), y: ty(currentY)))
                }
            case "V", "v":
                let rel = cmd == "v"
                while i < tokens.count && !tokens[i].first!.isLetter {
                    if rel { currentY += CGFloat(tokens[i].floatValue ?? 0) } else { currentY = CGFloat(tokens[i].floatValue ?? 0) }
                    i += 1
                    path.addLine(to: CGPoint(x: tx(currentX), y: ty(currentY)))
                }
            case "C", "c":
                let rel = cmd == "c"
                while i + 5 < tokens.count {
                    let x1 = CGFloat(tokens[i].floatValue ?? 0) + (rel ? currentX : 0)
                    let y1 = CGFloat(tokens[i+1].floatValue ?? 0) + (rel ? currentY : 0)
                    let x2 = CGFloat(tokens[i+2].floatValue ?? 0) + (rel ? currentX : 0)
                    let y2 = CGFloat(tokens[i+3].floatValue ?? 0) + (rel ? currentY : 0)
                    let x = CGFloat(tokens[i+4].floatValue ?? 0) + (rel ? currentX : 0)
                    let y = CGFloat(tokens[i+5].floatValue ?? 0) + (rel ? currentY : 0)
                    i += 6
                    path.addCurve(to: CGPoint(x: tx(x), y: ty(y)),
                                  control1: CGPoint(x: tx(x1), y: ty(y1)),
                                  control2: CGPoint(x: tx(x2), y: ty(y2)))
                    currentX = x; currentY = y
                    if i < tokens.count && tokens[i].first!.isLetter { break }
                }
            case "Q", "q":
                let rel = cmd == "q"
                while i + 3 < tokens.count {
                    let x1 = CGFloat(tokens[i].floatValue ?? 0) + (rel ? currentX : 0)
                    let y1 = CGFloat(tokens[i+1].floatValue ?? 0) + (rel ? currentY : 0)
                    let x = CGFloat(tokens[i+2].floatValue ?? 0) + (rel ? currentX : 0)
                    let y = CGFloat(tokens[i+3].floatValue ?? 0) + (rel ? currentY : 0)
                    i += 4
                    path.addQuadCurve(to: CGPoint(x: tx(x), y: ty(y)),
                                      control: CGPoint(x: tx(x1), y: ty(y1)))
                    currentX = x; currentY = y
                    if i < tokens.count && tokens[i].first!.isLetter { break }
                }
            case "Z", "z":
                path.closeSubpath()
                currentX = subpathStartX; currentY = subpathStartY
            default:
                break
            }
        }
        return path
    }

    static func tokenizeSVG(svgPath: String) -> [String] {
        let cmdChars: Set<Character> = ["M","m","L","l","H","h","V","v","C","c","S","s","Q","q","T","t","A","a","Z","z"]
        var tokens: [String] = []
        var current = ""
        for char in svgPath {
            if cmdChars.contains(char) {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(char))
            } else if char == "," || char == " " || char == "\t" || char == "\n" {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}

private extension String {
    var floatValue: Double? {
        return Double(self.replacingOccurrences(of: ",", with: "."))
    }
}
