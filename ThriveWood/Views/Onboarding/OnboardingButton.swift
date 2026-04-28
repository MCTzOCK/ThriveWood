//
//  OnboardingButton.swift
//  ThriveWood
//
//  Created by Ben Siebert on 28.04.26.
//


import SwiftUI

struct OnboardingButton: View {
    let title: String
    let accent: AccentTheme
    var icon: String? = nil
    let action: () -> Void
    var isSecondary: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.headline)
                if let icon {
                    Image(systemName: icon).font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(
                    isSecondary
                    ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                    : AnyShapeStyle(accent.color.gradient)
                )
            )
            .foregroundStyle(isSecondary ? .secondary : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.headline)
                .frame(width: 52, height: 52)
                .background(
                    Circle().fill(Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
