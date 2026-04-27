//
//  CanopyShapes.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct TriangleCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX

        // 3 überlagerte Tannenstufen: jede tiefer und breiter als die vorherige
        let tiers: [(yTop: CGFloat, yBottom: CGFloat, widthFactor: CGFloat)] = [
            (0.00, 0.48, 0.55),
            (0.28, 0.76, 0.78),
            (0.54, 1.00, 1.00)
        ]

        for tier in tiers {
            let yTop = rect.minY + h * tier.yTop
            let yBottom = rect.minY + h * tier.yBottom
            let halfW = w * 0.5 * tier.widthFactor

            p.move(to: CGPoint(x: cx, y: yTop))
            // rechte Flanke – leicht nach außen geschwungen
            p.addQuadCurve(
                to: CGPoint(x: cx + halfW, y: yBottom),
                control: CGPoint(x: cx + halfW * 0.35,
                                 y: yTop + (yBottom - yTop) * 0.72)
            )
            // weiche Unterseite
            p.addQuadCurve(
                to: CGPoint(x: cx - halfW, y: yBottom),
                control: CGPoint(x: cx, y: yBottom + h * 0.025)
            )
            // linke Flanke – Spiegel
            p.addQuadCurve(
                to: CGPoint(x: cx, y: yTop),
                control: CGPoint(x: cx - halfW * 0.35,
                                 y: yTop + (yBottom - yTop) * 0.72)
            )
            p.closeSubpath()
        }
        return p
    }
}

struct TeardropCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let topY = rect.minY + h * 0.02
        let bottomY = rect.maxY

        p.move(to: CGPoint(x: cx, y: topY))

        // rechte Hälfte: weiter Bauch, abgerundete Spitze unten
        p.addCurve(
            to: CGPoint(x: cx, y: bottomY),
            control1: CGPoint(x: cx + w * 0.62, y: topY + h * 0.18),
            control2: CGPoint(x: cx + w * 0.42, y: bottomY + h * 0.02)
        )
        // linke Hälfte: gespiegelt
        p.addCurve(
            to: CGPoint(x: cx, y: topY),
            control1: CGPoint(x: cx - w * 0.42, y: bottomY + h * 0.02),
            control2: CGPoint(x: cx - w * 0.62, y: topY + h * 0.18)
        )
        p.closeSubpath()
        return p
    }
}

struct CloudCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let minX = rect.minX
        let minY = rect.minY
        let maxY = rect.maxY

        // Startpunkt unten links
        p.move(to: CGPoint(x: minX + w * 0.08, y: maxY))

        // Linke Seite hoch mit kleinem Schwung nach außen
        p.addCurve(
            to: CGPoint(x: minX + w * 0.04, y: minY + h * 0.45),
            control1: CGPoint(x: minX - w * 0.06, y: maxY - h * 0.15),
            control2: CGPoint(x: minX - w * 0.04, y: minY + h * 0.62)
        )
        // Linke obere Lobe
        p.addCurve(
            to: CGPoint(x: minX + w * 0.32, y: minY + h * 0.18),
            control1: CGPoint(x: minX - w * 0.02, y: minY + h * 0.10),
            control2: CGPoint(x: minX + w * 0.10, y: minY - h * 0.05)
        )
        // Mittlere Lobe (höchster Punkt)
        p.addCurve(
            to: CGPoint(x: minX + w * 0.66, y: minY + h * 0.16),
            control1: CGPoint(x: minX + w * 0.42, y: minY - h * 0.10),
            control2: CGPoint(x: minX + w * 0.55, y: minY - h * 0.10)
        )
        // Rechte obere Lobe
        p.addCurve(
            to: CGPoint(x: minX + w * 0.96, y: minY + h * 0.42),
            control1: CGPoint(x: minX + w * 0.82, y: minY - h * 0.04),
            control2: CGPoint(x: minX + w * 1.02, y: minY + h * 0.12)
        )
        // Rechte Seite hinunter
        p.addCurve(
            to: CGPoint(x: minX + w * 0.92, y: maxY),
            control1: CGPoint(x: minX + w * 1.06, y: minY + h * 0.62),
            control2: CGPoint(x: minX + w * 1.06, y: maxY - h * 0.18)
        )
        // Sanfte Unterseite
        p.addQuadCurve(
            to: CGPoint(x: minX + w * 0.08, y: maxY),
            control: CGPoint(x: rect.midX, y: maxY + h * 0.04)
        )
        p.closeSubpath()
        return p
    }
}

