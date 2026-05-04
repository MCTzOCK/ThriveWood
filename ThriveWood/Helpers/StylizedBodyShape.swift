//
//  StylizedBodyShape.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI
import Foundation


struct StylizedBodyShape: Shape {
    let isFront: Bool
    
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        
        let p = BodyProportions.self
        let centerX = w * 0.5
        
        // === KOPF (oval) ===
        let headCenterY = h * (p.headTop + p.headBottom) / 2
        let headRadiusX = w * p.headWidth / 2
        let headRadiusY = h * (p.headBottom - p.headTop) / 2
        path.addEllipse(in: CGRect(
            x: centerX - headRadiusX,
            y: h * p.headTop,
            width: headRadiusX * 2,
            height: headRadiusY * 2
        ))
        
        // === KÖRPER (als ein zusammenhängender Pfad) ===
        path.move(to: CGPoint(x: centerX - w * p.neckWidth / 2, y: h * p.headBottom))
        
        // Hals links
        path.addLine(to: CGPoint(x: centerX - w * p.neckWidth / 2, y: h * p.neckBottom))
        
        // Linke Schulter
        path.addCurve(
            to: CGPoint(x: w * (0.5 - p.shoulderWidth / 2), y: h * p.shoulderY),
            control1: CGPoint(x: centerX - w * p.neckWidth / 2, y: h * p.shoulderY),
            control2: CGPoint(x: w * (0.5 - p.shoulderWidth / 2) + w * 0.05, y: h * p.shoulderY)
        )
        
        // Linker Arm außen - Schulter bis Ellbogen
        path.addCurve(
            to: CGPoint(x: w * 0.14, y: h * 0.34),
            control1: CGPoint(x: w * 0.20, y: h * 0.20),
            control2: CGPoint(x: w * 0.14, y: h * 0.28)
        )
        
