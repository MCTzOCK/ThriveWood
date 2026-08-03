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
        BentoButton(
            Text(title),
            systemImage: icon,
            iconPlacement: .trailing,
            variant: isSecondary ? .secondary : .primary,
            size: .large,
            expands: true,
            role: nil,
            action: action
        )
        .tint(accent.color)
    }
}

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        BentoIconButton(
            systemImage: "chevron.left",
            accessibilityLabel: Text("Zurück"),
            variant: .secondary,
            size: .medium,
            action: action
        )
    }
}