struct UmbrellaCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        let cx = rect.midX

        // Start unten links
        p.move(to: CGPoint(x: minX + w * 0.15, y: maxY))

        // Linke Außenkante hoch
        p.addCurve(
            to: CGPoint(x: minX + w * 0.04, y: minY + h * 0.35),
            control1: CGPoint(x: minX - w * 0.02, y: maxY - h * 0.05),
            control2: CGPoint(x: minX - w * 0.04, y: minY + h * 0.55)
        )
        // Linker oberer Rand – sanft gerundet
        p.addCurve(
            to: CGPoint(x: minX + w * 0.22, y: minY + h * 0.10),
            control1: CGPoint(x: minX + w * 0.04, y: minY + h * 0.05),
            control2: CGPoint(x: minX + w * 0.10, y: minY - h * 0.02)
        )
        // Top – flach mit subtilem Bump in der Mitte
        p.addCurve(
            to: CGPoint(x: maxX - w * 0.22, y: minY + h * 0.10),
            control1: CGPoint(x: cx - w * 0.10, y: minY - h * 0.04),
            control2: CGPoint(x: cx + w * 0.10, y: minY - h * 0.04)
        )
        // Rechter oberer Rand
        p.addCurve(
            to: CGPoint(x: maxX - w * 0.04, y: minY + h * 0.35),
            control1: CGPoint(x: maxX - w * 0.10, y: minY - h * 0.02),
            control2: CGPoint(x: maxX - w * 0.04, y: minY + h * 0.05)
        )
        // Rechte Außenkante runter
        p.addCurve(
            to: CGPoint(x: maxX - w * 0.15, y: maxY),
            control1: CGPoint(x: maxX + w * 0.04, y: minY + h * 0.55),
            control2: CGPoint(x: maxX + w * 0.02, y: maxY - h * 0.05)
        )
        // Konkave Unterseite (Pilz-Style)
        p.addQuadCurve(
            to: CGPoint(x: minX + w * 0.15, y: maxY),
            control: CGPoint(x: cx, y: maxY - h * 0.18)
        )
        p.closeSubpath()
        return p
    }
}

struct WeepingCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let minX = rect.minX
        let minY = rect.minY
        let maxY = rect.maxY

        // Oberer Schirm endet bei ~50% Höhe
        let canopyBottom = minY + h * 0.50

        // Linker Schirmrand
        p.move(to: CGPoint(x: minX + w * 0.05, y: canopyBottom))
        // Über die runde Krone
        p.addCurve(
            to: CGPoint(x: rect.maxX - w * 0.05, y: canopyBottom),
            control1: CGPoint(x: minX + w * 0.05, y: minY - h * 0.05),
            control2: CGPoint(x: rect.maxX - w * 0.05, y: minY - h * 0.05)
        )

        // 4 Hängezweige unterschiedlicher Länge (von rechts nach links)
        let strands: [(centerX: CGFloat, length: CGFloat)] = [
            (0.85, 0.85),
            (0.62, 1.00),
            (0.38, 0.92),
            (0.15, 0.78)
        ]

        for (i, strand) in strands.enumerated() {
            let centerX = minX + w * strand.centerX
            let strandWidth = w * 0.10
            let tipY = canopyBottom + (maxY - canopyBottom) * strand.length

            // Rechte Kante des Zweigs (vom Schirm runter zur Spitze)
            let rightX = centerX + strandWidth * 0.5
            let leftX  = centerX - strandWidth * 0.5

            if i > 0 {
                // Schwung zwischen den Zweigen am Schirmrand
                p.addQuadCurve(
                    to: CGPoint(x: rightX, y: canopyBottom),
                    control: CGPoint(x: rightX + strandWidth * 0.4,
                                     y: canopyBottom - h * 0.04)
                )
            } else {
                p.addLine(to: CGPoint(x: rightX, y: canopyBottom))
            }

            // Hinunter zur Spitze (geschwungen)
            p.addQuadCurve(
                to: CGPoint(x: centerX, y: tipY),
                control: CGPoint(x: rightX, y: tipY - h * 0.05)
            )
            // Spitze – sanft gerundet
            p.addQuadCurve(
                to: CGPoint(x: leftX, y: canopyBottom),
                control: CGPoint(x: leftX, y: tipY - h * 0.05)
            )
        }

        // Schließe zum Startpunkt
        p.addLine(to: CGPoint(x: minX + w * 0.05, y: canopyBottom))
        p.closeSubpath()
        return p
    }
}
