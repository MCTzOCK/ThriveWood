//
//  OrganisationCard.swift
//  ThriveWood
//
//  Created by Ben Siebert on 14.06.26.
//
import SwiftUI

struct OrganisationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(iconColor.gradient)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}
