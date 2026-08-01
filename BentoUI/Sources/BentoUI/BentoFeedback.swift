import SwiftUI

public enum BentoCalloutKind: Sendable {
    case info
    case success
    case warning
    case error

    fileprivate var tone: BentoTone {
        switch self {
        case .info:
            .info
        case .success:
            .success
        case .warning:
            .warning
        case .error:
            .danger
        }
    }

    fileprivate var symbol: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .success:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }
}

public struct BentoCallout: View {
    @Environment(\.bentoTheme) private var theme

    private let kind: BentoCalloutKind
    private let title: Text
    private let message: Text?
    private let onDismiss: (() -> Void)?

    public init(
        kind: BentoCalloutKind,
        title: Text,
        message: Text? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.kind = kind
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let tone = kind.tone

        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: kind.symbol)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                title.bentoTextStyle(.bodyStrong)

                if let message {
                    message.bentoTextStyle(.callout)
                }
            }

            Spacer(minLength: theme.spacing.xs)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .frame(
                            width: theme.sizing.minimumTouchTarget,
                            height: theme.sizing.minimumTouchTarget
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Dismiss"))
            }
        }
        .padding(theme.spacing.sm)
        .foregroundStyle(theme.colors.foreground(for: tone))
        .background(
            theme.colors.fill(for: tone),
            in: RoundedRectangle(
                cornerRadius: theme.radii.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: theme.radii.medium,
                style: .continuous
            )
            .strokeBorder(
                theme.colors.outline,
                lineWidth: theme.borders.regular
            )
        }
    }
}

public struct BentoProgressBar: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let progress: Double
    private let tone: BentoTone
    private let height: CGFloat
    private let label: Text?

    public init(
        progress: Double,
        tone: BentoTone = .accent,
        height: CGFloat = 12,
        label: Text? = nil
    ) {
        self.progress = progress
        self.tone = tone
        self.height = max(4, height)
        self.label = label
    }

    private var normalizedProgress: Double {
        guard progress.isFinite else {
            return 0
        }

        return min(max(progress, 0), 1)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                HStack {
                    label.bentoTextStyle(.callout)
                    Spacer()

                    Text("\(Int((normalizedProgress * 100).rounded()))%")
                        .bentoTextStyle(.callout)
                        .contentTransition(.numericText())
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.colors.outlineSubtle)

                    Capsule()
                        .fill(theme.colors.fill(for: tone))
                        .frame(
                            width: geometry.size.width
                                * normalizedProgress
                        )
                }
            }
            .frame(height: height)
            .overlay {
                Capsule()
                    .strokeBorder(
                        theme.colors.outline,
                        lineWidth: theme.borders.thin
                    )
            }
        }
        .animation(
            reduceMotion ? nil : theme.motion.regular,
            value: normalizedProgress
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            Text("\(Int((normalizedProgress * 100).rounded())) percent")
        )
    }
}

