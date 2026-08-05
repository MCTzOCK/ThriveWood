//
//  CompanionAccessories.swift
//  CompanionKit
//
//  App-unabhängige Accessoire- und Reaktions-Typen + Rendering.
//  Die App mappt ihre eigenen Enums hierauf (Bridge in CompanionBridge.swift).
//

import SwiftUI

// MARK: - Accessory Type (Kit-intern)

public enum CompanionAccessoryType: String, CaseIterable, Sendable {
    case topHat, partyHat, crown, flowerCrown
    case scarf, bowtie, pearlNecklace
    case ball, bone, featherToy

    public var slot: CompanionAccessorySlot {
        switch self {
        case .topHat, .partyHat, .crown, .flowerCrown: return .hat
        case .scarf, .bowtie, .pearlNecklace:           return .neck
        case .ball, .bone, .featherToy:                 return .toy
        }
    }
}

public enum CompanionAccessorySlot: Sendable { case hat, neck, toy }

// MARK: - Reaction Type

public enum CompanionReactionType: Sendable {
    case hearts, eats, bubbles, plays, happy

    public var emoji: String {
        switch self {
        case .hearts:  return "💖"
        case .eats:    return "😋"
        case .bubbles: return "🫧"
        case .plays:   return "🎉"
        case .happy:   return "✨"
        }
    }
}

// MARK: - Accessory Renderer

/// Rendert ein Accessoire an der passenden Position über dem Tier.
struct CompanionAccessoryView: View {
    let type: CompanionAccessoryType
    let bodySize: CGFloat

    var body: some View {
        switch type {
        // Hüte (oben auf dem Kopf).
        case .topHat:       TopHat(size: bodySize * 0.4)
        case .partyHat:     PartyHat(size: bodySize * 0.35)
        case .crown:        CrownShape(size: bodySize * 0.35)
        case .flowerCrown:  FlowerCrownShape(size: bodySize * 0.4)
        // Hals.
        case .scarf:        ScarfShape(size: bodySize * 0.5)
        case .bowtie:       BowtieShape(size: bodySize * 0.22)
        case .pearlNecklace:PearlNecklaceShape(size: bodySize * 0.4)
        // Spielzeug (unten rechts neben dem Tier).
        case .ball:         Circle().fill(Color.red).frame(width: bodySize * 0.18, height: bodySize * 0.18)
            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
            .offset(x: bodySize * 0.35, y: bodySize * 0.32)
        case .bone:         BoneShape().fill(Color(red: 0.95, green: 0.93, blue: 0.85))
            .frame(width: bodySize * 0.22, height: bodySize * 0.10)
            .offset(x: bodySize * 0.34, y: bodySize * 0.34)
        case .featherToy:   FeatherShape().stroke(Color.purple, style: StrokeStyle(lineWidth: bodySize * 0.02, lineCap: .round))
            .frame(width: bodySize * 0.14, height: bodySize * 0.30)
            .offset(x: bodySize * 0.34, y: bodySize * 0.20)
        }
    }
}

// MARK: - Hat Shapes

struct TopHat: View {
    let size: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle().fill(Color.black)
                Rectangle().fill(Color.red).frame(height: size * 0.15).offset(y: size * 0.3)
            }
            .frame(width: size * 0.7, height: size * 0.9)
            Ellipse().fill(Color.black).frame(width: size * 1.2, height: size * 0.2)
        }
    }
}

struct PartyHat: View {
    let size: CGFloat
    var body: some View {
        Triangle()
            .fill(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.8, height: size * 1.4)
            .overlay(
                VStack(spacing: size * 0.15) {
                    ForEach(0..<3) { i in
                        Circle().fill(Color.white.opacity(0.7)).frame(width: size * 0.08)
                            .offset(x: CGFloat(i - 1) * size * 0.1)
                    }
                }
                .offset(y: -size * 0.1)
            )
            .overlay(
                Circle().fill(Color.yellow).frame(width: size * 0.18).offset(y: -size * 0.75)
            )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct CrownShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            CrownPath()
                .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 1.4, height: size * 0.8)
            // Juwelen.
            Circle().fill(Color.red).frame(width: size * 0.12).offset(x: -size * 0.35, y: size * 0.1)
            Circle().fill(Color.blue).frame(width: size * 0.14).offset(y: size * 0.05)
            Circle().fill(Color.green).frame(width: size * 0.12).offset(x: size * 0.35, y: size * 0.1)
        }
    }
}

