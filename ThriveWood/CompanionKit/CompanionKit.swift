//
//  Package.swift
//  CompanionKit
//
//  Prozedural gezeichnete, animierte Companion-Kreaturen für ThriveWood.
// 再造 Standalone-Package (BentoUI-style), eingebunden via synchronized folder.
//

import SwiftUI

// MARK: - Public Entry

/// Haupt-View: zeichnet die gegebene Companion-Kreatur mit Atmung,
/// Blinzeln und Mood-Animation. Größe wird über `size` gesteuert.
public struct CompanionCreature: View {
    public let species: CompanionSpeciesType
    public let stage: CompanionStageType
    public let mood: CompanionMoodType
    public let size: CGFloat
    public let accessory: CompanionAccessoryType?
    public let reaction: CompanionReactionType?
    public let reactionTrigger: Int

    @State private var breathe: Bool = false
    @State private var blink: Bool = false
    @State private var bounce: Bool = false

    public init(
        species: CompanionSpeciesType,
        stage: CompanionStageType,
        mood: CompanionMoodType,
        size: CGFloat = 96,
        accessory: CompanionAccessoryType? = nil,
        reaction: CompanionReactionType? = nil,
        reactionTrigger: Int = 0
    ) {
        self.species = species
        self.stage = stage
        self.mood = mood
        self.size = size
        self.accessory = accessory
        self.reaction = reaction
        self.reactionTrigger = reactionTrigger
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            creature(at: t)
        }
        .frame(width: size, height: size)
        .scaleEffect(bounce ? 1.06 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: mood)
        .overlay(alignment: .top) {
            if let reaction {
                CompanionReactionOverlay(reaction: reaction, trigger: reactionTrigger)
                    .offset(y: -size * 0.15)
            }
        }
    }

    @ViewBuilder
    private func creature(at t: Double) -> some View {
        // Atmung: sanftes Skalieren (≈4s Periode).
        let breathScale = 1.0 + sin(t * .pi / 2.0) * 0.018
        // Blinzeln: alle ~4.2s für ~150ms.
        let blinkPhase = t.truncatingRemainder(dividingBy: 4.2)
        let isBlinking = blinkPhase < 0.15
        // Ohren-Wackeln: ~1.6s Periode, leicht.
        let earWiggle = sin(t * .pi / 0.8) * 0.06
        // Vibrant → Schwanzwedeln (schnellere Periode).
        let tailWag = mood == .vibrant ? sin(t * .pi / 0.3) * 0.12 : earWiggle * 0.5

        ZStack {
            switch species {
            case .fox:  FoxBody(stage: stage, mood: mood, isBlinking: isBlinking, earWiggle: earWiggle, tailWag: tailWag)
            case .owl:  OwlBody(stage: stage, mood: mood, isBlinking: isBlinking)
            case .bear: BearBody(stage: stage, mood: mood, isBlinking: isBlinking, earWiggle: earWiggle)
            case .wolf: WolfBody(stage: stage, mood: mood, isBlinking: isBlinking, earWiggle: earWiggle, tailWag: tailWag)
            case .deer: DeerBody(stage: stage, mood: mood, isBlinking: isBlinking)
            }

            // Accessoire obendrauf.
            if let accessory {
                CompanionAccessoryView(type: accessory, bodySize: size)
                    .offset(y: accessoryOffset(for: accessory))
            }
        }
        .scaleEffect(breathScale, anchor: .center)
        .frame(width: size, height: size, alignment: .center)
    }

    /// Positioniert das Accessoire grob passend zur Slot-Höhe.
    private func accessoryOffset(for accessory: CompanionAccessoryType) -> CGFloat {
        switch accessory.slot {
        case .hat:  return -size * 0.32
        case .neck: return size * 0.10
        case .toy:  return 0
        }
    }
}

// MARK: - Mood / Stage / Species (CompanionKit-eigene Typen, bridgebar)

public enum CompanionSpeciesType: String, CaseIterable, Identifiable, Sendable {
    case fox, owl, bear, wolf, deer
    public var id: String { rawValue }
}

