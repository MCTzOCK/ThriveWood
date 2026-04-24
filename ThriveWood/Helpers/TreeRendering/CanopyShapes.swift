//
//  CanopyShapes.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct TriangleCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct TeardropCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                           control: CGPoint(x: rect.maxX, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                           control: CGPoint(x: rect.minX, y: rect.midY))
        }
    }
}

struct CloudCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let r1 = h * 0.45, r2 = h * 0.40, r3 = h * 0.38
        p.addEllipse(in: CGRect(x: rect.minX, y: rect.maxY - r1 * 2,
                                width: r1 * 2, height: r1 * 2))
        p.addEllipse(in: CGRect(x: rect.maxX - r2 * 2, y: rect.maxY - r2 * 2,
                                width: r2 * 2, height: r2 * 2))
        p.addEllipse(in: CGRect(x: rect.midX - r3, y: rect.minY,
                                width: r3 * 2, height: r3 * 2))
        p.addRect(CGRect(x: rect.minX + r1 * 0.5, y: rect.midY,
                         width: w - r1, height: h * 0.4))
        return p
    }
}

struct UmbrellaCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                           control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.2))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct WeepingCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                           control: CGPoint(x: rect.maxX, y: rect.minY))
            let tips = 5
            for i in 0...tips {
                let x = rect.minX + rect.width * CGFloat(i) / CGFloat(tips)
                let y = rect.maxY - (i.isMultiple(of: 2) ? 0 : rect.height * 0.15)
                p.addLine(to: CGPoint(x: x, y: rect.maxY))
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                           control: CGPoint(x: rect.minX, y: rect.minY))
        }
    }
}
