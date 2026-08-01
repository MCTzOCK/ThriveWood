import SwiftUI

public enum BentoCardStyle: Sendable {
    case flat
    case outlined
    case elevated
}

public enum BentoDividerOrientation: Sendable {
    case horizontal
    case vertical
}

public struct BentoScreen<Content: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let scrolls: Bool
    private let showsIndicators: Bool
    private let horizontalPadding: BentoSpace
    private let verticalPadding: BentoSpace
    private let content: Content

    public init(
        scrolls: Bool = true,
        showsIndicators: Bool = false,
        horizontalPadding: BentoSpace = .sm,
        verticalPadding: BentoSpace = .sm,
        @ViewBuilder content: () -> Content
    ) {
        self.scrolls = scrolls
        self.showsIndicators = showsIndicators
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    public var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            if scrolls {
                ScrollView(showsIndicators: showsIndicators) {
                    content
                        .frame(maxWidth: theme.sizing.contentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(
                            .horizontal,
                            theme.spacing.value(horizontalPadding)
                        )
                        .padding(
                            .vertical,
                            theme.spacing.value(verticalPadding)
                        )
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                content
                    .frame(
                        maxWidth: theme.sizing.contentMaxWidth,
                        maxHeight: .infinity,
                        alignment: .top
                    )
                    .frame(maxWidth: .infinity)
                    .padding(
                        .horizontal,
                        theme.spacing.value(horizontalPadding)
                    )
                    .padding(
                        .vertical,
                        theme.spacing.value(verticalPadding)
                    )
            }
        }
        .foregroundStyle(theme.colors.onBackground)
    }
}

public struct BentoCard<Content: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let tone: BentoTone?
    private let customBackground: Color?
    private let customForeground: Color?
    private let style: BentoCardStyle
    private let padding: BentoSpace
    private let radius: BentoRadius
    private let content: Content

    public init(
        tone: BentoTone? = nil,
        background: Color? = nil,
        foreground: Color? = nil,
        style: BentoCardStyle = .outlined,
        padding: BentoSpace = .md,
        radius: BentoRadius = .large,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.customBackground = background
        self.customForeground = foreground
        self.style = style
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    private var backgroundColor: Color {
        if let customBackground {
            return customBackground
        }

        if let tone {
            return theme.colors.fill(for: tone)
        }

        return theme.colors.surface
    }

    private var foregroundColor: Color {
        if let customForeground {
            return customForeground
        }

        if let tone {
            return theme.colors.foreground(for: tone)
        }

        return theme.colors.onSurface
    }

    private var borderWidth: CGFloat {
        switch style {
        case .flat:
            0
        case .outlined:
            theme.borders.regular
        case .elevated:
            theme.borders.thin
        }
    }

    private var borderColor: Color {
        switch style {
        case .flat:
            .clear
        case .outlined:
            theme.colors.outline
        case .elevated:
            theme.colors.outlineSubtle
        }
    }

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.value(radius),
            style: .continuous
        )

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing.value(padding))
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: shape)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    borderColor,
                    lineWidth: borderWidth
                )
            }
            .shadow(
                color: style == .elevated
                    ? theme.colors.chrome.opacity(0.22)
                    : .clear,
                radius: style == .elevated ? 14 : 0,
                x: 0,
                y: style == .elevated ? 7 : 0
            )
    }
}

public struct BentoTile<Content: View>: View {
    private let tone: BentoTone
    private let minimumHeight: CGFloat
    private let style: BentoCardStyle
    private let alignment: Alignment
    private let content: Content

    public init(
        tone: BentoTone,
        minimumHeight: CGFloat = 160,
        style: BentoCardStyle = .outlined,
        alignment: Alignment = .topLeading,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.minimumHeight = minimumHeight
        self.style = style
        self.alignment = alignment
        self.content = content()
    }

    public var body: some View {
        BentoCard(
            tone: tone,
            style: style,
            padding: .md
        ) {
            content
                .frame(
                    maxWidth: .infinity,
                    minHeight: minimumHeight,
                    alignment: alignment
                )
        }
    }
}

public struct BentoSectionHeader<Trailing: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let trailing: Trailing

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                title.bentoTextStyle(.title3)

                if let subtitle {
                    subtitle.bentoTextStyle(
                        .callout,
                        color: theme.colors.onSurfaceMuted
                    )
                }
            }

            Spacer(minLength: theme.spacing.sm)
            trailing
        }
    }
}

public extension BentoSectionHeader where Trailing == EmptyView {
    init(
        title: Text,
        subtitle: Text? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle
        ) {
            EmptyView()
        }
    }
}

public struct BentoSection<Content: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let content: Content

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            BentoSectionHeader(
                title: title,
                subtitle: subtitle
            )

            content
        }
    }
}

public struct BentoDivider: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    private let orientation: BentoDividerOrientation
    private let color: Color?

    public init(
        orientation: BentoDividerOrientation = .horizontal,
        color: Color? = nil
    ) {
        self.orientation = orientation
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color ?? theme.colors.outlineSubtle)
            .frame(
                width: orientation == .vertical
                    ? max(1 / displayScale, theme.borders.thin)
                    : nil,
                height: orientation == .horizontal
                    ? max(1 / displayScale, theme.borders.thin)
                    : nil
            )
            .accessibilityHidden(true)
    }
}

public struct BentoAdaptiveGrid<Content: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let minimumItemWidth: CGFloat
    private let content: Content

    public init(
        minimumItemWidth: CGFloat = 160,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = max(80, minimumItemWidth)
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(minimum: minimumItemWidth),
                    spacing: theme.spacing.xs,
                    alignment: .top
                )
            ],
            alignment: .leading,
            spacing: theme.spacing.xs
        ) {
            content
        }
    }
}

public struct BentoFlowLayout: Layout {
    public typealias Cache = Void

    private let spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = max(0, spacing)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else {
            return .zero
        }

        let availableWidth = max(
            0,
            proposal.width ?? CGFloat.greatestFiniteMagnitude
        )

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maximumLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > availableWidth {
                maximumLineWidth = max(maximumLineWidth, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        maximumLineWidth = max(maximumLineWidth, max(0, x - spacing))

        return CGSize(
            width: proposal.width.map {
                min($0, maximumLineWidth)
            } ?? maximumLineWidth,
            height: y + rowHeight
        )
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX,
               x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: size.width,
                    height: size.height
                )
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}