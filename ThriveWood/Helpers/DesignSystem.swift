//
//  DesignSystem.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI

extension HabitColor {
    var color: Color {
        switch self {
        case .green:  .green
        case .mint:   .mint
        case .teal:   .teal
        case .blue:   .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink:   .pink
        case .red:    .red
        case .orange: .orange
        case .yellow: .yellow
        case .brown:  .brown
        case .gray:   .gray
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    enum Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
    }
    enum Shadow {
        static let card = Color.black.opacity(0.06)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: Theme.Shadow.card, radius: 8, x: 0, y: 2)
    }
}

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

@Observable
final class ErrorState {
    var message: String?
    var isPresented: Bool = false

    func show(_ error: Error) {
        message = error.localizedDescription
        isPresented = true
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Bindable var state: ErrorState
    func body(content: Content) -> some View {
        content.alert("Fehler", isPresented: $state.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.message ?? "Unbekannter Fehler.")
        }
    }
}

extension View {
    func errorAlert(_ state: ErrorState) -> some View {
        modifier(ErrorAlertModifier(state: state))
    }
}
