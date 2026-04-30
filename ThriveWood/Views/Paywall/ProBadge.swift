//
//  ProBadge.swift
//  ThriveWood
//
//  Created by Ben Siebert on 29.04.26.
//
import SwiftUI

struct ProBadge: ViewModifier {
    @Environment(AppEnvironment.self) private var env

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            if !env.entitlements.isPro {
                Text("PRO")
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.gradient))
                    .foregroundStyle(.white)
                    .offset(x: 4, y: -4)
            }
        }
    }
}

extension View {
    func proBadge() -> some View { modifier(ProBadge()) }
    func proBadgeCond(condition: Bool) -> some View {
        if condition {
            return AnyView(modifier(ProBadge()))
        } else {
            return AnyView(self)
        }
    }
}