        // Linker Unterarm
        path.addCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.48),
            control1: CGPoint(x: w * 0.12, y: h * 0.40),
            control2: CGPoint(x: w * 0.10, y: h * 0.44)
        )
        
        // Hand links
        path.addCurve(
            to: CGPoint(x: w * 0.14, y: h * 0.52),
            control1: CGPoint(x: w * 0.08, y: h * 0.50),
            control2: CGPoint(x: w * 0.10, y: h * 0.52)
        )
        
        // Linker Arm innen hoch
        path.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.36),
            control1: CGPoint(x: w * 0.16, y: h * 0.46),
            control2: CGPoint(x: w * 0.17, y: h * 0.40)
        )
        
        // Achsel / Seite
        path.addCurve(
            to: CGPoint(x: w * 0.26, y: h * 0.26),
            control1: CGPoint(x: w * 0.20, y: h * 0.30),
            control2: CGPoint(x: w * 0.22, y: h * 0.27)
        )
        
        // Linke Körperseite runter zur Taille
        path.addLine(to: CGPoint(x: w * 0.29, y: h * 0.32))
        path.addCurve(
            to: CGPoint(x: w * (0.5 - p.waistWidth / 2), y: h * p.waistY),
            control1: CGPoint(x: w * 0.28, y: h * 0.35),
            control2: CGPoint(x: w * (0.5 - p.waistWidth / 2), y: h * 0.36)
        )
        
        // Hüfte links
        path.addCurve(
            to: CGPoint(x: w * (0.5 - p.hipWidth / 2), y: h * p.hipY),
            control1: CGPoint(x: w * (0.5 - p.waistWidth / 2 - 0.02), y: h * (p.waistY + 0.02)),
            control2: CGPoint(x: w * (0.5 - p.hipWidth / 2 - 0.02), y: h * (p.hipY - 0.02))
        )
        
        // Linkes Bein außen
        path.addCurve(
            to: CGPoint(x: w * 0.30, y: h * p.kneeY),
            control1: CGPoint(x: w * 0.33, y: h * 0.52),
            control2: CGPoint(x: w * 0.31, y: h * 0.64)
        )
        
        // Unterschenkel außen
        path.addCurve(
            to: CGPoint(x: w * 0.32, y: h * p.ankleY),
            control1: CGPoint(x: w * 0.29, y: h * 0.80),
            control2: CGPoint(x: w * 0.30, y: h * 0.88)
        )
        
        // Fuß links
        path.addLine(to: CGPoint(x: w * 0.28, y: h * p.footY))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * p.footY))
        
        // Unterschenkel innen
        path.addCurve(
            to: CGPoint(x: w * 0.40, y: h * p.kneeY),
            control1: CGPoint(x: w * 0.40, y: h * 0.88),
            control2: CGPoint(x: w * 0.40, y: h * 0.80)
        )
        
        // Oberschenkel innen
        path.addCurve(
            to: CGPoint(x: w * 0.46, y: h * p.crotchY),
            control1: CGPoint(x: w * 0.42, y: h * 0.64),
            control2: CGPoint(x: w * 0.44, y: h * 0.56)
        )
        
        // Schritt
        path.addLine(to: CGPoint(x: w * 0.54, y: h * p.crotchY))
        
        // Rechtes Bein innen
        path.addCurve(
            to: CGPoint(x: w * 0.60, y: h * p.kneeY),
            control1: CGPoint(x: w * 0.56, y: h * 0.56),
            control2: CGPoint(x: w * 0.58, y: h * 0.64)
        )
        
        // Rechter Unterschenkel innen
        path.addCurve(
            to: CGPoint(x: w * 0.60, y: h * p.footY),
            control1: CGPoint(x: w * 0.60, y: h * 0.80),
            control2: CGPoint(x: w * 0.60, y: h * 0.88)
        )
        
        // Fuß rechts
        path.addLine(to: CGPoint(x: w * 0.72, y: h * p.footY))
        path.addLine(to: CGPoint(x: w * 0.68, y: h * p.ankleY))
        
        // Rechter Unterschenkel außen
        path.addCurve(
            to: CGPoint(x: w * 0.70, y: h * p.kneeY),
            control1: CGPoint(x: w * 0.70, y: h * 0.88),
            control2: CGPoint(x: w * 0.71, y: h * 0.80)
        )
        
        // Rechtes Bein außen
        path.addCurve(
            to: CGPoint(x: w * (0.5 + p.hipWidth / 2), y: h * p.hipY),
            control1: CGPoint(x: w * 0.69, y: h * 0.64),
            control2: CGPoint(x: w * 0.67, y: h * 0.52)
        )
        
        // Rechte Hüfte
        path.addCurve(
            to: CGPoint(x: w * (0.5 + p.waistWidth / 2), y: h * p.waistY),
            control1: CGPoint(x: w * (0.5 + p.hipWidth / 2 + 0.02), y: h * (p.hipY - 0.02)),
            control2: CGPoint(x: w * (0.5 + p.waistWidth / 2 + 0.02), y: h * (p.waistY + 0.02))
        )
        
        // Rechte Körperseite hoch
        path.addCurve(
            to: CGPoint(x: w * 0.71, y: h * 0.32),
            control1: CGPoint(x: w * (0.5 + p.waistWidth / 2), y: h * 0.36),
            control2: CGPoint(x: w * 0.72, y: h * 0.35)
        )
        path.addLine(to: CGPoint(x: w * 0.74, y: h * 0.26))
        
        // Rechte Achsel
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.36),
            control1: CGPoint(x: w * 0.78, y: h * 0.27),
            control2: CGPoint(x: w * 0.80, y: h * 0.30)
        )
        
        // Rechter Arm innen runter
        path.addCurve(
            to: CGPoint(x: w * 0.86, y: h * 0.52),
            control1: CGPoint(x: w * 0.83, y: h * 0.40),
            control2: CGPoint(x: w * 0.84, y: h * 0.46)
        )
        
        // Hand rechts
        path.addCurve(
            to: CGPoint(x: w * 0.90, y: h * 0.48),
            control1: CGPoint(x: w * 0.90, y: h * 0.52),
            control2: CGPoint(x: w * 0.92, y: h * 0.50)
        )
        
        // Rechter Unterarm hoch
        path.addCurve(
            to: CGPoint(x: w * 0.86, y: h * 0.34),
            control1: CGPoint(x: w * 0.90, y: h * 0.44),
            control2: CGPoint(x: w * 0.88, y: h * 0.40)
        )
        
        // Rechter Oberarm
        path.addCurve(
            to: CGPoint(x: w * (0.5 + p.shoulderWidth / 2), y: h * p.shoulderY),
            control1: CGPoint(x: w * 0.86, y: h * 0.28),
            control2: CGPoint(x: w * 0.80, y: h * 0.20)
        )
        
        // Rechte Schulter zum Hals
        path.addCurve(
            to: CGPoint(x: centerX + w * p.neckWidth / 2, y: h * p.neckBottom),
            control1: CGPoint(x: w * (0.5 + p.shoulderWidth / 2) - w * 0.05, y: h * p.shoulderY),
            control2: CGPoint(x: centerX + w * p.neckWidth / 2, y: h * p.shoulderY)
        )
        
        // Hals rechts hoch
        path.addLine(to: CGPoint(x: centerX + w * p.neckWidth / 2, y: h * p.headBottom))
        
        path.closeSubpath()
        
        return path
    }
}
