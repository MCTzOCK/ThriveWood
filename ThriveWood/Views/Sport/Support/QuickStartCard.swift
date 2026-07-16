//
//  QuickStartCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct QuickStartCard: View {
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Freies Training")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                    Text("Sofort loslegen")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        }
        .buttonStyle(BounceButtonStyle())
    }
}
