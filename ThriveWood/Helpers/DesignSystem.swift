//
//  DesignSystem.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI

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


enum Haptics {
    enum FeedbackStyle {
        case light, medium, heavy, soft, rigid
    }
    #if os(iOS)
    static func impact(_ style: FeedbackStyle = .medium) {
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle = switch style {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
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
    #else
    static func impact(_ style: FeedbackStyle = .medium) {}
    static func success() {}
    static func warning() {}
    static func selection() {}
    #endif
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
