//
//  CompanionBodies.swift
//  CompanionKit
//
//  Hand-gezeichnete Kreaturen-Körper (prozedural via SwiftUI Shapes).
//  Jede Art hat ihren eigenen Charakter: Ohren, Schnauze, Augen, Mund.
//  Evolution (stage) skaliert Proportionen / fügt Details hinzu.
//

import SwiftUI

// MARK: - Stage Helpers

extension CompanionStageType {
    /// Globaler Skalierungsfaktor (Keimling kleiner, Erwachsener größer).
    var bodyScale: CGFloat {
        switch self {
        case .seedling:    return 0.72
        case .juvenile:    return 0.86
        case .adult:       return 1.0
        case .enlightened: return 1.05
        }
    }

    /// `true` für „Erleuchtet" (zusätzliche Glüh-Details).
    var isEnlightened: Bool { self == .enlightened }
}

// MARK: - Fox

struct FoxBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool
    let earWiggle: Double
    var tailWag: Double = 0

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 8 : 0
            let fur = Color(red: 0.95, green: 0.55, blue: 0.25)
            let furDark = Color(red: 0.82, green: 0.40, blue: 0.15)
            let cream = Color(red: 0.98, green: 0.94, blue: 0.86)

            ZStack {
                // Aura bei „Erleuchtet".
                if stage.isEnlightened {
                    Circle().fill(fur.opacity(0.18)).frame(width: s, height: s)
                        .blur(radius: 6)
                }

                // Körper (kleiner Ellipsen-Blob unten).
                Ellipse()
                    .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.52, height: s * 0.42)
                    .offset(y: s * 0.26 + slump)

                // Schwanz (große Bushy-Curve hinter Körper).
                FoxTail()
                    .fill(LinearGradient(colors: [furDark, fur], startPoint: .leading, endPoint: .trailing))
                    .frame(width: s * 0.42, height: s * 0.5)
                    .overlay(
                        Ellipse().fill(cream).frame(width: s * 0.16, height: s * 0.2)
                            .offset(x: s * 0.16, y: -s * 0.18)
                    )
                    .offset(x: -s * 0.28, y: s * 0.18 + slump)
                    .rotationEffect(.degrees(tailWag * 40), anchor: .bottomTrailing)

                // Kopf.
                ZStack {
                    // Ohren (spitz, dreieckig) mit Wackeln.
                    FoxEar()
                        .fill(furDark)
                        .frame(width: s * 0.22, height: s * 0.28)
                        .overlay(FoxEar().fill(fur).scaleEffect(0.7))
                        .offset(x: -s * 0.22, y: -s * 0.30)
                        .rotationEffect(.degrees(earWiggle * 30), anchor: .bottom)
                    FoxEar()
                        .fill(furDark)
                        .frame(width: s * 0.22, height: s * 0.28)
                        .overlay(FoxEar().fill(fur).scaleEffect(0.7))
                        .offset(x: s * 0.22, y: -s * 0.30)
                        .rotationEffect(.degrees(-earWiggle * 30), anchor: .bottom)

                    // Kopf-Form.
                    Ellipse()
                        .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: s * 0.56, height: s * 0.52)

                    // Weiße Schnauze.
                    Ellipse().fill(cream)
                        .frame(width: s * 0.30, height: s * 0.26)
                        .offset(y: s * 0.10)

                    // Augen.
                    HStack(spacing: s * 0.12) {
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                    }
                    .offset(y: -s * 0.02)

                    // Nase.
                    Circle().fill(Color.black)
                        .frame(width: s * 0.06, height: s * 0.06)
                        .offset(y: s * 0.06)

                    // Mund.
                    CreatureMouth(width: s * 0.12, shape: mood.mouthShape)
                        .offset(y: s * 0.16)
                }
                .saturation(mood.saturation)
                .offset(y: -s * 0.04 + slump * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Fuchs-Ohr (spitzes Dreieck mit runder Basis).
struct FoxEar: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                       control: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// Fuchs-Schwanz (geschwungene Bushy-Form).
struct FoxTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.9, y: h * 0.8))
        p.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.2),
                       control: CGPoint(x: w * 0.0, y: h * 0.9))
        p.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.8),
                       control: CGPoint(x: w * 0.8, y: h * 0.0))
        p.closeSubpath()
        return p
    }
}

