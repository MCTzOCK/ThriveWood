import SwiftUI

// MARK: - Dialog

public struct BentoDialogAction: Identifiable {
    public let id: UUID
    public let title: Text
    public let systemImage: String?
    public let variant: BentoButtonVariant
    public let role: ButtonRole?
    public let action: () -> Void

    public init(
        id: UUID = UUID(),
        title: Text,
        systemImage: String? = nil,
        variant: BentoButtonVariant = .secondary,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.role = role
        self.action = action
    }
}

private struct BentoDialogPresentation: View {
    @Environment(\.bentoTheme) private var theme

    let systemImage: String?
    let title: Text
    let message: Text?
    let actions: [BentoDialogAction]
    let dismiss: () -> Void

    var body: some View {
        BentoCard(
            style: .elevated,
            padding: .lg,
            radius: .extraLarge
        ) {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.md
            ) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(theme.colors.accent)
                        .accessibilityHidden(true)
                }

                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.xs
                ) {
                    title.bentoTextStyle(.title2)

                    if let message {
                        message.bentoTextStyle(
                            .body,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                }

                VStack(spacing: theme.spacing.xs) {
                    ForEach(actions) { action in
                        BentoButton(
                            action.title,
                            systemImage: action.systemImage,
                            variant: action.variant,
                            expands: true,
                            role: action.role
                        ) {
                            dismiss()
                            action.action()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 420)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

private struct BentoDialogModifier: ViewModifier {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var isPresented: Bool

    let systemImage: String?
    let title: Text
    let message: Text?
    let actions: [BentoDialogAction]
    let dismissesOnBackgroundTap: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .accessibilityHidden(isPresented)

            if isPresented {
                theme.colors.chrome
                    .opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture {
                        guard dismissesOnBackgroundTap else {
                            return
                        }

                        dismiss()
                    }

                ScrollView {
                    BentoDialogPresentation(
                        systemImage: systemImage,
                        title: title,
                        message: message,
                        actions: actions,
                        dismiss: dismiss
                    )
                    .padding(theme.spacing.md)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 500,
                        alignment: .center
                    )
                }
                .scrollBounceBehavior(.basedOnSize)
                .transition(
                    .scale(scale: 0.94)
                    .combined(with: .opacity)
                )
                .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? nil : theme.motion.snappy,
            value: isPresented
        )
    }

    private func dismiss() {
        withAnimation(
            reduceMotion ? nil : theme.motion.snappy
        ) {
            isPresented = false
        }
    }
}

public extension View {
    func bentoDialog(
        isPresented: Binding<Bool>,
        systemImage: String? = nil,
        title: Text,
        message: Text? = nil,
        actions: [BentoDialogAction],
        dismissesOnBackgroundTap: Bool = true
    ) -> some View {
        modifier(
            BentoDialogModifier(
                isPresented: isPresented,
                systemImage: systemImage,
                title: title,
                message: message,
                actions: actions,
                dismissesOnBackgroundTap:
                    dismissesOnBackgroundTap
            )
        )
    }
}

// MARK: - Bottom sheet

public struct BentoBottomSheet<Content: View>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let title: Text?
    private let subtitle: Text?
    private let showsCloseButton: Bool
    private let content: Content

    public init(
        title: Text? = nil,
        subtitle: Text? = nil,
        showsCloseButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsCloseButton = showsCloseButton
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.colors.outlineSubtle)
                .frame(width: 42, height: 5)
                .padding(.top, theme.spacing.xs)
                .padding(.bottom, theme.spacing.sm)
                .accessibilityHidden(true)

            if title != nil || subtitle != nil || showsCloseButton {
                HStack(alignment: .top, spacing: theme.spacing.sm) {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.xxs
                    ) {
                        if let title {
                            title.bentoTextStyle(.title2)
                        }

                        if let subtitle {
                            subtitle.bentoTextStyle(
                                .callout,
                                color: theme.colors.onSurfaceMuted
                            )
                        }
                    }

                    Spacer()

                    if showsCloseButton {
                        BentoIconButton(
                            systemImage: "xmark",
                            accessibilityLabel: Text("Close"),
                            variant: .secondary,
                            size: .small
                        ) {
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.bottom, theme.spacing.md)
            }

            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .foregroundStyle(theme.colors.onBackground)
        .background(theme.colors.background)
    }
}

private struct BentoSheetModifier<
    SheetContent: View
>: ViewModifier {
    @Environment(\.bentoTheme) private var theme

    @Binding var isPresented: Bool

    let title: Text?
    let subtitle: Text?
    let showsCloseButton: Bool
    let detents: Set<PresentationDetent>
    let interactiveDismissDisabled: Bool
    let sheetContent: () -> SheetContent

    private var resolvedDetents: Set<PresentationDetent> {
        detents.isEmpty ? [.large] : detents
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            BentoBottomSheet(
                title: title,
                subtitle: subtitle,
                showsCloseButton: showsCloseButton
            ) {
                sheetContent()
            }
            .environment(\.bentoTheme, theme)
            .presentationDetents(resolvedDetents)
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(
                theme.radii.extraLarge
            )
            .presentationBackground(
                theme.colors.background
            )
            .interactiveDismissDisabled(
                interactiveDismissDisabled
            )
        }
    }
}

