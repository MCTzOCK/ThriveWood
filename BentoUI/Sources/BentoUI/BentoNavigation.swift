import SwiftUI

public struct BentoPageHeader<Trailing: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let eyebrow: Text?
    private let title: Text
    private let subtitle: Text?
    private let trailing: Trailing

    public init(
        eyebrow: Text? = nil,
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let eyebrow {
                    eyebrow
                        .bentoTextStyle(.overline)
                        .textCase(.uppercase)
                }

                title.bentoTextStyle(.title1)

                if let subtitle {
                    subtitle
                        .bentoTextStyle(.callout)
                        .opacity(0.72)
                }
            }

            Spacer(minLength: theme.spacing.sm)
            trailing
        }
    }
}

public extension BentoPageHeader where Trailing == EmptyView {
    init(
        eyebrow: Text? = nil,
        title: Text,
        subtitle: Text? = nil
    ) {
        self.init(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle
        ) {
            EmptyView()
        }
    }
}

public struct BentoTabItem<Selection: Hashable>: Identifiable {
    public let id: Selection
    public let title: Text
    public let systemImage: String
    public let badge: Int?

    public init(
        id: Selection,
        title: Text,
        systemImage: String,
        badge: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.badge = badge
    }
}

public struct BentoTabBar<Selection: Hashable>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var selectionNamespace

    @Binding private var selection: Selection
    private let items: [BentoTabItem<Selection>]
    private let showsLabels: Bool

    public init(
        selection: Binding<Selection>,
        items: [BentoTabItem<Selection>],
        showsLabels: Bool = false
    ) {
        self._selection = selection
        self.items = items
        self.showsLabels = showsLabels
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(items) { item in
                let isSelected = item.id == selection

                Button {
                    withAnimation(
                        reduceMotion ? nil : theme.motion.snappy
                    ) {
                        selection = item.id
                    }
                } label: {
                    VStack(spacing: theme.spacing.xxs) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 30, height: 28)

                            if let badge = item.badge, badge > 0 {
                                Text(verbatim: badge > 99 ? "99+" : "\(badge)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(theme.colors.onDanger)
                                    .padding(.horizontal, 5)
                                    .frame(minHeight: 17)
                                    .background(
                                        theme.colors.danger,
                                        in: Capsule()
                                    )
                                    .offset(x: 8, y: -5)
                            }
                        }

                        if showsLabels {
                            item.title
                                .bentoTextStyle(.caption)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(
                        minHeight: theme.sizing.tabBarHeight - 18
                    )
                    .foregroundStyle(
                        isSelected
                            ? theme.colors.onSurface
                            : theme.colors.onChrome.opacity(0.8)
                    )
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(theme.colors.surface)
                                .matchedGeometryEffect(
                                    id: "selected-tab",
                                    in: selectionNamespace
                                )
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.chrome)
        .animation(
            reduceMotion ? nil : theme.motion.snappy,
            value: selection
        )
    }
}

public struct BentoTabScaffold<
    Selection: Hashable,
    Content: View
>: View {
    @Binding private var selection: Selection

    private let items: [BentoTabItem<Selection>]
    private let showsLabels: Bool
    private let content: Content

    public init(
        selection: Binding<Selection>,
        items: [BentoTabItem<Selection>],
        showsLabels: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self.items = items
        self.showsLabels = showsLabels
        self.content = content()
    }

    @Environment(\.bentoTheme) private var theme
    @State private var lastSelection: Selection?

    private var isMovingForward: Bool {
        guard let last = lastSelection,
              let oldIndex = items.firstIndex(where: { $0.id == last }),
              let newIndex = items.firstIndex(where: { $0.id == selection })
        else {
            return true
        }
        return newIndex >= oldIndex
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            content
                .id(selection)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: isMovingForward ? .trailing : .leading),
                        removal: .move(edge: isMovingForward ? .leading : .trailing)
                    )
                )
                .clipped()
                .padding(.bottom, theme.sizing.tabBarHeight)

            BentoTabBar(
                selection: $selection,
                items: items,
                showsLabels: showsLabels
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .background(theme.colors.background)
        .onChange(of: selection) { oldValue, _ in
            lastSelection = oldValue
        }
    }
}