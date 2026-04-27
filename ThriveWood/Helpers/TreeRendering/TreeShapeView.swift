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
        let h = size * 0.42 * scale
        let w = size * 0.11 * scale
        return RoundedRectangle(cornerRadius: w * 0.35)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.75)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(width: w, height: h)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
    }


    // MARK: Canopy
    @ViewBuilder
    private func canopy(size: CGFloat, scale: CGFloat, style: TreeStyle) -> some View {
        let canopySize = size * 0.85 * scale
        let offset = size * 0.32 * scale

        let shape = canopyShape(style.canopyShape)
        let gradient = LinearGradient(
            colors: style.canopyColors,
            startPoint: .top, endPoint: .bottom
        )

        ZStack {
            // Schatten-Layer (nur bei layered Trees)
            if style.layered {
                shape
                    .fill(style.canopyColors.last ?? .green)
                    .frame(width: canopySize * 1.04, height: canopySize * 1.04)
                    .offset(y: -offset + 6)
                    .opacity(0.55)
                    .blur(radius: 1)
            }
            // Haupt-Krone
            shape
                .fill(gradient)
                .frame(width: canopySize, height: canopySize)
                .offset(y: -offset)
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)

            // Highlight-Layer für Tiefe
            shape
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: canopySize, height: canopySize)
                .offset(y: -offset)
                .blendMode(.plusLighter)
        }
    }


    private func canopyShape(_ shape: TreeStyle.CanopyShape) -> AnyShape {
        switch shape {
        case .round:    AnyShape(Circle())
        case .triangle: AnyShape(TriangleCanopy())
        case .teardrop: AnyShape(TeardropCanopy())
        case .cloud:    AnyShape(CloudCanopy())
        case .umbrella: AnyShape(UmbrellaCanopy())
        case .weeping:  AnyShape(WeepingCanopy())
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