// MARK: - Owl

struct OwlBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 6 : 0
            let body = Color(red: 0.42, green: 0.38, blue: 0.62)
            let bodyDark = Color(red: 0.30, green: 0.26, blue: 0.48)
            let belly = Color(red: 0.92, green: 0.88, blue: 0.78)

            ZStack {
                if stage.isEnlightened {
                    Circle().fill(body.opacity(0.18)).frame(width: s, height: s).blur(radius: 6)
                }

                // Körper (runder, flauschiger Blob).
                Ellipse()
                    .fill(LinearGradient(colors: [body, bodyDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.60, height: s * 0.66)
                    .offset(y: s * 0.04 + slump)

                // Bauch (heller).
                Ellipse().fill(belly)
                    .frame(width: s * 0.36, height: s * 0.42)
                    .offset(y: s * 0.12 + slump)
                    .overlay(
                        // Feder-Muster (kleine Vs).
                        VStack(spacing: s * 0.06) {
                            ForEach(0..<3) { _ in
                                HStack(spacing: s * 0.08) {
                                    ForEach(0..<2) { _ in
                                        Image(systemName: "minus")
                                            .font(.system(size: s * 0.05))
                                            .foregroundStyle(bodyDark.opacity(0.4))
                                    }
                                }
                            }
                        }
                        .offset(y: s * 0.10)
                    )

                // Augen-Scheiben (große Kreise, typisch Eule).
                ZStack {
                    // Augen-Disks.
                    HStack(spacing: s * 0.04) {
                        eyeDisk(s: s)
                        eyeDisk(s: s)
                    }
                    .offset(y: -s * 0.08 + slump * 0.4)

                    // Schnabel (kleines Dreieck).
                    OwlBeak()
                        .fill(Color(red: 0.85, green: 0.60, blue: 0.20))
                        .frame(width: s * 0.10, height: s * 0.12)
                        .offset(y: s * 0.04 + slump * 0.4)
                }

                // Ohren-Büschel (oben).
                OwlTuft().fill(bodyDark)
                    .frame(width: s * 0.14, height: s * 0.16)
                    .offset(x: -s * 0.16, y: -s * 0.30)
                    .rotationEffect(.degrees(-15))
                OwlTuft().fill(bodyDark)
                    .frame(width: s * 0.14, height: s * 0.16)
                    .offset(x: s * 0.16, y: -s * 0.30)
                    .rotationEffect(.degrees(15))
            }
            .saturation(mood.saturation)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func eyeDisk(s: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(red: 0.95, green: 0.92, blue: 0.85))
                .frame(width: s * 0.24, height: s * 0.24)
            CreatureEye(size: s * 0.14, shape: mood.eyeShape, isBlinking: isBlinking)
        }
    }
}

struct OwlBeak: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct OwlTuft: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Bear