struct CrownPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY * 0.7))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY * 0.7))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct FlowerCrownShape: View {
    let size: CGFloat
    var body: some View {
        HStack(spacing: -size * 0.05) {
            ForEach(0..<5) { i in
                ZStack {
                    Circle().fill([Color.pink, .purple, .blue, .orange, .yellow][i].opacity(0.85))
                        .frame(width: size * 0.3)
                    Circle().fill(Color.yellow).frame(width: size * 0.1)
                }
            }
        }
        .rotationEffect(.degrees(180))
    }
}

// MARK: - Neck Shapes

struct ScarfShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Capsule().fill(Color.red)
                .frame(width: size * 0.9, height: size * 0.22)
                .rotationEffect(.degrees(-8))
            // Fransen.
            HStack(spacing: size * 0.02) {
                ForEach(0..<5) { _ in
                    Rectangle().fill(Color.red).frame(width: size * 0.04, height: size * 0.18)
                }
            }
            .offset(x: size * 0.35, y: size * 0.12)
        }
    }
}

struct BowtieShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            BowtieHalf().fill(Color.red).frame(width: size, height: size * 0.7)
            BowtieHalf().fill(Color.red).scaleEffect(x: -1).frame(width: size, height: size * 0.7)
            Circle().fill(Color.red.opacity(0.9)).frame(width: size * 0.25)
        }
    }
}

struct BowtieHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct PearlNecklaceShape: View {
    let size: CGFloat
    var body: some View {
        HStack(spacing: size * 0.04) {
            ForEach(0..<7) { _ in
                Circle().fill(LinearGradient(colors: [.white, .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size * 0.1)
                    .shadow(color: .gray.opacity(0.3), radius: 1)
            }
        }
        .rotationEffect(.degrees(12))
    }
}

// MARK: - Toy Shapes

struct BoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // Linke Kappe (zwei Kreise).
        p.addEllipse(in: CGRect(x: 0, y: 0, width: w * 0.4, height: h * 0.6))
        p.addEllipse(in: CGRect(x: 0, y: h * 0.4, width: w * 0.4, height: h * 0.6))
        // Mittelschaft.
        p.addRoundedRect(in: CGRect(x: w * 0.2, y: h * 0.3, width: w * 0.6, height: h * 0.4), cornerSize: CGSize(width: 4, height: 4))
        // Rechte Kappe.
        p.addEllipse(in: CGRect(x: w * 0.6, y: 0, width: w * 0.4, height: h * 0.6))
        p.addEllipse(in: CGRect(x: w * 0.6, y: h * 0.4, width: w * 0.4, height: h * 0.6))
        return p
    }
}

struct FeatherShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.maxX, y: rect.midY))
        // Federstrahlen.
        for i in stride(from: 0.2, through: 0.8, by: 0.2) {
            let y = rect.maxY * (1 - i)
            p.move(to: CGPoint(x: rect.midX, y: y))
            p.addLine(to: CGPoint(x: rect.maxX, y: y - rect.height * 0.08))
            p.move(to: CGPoint(x: rect.midX, y: y))
            p.addLine(to: CGPoint(x: rect.minX, y: y - rect.height * 0.08))
        }
        return p
    }
}

// MARK: - Reaction Overlay

/// Zeigt eine kurze Reaktions-Animation (Emoji-Partikel) über dem Tier.
public struct CompanionReactionOverlay: View {
    public let reaction: CompanionReactionType
    public let trigger: Int

    @State private var animate = false

    public init(reaction: CompanionReactionType, trigger: Int) {
        self.reaction = reaction
        self.trigger = trigger
    }

    public var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Text(reaction.emoji)
                    .font(.system(size: 24))
                    .scaleEffect(animate ? 1.3 : 0.3)
                    .opacity(animate ? 0 : 1)
                    .offset(x: CGFloat(i - 1) * 30, y: animate ? -60 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.08),
                        value: animate
                    )
            }
        }
        .onChange(of: trigger) { _, _ in
            animate = false
            withAnimation { animate = true }
        }
        .allowsHitTesting(false)
    }
}
