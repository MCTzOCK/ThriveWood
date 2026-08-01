import SwiftUI

public enum BentoControlSize: Sendable {
    case small
    case medium
    case large

    fileprivate func height(in theme: BentoTheme) -> CGFloat {
        switch self {
        case .small:
            theme.sizing.controlSmall
        case .medium:
            theme.sizing.controlMedium
        case .large:
            theme.sizing.controlLarge
        }
    }

    fileprivate func horizontalPadding(in theme: BentoTheme) -> CGFloat {
        switch self {
        case .small:
            theme.spacing.sm
        case .medium:
            theme.spacing.md
        case .large:
            theme.spacing.lg
        }
    }

    fileprivate var textStyle: BentoTextStyle {
        switch self {
        case .small:
            .callout
        case .medium, .large:
            .bodyStrong
        }
    }
}

public enum BentoButtonVariant: Sendable {
    case primary
    case secondary
    case tonal(BentoTone)
    case ghost
    case destructive
    case chrome
}

public enum BentoIconPlacement: Sendable {
    case leading
    case trailing
}

private struct BentoButtonVisualStyle: ButtonStyle {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let variant: BentoButtonVariant
    let size: BentoControlSize
    let expands: Bool
    let iconOnly: Bool

    private var colors: (
        background: Color,
        foreground: Color,
        border: Color
    ) {
        switch variant {
        case .primary:
            (
                theme.colors.accent,
                theme.colors.onAccent,
                theme.colors.outline
            )

        case .secondary:
            (
                theme.colors.surface,
                theme.colors.onSurface,
                theme.colors.outline
            )

        case .tonal(let tone):
            (
                theme.colors.fill(for: tone),
                theme.colors.foreground(for: tone),
                theme.colors.outline
            )

        case .ghost:
            (
                .clear,
                theme.colors.onSurface,
                .clear
            )

        case .destructive:
            (
                theme.colors.danger,
                theme.colors.onDanger,
                theme.colors.outline
            )

        case .chrome:
            (
                theme.colors.chrome,
                theme.colors.onChrome,
                theme.colors.onChrome.opacity(0.5)
            )
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let height = size.height(in: theme)
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.pill,
            style: .continuous
        )

        configuration.label
            .frame(
                maxWidth: expands && !iconOnly ? .infinity : nil
            )
            .frame(minHeight: height)
            .frame(
                width: iconOnly ? height : nil
            )
            .padding(
                .horizontal,
                iconOnly ? 0 : size.horizontalPadding(in: theme)
            )
            .foregroundStyle(colors.foreground)
            .background(colors.background, in: shape)
            .overlay {
                shape.strokeBorder(
                    colors.border,
                    lineWidth: theme.borders.regular
                )
            }
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.48)
            .scaleEffect(
                configuration.isPressed && !reduceMotion ? 0.965 : 1
            )
            .animation(
                reduceMotion ? nil : theme.motion.fast,
                value: configuration.isPressed
            )
    }
}

public struct BentoButton: View {
    private let title: Text
    private let systemImage: String?
    private let iconPlacement: BentoIconPlacement
    private let variant: BentoButtonVariant
    private let size: BentoControlSize
    private let expands: Bool
    private let isLoading: Bool
    private let role: ButtonRole?
    private let action: () -> Void

    public init(
        _ title: Text,
        systemImage: String? = nil,
        iconPlacement: BentoIconPlacement = .leading,
        variant: BentoButtonVariant = .primary,
        size: BentoControlSize = .medium,
        expands: Bool = false,
        isLoading: Bool = false,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconPlacement = iconPlacement
        self.variant = variant
        self.size = size
        self.expands = expands
        self.isLoading = isLoading
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            ZStack {
                HStack(spacing: 8) {
                    if iconPlacement == .leading, let systemImage {
                        Image(systemName: systemImage)
                            .accessibilityHidden(true)
                    }

                    title.bentoTextStyle(size.textStyle)

                    if iconPlacement == .trailing, let systemImage {
                        Image(systemName: systemImage)
                            .accessibilityHidden(true)
                    }
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .buttonStyle(
            BentoButtonVisualStyle(
                variant: variant,
                size: size,
                expands: expands,
                iconOnly: false
            )
        )
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? Text("Loading") : title)
    }
}

public struct BentoIconButton: View {
    private let systemImage: String
    private let accessibilityLabel: Text
    private let variant: BentoButtonVariant
    private let size: BentoControlSize
    private let action: () -> Void

    public init(
        systemImage: String,
        accessibilityLabel: Text,
        variant: BentoButtonVariant = .secondary,
        size: BentoControlSize = .medium,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
        }
        .buttonStyle(
            BentoButtonVisualStyle(
                variant: variant,
                size: size,
                expands: false,
                iconOnly: true
            )
        )
        .accessibilityLabel(accessibilityLabel)
    }
}

public struct BentoFloatingActionButton: View {
    @Environment(\.bentoTheme) private var theme

    private let systemImage: String
    private let accessibilityLabel: Text
    private let action: () -> Void

    public init(
        systemImage: String,
        accessibilityLabel: Text,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        BentoIconButton(
            systemImage: systemImage,
            accessibilityLabel: accessibilityLabel,
            variant: .primary,
            size: .large,
            action: action
        )
        .shadow(
            color: theme.colors.chrome.opacity(0.3),
            radius: 12,
            y: 6
        )
    }
}

public struct BentoBadge: View {
    @Environment(\.bentoTheme) private var theme

    private let text: Text
    private let tone: BentoTone
    private let systemImage: String?

    public init(
        _ text: Text,
        tone: BentoTone = .neutral,
        systemImage: String? = nil
    ) {
        self.text = text
        self.tone = tone
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }

            text.bentoTextStyle(.caption)
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .foregroundStyle(theme.colors.foreground(for: tone))
        .background(
            theme.colors.fill(for: tone),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    theme.colors.outline.opacity(0.45),
                    lineWidth: theme.borders.thin
                )
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

public struct BentoChip: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let systemImage: String?
    private let tone: BentoTone
    private let isSelected: Bool
    private let action: (() -> Void)?

    public init(
        _ title: Text,
        systemImage: String? = nil,
        tone: BentoTone = .accent,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
        self.isSelected = isSelected
        self.action = action
    }

    private var label: some View {
        HStack(spacing: theme.spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }

            title.bentoTextStyle(.callout)

            if isSelected {
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .frame(minHeight: theme.sizing.minimumTouchTarget)
        .foregroundStyle(
            isSelected
                ? theme.colors.foreground(for: tone)
                : theme.colors.onSurface
        )
        .background(
            isSelected
                ? theme.colors.fill(for: tone)
                : theme.colors.surfaceSecondary,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    theme.colors.outline,
                    lineWidth: theme.borders.thin
                )
        }
    }

    @ViewBuilder
    public var body: some View {
        if let action {
            Button(action: action) {
                label
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            label
        }
    }
}