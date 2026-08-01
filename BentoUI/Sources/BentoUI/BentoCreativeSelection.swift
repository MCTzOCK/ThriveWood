import SwiftUI

// MARK: - Choice grid

public enum BentoChoiceGridBehavior:
    Sendable {
    case single(allowsEmpty: Bool)
    case multiple(maximum: Int?)
}

public struct BentoChoiceGrid<
    Item: Identifiable,
    Content: View
>: View where Item.ID: Hashable {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selection: Set<Item.ID>

    private let items: [Item]
    private let behavior: BentoChoiceGridBehavior
    private let minimumItemWidth: CGFloat
    private let minimumItemHeight: CGFloat
    private let tone: (Item) -> BentoTone
    private let accessibilityLabel: (Item) -> Text
    private let content:
        (Item, Bool) -> Content

    public init(
        items: [Item],
        selection: Binding<Set<Item.ID>>,
        behavior: BentoChoiceGridBehavior =
            .multiple(maximum: nil),
        minimumItemWidth: CGFloat = 150,
        minimumItemHeight: CGFloat = 140,
        tone: @escaping (Item) -> BentoTone,
        accessibilityLabel:
            @escaping (Item) -> Text,
        @ViewBuilder content:
            @escaping (Item, Bool) -> Content
    ) {
        self.items = items
        self._selection = selection
        self.behavior = behavior
        self.minimumItemWidth = max(
            110,
            minimumItemWidth
        )
        self.minimumItemHeight = max(
            80,
            minimumItemHeight
        )
        self.tone = tone
        self.accessibilityLabel =
            accessibilityLabel
        self.content = content
    }

    public init(
        items: [Item],
        selection: Binding<Item.ID?>,
        allowsEmpty: Bool = false,
        minimumItemWidth: CGFloat = 150,
        minimumItemHeight: CGFloat = 140,
        tone: @escaping (Item) -> BentoTone,
        accessibilityLabel:
            @escaping (Item) -> Text,
        @ViewBuilder content:
            @escaping (Item, Bool) -> Content
    ) {
        self.items = items

        self._selection = Binding(
            get: {
                guard let selectedID =
                        selection.wrappedValue else {
                    return []
                }

                return [selectedID]
            },
            set: { newSelection in
                selection.wrappedValue =
                    items.first {
                        newSelection.contains($0.id)
                    }?.id
            }
        )

        self.behavior = .single(
            allowsEmpty: allowsEmpty
        )

        self.minimumItemWidth = max(
            110,
            minimumItemWidth
        )

        self.minimumItemHeight = max(
            80,
            minimumItemHeight
        )

        self.tone = tone
        self.accessibilityLabel =
            accessibilityLabel
        self.content = content
    }

    public var body: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(
                        minimum:
                            minimumItemWidth
                    ),
                    spacing: theme.spacing.xs,
                    alignment: .top
                )
            ],
            alignment: .leading,
            spacing: theme.spacing.xs
        ) {
            ForEach(items) { item in
                choiceTile(item)
            }
        }
        .onAppear(perform: sanitizeSelection)
        .onChange(
            of: items.map(\.id)
        ) { _, _ in
            sanitizeSelection()
        }
    }

    private func choiceTile(
        _ item: Item
    ) -> some View {
        let isSelected =
            selection.contains(item.id)

        let isDisabled =
            selectionIsFull
            && !isSelected

        let itemTone = tone(item)

        let shape = RoundedRectangle(
            cornerRadius: theme.radii.large,
            style: .continuous
        )

        return Button {
            toggle(item.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        theme.colors.foreground(
                            for: itemTone
                        )
                        .opacity(
                            isSelected ? 0.1 : 0.06
                        )
                    )
                    .frame(width: 110, height: 110)
                    .offset(x: 38, y: -42)
                    .accessibilityHidden(true)

                content(item, isSelected)
                    .frame(
                        maxWidth: .infinity,
                        minHeight:
                            minimumItemHeight,
                        alignment: .topLeading
                    )

                if isSelected {
                    Image(
                        systemName:
                            "checkmark"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(
                        theme.colors.onSurface
                    )
                    .frame(width: 30, height: 30)
                    .background(
                        theme.colors.surface,
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                theme.colors.outline,
                                lineWidth:
                                    theme.borders.regular
                            )
                    }
                    .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.md)
            .foregroundStyle(
                isSelected
                    ? theme.colors.foreground(
                        for: itemTone
                    )
                    : theme.colors.onSurface
            )
            .background(
                isSelected
                    ? theme.colors.fill(
                        for: itemTone
                    )
                    : theme.colors.fill(
                        for: itemTone
                    ).opacity(0.2),
                in: shape
            )
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    isSelected
                        ? theme.colors.outline
                        : theme.colors.outlineSubtle,
                    lineWidth: isSelected
                        ? theme.borders.strong
                        : theme.borders.regular
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.48 : 1)
        .accessibilityLabel(
            accessibilityLabel(item)
        )
        .accessibilityValue(
            isSelected
                ? Text("Selected")
                : Text("Not selected")
        )
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private var selectionIsFull: Bool {
        guard case .multiple(let maximum)
                = behavior,
              let maximum else {
            return false
        }

        return selection.count >= max(0, maximum)
    }

    private func toggle(
        _ id: Item.ID
    ) {
        switch behavior {
        case .single(let allowsEmpty):
            if selection.contains(id),
               allowsEmpty {
                selection.removeAll()
            } else {
                selection = [id]
            }

        case .multiple(let maximum):
            if selection.contains(id) {
                selection.remove(id)
                return
            }

            if let maximum,
               selection.count
                >= max(0, maximum) {
                return
            }

            selection.insert(id)
        }
    }

    private func sanitizeSelection() {
        let validIDs = Set(
            items.map(\.id)
        )

        selection.formIntersection(
            validIDs
        )

        switch behavior {
        case .single:
            guard selection.count > 1 else {
                return
            }

            if let first = items.first(
                where: {
                    selection.contains($0.id)
                }
            ) {
                selection = [first.id]
            } else {
                selection.removeAll()
            }

        case .multiple(let maximum):
            guard let maximum else {
                return
            }

            let safeMaximum =
                max(0, maximum)

            guard selection.count
                    > safeMaximum else {
                return
            }

            selection = Set(
                items
                    .filter {
                        selection.contains($0.id)
                    }
                    .prefix(safeMaximum)
                    .map(\.id)
            )
        }
    }
}