struct BearBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool
    let earWiggle: Double

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 10 : 0
            let fur = Color(red: 0.55, green: 0.42, blue: 0.30)
            let furDark = Color(red: 0.42, green: 0.30, blue: 0.20)
            let muzzle = Color(red: 0.90, green: 0.82, blue: 0.70)

            ZStack {
                if stage.isEnlightened {
                    Circle().fill(fur.opacity(0.18)).frame(width: s, height: s).blur(radius: 6)
                }

                // Körper (großer runder Blob).
                Ellipse()
                    .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.62, height: s * 0.50)
                    .offset(y: s * 0.22 + slump)

                // Beine (kleine Ellipsen vorne).
                HStack(spacing: s * 0.20) {
                    Ellipse().fill(furDark).frame(width: s * 0.14, height: s * 0.18)
                    Ellipse().fill(furDark).frame(width: s * 0.14, height: s * 0.18)
                }
                .offset(y: s * 0.42 + slump)

                // Rundes Ohr (links/rechts) mit Wackeln.
                ZStack {
                    Circle().fill(furDark)
                        .frame(width: s * 0.20, height: s * 0.20)
                        .overlay(Circle().fill(fur).scaleEffect(0.6))
                        .offset(x: -s * 0.24, y: -s * 0.26)
                        .rotationEffect(.degrees(earWiggle * 25), anchor: .bottom)

                    Circle().fill(furDark)
                        .frame(width: s * 0.20, height: s * 0.20)
                        .overlay(Circle().fill(fur).scaleEffect(0.6))
                        .offset(x: s * 0.24, y: -s * 0.26)
                        .rotationEffect(.degrees(-earWiggle * 25), anchor: .bottom)

                    // Kopf.
                    Circle()
                        .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: s * 0.56, height: s * 0.56)

                    // Schnauze.
                    Ellipse().fill(muzzle)
                        .frame(width: s * 0.32, height: s * 0.26)
                        .offset(y: s * 0.08)

                    // Augen.
                    HStack(spacing: s * 0.14) {
                        CreatureEye(size: s * 0.09, shape: mood.eyeShape, isBlinking: isBlinking)
                        CreatureEye(size: s * 0.09, shape: mood.eyeShape, isBlinking: isBlinking)
                    }
                    .offset(y: -s * 0.04)

                    // Nase.
                    BearNose()
                        .fill(Color.black)
                        .frame(width: s * 0.12, height: s * 0.08)
                        .offset(y: s * 0.04)

                    // Mund.
                    CreatureMouth(width: s * 0.10, shape: mood.mouthShape)
                        .offset(y: s * 0.16)
                }
                .saturation(mood.saturation)
                .offset(y: -s * 0.02 + slump * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct BearNose: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.7),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Wolf

