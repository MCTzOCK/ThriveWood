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

    private var zones: [MuscleZone] {
        showFront ? Self.frontZones : Self.backZones
    }

    var body: some View {
        GeometryReader { geo in
            let b = BodyLayout(in: geo.size)
            ZStack {
                silhouetteFill(b: b)
                silhouetteStroke(b: b)
                silhouetteShadow(b: b)
                zoneOverlays(b: b)
                selectedLabel(b: b)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMuscle)
        }
        .aspectRatio(0.55 / 1.0, contentMode: .fit)
    }

    private func zoneOverlays(b: BodyLayout) -> some View {
        ForEach(zones) { zone in
            let isSel = selectedMuscle == zone.muscle
            zone.path(b: b)
                .fill(zoneColor(for: zone))
                .overlay(
                    zone.path(b: b)
                        .stroke(isSel ? Color.white : Color.black.opacity(0.08),
                                lineWidth: isSel ? 2 : 0.5)
                )
                .scaleEffect(isSel ? 1.04 : 1.0)
                .onTapGesture {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMuscle = selectedMuscle == zone.muscle ? nil : zone.muscle
                    }
                }
        }
    }

    @ViewBuilder
    private func selectedLabel(b: BodyLayout) -> some View {
        if let sel = selectedMuscle {
            let centers = zones.filter { $0.muscle == sel }.map { $0.center(b: b) }
            let labelPos = CGPoint(
                x: centers.map(\.x).reduce(0, +) / CGFloat(centers.count),
                y: centers.map(\.y).reduce(0, +) / CGFloat(centers.count)
            )
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

    private func zoneColor(for zone: MuscleZone) -> Color {
        let r = rank(for: zone.muscle)
        if zone.muscle == selectedMuscle { return r.primaryColor.opacity(0.85) }
        if r == .untrained { return Color(.systemGray5).opacity(0.3) }
        return r.primaryColor.opacity(0.5)
    }

    // MARK: - Silhouette

    private func silhouetteFill(b: BodyLayout) -> some View {
        let torso = torsoPath(b: b)
        let arms = armsPath(b: b)
        let head = headPath(b: b)
        return ZStack {
            torso.fill(Color(.systemGray5).opacity(0.35))
            head.fill(Color(.systemGray5).opacity(0.35))
            arms.fill(Color(.systemGray5).opacity(0.35))
        }
    }

    private func silhouetteStroke(b: BodyLayout) -> some View {
        let torso = torsoPath(b: b)
        let arms = armsPath(b: b)
        let head = headPath(b: b)
        return ZStack {
            torso.stroke(Color(.systemGray3), lineWidth: 1.2)
            head.stroke(Color(.systemGray3), lineWidth: 1.2)
            arms.stroke(Color(.systemGray3), lineWidth: 1.2)
        }
    }

    private func silhouetteShadow(b: BodyLayout) -> some View {
        let torso = torsoPath(b: b)
        let arms = armsPath(b: b)
        return ZStack {
            torso.fill(Color.black.opacity(0.05)).offset(x: 1, y: 2)
            arms.fill(Color.black.opacity(0.05)).offset(x: 1, y: 2)
        }
    }

    // MARK: - Head

    private func headPath(b: BodyLayout) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: b.x(-0.055), y: b.y(0.00), width: b.s * 0.11, height: b.s * 0.095))
        return p
    }

    // MARK: - Torso + Legs Silhouette

    private func torsoPath(b: BodyLayout) -> Path {
        var p = Path()
        p.move(to: b.p(0, 0.095))
        // Left side: neck → shoulder → armpit → waist → hip → outer leg → foot
        p.addCurve(to: b.p(-0.195, 0.155), control1: b.p(-0.08, 0.09), control2: b.p(-0.17, 0.12))
        p.addCurve(to: b.p(-0.195, 0.185), control1: b.p(-0.205, 0.16), control2: b.p(-0.205, 0.175))
        p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.20, 0.20), control2: b.p(-0.155, 0.22))
        p.addCurve(to: b.p(-0.125, 0.275), control1: b.p(-0.12, 0.245), control2: b.p(-0.125, 0.26))
        p.addCurve(to: b.p(-0.095, 0.38), control1: b.p(-0.13, 0.32), control2: b.p(-0.105, 0.36))
        p.addCurve(to: b.p(-0.12, 0.47), control1: b.p(-0.09, 0.41), control2: b.p(-0.12, 0.44))
        p.addCurve(to: b.p(-0.125, 0.58), control1: b.p(-0.125, 0.50), control2: b.p(-0.13, 0.54))
        p.addCurve(to: b.p(-0.105, 0.72), control1: b.p(-0.12, 0.64), control2: b.p(-0.11, 0.69))
        p.addCurve(to: b.p(-0.085, 0.86), control1: b.p(-0.09, 0.77), control2: b.p(-0.085, 0.82))
        p.addCurve(to: b.p(-0.06, 0.96), control1: b.p(-0.08, 0.90), control2: b.p(-0.07, 0.94))
        p.addLine(to: b.p(-0.03, 0.97))
        // Inner left leg up to crotch
        p.addCurve(to: b.p(-0.025, 0.86), control1: b.p(-0.05, 0.94), control2: b.p(-0.04, 0.90))
        p.addCurve(to: b.p(-0.015, 0.72), control1: b.p(-0.02, 0.82), control2: b.p(-0.015, 0.77))
        p.addCurve(to: b.p(0, 0.515), control1: b.p(-0.01, 0.64), control2: b.p(0, 0.58))
        // Crotch center
        p.addCurve(to: b.p(0.015, 0.72), control1: b.p(0, 0.58), control2: b.p(0.01, 0.64))
        p.addCurve(to: b.p(0.025, 0.86), control1: b.p(0.015, 0.77), control2: b.p(0.02, 0.82))
        // Right foot
        p.addCurve(to: b.p(0.06, 0.96), control1: b.p(0.04, 0.90), control2: b.p(0.05, 0.94))
        p.addLine(to: b.p(0.03, 0.97))
        // Right side up
        p.addCurve(to: b.p(0.085, 0.86), control1: b.p(0.07, 0.94), control2: b.p(0.08, 0.90))
        p.addCurve(to: b.p(0.105, 0.72), control1: b.p(0.085, 0.82), control2: b.p(0.09, 0.77))
        p.addCurve(to: b.p(0.125, 0.58), control1: b.p(0.11, 0.64), control2: b.p(0.12, 0.69))
        p.addCurve(to: b.p(0.12, 0.47), control1: b.p(0.13, 0.54), control2: b.p(0.13, 0.50))
        p.addCurve(to: b.p(0.095, 0.38), control1: b.p(0.12, 0.44), control2: b.p(0.105, 0.36))
        p.addCurve(to: b.p(0.125, 0.275), control1: b.p(0.125, 0.26), control2: b.p(0.12, 0.245))
        p.addCurve(to: b.p(0.125, 0.225), control1: b.p(0.125, 0.255), control2: b.p(0.125, 0.24))
        p.addCurve(to: b.p(0.195, 0.185), control1: b.p(0.155, 0.22), control2: b.p(0.20, 0.20))
        p.addCurve(to: b.p(0.195, 0.155), control1: b.p(0.205, 0.175), control2: b.p(0.205, 0.16))
        p.addCurve(to: b.p(0, 0.095), control1: b.p(0.17, 0.12), control2: b.p(0.08, 0.09))
        p.closeSubpath()
        return p
    }

    // MARK: - Arms Silhouette

    private func armsPath(b: BodyLayout) -> Path {
        var p = Path()
        // Left arm: top → outer → hand → inner → armpit
        p.move(to: b.p(-0.195, 0.185))
        p.addCurve(to: b.p(-0.215, 0.27), control1: b.p(-0.20, 0.21), control2: b.p(-0.21, 0.24))
        p.addCurve(to: b.p(-0.20, 0.35), control1: b.p(-0.22, 0.30), control2: b.p(-0.21, 0.33))
        p.addCurve(to: b.p(-0.23, 0.44), control1: b.p(-0.20, 0.38), control2: b.p(-0.22, 0.41))
        p.addCurve(to: b.p(-0.22, 0.52), control1: b.p(-0.24, 0.48), control2: b.p(-0.23, 0.51))
        p.addCurve(to: b.p(-0.20, 0.53), control1: b.p(-0.21, 0.53), control2: b.p(-0.205, 0.53))
        p.addCurve(to: b.p(-0.17, 0.44), control1: b.p(-0.19, 0.52), control2: b.p(-0.17, 0.48))
        p.addCurve(to: b.p(-0.155, 0.35), control1: b.p(-0.17, 0.39), control2: b.p(-0.16, 0.37))
        p.addCurve(to: b.p(-0.155, 0.27), control1: b.p(-0.155, 0.31), control2: b.p(-0.155, 0.29))
        p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.155, 0.25), control2: b.p(-0.145, 0.235))
        p.closeSubpath()

        // Right arm: mirror of left
        p.move(to: b.p(0.195, 0.185))
        p.addCurve(to: b.p(0.125, 0.225), control1: b.p(0.145, 0.235), control2: b.p(0.155, 0.25))
        p.addCurve(to: b.p(0.155, 0.27), control1: b.p(0.155, 0.29), control2: b.p(0.155, 0.31))
        p.addCurve(to: b.p(0.155, 0.35), control1: b.p(0.16, 0.37), control2: b.p(0.17, 0.39))
        p.addCurve(to: b.p(0.17, 0.44), control1: b.p(0.17, 0.48), control2: b.p(0.19, 0.52))
        p.addCurve(to: b.p(0.20, 0.53), control1: b.p(0.205, 0.53), control2: b.p(0.21, 0.53))
        p.addCurve(to: b.p(0.22, 0.52), control1: b.p(0.23, 0.51), control2: b.p(0.24, 0.48))
        p.addCurve(to: b.p(0.23, 0.44), control1: b.p(0.22, 0.41), control2: b.p(0.20, 0.38))
        p.addCurve(to: b.p(0.20, 0.35), control1: b.p(0.21, 0.33), control2: b.p(0.22, 0.30))
        p.addCurve(to: b.p(0.215, 0.27), control1: b.p(0.21, 0.24), control2: b.p(0.20, 0.21))
        p.addCurve(to: b.p(0.195, 0.185), control1: b.p(0.21, 0.19), control2: b.p(0.205, 0.18))
        p.closeSubpath()
        return p
    }

    // MARK: - Zone Model

    private enum Side: String { case left, right, center }

    private struct MuscleZone: Identifiable {
        let muscle: MuscleGroup
        let side: Side
        let isFront: Bool
        let buildPath: (BodyLayout) -> Path
        let centerPoint: (CGFloat, CGFloat)

        var id: String { "\(muscle.rawValue)-\(side.rawValue)-\(isFront ? "F" : "B")" }

        func path(b: BodyLayout) -> Path { buildPath(b) }
        func center(b: BodyLayout) -> CGPoint { b.p(centerPoint.0, centerPoint.1) }
    }

    // MARK: - Shared Body Outline Points (for zones to reference)
    // These MUST match the torsoPath/armsPath curves exactly.

    private static func shoulder(_ x: CGFloat, b: BodyLayout) -> CGPoint { b.p(x, x < 0 ? 0.185 : 0.185) }
    private static func armpit(_ x: CGFloat, b: BodyLayout) -> CGPoint { b.p(x, x < 0 ? 0.225 : 0.225) }

    // MARK: - Front Zones (symmetric left/right)

    private static let frontZones: [MuscleZone] = [
        // TRAPS (center)
        .init(muscle: .traps, side: .center, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0, 0.095))
            p.addCurve(to: b.p(-0.12, 0.155), control1: b.p(-0.07, 0.095), control2: b.p(-0.10, 0.13))
            p.addLine(to: b.p(-0.09, 0.20))
            p.addLine(to: b.p(0, 0.18))
            p.addLine(to: b.p(0.09, 0.20))
            p.addLine(to: b.p(0.12, 0.155))
            p.addCurve(to: b.p(0, 0.095), control1: b.p(0.10, 0.13), control2: b.p(0.07, 0.095))
            return p
        }, centerPoint: (0, 0.16)),

        // LEFT SHOULDER
        .init(muscle: .shoulders, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.12, 0.155))
            p.addCurve(to: b.p(-0.195, 0.155), control1: b.p(-0.15, 0.145), control2: b.p(-0.18, 0.15))
            p.addCurve(to: b.p(-0.195, 0.185), control1: b.p(-0.205, 0.16), control2: b.p(-0.205, 0.175))
            p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.20, 0.20), control2: b.p(-0.155, 0.22))
            p.addLine(to: b.p(-0.09, 0.20))
            return p
        }, centerPoint: (-0.16, 0.19)),

        // RIGHT SHOULDER
        .init(muscle: .shoulders, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.12, 0.155))
            p.addLine(to: b.p(0.09, 0.20))
            p.addLine(to: b.p(0.125, 0.225))
            p.addCurve(to: b.p(0.195, 0.185), control1: b.p(0.155, 0.22), control2: b.p(0.20, 0.20))
            p.addCurve(to: b.p(0.195, 0.155), control1: b.p(0.205, 0.175), control2: b.p(0.205, 0.16))
            p.addCurve(to: b.p(0.12, 0.155), control1: b.p(0.18, 0.15), control2: b.p(0.15, 0.145))
            return p
        }, centerPoint: (0.16, 0.19)),

        // Chest
        .init(muscle: .chest, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.09, 0.20))
            p.addLine(to: b.p(-0.125, 0.225))
            p.addCurve(to: b.p(-0.125, 0.275), control1: b.p(-0.12, 0.24), control2: b.p(-0.125, 0.26))
            p.addCurve(to: b.p(-0.095, 0.38), control1: b.p(-0.13, 0.33), control2: b.p(-0.10, 0.37))
            p.addLine(to: b.p(-0.04, 0.38))
            p.addLine(to: b.p(0, 0.285))
            p.addLine(to: b.p(0, 0.18))
            return p
        }, centerPoint: (-0.07, 0.28)),

        .init(muscle: .chest, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.09, 0.20))
            p.addLine(to: b.p(0, 0.18))
            p.addLine(to: b.p(0, 0.285))
            p.addLine(to: b.p(0.04, 0.38))
            p.addCurve(to: b.p(0.095, 0.38), control1: b.p(0.10, 0.37), control2: b.p(0.13, 0.33))
            p.addCurve(to: b.p(0.125, 0.275), control1: b.p(0.125, 0.26), control2: b.p(0.12, 0.24))
            p.addLine(to: b.p(0.125, 0.225))
            return p
        }, centerPoint: (0.07, 0.28)),

        // Core
        .init(muscle: .core, side: .center, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.04, 0.285))
            p.addLine(to: b.p(0.04, 0.285))
            p.addCurve(to: b.p(0.055, 0.38), control1: b.p(0.045, 0.33), control2: b.p(0.05, 0.36))
            p.addLine(to: b.p(0.04, 0.38))
            p.addLine(to: b.p(-0.04, 0.38))
            p.addLine(to: b.p(-0.055, 0.38))
            p.addCurve(to: b.p(-0.04, 0.285), control1: b.p(-0.05, 0.36), control2: b.p(-0.045, 0.33))
            return p
        }, centerPoint: (0, 0.335)),

        // Obliques
        .init(muscle: .obliques, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.125, 0.275))
            p.addCurve(to: b.p(-0.095, 0.38), control1: b.p(-0.13, 0.32), control2: b.p(-0.10, 0.37))
            p.addLine(to: b.p(-0.055, 0.38))
            p.addCurve(to: b.p(-0.095, 0.38), control1: b.p(-0.07, 0.38), control2: b.p(-0.085, 0.385))
            p.addCurve(to: b.p(-0.125, 0.275), control1: b.p(-0.115, 0.41), control2: b.p(-0.13, 0.30))
            return p
        }, centerPoint: (-0.10, 0.33)),

        .init(muscle: .obliques, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.125, 0.275))
            p.addCurve(to: b.p(0.095, 0.38), control1: b.p(0.13, 0.30), control2: b.p(0.115, 0.41))
            p.addCurve(to: b.p(0.095, 0.38), control1: b.p(0.085, 0.385), control2: b.p(0.07, 0.38))
            p.addLine(to: b.p(0.055, 0.38))
            p.addCurve(to: b.p(0.125, 0.275), control1: b.p(0.10, 0.37), control2: b.p(0.13, 0.32))
            return p
        }, centerPoint: (0.10, 0.33)),

        // Biceps
        .init(muscle: .biceps, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.125, 0.225))
            p.addCurve(to: b.p(-0.155, 0.27), control1: b.p(-0.14, 0.24), control2: b.p(-0.16, 0.26))
            p.addCurve(to: b.p(-0.195, 0.275), control1: b.p(-0.18, 0.265), control2: b.p(-0.20, 0.27))
            p.addCurve(to: b.p(-0.195, 0.22), control1: b.p(-0.20, 0.26), control2: b.p(-0.20, 0.20))
            p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.18, 0.20), control2: b.p(-0.15, 0.22))
            return p
        }, centerPoint: (-0.17, 0.25)),

        .init(muscle: .biceps, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.125, 0.225))
            p.addCurve(to: b.p(0.195, 0.22), control1: b.p(0.15, 0.22), control2: b.p(0.18, 0.20))
            p.addCurve(to: b.p(0.195, 0.275), control1: b.p(0.20, 0.20), control2: b.p(0.20, 0.26))
            p.addCurve(to: b.p(0.155, 0.27), control1: b.p(0.20, 0.27), control2: b.p(0.18, 0.265))
            p.addCurve(to: b.p(0.125, 0.225), control1: b.p(0.16, 0.26), control2: b.p(0.14, 0.24))
            return p
        }, centerPoint: (0.17, 0.25)),

        // Forearms
        .init(muscle: .forearms, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.155, 0.35))
            p.addCurve(to: b.p(-0.20, 0.35), control1: b.p(-0.175, 0.34), control2: b.p(-0.19, 0.345))
            p.addCurve(to: b.p(-0.23, 0.44), control1: b.p(-0.22, 0.375), control2: b.p(-0.23, 0.41))
            p.addCurve(to: b.p(-0.22, 0.52), control1: b.p(-0.24, 0.48), control2: b.p(-0.23, 0.51))
            p.addCurve(to: b.p(-0.17, 0.44), control1: b.p(-0.20, 0.52), control2: b.p(-0.17, 0.48))
            p.addCurve(to: b.p(-0.155, 0.35), control1: b.p(-0.17, 0.39), control2: b.p(-0.155, 0.37))
            return p
        }, centerPoint: (-0.20, 0.43)),

        .init(muscle: .forearms, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.155, 0.35))
            p.addCurve(to: b.p(0.17, 0.44), control1: b.p(0.155, 0.37), control2: b.p(0.17, 0.39))
            p.addCurve(to: b.p(0.22, 0.52), control1: b.p(0.17, 0.48), control2: b.p(0.20, 0.52))
            p.addCurve(to: b.p(0.23, 0.44), control1: b.p(0.23, 0.51), control2: b.p(0.24, 0.48))
            p.addCurve(to: b.p(0.20, 0.35), control1: b.p(0.23, 0.41), control2: b.p(0.22, 0.375))
            p.addCurve(to: b.p(0.155, 0.35), control1: b.p(0.19, 0.345), control2: b.p(0.175, 0.34))
            return p
        }, centerPoint: (0.20, 0.43)),

        // Hip Flexors
        .init(muscle: .hipFlexors, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.055, 0.38))
            p.addCurve(to: b.p(-0.12, 0.47), control1: b.p(-0.08, 0.39), control2: b.p(-0.11, 0.43))
            p.addCurve(to: b.p(-0.10, 0.51), control1: b.p(-0.125, 0.50), control2: b.p(-0.11, 0.51))
            p.addLine(to: b.p(-0.02, 0.52))
            p.addLine(to: b.p(-0.04, 0.38))
            return p
        }, centerPoint: (-0.07, 0.44)),

        .init(muscle: .hipFlexors, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.055, 0.38))
            p.addLine(to: b.p(0.04, 0.38))
            p.addLine(to: b.p(0.02, 0.52))
            p.addLine(to: b.p(0.10, 0.51))
            p.addCurve(to: b.p(0.12, 0.47), control1: b.p(0.11, 0.51), control2: b.p(0.125, 0.50))
            p.addCurve(to: b.p(0.055, 0.38), control1: b.p(0.11, 0.43), control2: b.p(0.08, 0.39))
            return p
        }, centerPoint: (0.07, 0.44)),

        // Quads
        .init(muscle: .quads, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.095, 0.51))
            p.addCurve(to: b.p(-0.02, 0.52), control1: b.p(-0.06, 0.51), control2: b.p(-0.03, 0.515))
            p.addCurve(to: b.p(-0.015, 0.65), control1: b.p(-0.01, 0.57), control2: b.p(-0.01, 0.61))
            p.addCurve(to: b.p(-0.105, 0.72), control1: b.p(-0.03, 0.70), control2: b.p(-0.09, 0.72))
            p.addCurve(to: b.p(-0.125, 0.58), control1: b.p(-0.13, 0.68), control2: b.p(-0.13, 0.55))
            p.addCurve(to: b.p(-0.095, 0.51), control1: b.p(-0.12, 0.51), control2: b.p(-0.10, 0.51))
            return p
        }, centerPoint: (-0.08, 0.60)),

        .init(muscle: .quads, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.095, 0.51))
            p.addCurve(to: b.p(0.10, 0.51), control1: b.p(0.10, 0.51), control2: b.p(0.12, 0.51))
            p.addCurve(to: b.p(0.125, 0.58), control1: b.p(0.13, 0.55), control2: b.p(0.13, 0.68))
            p.addCurve(to: b.p(0.105, 0.72), control1: b.p(0.09, 0.72), control2: b.p(0.03, 0.70))
            p.addCurve(to: b.p(0.015, 0.65), control1: b.p(0.01, 0.61), control2: b.p(0.01, 0.57))
            p.addCurve(to: b.p(0.02, 0.52), control1: b.p(0.02, 0.515), control2: b.p(0.03, 0.515))
            p.addLine(to: b.p(0.095, 0.51))
            return p
        }, centerPoint: (0.08, 0.60)),

        // Adductors (wider!)
        .init(muscle: .adductors, side: .left, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.02, 0.52))
            p.addCurve(to: b.p(-0.015, 0.65), control1: b.p(-0.01, 0.57), control2: b.p(-0.01, 0.61))
            p.addCurve(to: b.p(-0.025, 0.73), control1: b.p(-0.015, 0.69), control2: b.p(-0.02, 0.72))
            p.addLine(to: b.p(0, 0.515))
            return p
        }, centerPoint: (-0.01, 0.62)),

        .init(muscle: .adductors, side: .right, isFront: true, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.02, 0.52))
            p.addLine(to: b.p(0, 0.515))
            p.addLine(to: b.p(0.025, 0.73))
            p.addCurve(to: b.p(0.015, 0.65), control1: b.p(0.02, 0.72), control2: b.p(0.01, 0.69))
            p.addCurve(to: b.p(0.02, 0.52), control1: b.p(0.01, 0.61), control2: b.p(0.01, 0.57))
            return p
        }, centerPoint: (0.01, 0.62)),
    ]

    // MARK: - Back Zones

    private static let backZones: [MuscleZone] = [
        // TRAPS
        .init(muscle: .traps, side: .center, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0, 0.095))
            p.addCurve(to: b.p(-0.12, 0.155), control1: b.p(-0.07, 0.095), control2: b.p(-0.10, 0.13))
            p.addLine(to: b.p(-0.10, 0.225))
            p.addLine(to: b.p(0, 0.20))
            p.addLine(to: b.p(0.10, 0.225))
            p.addLine(to: b.p(0.12, 0.155))
            p.addCurve(to: b.p(0, 0.095), control1: b.p(0.10, 0.13), control2: b.p(0.07, 0.095))
            return p
        }, centerPoint: (0, 0.17)),

        // Rear Delts
        .init(muscle: .rearDelts, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.12, 0.155))
            p.addCurve(to: b.p(-0.195, 0.155), control1: b.p(-0.15, 0.145), control2: b.p(-0.18, 0.15))
            p.addCurve(to: b.p(-0.195, 0.185), control1: b.p(-0.205, 0.16), control2: b.p(-0.205, 0.175))
            p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.20, 0.20), control2: b.p(-0.155, 0.22))
            p.addLine(to: b.p(-0.10, 0.225))
            return p
        }, centerPoint: (-0.16, 0.19)),

        .init(muscle: .rearDelts, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.12, 0.155))
            p.addLine(to: b.p(0.10, 0.225))
            p.addLine(to: b.p(0.125, 0.225))
            p.addCurve(to: b.p(0.195, 0.185), control1: b.p(0.155, 0.22), control2: b.p(0.20, 0.20))
            p.addCurve(to: b.p(0.195, 0.155), control1: b.p(0.205, 0.175), control2: b.p(0.205, 0.16))
            p.addCurve(to: b.p(0.12, 0.155), control1: b.p(0.18, 0.15), control2: b.p(0.15, 0.145))
            return p
        }, centerPoint: (0.16, 0.19)),

        // Upper Back
        .init(muscle: .upperBack, side: .center, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.10, 0.225))
            p.addLine(to: b.p(0, 0.20))
            p.addLine(to: b.p(0.10, 0.225))
            p.addCurve(to: b.p(-0.10, 0.225), control1: b.p(0.06, 0.31), control2: b.p(-0.06, 0.31))
            return p
        }, centerPoint: (0, 0.27)),

        // Lats
        .init(muscle: .lats, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.10, 0.225))
            p.addLine(to: b.p(-0.125, 0.225))
            p.addCurve(to: b.p(-0.11, 0.37), control1: b.p(-0.14, 0.27), control2: b.p(-0.12, 0.34))
            p.addLine(to: b.p(-0.06, 0.31))
            p.addLine(to: b.p(-0.06, 0.25))
            p.addLine(to: b.p(-0.10, 0.225))
            return p
        }, centerPoint: (-0.09, 0.29)),

        .init(muscle: .lats, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.10, 0.225))
            p.addLine(to: b.p(0.06, 0.25))
            p.addLine(to: b.p(0.06, 0.31))
            p.addLine(to: b.p(0.11, 0.37))
            p.addCurve(to: b.p(0.125, 0.225), control1: b.p(0.12, 0.34), control2: b.p(0.14, 0.27))
            p.addLine(to: b.p(0.10, 0.225))
            return p
        }, centerPoint: (0.09, 0.29)),

        // Lower Back
        .init(muscle: .lowerBack, side: .center, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.11, 0.37))
            p.addCurve(to: b.p(-0.12, 0.47), control1: b.p(-0.12, 0.41), control2: b.p(-0.125, 0.45))
            p.addCurve(to: b.p(0, 0.47), control1: b.p(-0.10, 0.48), control2: b.p(-0.04, 0.47))
            p.addCurve(to: b.p(0.12, 0.47), control1: b.p(0.04, 0.47), control2: b.p(0.10, 0.48))
            p.addCurve(to: b.p(0.11, 0.37), control1: b.p(0.125, 0.45), control2: b.p(0.12, 0.41))
            p.closeSubpath()
            return p
        }, centerPoint: (0, 0.42)),

        // Triceps
        .init(muscle: .triceps, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.125, 0.225))
            p.addCurve(to: b.p(-0.155, 0.27), control1: b.p(-0.14, 0.24), control2: b.p(-0.16, 0.26))
            p.addCurve(to: b.p(-0.195, 0.275), control1: b.p(-0.18, 0.265), control2: b.p(-0.20, 0.27))
            p.addCurve(to: b.p(-0.195, 0.22), control1: b.p(-0.20, 0.26), control2: b.p(-0.20, 0.20))
            p.addCurve(to: b.p(-0.125, 0.225), control1: b.p(-0.18, 0.20), control2: b.p(-0.15, 0.22))
            return p
        }, centerPoint: (-0.17, 0.25)),

        .init(muscle: .triceps, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.125, 0.225))
            p.addCurve(to: b.p(0.195, 0.22), control1: b.p(0.15, 0.22), control2: b.p(0.18, 0.20))
            p.addCurve(to: b.p(0.195, 0.275), control1: b.p(0.20, 0.20), control2: b.p(0.20, 0.26))
            p.addCurve(to: b.p(0.155, 0.27), control1: b.p(0.20, 0.27), control2: b.p(0.18, 0.265))
            p.addCurve(to: b.p(0.125, 0.225), control1: b.p(0.16, 0.26), control2: b.p(0.14, 0.24))
            return p
        }, centerPoint: (0.17, 0.25)),

        // Glutes (symmetric, touching at center)
        .init(muscle: .glutes, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0, 0.47))
            p.addCurve(to: b.p(-0.12, 0.47), control1: b.p(-0.05, 0.46), control2: b.p(-0.09, 0.465))
            p.addCurve(to: b.p(-0.12, 0.53), control1: b.p(-0.14, 0.50), control2: b.p(-0.13, 0.525))
            p.addCurve(to: b.p(0, 0.54), control1: b.p(-0.09, 0.55), control2: b.p(-0.04, 0.55))
            return p
        }, centerPoint: (-0.06, 0.50)),

        .init(muscle: .glutes, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0, 0.47))
            p.addCurve(to: b.p(0, 0.54), control1: b.p(0.04, 0.55), control2: b.p(0.09, 0.55))
            p.addCurve(to: b.p(0.12, 0.53), control1: b.p(0.13, 0.525), control2: b.p(0.14, 0.50))
            p.addCurve(to: b.p(0.12, 0.47), control1: b.p(0.09, 0.465), control2: b.p(0.05, 0.46))
            return p
        }, centerPoint: (0.06, 0.50)),

        // Abductors (inside body silhouette)
        .init(muscle: .abductors, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.12, 0.53))
            p.addCurve(to: b.p(-0.125, 0.60), control1: b.p(-0.13, 0.555), control2: b.p(-0.13, 0.58))
            p.addCurve(to: b.p(-0.105, 0.72), control1: b.p(-0.13, 0.65), control2: b.p(-0.11, 0.70))
            p.addCurve(to: b.p(-0.09, 0.63), control1: b.p(-0.10, 0.71), control2: b.p(-0.09, 0.67))
            p.addCurve(to: b.p(-0.09, 0.54), control1: b.p(-0.09, 0.59), control2: b.p(-0.09, 0.56))
            return p
        }, centerPoint: (-0.11, 0.62)),

        .init(muscle: .abductors, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.12, 0.53))
            p.addCurve(to: b.p(0.09, 0.54), control1: b.p(0.09, 0.56), control2: b.p(0.09, 0.59))
            p.addCurve(to: b.p(0.09, 0.63), control1: b.p(0.09, 0.67), control2: b.p(0.10, 0.71))
            p.addCurve(to: b.p(0.125, 0.60), control1: b.p(0.11, 0.70), control2: b.p(0.13, 0.65))
            p.addCurve(to: b.p(0.12, 0.53), control1: b.p(0.13, 0.58), control2: b.p(0.13, 0.555))
            return p
        }, centerPoint: (0.11, 0.62)),

        // Hamstrings (inside body silhouette)
        .init(muscle: .hamstrings, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.025, 0.54))
            p.addCurve(to: b.p(-0.09, 0.54), control1: b.p(-0.05, 0.53), control2: b.p(-0.07, 0.53))
            p.addCurve(to: b.p(-0.09, 0.63), control1: b.p(-0.10, 0.57), control2: b.p(-0.10, 0.60))
            p.addCurve(to: b.p(-0.10, 0.73), control1: b.p(-0.10, 0.67), control2: b.p(-0.11, 0.71))
            p.addCurve(to: b.p(-0.08, 0.73), control1: b.p(-0.11, 0.73), control2: b.p(-0.09, 0.73))
            p.addCurve(to: b.p(-0.025, 0.65), control1: b.p(-0.06, 0.73), control2: b.p(-0.025, 0.68))
            p.addCurve(to: b.p(-0.025, 0.54), control1: b.p(-0.025, 0.60), control2: b.p(-0.025, 0.57))
            return p
        }, centerPoint: (-0.06, 0.63)),

        .init(muscle: .hamstrings, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.025, 0.54))
            p.addCurve(to: b.p(0.025, 0.65), control1: b.p(0.025, 0.57), control2: b.p(0.025, 0.60))
            p.addCurve(to: b.p(0.08, 0.73), control1: b.p(0.025, 0.68), control2: b.p(0.06, 0.73))
            p.addCurve(to: b.p(0.10, 0.73), control1: b.p(0.09, 0.73), control2: b.p(0.11, 0.73))
            p.addCurve(to: b.p(0.09, 0.63), control1: b.p(0.11, 0.71), control2: b.p(0.10, 0.67))
            p.addCurve(to: b.p(0.09, 0.54), control1: b.p(0.10, 0.60), control2: b.p(0.10, 0.57))
            p.addCurve(to: b.p(0.025, 0.54), control1: b.p(0.07, 0.53), control2: b.p(0.05, 0.53))
            return p
        }, centerPoint: (0.06, 0.63)),

        // Calves (inside body silhouette)
        .init(muscle: .calves, side: .left, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(-0.085, 0.73))
            p.addCurve(to: b.p(-0.11, 0.73), control1: b.p(-0.09, 0.73), control2: b.p(-0.10, 0.73))
            p.addCurve(to: b.p(-0.115, 0.85), control1: b.p(-0.115, 0.77), control2: b.p(-0.115, 0.82))
            p.addCurve(to: b.p(-0.09, 0.86), control1: b.p(-0.115, 0.84), control2: b.p(-0.10, 0.86))
            p.addCurve(to: b.p(-0.075, 0.73), control1: b.p(-0.08, 0.86), control2: b.p(-0.075, 0.80))
            return p
        }, centerPoint: (-0.09, 0.79)),

        .init(muscle: .calves, side: .right, isFront: false, buildPath: { b in
            var p = Path()
            p.move(to: b.p(0.075, 0.73))
            p.addCurve(to: b.p(0.08, 0.86), control1: b.p(0.075, 0.80), control2: b.p(0.08, 0.86))
            p.addCurve(to: b.p(0.115, 0.85), control1: b.p(0.10, 0.86), control2: b.p(0.115, 0.84))
            p.addCurve(to: b.p(0.11, 0.73), control1: b.p(0.115, 0.82), control2: b.p(0.115, 0.77))
            p.addCurve(to: b.p(0.075, 0.73), control1: b.p(0.10, 0.73), control2: b.p(0.09, 0.73))
            return p
        }, centerPoint: (0.09, 0.79)),
    ]

    }

// MARK: - Body Layout Helper

private struct BodyLayout {
    let s: CGFloat
    let cx: CGFloat
    let ty: CGFloat

    init(in size: CGSize) {
        let bodyXRange: CGFloat = 0.55
        let bodyYRange: CGFloat = 0.97
        let scaleX = size.width * 0.90 / bodyXRange
        let scaleY = size.height * 0.90 / bodyYRange
        self.s = min(scaleX, scaleY)
        self.cx = size.width / 2
        self.ty = (size.height - bodyYRange * s) / 2
    }

    func p(_ nx: CGFloat, _ ny: CGFloat) -> CGPoint {
        CGPoint(x: cx + nx * s, y: ty + ny * s)
    }

    func x(_ nx: CGFloat) -> CGFloat { cx + nx * s }
    func y(_ ny: CGFloat) -> CGFloat { ty + ny * s }
}