public extension View {
    func bentoSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        title: Text? = nil,
        subtitle: Text? = nil,
        showsCloseButton: Bool = true,
        detents: Set<PresentationDetent> = [
            .medium,
            .large
        ],
        interactiveDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            BentoSheetModifier(
                isPresented: isPresented,
                title: title,
                subtitle: subtitle,
                showsCloseButton: showsCloseButton,
                detents: detents,
                interactiveDismissDisabled:
                    interactiveDismissDisabled,
                sheetContent: content
            )
        )
    }
}

// MARK: - Tooltip

private struct BentoTooltipModifier<
    TooltipContent: View
>: ViewModifier {
    @Environment(\.bentoTheme) private var theme

    @Binding var isPresented: Bool

    let arrowEdge: Edge
    let tooltipContent: () -> TooltipContent

    func body(content: Content) -> some View {
        content.popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: arrowEdge
        ) {
            BentoCard(
                style: .elevated,
                padding: .sm,
                radius: .medium
            ) {
                tooltipContent()
            }
            .frame(maxWidth: 280)
            .padding(theme.spacing.xs)
            .presentationCompactAdaptation(.popover)
        }
    }
}

public extension View {
    func bentoTooltip<TooltipContent: View>(
        isPresented: Binding<Bool>,
        arrowEdge: Edge = .top,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        modifier(
            BentoTooltipModifier(
                isPresented: isPresented,
                arrowEdge: arrowEdge,
                tooltipContent: content
            )
        )
    }
}

// MARK: - Snackbar

public struct BentoSnackbarData: Identifiable {
    public let id: UUID
    public let title: Text
    public let message: Text?
    public let tone: BentoTone
    public let systemImage: String?
    public let actionTitle: Text?
    public let duration: TimeInterval?
    public let action: (() -> Void)?

    public init(
        id: UUID = UUID(),
        title: Text,
        message: Text? = nil,
        tone: BentoTone = .neutral,
        systemImage: String? = nil,
        actionTitle: Text? = nil,
        duration: TimeInterval? = 4,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.duration = duration
        self.action = action
    }
}

private extension BentoTone {
    var defaultSnackbarSystemImage: String {
        switch self {
        case .success, .green:
            "checkmark.circle.fill"

        case .warning, .yellow:
            "exclamationmark.triangle.fill"

        case .danger, .pink:
            "xmark.octagon.fill"

        case .info, .blue:
            "info.circle.fill"

        case .accent:
            "sparkles"

        case .neutral:
            "bell.fill"
        }
    }
}

private struct BentoSnackbarView: View {
    @Environment(\.bentoTheme) private var theme

    let snackbar: BentoSnackbarData
    let dismiss: () -> Void

    var body: some View {
        BentoCard(
            tone: snackbar.tone,
            style: .elevated,
            padding: .sm,
            radius: .medium
        ) {
            HStack(
                alignment: .center,
                spacing: theme.spacing.sm
            ) {
                Image(
                    systemName: snackbar.systemImage
                        ?? snackbar.tone
                        .defaultSnackbarSystemImage
                )
                .font(.headline)
                .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.xxs
                ) {
                    snackbar.title.bentoTextStyle(.bodyStrong)

                    if let message = snackbar.message {
                        message.bentoTextStyle(.caption)
                    }
                }

                Spacer(minLength: theme.spacing.xs)

                if let actionTitle = snackbar.actionTitle,
                   let action = snackbar.action {
                    Button {
                        action()
                        dismiss()
                    } label: {
                        actionTitle
                            .bentoTextStyle(.callout)
                            .underline()
                            .frame(
                                minHeight:
                                    theme.sizing.minimumTouchTarget
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: dismiss) {
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
    }
}

private struct BentoSnackbarModifier: ViewModifier {
    @Environment(\.bentoTheme) private var theme

    @Binding var snackbar: BentoSnackbarData?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let snackbar {
                BentoSnackbarView(
                    snackbar: snackbar
                ) {
                    dismiss(snackbar)
                }
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, theme.spacing.sm)
                .transition(
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                )
                .task(id: snackbar.id) {
                    guard let duration = snackbar.duration,
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
                          self.snackbar?.id == snackbar.id else {
                        return
                    }

                    dismiss(snackbar)
                }
            }
        }
        .animation(
            theme.motion.snappy,
            value: snackbar?.id
        )
    }

    private func dismiss(
        _ snackbar: BentoSnackbarData
    ) {
        guard self.snackbar?.id == snackbar.id else {
            return
        }

        withAnimation(theme.motion.snappy) {
            self.snackbar = nil
        }
    }
}

public extension View {
    func bentoSnackbar(
        _ snackbar: Binding<BentoSnackbarData?>
    ) -> some View {
        modifier(
            BentoSnackbarModifier(snackbar: snackbar)
        )
    }
}