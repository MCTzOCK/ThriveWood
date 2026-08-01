import SwiftUI
import UIKit

// MARK: - Async button

public struct BentoAsyncButton: View {
    private let title: Text
    private let successTitle: Text?
    private let systemImage: String?
    private let variant: BentoButtonVariant
    private let size: BentoControlSize
    private let expands: Bool
    private let minimumLoadingDuration: Double
    private let successDisplayDuration: Double
    private let action: @MainActor () async throws -> Void
    private let onError: @MainActor (Error) -> Void

    @State private var isRunning = false
    @State private var didSucceed = false
    @State private var task: Task<Void, Never>?

    public init(
        _ title: Text,
        successTitle: Text? = nil,
        systemImage: String? = nil,
        variant: BentoButtonVariant = .primary,
        size: BentoControlSize = .medium,
        expands: Bool = false,
        minimumLoadingDuration: Double = 0.35,
        successDisplayDuration: Double = 0.8,
        action: @escaping @MainActor () async throws -> Void,
        onError: @escaping @MainActor (Error) -> Void = { _ in }
    ) {
        self.title = title
        self.successTitle = successTitle
        self.systemImage = systemImage
        self.variant = variant
        self.size = size
        self.expands = expands
        self.minimumLoadingDuration = max(0, minimumLoadingDuration)
        self.successDisplayDuration = max(0, successDisplayDuration)
        self.action = action
        self.onError = onError
    }

    private var resolvedTitle: Text {
        if didSucceed {
            return successTitle ?? title
        }

        return title
    }

    private var resolvedSystemImage: String? {
        didSucceed ? "checkmark" : systemImage
    }

    public var body: some View {
        BentoButton(
            resolvedTitle,
            systemImage: resolvedSystemImage,
            variant: variant,
            size: size,
            expands: expands,
            isLoading: isRunning,
            action: run
        )
        .disabled(isRunning || didSucceed)
        .onDisappear {
            task?.cancel()
            task = nil
            isRunning = false
            didSucceed = false
        }
    }

    private func run() {
        guard !isRunning, !didSucceed else {
            return
        }

        task?.cancel()
        isRunning = true

        task = Task { @MainActor in
            let clock = ContinuousClock()
            let startedAt = clock.now

            do {
                try await action()
                await waitForMinimumDuration(
                    clock: clock,
                    startedAt: startedAt
                )

                guard !Task.isCancelled else {
                    isRunning = false
                    return
                }

                isRunning = false
                didSucceed = true

                try? await clock.sleep(
                    for: .seconds(successDisplayDuration)
                )

                guard !Task.isCancelled else {
                    return
                }

                didSucceed = false
                task = nil
            } catch {
                await waitForMinimumDuration(
                    clock: clock,
                    startedAt: startedAt
                )

                isRunning = false
                task = nil

                guard !Task.isCancelled,
                      !(error is CancellationError) else {
                    return
                }

                onError(error)
            }
        }
    }

    private func waitForMinimumDuration(
        clock: ContinuousClock,
        startedAt: ContinuousClock.Instant
    ) async {
        let minimumDuration = Duration.seconds(
            minimumLoadingDuration
        )

        let elapsed = startedAt.duration(to: clock.now)

        guard elapsed < minimumDuration else {
            return
        }

        try? await clock.sleep(
            for: minimumDuration - elapsed
        )
    }
}

// MARK: - Disclosure card

public struct BentoDisclosureCard<
    Header: View,
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isExpanded: Bool

    private let tone: BentoTone?
    private let header: Header
    private let content: Content

    public init(
        isExpanded: Binding<Bool>,
        tone: BentoTone? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self._isExpanded = isExpanded
        self.tone = tone
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        BentoCard(tone: tone) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Button {
                    withAnimation(
                        reduceMotion ? nil : theme.motion.snappy
                    ) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: theme.spacing.sm) {
                        header
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        Image(systemName: "chevron.down")
                            .rotationEffect(
                                .degrees(isExpanded ? 180 : 0)
                            )
                            .accessibilityHidden(true)
                    }
                    .frame(
                        minHeight: theme.sizing.minimumTouchTarget
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(
                    isExpanded ? Text("Expanded") : Text("Collapsed")
                )

                if isExpanded {
                    BentoDivider()

                    content
                        .transition(
                            .opacity.combined(
                                with: .move(edge: .top)
                            )
                        )
                }
            }
        }
    }
}

