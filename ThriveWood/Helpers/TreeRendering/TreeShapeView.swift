//
//  TreeShapeView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct TreeShapeView: View {
    let species: TreeSpecies
    let stage: TreeGrowthStage
    /// Animations-Trigger (z.B. beim Gießen).
    var animate: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let scale = stage.scale
            let style = species.style

            ZStack(alignment: .bottom) {
                if stage == .seed {
                    seedView(size: size)
                } else {
                    // Stamm
                    trunk(size: size, scale: scale, color: style.trunkColor)
                    // Krone
                    canopy(size: size, scale: scale, style: style)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            .scaleEffect(animate ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: animate)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Trunk
    private func trunk(size: CGFloat, scale: CGFloat, color: Color) -> some View {
        let h = size * 0.40 * scale
        let w = size * 0.10 * scale
        return RoundedRectangle(cornerRadius: w * 0.3)
            .fill(color)
            .frame(width: w, height: h)
            .offset(y: 0)
    }

    // MARK: Canopy
    @ViewBuilder
    private func canopy(size: CGFloat, scale: CGFloat, style: TreeStyle) -> some View {
        let canopySize = size * 0.80 * scale
        let offset = size * 0.30 * scale // über dem Stamm

        let shape = canopyShape(style.canopyShape)
        let gradient = LinearGradient(
            colors: style.canopyColors,
            startPoint: .top, endPoint: .bottom
        )

        ZStack {
            if style.layered {
                shape
                    //.fill(style.canopyColors.last ?? .green)
                    .frame(width: canopySize * 1.05, height: canopySize * 1.05)
                    .offset(y: -offset + 4)
                    .opacity(0.85)
            }
            shape
                //.fill(gradient)
                .frame(width: canopySize, height: canopySize)
                .offset(y: -offset)
        }
    }

    @ViewBuilder
    private func canopyShape(_ shape: TreeStyle.CanopyShape) -> some View {
        switch shape {
        case .round:    Circle()
        case .triangle: TriangleCanopy()
        case .teardrop: TeardropCanopy()
        case .cloud:    CloudCanopy()
        case .umbrella: UmbrellaCanopy()
        case .weeping:  WeepingCanopy()
        }
    }

    // MARK: Seed
    private func seedView(size: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.45, green: 0.30, blue: 0.15))
                .frame(width: size * 0.22, height: size * 0.16)
            Capsule()
                .fill(Color.green)
                .frame(width: size * 0.04, height: size * 0.18)
                .offset(y: -size * 0.12)
        }
    }
}