struct WolfBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool
    let earWiggle: Double
    var tailWag: Double = 0

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 8 : 0
            let fur = Color(red: 0.62, green: 0.62, blue: 0.66)
            let furDark = Color(red: 0.45, green: 0.45, blue: 0.50)
            let cream = Color(red: 0.92, green: 0.90, blue: 0.88)

            ZStack {
                if stage.isEnlightened {
                    Circle().fill(fur.opacity(0.18)).frame(width: s, height: s).blur(radius: 6)
                }

                // Körper ( länglicher).
                Capsule()
                    .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.50, height: s * 0.44)
                    .offset(y: s * 0.24 + slump)

                // Schwanz (buschig, hängend).
                FoxTail()
                    .fill(LinearGradient(colors: [furDark, fur], startPoint: .leading, endPoint: .trailing))
                    .frame(width: s * 0.36, height: s * 0.42)
                    .overlay(
                        Ellipse().fill(cream).frame(width: s * 0.14, height: s * 0.18)
                            .offset(x: s * 0.12, y: -s * 0.14)
                    )
                    .offset(x: s * 0.26, y: s * 0.16 + slump)
                    .rotationEffect(.degrees(20 + tailWag * 40), anchor: .bottomLeading)

                // Kopf (spitzer, kantiger).
                ZStack {
                    // Spitze Ohren (aufrecht).
                    FoxEar()
                        .fill(furDark)
                        .frame(width: s * 0.18, height: s * 0.30)
                        .overlay(FoxEar().fill(fur).scaleEffect(0.65))
                        .offset(x: -s * 0.18, y: -s * 0.28)
                        .rotationEffect(.degrees(earWiggle * 20), anchor: .bottom)
                    FoxEar()
                        .fill(furDark)
                        .frame(width: s * 0.18, height: s * 0.30)
                        .overlay(FoxEar().fill(fur).scaleEffect(0.65))
                        .offset(x: s * 0.18, y: -s * 0.28)
                        .rotationEffect(.degrees(-earWiggle * 20), anchor: .bottom)

                    // Kopf (eher birnenförmig).
                    WolfHead()
                        .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: s * 0.52, height: s * 0.56)

                    // Helle Schnauze.
                    WolfMuzzle().fill(cream)
                        .frame(width: s * 0.28, height: s * 0.24)
                        .offset(y: s * 0.14)

                    // Augen (schmaler, intensiver).
                    HStack(spacing: s * 0.12) {
                        CreatureEye(size: s * 0.09, shape: mood.eyeShape, isBlinking: isBlinking)
                        CreatureEye(size: s * 0.09, shape: mood.eyeShape, isBlinking: isBlinking)
                    }
                    .offset(y: -s * 0.04)

                    // Nase.
                    Circle().fill(Color.black)
                        .frame(width: s * 0.07, height: s * 0.06)
                        .offset(y: s * 0.08)

                    // Mund.
                    CreatureMouth(width: s * 0.10, shape: mood.mouthShape)
                        .offset(y: s * 0.18)
                }
                .saturation(mood.saturation)
                .offset(y: -s * 0.04 + slump * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct WolfHead: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.4),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX * 0.8, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.4),
                       control: CGPoint(x: rect.minX * 0.2, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct WolfMuzzle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Deer

struct DeerBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 6 : 0
            let fur = Color(red: 0.78, green: 0.55, blue: 0.40)
            let furDark = Color(red: 0.62, green: 0.42, blue: 0.28)
            let spots = Color(red: 0.98, green: 0.95, blue: 0.85)

            ZStack {
                if stage.isEnlightened {
                    Circle().fill(fur.opacity(0.18)).frame(width: s, height: s).blur(radius: 6)
                }

                // Körper (schlank, oval).
                Ellipse()
                    .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.52, height: s * 0.40)
                    .offset(y: s * 0.26 + slump)
                    .overlay(
                        // Weiße Flecken (Reh-typisch).
                        VStack(spacing: s * 0.04) {
                            ForEach(0..<2) { _ in
                                HStack(spacing: s * 0.10) {
                                    Circle().fill(spots).frame(width: s * 0.04, height: s * 0.04)
                                    Circle().fill(spots).frame(width: s * 0.05, height: s * 0.05)
                                    Circle().fill(spots).frame(width: s * 0.04, height: s * 0.04)
                                }
                            }
                        }
                        .offset(y: s * 0.24)
                    )

                // Geweih (nur ab Juvenile).
                if stage != .seedling {
                    DeerAntler(side: .left)
                        .stroke(furDark, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                        .frame(width: s * 0.20, height: s * 0.30)
                        .offset(x: -s * 0.18, y: -s * 0.30)
                    DeerAntler(side: .right)
                        .stroke(furDark, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                        .frame(width: s * 0.20, height: s * 0.30)
                        .offset(x: s * 0.18, y: -s * 0.30)
                }

                // Kopf (länglich).
                ZStack {
                    Ellipse()
                        .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: s * 0.40, height: s * 0.52)

                    // Nase (dunkel).
                    Ellipse().fill(furDark)
                        .frame(width: s * 0.10, height: s * 0.08)
                        .offset(y: s * 0.18)

                    // Augen (groß, sanft).
                    HStack(spacing: s * 0.10) {
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                    }
                    .offset(y: -s * 0.02)

                    // Mund.
                    CreatureMouth(width: s * 0.08, shape: mood.mouthShape)
                        .offset(y: s * 0.12)

                    // Ohren (klein, seitlich).
                    Ellipse().fill(fur)
                        .frame(width: s * 0.10, height: s * 0.16)
                        .offset(x: -s * 0.22, y: -s * 0.08)
                        .rotationEffect(.degrees(-20))
                    Ellipse().fill(fur)
                        .frame(width: s * 0.10, height: s * 0.16)
                        .offset(x: s * 0.22, y: -s * 0.08)
                        .rotationEffect(.degrees(20))
                }
                .saturation(mood.saturation)
                .offset(y: -s * 0.06 + slump * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct DeerAntler: Shape {
    enum Side { case left, right }
    let side: Side

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let dir: CGFloat = side == .left ? -1 : 1
        // Hauptstamm.
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX + dir * rect.width * 0.3, y: rect.minY),
                       control: CGPoint(x: rect.midX + dir * rect.width * 0.1, y: rect.midY))
        // Zacken.
        p.move(to: CGPoint(x: rect.midX + dir * rect.width * 0.15, y: rect.midY * 0.7))
        p.addLine(to: CGPoint(x: rect.midX + dir * rect.width * 0.45, y: rect.midY * 0.5))
        p.move(to: CGPoint(x: rect.midX + dir * rect.width * 0.25, y: rect.midY * 0.35))
        p.addLine(to: CGPoint(x: rect.midX + dir * rect.width * 0.5, y: rect.midY * 0.15))
        return p
    }
}