// MARK: - Swipe deck

public enum BentoSwipeDecision:
    Hashable,
    Sendable {
    case left
    case right
    case up
}

public struct BentoSwipeDeckAction {
    public let title: Text
    public let systemImage: String
    public let tone: BentoTone

    public init(
        title: Text,
        systemImage: String,
        tone: BentoTone
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
    }
}

public struct BentoSwipeDeckConfiguration {
    public let left: BentoSwipeDeckAction
    public let right: BentoSwipeDeckAction
    public let up: BentoSwipeDeckAction?
    public let threshold: CGFloat

    public init(
        left: BentoSwipeDeckAction,
        right: BentoSwipeDeckAction,
        up: BentoSwipeDeckAction? = nil,
        threshold: CGFloat = 100
    ) {
        self.left = left
        self.right = right
        self.up = up
        self.threshold = max(54, threshold)
    }

    public static let standard =
        BentoSwipeDeckConfiguration(
            left: BentoSwipeDeckAction(
                title: Text("Skip"),
                systemImage: "xmark",
                tone: .danger
            ),
            right: BentoSwipeDeckAction(
                title: Text("Keep"),
                systemImage: "checkmark",
                tone: .success
            ),
            up: BentoSwipeDeckAction(
                title: Text("Later"),
                systemImage: "clock.fill",
                tone: .warning
            )
        )

    fileprivate func action(
        for decision: BentoSwipeDecision
    ) -> BentoSwipeDeckAction? {
        switch decision {
        case .left:
            left
        case .right:
            right
        case .up:
            up
        }
    }
}