// MARK: - Rating

public struct BentoRatingPicker: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var value: Int

    private let maximum: Int
    private let allowsZero: Bool
    private let selectedSystemImage: String
    private let unselectedSystemImage: String
    private let accessibilityLabel: Text

    public init(
        value: Binding<Int>,
        maximum: Int = 5,
        allowsZero: Bool = true,
        selectedSystemImage: String = "star.fill",
        unselectedSystemImage: String = "star",
        accessibilityLabel: Text = Text("Rating")
    ) {
        self._value = value
        self.maximum = min(max(1, maximum), 10)
        self.allowsZero = allowsZero
        self.selectedSystemImage = selectedSystemImage
        self.unselectedSystemImage = unselectedSystemImage
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: theme.spacing.xxs) {
                ForEach(1...maximum, id: \.self) { rating in
                    Button {
                        if allowsZero, value == rating {
                            value = 0
                        } else {
                            value = rating
                        }
                    } label: {
                        Image(
                            systemName: rating <= value
                                ? selectedSystemImage
                                : unselectedSystemImage
                        )
                        .font(.title2)
                        .foregroundStyle(
                            rating <= value
                                ? theme.colors.warning
                                : theme.colors.onSurfaceMuted
                        )
                        .frame(
                            minWidth: theme.sizing.minimumTouchTarget,
                            minHeight: theme.sizing.minimumTouchTarget
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(Text("\(value) of \(maximum)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(maximum, value + 1)

            case .decrement:
                value = max(allowsZero ? 0 : 1, value - 1)

            @unknown default:
                break
            }
        }
        .onAppear(perform: sanitizeValue)
        .onChange(of: value) {
            sanitizeValue()
        }
    }

    private func sanitizeValue() {
        value = min(
            maximum,
            max(allowsZero ? 0 : 1, value)
        )
    }
}

// MARK: - Page indicator

public struct BentoPageIndicator: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var current: Int

    private let count: Int
    private let allowsDirectSelection: Bool

    public init(
        count: Int,
        current: Binding<Int>,
        allowsDirectSelection: Bool = true
    ) {
        self.count = min(max(0, count), 100)
        self._current = current
        self.allowsDirectSelection = allowsDirectSelection
    }

    @ViewBuilder
    public var body: some View {
        if count > 0 {
            ScrollView(.horizontal) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(0..<count, id: \.self) { index in
                        Button {
                            guard allowsDirectSelection else {
                                return
                            }

                            current = index
                        } label: {
                            Capsule()
                                .fill(
                                    index == current
                                        ? theme.colors.accent
                                        : theme.colors.outlineSubtle
                                )
                                .frame(
                                    width: index == current ? 28 : 9,
                                    height: 9
                                )
                                .contentShape(
                                    Rectangle()
                                        .inset(by: -12)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!allowsDirectSelection)
                        .accessibilityHidden(true)
                    }
                }
                .padding(.vertical, theme.spacing.xs)
            }
            .scrollIndicators(.hidden)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Page"))
            .accessibilityValue(
                Text("\(current + 1) of \(count)")
            )
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    current = min(count - 1, current + 1)

                case .decrement:
                    current = max(0, current - 1)

                @unknown default:
                    break
                }
            }
            .onAppear(perform: sanitizeCurrentPage)
            .onChange(of: current) {
                sanitizeCurrentPage()
            }
        }
    }

    private func sanitizeCurrentPage() {
        guard count > 0 else {
            current = 0
            return
        }

        current = min(count - 1, max(0, current))
    }
}

// MARK: - Semantic tone picker

