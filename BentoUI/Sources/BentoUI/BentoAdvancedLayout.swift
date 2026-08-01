import SwiftUI

public enum BentoResponsiveAxis: Sendable {
    case horizontal
    case vertical
}

public struct BentoResponsiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.bentoTheme) private var theme

    private let compactAxis: BentoResponsiveAxis
    private let regularAxis: BentoResponsiveAxis
    private let spacing: CGFloat?
    private let horizontalAlignment: VerticalAlignment
    private let verticalAlignment: HorizontalAlignment
    private let content: Content

    public init(
        compactAxis: BentoResponsiveAxis = .vertical,
        regularAxis: BentoResponsiveAxis = .horizontal,
        spacing: CGFloat? = nil,
        horizontalAlignment: VerticalAlignment = .center,
        verticalAlignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.compactAxis = compactAxis
        self.regularAxis = regularAxis
        self.spacing = spacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.content = content()
    }

    private var resolvedAxis: BentoResponsiveAxis {
        guard horizontalSizeClass == .regular,
              !dynamicTypeSize.isAccessibilitySize else {
            return compactAxis
        }

        return regularAxis
    }

    public var body: some View {
        switch resolvedAxis {
        case .horizontal:
            HStack(
                alignment: horizontalAlignment,
                spacing: spacing ?? theme.spacing.sm
            ) {
                content
            }

        case .vertical:
            VStack(
                alignment: verticalAlignment,
                spacing: spacing ?? theme.spacing.sm
            ) {
                content
            }
        }
    }
}

// MARK: - Masonry

public struct BentoMasonryLayout: Layout {
    public typealias Cache = Void

    private let columns: Int
    private let spacing: CGFloat

    public init(
        columns: Int = 2,
        spacing: CGFloat = 8
    ) {
        self.columns = max(1, columns)
        self.spacing = max(0, spacing)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        arrangement(
            proposal: proposal,
            subviews: subviews
        ).size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let arrangement = arrangement(
            proposal: ProposedViewSize(
                width: bounds.width,
                height: proposal.height
            ),
            subviews: subviews
        )

        for (index, frame) in arrangement.frames.enumerated() {
            guard subviews.indices.contains(index) else {
                continue
            }

            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + frame.minX,
                    y: bounds.minY + frame.minY
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: frame.width,
                    height: frame.height
                )
            )
        }
    }

    private func arrangement(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> MasonryArrangement {
        guard !subviews.isEmpty else {
            return MasonryArrangement(
                size: CGSize(
                    width: max(0, proposal.width ?? 0),
                    height: 0
                ),
                frames: []
            )
        }

        let idealColumnWidth = subviews
            .map { $0.sizeThatFits(.unspecified).width }
            .max() ?? 0

        let inferredWidth =
            idealColumnWidth * CGFloat(columns)
            + spacing * CGFloat(max(0, columns - 1))

        let proposedWidth = proposal.width ?? inferredWidth

        let resolvedWidth = proposedWidth.isFinite
            ? max(0, proposedWidth)
            : max(0, inferredWidth)

        let availableSpacing =
            spacing * CGFloat(max(0, columns - 1))

        let columnWidth = max(
            0,
            (resolvedWidth - availableSpacing) / CGFloat(columns)
        )

        var columnHeights = Array(
            repeating: CGFloat.zero,
            count: columns
        )

        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)

        for subview in subviews {
            var targetColumn = 0

            if columns > 1 {
                for index in 1..<columns where
                    columnHeights[index] < columnHeights[targetColumn] {
                    targetColumn = index
                }
            }

            let measuredSize = subview.sizeThatFits(
                ProposedViewSize(
                    width: columnWidth,
                    height: nil
                )
            )

            let originX =
                CGFloat(targetColumn) * (columnWidth + spacing)

            let originY = columnHeights[targetColumn] == 0
                ? 0
                : columnHeights[targetColumn] + spacing

            let frame = CGRect(
                x: originX,
                y: originY,
                width: columnWidth,
                height: measuredSize.height
            )

            frames.append(frame)
            columnHeights[targetColumn] = frame.maxY
        }

        return MasonryArrangement(
            size: CGSize(
                width: resolvedWidth,
                height: columnHeights.max() ?? 0
            ),
            frames: frames
        )
    }
}