// MARK: - Highland Cow

/// Fluffige Scottish Highland-Kuh: langes rotes Fell, die typische
/// Pony-Frisur über den Augen, kleine Hörner, großer sanfter Blick.
struct HighlandCowBody: View {
    let stage: CompanionStageType
    let mood: CompanionMoodType
    let isBlinking: Bool
    let earWiggle: Double

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) * stage.bodyScale
            let slump: CGFloat = mood.isSlumped ? 6 : 0
            // Typisches Highland-rotbraun.
            let fur = Color(red: 0.72, green: 0.40, blue: 0.20)
            let furLight = Color(red: 0.82, green: 0.52, blue: 0.30)
            let furDark = Color(red: 0.55, green: 0.28, blue: 0.12)
            let cream = Color(red: 0.96, green: 0.92, blue: 0.84)

            ZStack {
                if stage.isEnlightened {
                    Circle().fill(fur.opacity(0.18)).frame(width: s, height: s).blur(radius: 6)
                }

                // Großer fluffiger Körper (Highlands sind sehr behaart).
                FluffyBlob()
                    .fill(LinearGradient(colors: [furLight, furDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.66, height: s * 0.54)
                    .offset(y: s * 0.22 + slump)
                    // Fransen-Schwung am Bauch.
                    .overlay(
                        FluffyBlob().fill(fur)
                            .frame(width: s * 0.5, height: s * 0.18)
                            .offset(y: s * 0.40 + slump)
                            .blur(radius: 2)
                    )

                // Beine (klein, hinter dem Fell).
                HStack(spacing: s * 0.22) {
                    RoundedRectangle(cornerRadius: s * 0.04).fill(furDark)
                        .frame(width: s * 0.08, height: s * 0.16)
                    RoundedRectangle(cornerRadius: s * 0.04).fill(furDark)
                        .frame(width: s * 0.08, height: s * 0.16)
                }
                .offset(y: s * 0.44 + slump)

                // Kopf-Gruppe.
                ZStack {
                    // Kleine Hörner (ab Juvenile, weißlich, seitlich-oben).
                    if stage != .seedling {
                        CowHorn(side: .left)
                            .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.75)], startPoint: .top, endPoint: .bottom))
                            .frame(width: s * 0.14, height: s * 0.18)
                            .offset(x: -s * 0.30, y: -s * 0.26)
                        CowHorn(side: .right)
                            .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.75)], startPoint: .top, endPoint: .bottom))
                            .frame(width: s * 0.14, height: s * 0.18)
                            .offset(x: s * 0.30, y: -s * 0.26)
                    }

                    // Fluffige Ohren (seitlich, leicht wackelnd).
                    Ellipse().fill(furDark)
                        .frame(width: s * 0.18, height: s * 0.22)
                        .overlay(Ellipse().fill(furLight).scaleEffect(0.6))
                        .offset(x: -s * 0.34, y: -s * 0.08)
                        .rotationEffect(.degrees(-12 + earWiggle * 25), anchor: .bottomTrailing)
                    Ellipse().fill(furDark)
                        .frame(width: s * 0.18, height: s * 0.22)
                        .overlay(Ellipse().fill(furLight).scaleEffect(0.6))
                        .offset(x: s * 0.34, y: -s * 0.08)
                        .rotationEffect(.degrees(12 - earWiggle * 25), anchor: .bottomLeading)

                    // Großer runder fluffiger Kopf.
                    FluffyBlob()
                        .fill(LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: s * 0.60, height: s * 0.56)

                    // Der ikonische Pony-Franse über den Augen (langes Fell).
                    FluffyBlob()
                        .fill(furLight)
                        .frame(width: s * 0.62, height: s * 0.22)
                        .offset(y: -s * 0.18)
                        .blur(radius: 1.5)

                    // Helles Gesichtsfeld (Schnauzen-Bereich).
                    Ellipse().fill(cream.opacity(0.85))
                        .frame(width: s * 0.34, height: s * 0.28)
                        .offset(y: s * 0.14)

                    // Augen (groß, sanft — Highlands haben weichen Blick).
                    HStack(spacing: s * 0.14) {
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                        CreatureEye(size: s * 0.10, shape: mood.eyeShape, isBlinking: isBlinking)
                    }
                    .offset(y: -s * 0.02)

                    // Große Nüstern (typisch Rind).
                    HStack(spacing: s * 0.06) {
                        Ellipse().fill(furDark).frame(width: s * 0.05, height: s * 0.07)
                        Ellipse().fill(furDark).frame(width: s * 0.05, height: s * 0.07)
                    }
                    .offset(y: s * 0.18)

                    // Mund.
                    CreatureMouth(width: s * 0.10, shape: mood.mouthShape)
                        .offset(y: s * 0.26)
                }
                .saturation(mood.saturation)
                .offset(y: -s * 0.04 + slump * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Fluffiger Blob mit welligem Rand (für Fell-Look).
struct FluffyBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        // Welliger Kreis mit mehreren Kontrollpunkten → flauschig.
        let bumps: [(CGPoint, CGFloat)] = [
            (CGPoint(x: cx, y: rect.minY), 0),
            (CGPoint(x: rect.maxX, y: cy - h * 0.1), 8),
            (CGPoint(x: cx, y: rect.maxY), -6),
            (CGPoint(x: rect.minX, y: cy + h * 0.1), 4),
            (CGPoint(x: rect.minX, y: cy - h * 0.1), -4),
            (CGPoint(x: rect.maxX, y: cy + h * 0.1), 6)
        ]
        // Einfacher welliger Pfad über QuadCurves.
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        // Zacken am rechten Rand (Fell-Schwung).
        for i in stride(from: CGFloat(0), through: 4, by: 1) {
            let t = i / 4
            let y = cy + h * 0.1 + t * h * 0.35
            let xOut = rect.maxX + (i.truncatingRemainder(dividingBy: 2) == 0 ? w * 0.04 : -w * 0.02)
            p.addQuadCurve(to: CGPoint(x: xOut, y: y),
                           control: CGPoint(x: rect.maxX, y: y - h * 0.05))
        }
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: cy),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        for i in stride(from: CGFloat(0), through: 4, by: 1) {
            let t = i / 4
            let y = cy - h * 0.1 - t * h * 0.35
            let xOut = rect.minX - (i.truncatingRemainder(dividingBy: 2) == 0 ? w * 0.04 : -w * 0.02)
            p.addQuadCurve(to: CGPoint(x: xOut, y: y),
                           control: CGPoint(x: rect.minX, y: y + h * 0.05))
        }
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        _ = bumps
        return p
    }
}

/// Kuh-Horn (leicht gebogen, seitlich).
struct CowHorn: Shape {
    enum Side { case left, right }
    let side: Side

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let dir: CGFloat = side == .left ? -1 : 1
        // Basis breit am Kopf, Spitze nach oben-außen gebogen.
        p.move(to: CGPoint(x: rect.midX - dir * rect.width * 0.3, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX + dir * rect.width * 0.5, y: rect.minY),
                       control: CGPoint(x: rect.midX + dir * rect.width * 0.6, y: rect.maxY * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.midX - dir * rect.width * 0.1, y: rect.maxY),
                       control: CGPoint(x: rect.midX + dir * rect.width * 0.1, y: rect.minY + rect.height * 0.2))
        p.closeSubpath()
        return p
    }
}
