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
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Freies Training").font(.headline).foregroundStyle(.white)
                    Text("Ohne Plan loslegen").font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
            }
            .padding(Theme.Spacing.l)
            .background(
                LinearGradient(colors: [.accentColor, .mint],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }
}
