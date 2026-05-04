//
//  ProgressRing.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(colors: [.accentColor, .mint, .accentColor],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
    }
}
