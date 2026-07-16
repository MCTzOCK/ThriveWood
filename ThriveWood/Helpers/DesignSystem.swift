//
//  DesignSystem.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//

import SwiftUI

// MARK: - Core Theme

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    enum Radius {
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 28
        static let pill: CGFloat = 100
    }

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .heavy, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
        static let subheadline = Font.system(size: 14, weight: .medium, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
        static let mono = Font.system(size: 16, weight: .semibold, design: .monospaced)
        static let monoLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
    }

    enum Shadow {
        static let card = Color.black.opacity(0.06)
        static let cardStrong = Color.black.opacity(0.12)
        static let cardSoft = Color.black.opacity(0.03)
        static let glow = Color.white.opacity(0.15)
    }

    enum Surface {
        static let primary = Color(.systemBackground)
        static let secondary = Color(.secondarySystemBackground)
        static let grouped = Color(.systemGroupedBackground)
        static let groupedSecondary = Color(.secondarySystemGroupedBackground)
        static let card = Color(.secondarySystemGroupedBackground)
    }

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.78)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.65)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.82)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - Haptics

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

// MARK: - Error State

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

// MARK: - Premium Card

struct GlassCard<Content: View>: View {
    var radius: CGFloat = Theme.Radius.l
    var padding: CGFloat = Theme.Spacing.l
    var bgColor: Color? = nil
    @Environment(\.colorScheme) private var scheme
    let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(bgColor ?? Color(.secondarySystemGroupedBackground))
            )
    }
}

// MARK: - Gradient Card Background

struct GradientCardBackground: View {
    var baseColor: Color
    var radius: CGFloat = Theme.Radius.l
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        baseColor.opacity(scheme == .dark ? 0.25 : 0.12),
                        baseColor.opacity(scheme == .dark ? 0.08 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(baseColor.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Premium Button Styles

struct BounceButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var opacity: Double = 1.0
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(Theme.Animation.springSnappy, value: configuration.isPressed)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Theme.Animation.springSnappy, value: configuration.isPressed)
    }
}

struct ShimmerButtonStyle: ButtonStyle {
    var baseColor: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailingView: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let trailingView { trailingView }
        }
    }
}

// MARK: - Pill Badge

struct PillBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = .accentColor
    var bgColor: Color? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(Theme.Typography.caption)
            }
            Text(text)
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs + 1)
        .background(
            Capsule()
                .fill(bgColor ?? color.opacity(0.12))
        )
        .foregroundStyle(color)
    }
}

// MARK: - Gradient Text

struct GradientText: View {
    let text: String
    var colors: [Color]
    var font: Font = Theme.Typography.title

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Empty State View

struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
                .padding(.bottom, Theme.Spacing.s)

            Text(title)
                .font(Theme.Typography.title3)
                .foregroundStyle(.primary)

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            if let actionTitle, let action {
                Button {
                    Haptics.impact(.light)
                    action()
                } label: {
                    Text(actionTitle)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.m)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(BounceButtonStyle())
                .padding(.top, Theme.Spacing.s)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
    }
}

// MARK: - Stat Pill (inline stats)

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .accentColor

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(Theme.Typography.body)
                .foregroundStyle(color)
            Text(value)
                .font(Theme.Typography.mono)
                .foregroundStyle(.primary)
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Animated Number Text

struct AnimatedNumberText: View {
    let value: Double
    var format: String = "%.0f"
    var font: Font = Theme.Typography.monoLarge
    var color: Color = .primary

    @State private var displayValue: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        Text(String(format: format, value))
            .font(font)
            .foregroundStyle(color)
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
            }
    }
}

// MARK: - Soft Background Modifier

struct SoftBackground: ViewModifier {
    var color: Color = Color(.secondarySystemGroupedBackground)
    var radius: CGFloat = Theme.Radius.m

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
            )
    }
}

extension View {
    func softBackground(_ color: Color = Color(.secondarySystemGroupedBackground), radius: CGFloat = Theme.Radius.m) -> some View {
        modifier(SoftBackground(color: color, radius: radius))
    }

    func glassCard(radius: CGFloat = Theme.Radius.l, padding: CGFloat = Theme.Spacing.l, bgColor: Color? = nil) -> some View {
        GlassCard(radius: radius, padding: padding, bgColor: bgColor) { self }
    }

    func bounceButton() -> some View {
        buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Custom Segmented Picker

struct PremiumSegmentedPicker<T: Hashable, Label: View>: View {
    @Binding var selection: T
    let options: [T]
    @ViewBuilder let label: (T) -> Label
    @Namespace private var ns

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(options, id: \.self) { option in
                Button {
                    Haptics.selection()
                    withAnimation(Theme.Animation.springSnappy) {
                        selection = option
                    }
                } label: {
                    HStack {
                        label(option)
                    }
                    .font(Theme.Typography.subheadline)
                    .fontWeight(selection == option ? .bold : .medium)
                    .foregroundStyle(selection == option ? Color.white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.s + 2)
                    .background {
                        if selection == option {
                            Capsule()
                                .fill(Color.accentColor)
                                .matchedGeometryEffect(id: "picker", in: ns)
                        }
                    }
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .padding(Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Custom Divider

struct PremiumDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 0.5)
    }
}

// MARK: - Toolbar Title Display

struct LargeTitleHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