private struct MasonryArrangement {
    let size: CGSize
    let frames: [CGRect]
}

public struct BentoMasonryGrid<
    Item: Identifiable,
    Content: View
>: View {
    private let items: [Item]
    private let columns: Int
    private let spacing: CGFloat
    private let content: (Item) -> Content

    public init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = max(1, columns)
        self.spacing = max(0, spacing)
        self.content = content
    }

    public var body: some View {
        BentoMasonryLayout(
            columns: columns,
            spacing: spacing
        ) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

// MARK: - Carousel

public struct BentoCarousel<
    Item: Identifiable,
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let items: [Item]
    private let selection: Binding<Item.ID?>?
    private let itemWidth: CGFloat
    private let spacing: CGFloat?
    private let content: (Item) -> Content

    public init(
        items: [Item],
        selection: Binding<Item.ID?>? = nil,
        itemWidth: CGFloat = 292,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.selection = selection
        self.itemWidth = max(120, itemWidth)
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    public var body: some View {
        if let selection {
            carousel
                .scrollPosition(id: selection)
        } else {
            carousel
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(
                alignment: .top,
                spacing: spacing ?? theme.spacing.xs
            ) {
                ForEach(items) { item in
                    content(item)
                        .frame(
                            width: itemWidth,
                            alignment: .topLeading
                        )
                        .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .contentMargins(
            .horizontal,
            theme.spacing.sm,
            for: .scrollContent
        )
        .scrollTargetBehavior(.viewAligned)
    }
}

// MARK: - Sticky sections

public struct BentoStickySection<
    Header: View,
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let header: Header
    private let content: Content

    public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: theme.spacing.sm,
            pinnedViews: [.sectionHeaders]
        ) {
            Section {
                content
            } header: {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.xs)
                    .background(theme.colors.background)
            }
        }
    }
}

// MARK: - Split card

public struct BentoSplitCard<
    Leading: View,
    Trailing: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let tone: BentoTone?
    private let leading: Leading
    private let trailing: Trailing

    public init(
        tone: BentoTone? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.tone = tone
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        BentoCard(tone: tone) {
            BentoResponsiveStack(
                compactAxis: .vertical,
                regularAxis: .horizontal,
                spacing: theme.spacing.lg,
                horizontalAlignment: .top
            ) {
                leading
                    .frame(
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )

                trailing
                    .frame(
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )
            }
        }
    }
}

// MARK: - Overlay tile

public struct BentoOverlayTile<
    Background: View,
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let minimumHeight: CGFloat
    private let alignment: Alignment
    private let background: Background
    private let content: Content

    public init(
        minimumHeight: CGFloat = 220,
        alignment: Alignment = .bottomLeading,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumHeight = max(100, minimumHeight)
        self.alignment = alignment
        self.background = background()
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.large,
            style: .continuous
        )

        ZStack(alignment: alignment) {
            background
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    theme.colors.chrome.opacity(0.18),
                    theme.colors.chrome.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            content
                .padding(theme.spacing.md)
                .foregroundStyle(theme.colors.onChrome)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: minimumHeight
        )
        .background(theme.colors.surface)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                theme.colors.outline,
                lineWidth: theme.borders.regular
            )
        }
    }
}

// MARK: - Bottom action bar

public struct BentoActionBar<Content: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let content: Content

    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: theme.sizing.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.top, theme.spacing.xs)
            .padding(.bottom, theme.spacing.xs)
            .foregroundStyle(theme.colors.onChrome)
            .background {
                theme.colors.chrome
                    .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.colors.onChrome.opacity(0.14))
                    .frame(height: theme.borders.thin)
            }
    }
}

public extension View {
    func bentoActionBar<Bar: View>(
        @ViewBuilder content: () -> Bar
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            BentoActionBar {
                content()
            }
        }
    }
}