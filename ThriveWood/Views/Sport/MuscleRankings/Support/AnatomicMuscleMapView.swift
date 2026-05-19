//
//  AnatomicMuscleMapView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 19.05.26.
//

import SwiftUI

struct AnatomicMuscleMapView: View {
    let rankings: [MuscleRankingData]
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var showFront: Bool

    private func rank(for muscle: MuscleGroup) -> MuscleRank {
        rankings.first(where: { $0.muscleGroup == muscle })?.rank ?? .untrained
    }

    var body: some View {
        GeometryReader { geo in
            let helpers = AnatomicMuscleHelpers()
            let defs = showFront ? helpers.FRONT_MUSCLES : helpers.BACK_MUSCLES
            let scaleX = geo.size.width / 35.0
            let scaleY = geo.size.height / 93.0
            let scale = min(scaleX, scaleY)
            let offsetX = (geo.size.width - 35.0 * scale) / 2.0
            let offsetY = (geo.size.height - 93.0 * scale) / 2.0

            ZStack {
                ForEach(groupedZones(from: defs), id: \.muscle.rawValue) { group in
                    group.path(scale: scale, offsetX: offsetX, offsetY: offsetY)
                        .fill(zoneColor(for: group.muscle))
                        .overlay(
                            group.path(scale: scale, offsetX: offsetX, offsetY: offsetY)
                                .stroke(selectedMuscle == group.muscle ? Color.white : Color.black.opacity(0.12),
                                        lineWidth: selectedMuscle == group.muscle ? 2.5 : 0.5)
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
                    let groups = groupedZones(from: defs)
                    let matching = groups.filter { $0.muscle == sel }
                    if !matching.isEmpty {
                        let cx = matching.flatMap(\.centers).reduce(0, +) / CGFloat(matching.flatMap(\.centers).count)
                        let cy = matching.flatMap(\.centersY).reduce(0, +) / CGFloat(matching.flatMap(\.centersY).count)
                        let labelPos = CGPoint(x: offsetX + cx * scale, y: offsetY + cy * scale)
                        VStack(spacing: 1) {
                            Image(systemName: rank(for: sel).icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(sel.shortLabel)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.7), radius: 2)
                        .position(labelPos)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMuscle)
        }
        .aspectRatio(35.0 / 93.0, contentMode: .fit)
    }

    private func zoneColor(for muscle: MuscleGroup) -> Color {
        let r = rank(for: muscle)
        if muscle == selectedMuscle { return r.primaryColor.opacity(0.85) }
        if r == .untrained { return Color(.systemGray5).opacity(0.3) }
        return r.primaryColor.opacity(0.5)
    }

    // MARK: - Grouping SVG paths by MuscleGroup

    private struct MuscleGroupZone {
        let muscle: MuscleGroup
        let svgPaths: [String]
        let centers: [CGFloat]
        let centersY: [CGFloat]

        func path(scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> Path {
            var result = Path()
            for svgPath in svgPaths {
                let parsed = AnatomicMuscleMapView.parseSVGPath(svgPath: svgPath, scale: scale, offsetX: offsetX, offsetY: offsetY)
                result.addPath(parsed)
            }
            return result
        }
    }

    private func groupedZones(from defs: [AMH_MuscleDef]) -> [MuscleGroupZone] {
        var map: [MuscleGroup: [(String, CGFloat, CGFloat)]] = [:]
        for d in defs {
            guard let group = svgIdToMuscleGroup(d.id) else { continue }
            let center = Self.approximateCenter(of: d.path)
            if map[group] == nil { map[group] = [] }
            map[group]!.append((d.path, center.0, center.1))
        }
        return map.map { muscle, entries in
            MuscleGroupZone(
                muscle: muscle,
                svgPaths: entries.map(\.0),
                centers: entries.map(\.1),
                centersY: entries.map(\.2)
            )
        }.sorted { $0.centers.first ?? 0 < $1.centers.first ?? 0 }
    }

    // MARK: - SVG ID → MuscleGroup mapping

    private func svgIdToMuscleGroup(_ id: String) -> MuscleGroup? {
        switch id {
        // Front
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
        // Back
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

    private static func parseSVGPath(svgPath: String, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> Path {
        let tokens = tokenizeSVG(svgPath: svgPath)
        var path = Path()
        var currentX: CGFloat = 0, currentY: CGFloat = 0
        var subpathStartX: CGFloat = 0, subpathStartY: CGFloat = 0
        var i = 0

        func tx(_ x: CGFloat) -> CGFloat { offsetX + x * scale }
        func ty(_ y: CGFloat) -> CGFloat { offsetY + y * scale }

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

    private static func tokenizeSVG(svgPath: String) -> [String] {
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

    private static func approximateCenter(of path: String) -> (CGFloat, CGFloat) {
        let tokens = tokenizeSVG(svgPath: path)
        var sumX: CGFloat = 0, sumY: CGFloat = 0, count: CGFloat = 0
        var i = 0
        while i < tokens.count {
            guard let first = tokens[i].first, first.isLetter else { i += 1; continue }
            i += 1
            switch first {
            case "M", "m", "L", "l":
                let rel = first == "m" || first == "l"
                if i + 1 < tokens.count {
                    sumX += CGFloat(tokens[i].floatValue ?? 0) + (rel && count > 0 ? 0 : 0)
                    sumY += CGFloat(tokens[i+1].floatValue ?? 0)
                    count += 1
                    i += 2
                }
                while i < tokens.count && (tokens[i].first?.isLetter ?? true) == false {
                    if i + 1 < tokens.count && (tokens[i].first?.isLetter ?? true) == false {
                        sumX += CGFloat(tokens[i].floatValue ?? 0)
                        sumY += CGFloat(tokens[i+1].floatValue ?? 0)
                        count += 1
                        i += 2
                    } else { i += 1 }
                }
            case "H", "h":
                if i < tokens.count && (tokens[i].first?.isLetter ?? true) == false {
                    sumX += CGFloat(tokens[i].floatValue ?? 0)
                    count += 1
                    i += 1
                }
                while i < tokens.count && (tokens[i].first?.isLetter ?? true) == false { i += 1 }
            case "V", "v":
                if i < tokens.count && (tokens[i].first?.isLetter ?? true) == false {
                    sumY += CGFloat(tokens[i].floatValue ?? 0)
                    count += 1
                    i += 1
                }
                while i < tokens.count && (tokens[i].first?.isLetter ?? true) == false { i += 1 }
            case "C", "c":
                i += 6
                while i < tokens.count && (tokens[i].first?.isLetter ?? true) == false { i += 6 }
            case "Q", "q":
                i += 4
                while i < tokens.count && (tokens[i].first?.isLetter ?? true) == false { i += 4 }
            default:
                break
            }
        }
        return count > 0 ? (sumX / count, sumY / count) : (0, 0)
    }
}

private extension String {
    var floatValue: Double? {
        return Double(self.replacingOccurrences(of: ",", with: "."))
    }
}