public struct BentoSwipeDeck<
    Item: Identifiable,
    Card: View
>: View where Item.ID: Hashable {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var items: [Item]

    private let configuration:
        BentoSwipeDeckConfiguration

    private let cardHeight: CGFloat
    private let maximumVisibleCards: Int
    private let onDecision:
        (Item, BentoSwipeDecision) -> Void

    private let card:
        (Item) -> Card

    @State private var dragOffset =
        CGSize.zero

    @State private var isCommitting = false

    @State private var decisionTask:
        Task<Void, Never>?

    public init(
        items: Binding<[Item]>,
        configuration:
            BentoSwipeDeckConfiguration = .standard,
        cardHeight: CGFloat = 360,
        maximumVisibleCards: Int = 3,
        onDecision:
            @escaping (
                Item,
                BentoSwipeDecision
            ) -> Void = { _, _ in },
        @ViewBuilder card:
            @escaping (Item) -> Card
    ) {
        self._items = items
        self.configuration = configuration
        self.cardHeight = max(220, cardHeight)
        self.maximumVisibleCards = min(
            5,
            max(1, maximumVisibleCards)
        )
        self.onDecision = onDecision
        self.card = card
    }

    private var visibleItems: [Item] {
        Array(
            items.prefix(maximumVisibleCards)
        )
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                if items.isEmpty {
                    BentoEmptyState(
                        systemImage:
                            "rectangle.stack.badge.checkmark",
                        title: Text("All done"),
                        message: Text(
                            "There are no more cards to review."
                        )
                    )
                } else {
                    ForEach(
                        Array(
                            visibleItems
                                .enumerated()
                                .reversed()
                        ),
                        id: \.element.id
                    ) { index, item in
                        if index == 0 {
                            topCard(item)
                        } else {
                            stackedCard(
                                item,
                                index: index
                            )
                        }
                    }
                }
            }
            .frame(height: cardHeight)

            if !items.isEmpty {
                controls
            }
        }
        .onDisappear {
            decisionTask?.cancel()
            decisionTask = nil
            isCommitting = false
            dragOffset = .zero
        }
    }

    private func stackedCard(
        _ item: Item,
        index: Int
    ) -> some View {
        card(item)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .scaleEffect(
                1 - CGFloat(index) * 0.045
            )
            .offset(
                y: CGFloat(index) * 12
            )
            .opacity(
                1 - Double(index) * 0.14
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func topCard(
        _ item: Item
    ) -> some View {
        card(item)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .overlay {
                decisionOverlay
            }
            .offset(dragOffset)
            .rotationEffect(
                .degrees(
                    min(
                        11,
                        max(
                            -11,
                            Double(
                                dragOffset.width / 24
                            )
                        )
                    )
                )
            )
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { gesture in
                        guard !isCommitting else {
                            return
                        }

                        dragOffset =
                            gesture.translation
                    }
                    .onEnded { _ in
                        guard !isCommitting else {
                            return
                        }

                        if let decision =
                            committedDecision {
                            commit(
                                item,
                                decision: decision
                            )
                        } else {
                            resetDrag()
                        }
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityAction(
                named: configuration.left.title
            ) {
                commit(
                    item,
                    decision: .left
                )
            }
            .accessibilityAction(
                named: configuration.right.title
            ) {
                commit(
                    item,
                    decision: .right
                )
            }
            .modifier(
                BentoOptionalSwipeUpActionModifier(
                    action: configuration.up
                ) {
                    commit(
                        item,
                        decision: .up
                    )
                }
            )
    }

    @ViewBuilder
    private var decisionOverlay: some View {
        if let decision = activeDecision,
           let action =
                configuration.action(for: decision) {
            VStack {
                BentoBadge(
                    action.title,
                    tone: action.tone,
                    systemImage:
                        action.systemImage
                )
                .scaleEffect(
                    0.85 + dragIntensity * 0.15
                )
                .opacity(dragIntensity)

                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding(theme.spacing.md)
            .allowsHitTesting(false)
        }
    }

    private var controls: some View {
        HStack(spacing: theme.spacing.lg) {
            BentoIconButton(
                systemImage:
                    configuration.left.systemImage,
                accessibilityLabel:
                    configuration.left.title,
                variant: .tonal(
                    configuration.left.tone
                ),
                size: .large
            ) {
                guard let item = items.first else {
                    return
                }

                commit(
                    item,
                    decision: .left
                )
            }
            .disabled(isCommitting)

            if let up = configuration.up {
                BentoIconButton(
                    systemImage: up.systemImage,
                    accessibilityLabel: up.title,
                    variant: .tonal(up.tone),
                    size: .large
                ) {
                    guard let item =
                            items.first else {
                        return
                    }

                    commit(
                        item,
                        decision: .up
                    )
                }
                .disabled(isCommitting)
            }

            BentoIconButton(
                systemImage:
                    configuration.right.systemImage,
                accessibilityLabel:
                    configuration.right.title,
                variant: .tonal(
                    configuration.right.tone
                ),
                size: .large
            ) {
                guard let item = items.first else {
                    return
                }

                commit(
                    item,
                    decision: .right
                )
            }
            .disabled(isCommitting)
        }
    }

    private var activeDecision:
        BentoSwipeDecision? {
        let horizontal =
            abs(dragOffset.width)

        let vertical =
            abs(dragOffset.height)

        if dragOffset.height < -24,
           vertical > horizontal * 0.72,
           configuration.up != nil {
            return .up
        }

        if dragOffset.width > 24 {
            return .right
        }

        if dragOffset.width < -24 {
            return .left
        }

        return nil
    }

    private var committedDecision:
        BentoSwipeDecision? {
        let threshold =
            configuration.threshold

        if dragOffset.height < -threshold,
           abs(dragOffset.height)
            > abs(dragOffset.width) * 0.72,
           configuration.up != nil {
            return .up
        }

        if dragOffset.width > threshold {
            return .right
        }

        if dragOffset.width < -threshold {
            return .left
        }

        return nil
    }

    private var dragIntensity: Double {
        let distance = max(
            abs(dragOffset.width),
            abs(dragOffset.height)
        )

        return min(
            1,
            max(
                0,
                Double(distance)
                / Double(
                    configuration.threshold
                )
            )
        )
    }

    private func commit(
        _ item: Item,
        decision: BentoSwipeDecision
    ) {
        guard !isCommitting,
              configuration.action(
                for: decision
              ) != nil,
              items.first?.id == item.id else {
            return
        }

        isCommitting = true
        decisionTask?.cancel()

        let targetOffset: CGSize

        switch decision {
        case .left:
            targetOffset = CGSize(
                width: -800,
                height: 80
            )

        case .right:
            targetOffset = CGSize(
                width: 800,
                height: 80
            )

        case .up:
            targetOffset = CGSize(
                width: 0,
                height: -800
            )
        }

        withAnimation(
            reduceMotion
                ? nil
                : .easeIn(duration: 0.24)
        ) {
            dragOffset = targetOffset
        }

        decisionTask = Task { @MainActor in
            try? await ContinuousClock()
                .sleep(for: .seconds(0.24))

            guard !Task.isCancelled else {
                return
            }

            guard items.first?.id
                    == item.id else {
                resetWithoutAnimation()
                return
            }

            items.removeFirst()
            onDecision(item, decision)
            resetWithoutAnimation()
            decisionTask = nil
        }
    }

    private func resetDrag() {
        withAnimation(
            reduceMotion
                ? nil
                : theme.motion.snappy
        ) {
            dragOffset = .zero
        }
    }

    private func resetWithoutAnimation() {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            dragOffset = .zero
            isCommitting = false
        }
    }
}

private struct BentoOptionalSwipeUpActionModifier:
    ViewModifier {
    let action: BentoSwipeDeckAction?
    let perform: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if let action {
            content.accessibilityAction(
                named: action.title,
                perform
            )
        } else {
            content
        }
    }
}