public struct BentoTonePicker: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selection: BentoTone

    private let tones: [BentoTone]

    public init(
        selection: Binding<BentoTone>,
        tones: [BentoTone] = BentoTone.allCases
    ) {
        var seen = Set<BentoTone>()

        self._selection = selection
        self.tones = tones.filter {
            seen.insert($0).inserted
        }
    }

    public var body: some View {
        BentoFlowLayout(spacing: theme.spacing.xs) {
            ForEach(tones) { tone in
                Button {
                    selection = tone
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.colors.fill(for: tone))

                        if selection == tone {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(
                                    theme.colors.foreground(for: tone)
                                )
                        }
                    }
                    .frame(
                        width: theme.sizing.minimumTouchTarget,
                        height: theme.sizing.minimumTouchTarget
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                selection == tone
                                    ? theme.colors.focus
                                    : theme.colors.outline,
                                lineWidth: selection == tone
                                    ? theme.borders.strong
                                    : theme.borders.thin
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(verbatim: tone.rawValue.capitalized)
                )
                .accessibilityAddTraits(
                    selection == tone ? .isSelected : []
                )
            }
        }
        .onAppear {
            guard !tones.isEmpty,
                  !tones.contains(selection) else {
                return
            }

            selection = tones[0]
        }
    }
}

// MARK: - Multi-selection chips

public enum BentoChipSelectionBehavior: Sendable {
    case single(allowsEmpty: Bool)
    case multiple(maximum: Int?)
}

public struct BentoSelectionChips<Option: Hashable>: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selection: Set<Option>

    private let options: [Option]
    private let behavior: BentoChipSelectionBehavior
    private let tone: BentoTone
    private let label: (Option) -> Text
    private let systemImage: (Option) -> String?

    public init(
        options: [Option],
        selection: Binding<Set<Option>>,
        behavior: BentoChipSelectionBehavior = .multiple(
            maximum: nil
        ),
        tone: BentoTone = .accent,
        label: @escaping (Option) -> Text,
        systemImage: @escaping (Option) -> String? = { _ in nil }
    ) {
        var seen = Set<Option>()

        self.options = options.filter {
            seen.insert($0).inserted
        }

        self._selection = selection
        self.behavior = behavior
        self.tone = tone
        self.label = label
        self.systemImage = systemImage
    }

    public var body: some View {
        BentoFlowLayout(spacing: theme.spacing.xs) {
            ForEach(options, id: \.self) { option in
                BentoChip(
                    label(option),
                    systemImage: systemImage(option),
                    tone: tone,
                    isSelected: selection.contains(option)
                ) {
                    toggle(option)
                }
                .disabled(isDisabled(option))
            }
        }
        .onAppear(perform: sanitizeSelection)
        .onChange(of: options) {
            sanitizeSelection()
        }
    }

    private func toggle(_ option: Option) {
        switch behavior {
        case .single(let allowsEmpty):
            if selection.contains(option), allowsEmpty {
                selection.removeAll()
            } else {
                selection = [option]
            }

        case .multiple(let maximum):
            if selection.contains(option) {
                selection.remove(option)
                return
            }

            if let maximum,
               selection.count >= max(0, maximum) {
                return
            }

            selection.insert(option)
        }
    }

    private func isDisabled(_ option: Option) -> Bool {
        guard case .multiple(let maximum) = behavior,
              let maximum else {
            return false
        }

        return !selection.contains(option)
            && selection.count >= max(0, maximum)
    }

    private func sanitizeSelection() {
        selection.formIntersection(Set(options))

        switch behavior {
        case .single:
            guard selection.count > 1 else {
                return
            }

            if let first = options.first(
                where: selection.contains
            ) {
                selection = [first]
            } else {
                selection.removeAll()
            }

        case .multiple(let maximum):
            guard let maximum else {
                return
            }

            let safeMaximum = max(0, maximum)

            guard selection.count > safeMaximum else {
                return
            }

            selection = Set(
                options
                    .filter(selection.contains)
                    .prefix(safeMaximum)
            )
        }
    }
}

// MARK: - Expandable text

private struct BentoCollapsedTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}

private struct BentoExpandedTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}