public struct BentoProgressRing: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let progress: Double
    private let tone: BentoTone
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let label: Text?

    public init(
        progress: Double,
        tone: BentoTone = .accent,
        size: CGFloat = 104,
        lineWidth: CGFloat = 12,
        label: Text? = nil
    ) {
        self.progress = progress
        self.tone = tone
        self.size = max(44, size)
        self.lineWidth = max(3, lineWidth)
        self.label = label
    }

    private var normalizedProgress: Double {
        guard progress.isFinite else {
            return 0
        }

        return min(max(progress, 0), 1)
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    theme.colors.outlineSubtle,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(
                    theme.colors.fill(for: tone),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            if let label {
                label.bentoTextStyle(.headline)
            } else {
                Text("\(Int((normalizedProgress * 100).rounded()))%")
                    .bentoTextStyle(.headline)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .animation(
            reduceMotion ? nil : theme.motion.regular,
            value: normalizedProgress
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(
            Text("\(Int((normalizedProgress * 100).rounded())) percent")
        )
    }
}

public struct BentoSpinner: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat
    private let color: Color?

    public init(
        size: CGFloat = 28,
        color: Color? = nil
    ) {
        self.size = max(16, size)
        self.color = color
    }

    public var body: some View {
        Group {
            if reduceMotion {
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        color ?? theme.colors.accent,
                        style: StrokeStyle(
                            lineWidth: max(2, size * 0.12),
                            lineCap: .round
                        )
                    )
            } else {
                TimelineView(.animation) { context in
                    let seconds = context.date
                        .timeIntervalSinceReferenceDate
                    let rotation = seconds
                        .truncatingRemainder(dividingBy: 0.85)
                        / 0.85
                        * 360

                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            color ?? theme.colors.accent,
                            style: StrokeStyle(
                                lineWidth: max(2, size * 0.12),
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(rotation))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("Loading"))
    }
}

public struct BentoSkeleton: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let height: CGFloat
    private let radius: BentoRadius

    public init(
        height: CGFloat = 18,
        radius: BentoRadius = .small
    ) {
        self.height = max(4, height)
        self.radius = radius
    }

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.value(radius),
            style: .continuous
        )

        Group {
            if reduceMotion || reduceTransparency {
                shape.fill(theme.colors.surfaceSecondary)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    GeometryReader { geometry in
                        let seconds = context.date
                            .timeIntervalSinceReferenceDate
                        let phase = seconds
                            .truncatingRemainder(dividingBy: 1.35)
                            / 1.35

                        shape
                            .fill(theme.colors.surfaceSecondary)
                            .overlay {
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        theme.colors.surface.opacity(0.8),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.7)
                                .offset(
                                    x: -geometry.size.width
                                        + geometry.size.width
                                        * CGFloat(phase)
                                        * 2
                                )
                            }
                            .clipShape(shape)
                    }
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

public struct BentoEmptyState: View {
    @Environment(\.bentoTheme) private var theme

    private let systemImage: String
    private let title: Text
    private let message: Text
    private let actionTitle: Text?
    private let action: (() -> Void)?

    public init(
        systemImage: String,
        title: Text,
        message: Text,
        actionTitle: Text? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(theme.colors.accent)
                .accessibilityHidden(true)

            VStack(spacing: theme.spacing.xs) {
                title
                    .bentoTextStyle(.title3)
                    .multilineTextAlignment(.center)

                message
                    .bentoTextStyle(
                        .callout,
                        color: theme.colors.onSurfaceMuted
                    )
                    .multilineTextAlignment(.center)
            }

            if let action, let actionTitle {
                BentoButton(
                    actionTitle,
                    variant: .primary,
                    action: action
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xl)
    }
}

// MARK: - Toasts

public struct BentoToastData: Identifiable {
    public enum Kind {
        case info
        case success
        case warning
        case error
    }

    public let id: UUID
    public let kind: Kind
    public let title: Text
    public let message: Text?
    public let duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: Text,
        message: Text? = nil,
        duration: TimeInterval? = 3
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.duration = duration
    }
}

private extension BentoToastData.Kind {
    var calloutKind: BentoCalloutKind {
        switch self {
        case .info:
            .info
        case .success:
            .success
        case .warning:
            .warning
        case .error:
            .error
        }
    }
}

private struct BentoToastView: View {
    let toast: BentoToastData
    let onDismiss: () -> Void

    var body: some View {
        BentoCallout(
            kind: toast.kind.calloutKind,
            title: toast.title,
            message: toast.message,
            onDismiss: onDismiss
        )
    }
}

private struct BentoToastPresenterModifier: ViewModifier {
    @Environment(\.bentoTheme) private var theme
    @Binding var toast: BentoToastData?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    BentoToastView(toast: toast) {
                        dismiss(toast)
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.xs)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                    .zIndex(1_000)
                    .task(id: toast.id) {
                        guard let duration = toast.duration,
                              duration > 0 else {
                            return
                        }

                        do {
                            try await ContinuousClock()
                                .sleep(for: .seconds(duration))
                        } catch {
                            return
                        }

                        guard !Task.isCancelled,
                              self.toast?.id == toast.id else {
                            return
                        }

                        dismiss(toast)
                    }
                }
            }
            .animation(theme.motion.snappy, value: toast?.id)
    }

    private func dismiss(_ toast: BentoToastData) {
        guard self.toast?.id == toast.id else {
            return
        }

        withAnimation(theme.motion.snappy) {
            self.toast = nil
        }
    }
}

private struct BentoLoadingModifier: ViewModifier {
    @Environment(\.bentoTheme) private var theme

    let isLoading: Bool
    let label: Text

    func body(content: Content) -> some View {
        content
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ZStack {
                        theme.colors.chrome.opacity(0.25)
                            .contentShape(Rectangle())

                        BentoCard(
                            style: .elevated,
                            padding: .md,
                            radius: .medium
                        ) {
                            HStack(spacing: theme.spacing.sm) {
                                BentoSpinner()
                                label.bentoTextStyle(.bodyStrong)
                            }
                            .fixedSize()
                        }
                        .frame(maxWidth: 220)
                    }
                    .transition(.opacity)
                }
            }
            .animation(theme.motion.fast, value: isLoading)
    }
}

public extension View {
    func bentoToast(
        _ toast: Binding<BentoToastData?>
    ) -> some View {
        modifier(
            BentoToastPresenterModifier(toast: toast)
        )
    }

    func bentoLoading(
        _ isLoading: Bool,
        label: Text = Text("Loading")
    ) -> some View {
        modifier(
            BentoLoadingModifier(
                isLoading: isLoading,
                label: label
            )
        )
    }
}