public enum CompanionStageType: Int, CaseIterable, Sendable {
    case seedling = 1, juvenile, adult, enlightened
}

public enum CompanionMoodType: Sendable {
    case vibrant, content, tired, critical
}

// MARK: - Mood Helpers

extension CompanionMoodType {
    /// Augen-Form je Mood.
    var eyeShape: EyeShape {
        switch self {
        case .vibrant:  return .sparkle
        case .content:  return .round
        case .tired:    return .sleepy
        case .critical: return .x
        }
    }

    /// Mund-Form je Mood.
    var mouthShape: MouthShape {
        switch self {
        case .vibrant:  return .bigSmile
        case .content:  return .smile
        case .tired:    return .flat
        case .critical: return .frown
        }
    }

    /// Sichtbare Müdigkeit (Augenringe / hängende Haltung)?
    var isSlumped: Bool { self == .tired || self == .critical }

    /// Farbsättigung der Kreatur (traurig = blasser).
    var saturation: Double {
        switch self {
        case .vibrant:  return 1.0
        case .content:  return 0.95
        case .tired:    return 0.75
        case .critical: return 0.6
        }
    }
}

enum EyeShape { case round, sparkle, sleepy, x }
enum MouthShape { case smile, bigSmile, flat, frown }

// MARK: - Shared Body Parts

/// Auge mit Blinzeln (Höhe kollabiert beim Blinzeln).
struct CreatureEye: View {
    let size: CGFloat
    let shape: EyeShape
    let isBlinking: Bool

    var body: some View {
        let openHeight: CGFloat = isBlinking ? size * 0.12 : size
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.white)
                .frame(width: size, height: openHeight)
            if !isBlinking {
                pupil
            }
        }
        .frame(width: size, height: size, alignment: .center)
        .clipped()
    }

    @ViewBuilder
    private var pupil: some View {
        switch shape {
        case .round, .sparkle:
            ZStack {
                Circle().fill(Color.black).frame(width: size * 0.55, height: size * 0.55)
                if shape == .sparkle {
                    Circle().fill(Color.white).frame(width: size * 0.18, height: size * 0.18)
                        .offset(x: -size * 0.12, y: -size * 0.12)
                }
            }
        case .sleepy:
            // Halbierte Pupille (schweres Lid).
            Capsule(style: .continuous)
                .fill(Color.black)
                .frame(width: size * 0.6, height: size * 0.35)
                .offset(y: size * 0.18)
        case .x:
            Image(systemName: "xmark")
                .font(.system(size: size * 0.6, weight: .heavy))
                .foregroundStyle(Color.black)
        }
    }
}

/// Mund je Mood.
struct CreatureMouth: View {
    let width: CGFloat
    let shape: MouthShape

    var body: some View {
        switch shape {
        case .smile:
            // Sanfter Bogen nach oben.
            SmileShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: width * 0.12, lineCap: .round))
                .frame(width: width, height: width * 0.5)
        case .bigSmile:
            // Offenes Lächeln.
            ZStack {
                Ellipse().fill(Color.black.opacity(0.85))
                    .frame(width: width, height: width * 0.55)
                Ellipse().fill(Color(red: 0.9, green: 0.4, blue: 0.4))
                    .frame(width: width * 0.8, height: width * 0.25)
                    .offset(y: width * 0.18)
            }
            .frame(width: width, height: width * 0.6)
            .clipShape(SmileShape())
        case .flat:
            // Gerader Strich.
            Rectangle()
                .fill(Color.black)
                .frame(width: width * 0.8, height: width * 0.08)
                .cornerRadius(width * 0.04)
        case .frown:
            // Nach unten gebogen.
            FrownShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: width * 0.12, lineCap: .round))
                .frame(width: width, height: width * 0.5)
        }
    }
}

/// Bogen-Shape für nach-unten-Mund (Frown).
struct FrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return p
    }
}

/// Bogen-Shape für Lächeln.
struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return p
    }
}