public struct BentoExpandableText: View {
    @Environment(\.bentoTheme) private var theme

    private let text: Text
    private let lineLimit: Int
    private let style: BentoTextStyle
    private let moreTitle: Text
    private let lessTitle: Text

    @State private var isExpanded = false
    @State private var collapsedHeight: CGFloat = 0
    @State private var expandedHeight: CGFloat = 0

    public init(
        _ text: Text,
        lineLimit: Int = 3,
        style: BentoTextStyle = .body,
        moreTitle: Text = Text("Show more"),
        lessTitle: Text = Text("Show less")
    ) {
        self.text = text
        self.lineLimit = max(1, lineLimit)
        self.style = style
        self.moreTitle = moreTitle
        self.lessTitle = lessTitle
    }

    private var isTruncated: Bool {
        expandedHeight > collapsedHeight + 1
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            text
                .bentoTextStyle(style)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background {
                    text
                        .bentoTextStyle(style)
                        .lineLimit(lineLimit)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .hidden()
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: BentoCollapsedTextHeightKey.self,
                                    value: geometry.size.height
                                )
                            }
                        }
                }
                .background {
                    text
                        .bentoTextStyle(style)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .hidden()
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: BentoExpandedTextHeightKey.self,
                                    value: geometry.size.height
                                )
                            }
                        }
                }

            if isTruncated || isExpanded {
                Button {
                    withAnimation(theme.motion.snappy) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: theme.spacing.xxs) {
                        isExpanded ? lessTitle : moreTitle

                        Image(
                            systemName: isExpanded
                                ? "chevron.up"
                                : "chevron.down"
                        )
                        .accessibilityHidden(true)
                    }
                    .bentoTextStyle(
                        .callout,
                        color: theme.colors.accent
                    )
                    .frame(
                        minHeight: theme.sizing.minimumTouchTarget
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .onPreferenceChange(
            BentoCollapsedTextHeightKey.self
        ) {
            collapsedHeight = $0
        }
        .onPreferenceChange(
            BentoExpandedTextHeightKey.self
        ) {
            expandedHeight = $0
        }
    }
}

// MARK: - Copy field

public struct BentoCopyField: View {
    @Environment(\.bentoTheme) private var theme

    private let value: String
    private let label: Text?
    private let copiedTitle: Text

    @State private var copied = false
    @State private var resetTask: Task<Void, Never>?

    public init(
        value: String,
        label: Text? = nil,
        copiedTitle: Text = Text("Copied")
    ) {
        self.value = value
        self.label = label
        self.copiedTitle = copiedTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                label.bentoTextStyle(.callout)
            }

            HStack(spacing: theme.spacing.sm) {
                Text(verbatim: value)
                    .bentoTextStyle(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Spacer(minLength: theme.spacing.sm)

                Button {
                    copy()
                } label: {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(
                            systemName: copied
                                ? "checkmark"
                                : "doc.on.doc"
                        )

                        if copied {
                            copiedTitle
                        }
                    }
                    .bentoTextStyle(.callout)
                    .frame(
                        minHeight: theme.sizing.minimumTouchTarget
                    )
                }
                .buttonStyle(.plain)
                .disabled(value.isEmpty)
                .accessibilityLabel(
                    copied ? copiedTitle : Text("Copy")
                )
            }
            .padding(.horizontal, theme.spacing.sm)
            .frame(minHeight: theme.sizing.controlMedium)
            .background(
                theme.colors.surfaceSecondary,
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
                    copied
                        ? theme.colors.success
                        : theme.colors.outline,
                    lineWidth: theme.borders.regular
                )
            }
        }
        .onDisappear {
            resetTask?.cancel()
            resetTask = nil
        }
    }

    private func copy() {
        guard !value.isEmpty else {
            return
        }

        UIPasteboard.general.string = value
        copied = true

        resetTask?.cancel()
        resetTask = Task { @MainActor in
            try? await ContinuousClock()
                .sleep(for: .seconds(1.5))

            guard !Task.isCancelled else {
                return
            }

            copied = false
            resetTask = nil
        }
    }
}