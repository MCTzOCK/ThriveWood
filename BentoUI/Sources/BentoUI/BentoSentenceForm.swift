import SwiftUI
import UIKit

// MARK: - Public configuration

public enum BentoSentenceGapStatus: Equatable, Sendable {
    case empty
    case filled
    case warning
    case error
    case loading
    case disabled
}

public enum BentoSentenceSpacingBehavior: Sendable {
    case separated
    case joinedToPrevious
    case joinedToNext
    case joined

    fileprivate var joinsPrevious: Bool {
        switch self {
        case .joinedToPrevious, .joined:
            true
        case .separated, .joinedToNext:
            false
        }
    }

    fileprivate var joinsNext: Bool {
        switch self {
        case .joinedToNext, .joined:
            true
        case .separated, .joinedToPrevious:
            false
        }
    }
}

public enum BentoSentenceHorizontalAlignment: Sendable {
    case leading
    case center
    case trailing
}

public enum BentoSentenceLineAlignment: Sendable {
    case center
    case firstTextBaseline
}

public enum BentoSentenceDirection: Sendable {
    case automatic
    case leftToRight
    case rightToLeft
}

public struct BentoSentenceGapSizing: Equatable, Sendable {
    public let minimumWidth: CGFloat
    public let maximumWidth: CGFloat?
    public let lineLimit: Int?

    public init(
        minimumWidth: CGFloat = 64,
        maximumWidth: CGFloat? = 320,
        lineLimit: Int? = 2
    ) {
        let resolvedMinimumWidth = max(44, minimumWidth)

        self.minimumWidth = resolvedMinimumWidth
        self.maximumWidth = maximumWidth.map {
            max(resolvedMinimumWidth, $0)
        }
        self.lineLimit = lineLimit.map {
            max(1, $0)
        }
    }

    public static let standard = BentoSentenceGapSizing()

    public static let compact = BentoSentenceGapSizing(
        minimumWidth: 56,
        maximumWidth: 240,
        lineLimit: 1
    )

    public static let wide = BentoSentenceGapSizing(
        minimumWidth: 120,
        maximumWidth: 420,
        lineLimit: 3
    )
}

// MARK: - Internal fragment storage

private struct BentoSentenceTextPayload {
    let id: AnyHashable?
    let value: String
    let spacing: BentoSentenceSpacingBehavior
    let accessibilityLabel: Text?
    let announcesForAccessibility: Bool
}

private struct BentoSentenceCustomPayload {
    let id: AnyHashable
    let revision: AnyHashable?
    let spacing: BentoSentenceSpacingBehavior
    let makeView: () -> AnyView
}

private struct BentoSentenceBreakPayload {
    let id: AnyHashable?
}

public struct BentoSentenceFragment {
    fileprivate enum Storage {
        case text(BentoSentenceTextPayload)
        case custom(BentoSentenceCustomPayload)
        case lineBreak(BentoSentenceBreakPayload)
    }

    fileprivate let storage: Storage

    fileprivate init(storage: Storage) {
        self.storage = storage
    }
}

public protocol BentoSentenceComponent {
    var bentoSentenceFragments: [BentoSentenceFragment] { get }
}

// MARK: - Result builder

@resultBuilder
public enum BentoSentenceBuilder {
    public static func buildExpression<Component: BentoSentenceComponent>(
        _ expression: Component
    ) -> [BentoSentenceFragment] {
        expression.bentoSentenceFragments
    }

    public static func buildExpression(
        _ expression: String
    ) -> [BentoSentenceFragment] {
        BentoSentenceText(expression)
            .bentoSentenceFragments
    }

    public static func buildExpression(
        _ expression: Substring
    ) -> [BentoSentenceFragment] {
        BentoSentenceText(String(expression))
            .bentoSentenceFragments
    }

    public static func buildBlock(
        _ components: [BentoSentenceFragment]...
    ) -> [BentoSentenceFragment] {
        components.flatMap { $0 }
    }

    public static func buildOptional(
        _ component: [BentoSentenceFragment]?
    ) -> [BentoSentenceFragment] {
        component ?? []
    }

    public static func buildEither(
        first component: [BentoSentenceFragment]
    ) -> [BentoSentenceFragment] {
        component
    }

    public static func buildEither(
        second component: [BentoSentenceFragment]
    ) -> [BentoSentenceFragment] {
        component
    }

    public static func buildArray(
        _ components: [[BentoSentenceFragment]]
    ) -> [BentoSentenceFragment] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(
        _ component: [BentoSentenceFragment]
    ) -> [BentoSentenceFragment] {
        component
    }
}

// MARK: - Static text

public struct BentoSentenceText: BentoSentenceComponent {
    private let id: AnyHashable?
    private let value: String
    private let spacing: BentoSentenceSpacingBehavior
    private let accessibilityLabel: Text?
    private let announcesForAccessibility: Bool

    public init(
        _ value: String,
        spacing: BentoSentenceSpacingBehavior = .separated,
        accessibilityLabel: Text? = nil,
        announcesForAccessibility: Bool = true
    ) {
        self.id = nil
        self.value = value
        self.spacing = spacing
        self.accessibilityLabel = accessibilityLabel
        self.announcesForAccessibility =
            announcesForAccessibility
    }

    public init<ID: Hashable>(
        _ value: String,
        id: ID,
        spacing: BentoSentenceSpacingBehavior = .separated,
        accessibilityLabel: Text? = nil,
        announcesForAccessibility: Bool = true
    ) {
        self.id = AnyHashable(id)
        self.value = value
        self.spacing = spacing
        self.accessibilityLabel = accessibilityLabel
        self.announcesForAccessibility =
            announcesForAccessibility
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        [
            BentoSentenceFragment(
                storage: .text(
                    BentoSentenceTextPayload(
                        id: id,
                        value: value,
                        spacing: spacing,
                        accessibilityLabel: accessibilityLabel,
                        announcesForAccessibility:
                            announcesForAccessibility
                    )
                )
            )
        ]
    }
}

public struct BentoSentencePunctuation: BentoSentenceComponent {
    private let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        BentoSentenceText(
            value,
            spacing: .joinedToPrevious,
            announcesForAccessibility: false
        )
        .bentoSentenceFragments
    }
}

public struct BentoSentenceLineBreak: BentoSentenceComponent {
    private let id: AnyHashable?

    public init() {
        self.id = nil
    }

    public init<ID: Hashable>(id: ID) {
        self.id = AnyHashable(id)
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        [
            BentoSentenceFragment(
                storage: .lineBreak(
                    BentoSentenceBreakPayload(id: id)
                )
            )
        ]
    }
}

// MARK: - Generic custom gap

public struct BentoSentenceGap<Label: View>: BentoSentenceComponent {
    private let id: AnyHashable
    private let revision: AnyHashable?
    private let tone: BentoTone
    private let status: BentoSentenceGapStatus
    private let required: Bool
    private let sizing: BentoSentenceGapSizing
    private let spacing: BentoSentenceSpacingBehavior
    private let accessibilityLabel: Text
    private let accessibilityValue: Text?
    private let accessibilityHint: Text?
    private let action: (() -> Void)?
    private let label: Label

    public init<ID: Hashable>(
        id: ID,
        tone: BentoTone,
        status: BentoSentenceGapStatus = .filled,
        required: Bool = false,
        sizing: BentoSentenceGapSizing = .standard,
        spacing: BentoSentenceSpacingBehavior = .separated,
        revision: AnyHashable? = nil,
        accessibilityLabel: Text,
        accessibilityValue: Text? = nil,
        accessibilityHint: Text? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.id = AnyHashable(id)
        self.revision = revision
        self.tone = tone
        self.status = status
        self.required = required
        self.sizing = sizing
        self.spacing = spacing
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.label = label()
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        let label = self.label

        return [
            BentoSentenceFragment(
                storage: .custom(
                    BentoSentenceCustomPayload(
                        id: id,
                        revision: revision,
                        spacing: spacing
                    ) {
                        AnyView(
                            BentoSentenceActionGap(
                                tone: tone,
                                status: status,
                                required: required,
                                sizing: sizing,
                                accessibilityLabel:
                                    accessibilityLabel,
                                accessibilityValue:
                                    accessibilityValue,
                                accessibilityHint:
                                    accessibilityHint,
                                action: action,
                                label: label
                            )
                        )
                    }
                )
            )
        ]
    }
}

// MARK: - Convenience value gap

public struct BentoSentenceValueGap: BentoSentenceComponent {
    private let id: AnyHashable
    private let value: String?
    private let placeholder: String
    private let systemImage: String?
    private let tone: BentoTone
    private let status: BentoSentenceGapStatus
    private let required: Bool
    private let sizing: BentoSentenceGapSizing
    private let spacing: BentoSentenceSpacingBehavior
    private let accessibilityLabel: Text
    private let accessibilityHint: Text?
    private let action: (() -> Void)?

    public init<ID: Hashable>(
        id: ID,
        value: String?,
        placeholder: String,
        systemImage: String? = nil,
        tone: BentoTone,
        status: BentoSentenceGapStatus? = nil,
        required: Bool = false,
        sizing: BentoSentenceGapSizing = .standard,
        spacing: BentoSentenceSpacingBehavior = .separated,
        accessibilityLabel: Text? = nil,
        accessibilityHint: Text? = nil,
        action: (() -> Void)? = nil
    ) {
        let resolvedValue = value.flatMap {
            $0.isEmpty ? nil : $0
        }

        self.id = AnyHashable(id)
        self.value = resolvedValue
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.tone = tone
        self.status = status ?? (
            resolvedValue == nil ? .empty : .filled
        )
        self.required = required
        self.sizing = sizing
        self.spacing = spacing
        self.accessibilityLabel = accessibilityLabel
            ?? Text(verbatim: placeholder)
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        let displayValue = value ?? placeholder
        let accessibilityValue = value.map {
            Text(verbatim: $0)
        }

        return BentoSentenceGap(
            id: id,
            tone: tone,
            status: status,
            required: required,
            sizing: sizing,
            spacing: spacing,
            revision: AnyHashable(value ?? "__empty__"),
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            accessibilityHint: accessibilityHint,
            action: action
        ) {
            BentoSentenceSimpleLabel(
                value: displayValue,
                systemImage: systemImage
            )
        }
        .bentoSentenceFragments
    }
}

private struct BentoSentenceSimpleLabel: View {
    let value: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }

            Text(verbatim: value)
        }
    }
}

// MARK: - Image and entity label

public struct BentoSentenceEntityLabel<Visual: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let visualSize: CGFloat
    private let visual: Visual

    public init(
        title: Text,
        subtitle: Text? = nil,
        visualSize: CGFloat = 30,
        @ViewBuilder visual: () -> Visual
    ) {
        self.title = title
        self.subtitle = subtitle
        self.visualSize = max(22, visualSize)
        self.visual = visual()
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            visual
                .frame(
                    width: visualSize,
                    height: visualSize
                )
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: theme.spacing.xxs
            ) {
                title
                    .bentoTextStyle(.headline)
                    .lineLimit(1)

                if let subtitle {
                    subtitle
                        .bentoTextStyle(.caption)
                        .lineLimit(1)
                        .opacity(0.72)
                }
            }
        }
    }
}

// MARK: - Inline text input gap

public struct BentoSentenceInlineTextGap: BentoSentenceComponent {
    private let id: AnyHashable
    private let text: Binding<String>
    private let placeholder: String
    private let tone: BentoTone
    private let status: BentoSentenceGapStatus?
    private let required: Bool
    private let sizing: BentoSentenceGapSizing
    private let spacing: BentoSentenceSpacingBehavior
    private let maximumLength: Int?
    private let keyboardType: UIKeyboardType
    private let contentType: UITextContentType?
    private let capitalization: TextInputAutocapitalization
    private let autocorrectionDisabled: Bool
    private let submitLabel: SubmitLabel
    private let externalFocus: Binding<Bool>?
    private let accessibilityLabel: Text
    private let animatesWidth: Bool
    private let onSubmit: () -> Void

    public init<ID: Hashable>(
        id: ID,
        text: Binding<String>,
        placeholder: String,
        tone: BentoTone,
        status: BentoSentenceGapStatus? = nil,
        required: Bool = false,
        sizing: BentoSentenceGapSizing = .compact,
        spacing: BentoSentenceSpacingBehavior = .separated,
        maximumLength: Int? = nil,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        submitLabel: SubmitLabel = .done,
        isFocused: Binding<Bool>? = nil,
        accessibilityLabel: Text,
        animatesWidth: Bool = false,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.id = AnyHashable(id)
        self.text = text
        self.placeholder = placeholder
        self.tone = tone
        self.status = status
        self.required = required
        self.sizing = sizing
        self.spacing = spacing
        self.maximumLength = maximumLength.map {
            max(0, $0)
        }
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.capitalization = capitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.submitLabel = submitLabel
        self.externalFocus = isFocused
        self.accessibilityLabel = accessibilityLabel
        self.animatesWidth = animatesWidth
        self.onSubmit = onSubmit
    }

    public var bentoSentenceFragments: [BentoSentenceFragment] {
        let resolvedStatus = status ?? (
            text.wrappedValue.isEmpty ? .empty : .filled
        )

        let revision: AnyHashable? = animatesWidth
            ? AnyHashable(text.wrappedValue)
            : nil

        return [
            BentoSentenceFragment(
                storage: .custom(
                    BentoSentenceCustomPayload(
                        id: id,
                        revision: revision,
                        spacing: spacing
                    ) {
                        AnyView(
                            BentoSentenceInlineTextField(
                                text: text,
                                placeholder: placeholder,
                                tone: tone,
                                status: resolvedStatus,
                                required: required,
                                sizing: sizing,
                                maximumLength: maximumLength,
                                keyboardType: keyboardType,
                                contentType: contentType,
                                capitalization: capitalization,
                                autocorrectionDisabled:
                                    autocorrectionDisabled,
                                submitLabel: submitLabel,
                                externalFocus: externalFocus,
                                accessibilityLabel:
                                    accessibilityLabel,
                                onSubmit: onSubmit
                            )
                        )
                    }
                )
            )
        ]
    }
}

// MARK: - Sentence form

public struct BentoSentenceForm: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fragments: [BentoSentenceFragment]
    private let textStyle: BentoTextStyle
    private let wordSpacing: CGFloat?
    private let lineSpacing: CGFloat?
    private let gapHorizontalPadding: CGFloat?
    private let gapVerticalPadding: CGFloat?
    private let horizontalAlignment:
        BentoSentenceHorizontalAlignment
    private let lineAlignment: BentoSentenceLineAlignment
    private let direction: BentoSentenceDirection
    private let animatesChanges: Bool
    private let accessibilityLabel: Text?

    public init(
        textStyle: BentoTextStyle = .title2,
        wordSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        gapHorizontalPadding: CGFloat? = nil,
        gapVerticalPadding: CGFloat? = nil,
        horizontalAlignment:
            BentoSentenceHorizontalAlignment = .leading,
        lineAlignment: BentoSentenceLineAlignment = .center,
        direction: BentoSentenceDirection = .automatic,
        animatesChanges: Bool = true,
        accessibilityLabel: Text? = nil,
        @BentoSentenceBuilder content:
            () -> [BentoSentenceFragment]
    ) {
        self.fragments = content()
        self.textStyle = textStyle
        self.wordSpacing = wordSpacing
        self.lineSpacing = lineSpacing
        self.gapHorizontalPadding = gapHorizontalPadding
        self.gapVerticalPadding = gapVerticalPadding
        self.horizontalAlignment = horizontalAlignment
        self.lineAlignment = lineAlignment
        self.direction = direction
        self.animatesChanges = animatesChanges
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let resolvedWordSpacing =
            max(0, wordSpacing ?? theme.spacing.xs)

        let resolvedLineSpacing =
            max(0, lineSpacing ?? theme.spacing.sm)

        let configuration =
            BentoSentenceEnvironmentConfiguration(
                textStyle: textStyle,
                gapHorizontalPadding:
                    gapHorizontalPadding ?? theme.spacing.sm,
                gapVerticalPadding:
                    gapVerticalPadding ?? theme.spacing.xs
            )

        let items = makeRenderItems(
            wordSpacing: resolvedWordSpacing
        )

        BentoSentenceFlowLayout(
            lineSpacing: resolvedLineSpacing,
            horizontalAlignment: horizontalAlignment,
            lineAlignment: lineAlignment,
            isRightToLeft: resolvedDirection
                == .rightToLeft
        ) {
            ForEach(items) { item in
                item
                    .makeView(textStyle: textStyle)
                    .layoutValue(
                        key:
                            BentoSentenceLeadingSpacingKey.self,
                        value: item.leadingSpacing
                    )
                    .layoutValue(
                        key:
                            BentoSentenceLineBreakKey.self,
                        value: item.isLineBreak
                    )
                    .layoutValue(
                        key:
                            BentoSentenceBaselineInsetKey.self,
                        value: item.isGap
                            ? configuration.gapVerticalPadding
                            : -1
                    )
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.96)
                        )
                    )
            }
        }
        .environment(
            \.bentoSentenceConfiguration,
            configuration
        )
        .modifier(
            BentoSentenceContainerAccessibilityModifier(
                label: accessibilityLabel
            )
        )
        .animation(
            animatesChanges && !reduceMotion
                ? theme.motion.snappy
                : nil,
            value: items.map(\.signature)
        )
    }

    private var resolvedDirection: LayoutDirection {
        switch direction {
        case .automatic:
            layoutDirection
        case .leftToRight:
            .leftToRight
        case .rightToLeft:
            .rightToLeft
        }
    }

    private func makeRenderItems(
        wordSpacing: CGFloat
    ) -> [BentoSentenceRenderItem] {
        var result: [BentoSentenceRenderItem] = []
        var customOccurrences: [AnyHashable: Int] = [:]

        for (componentIndex, fragment) in fragments.enumerated() {
            switch fragment.storage {
            case .text(let payload):
                let words = payload.value
                    .split {
                        $0.isWhitespace
                    }
                    .map(String.init)

                guard !words.isEmpty else {
                    continue
                }

                for (wordIndex, word) in words.enumerated() {
                    let isFirstWord = wordIndex == 0
                    let isLastWord =
                        wordIndex == words.count - 1

                    let announcement: Text?

                    if isFirstWord,
                       payload.announcesForAccessibility {
                        announcement =
                            payload.accessibilityLabel
                            ?? Text(verbatim: payload.value)
                    } else {
                        announcement = nil
                    }

                    result.append(
                        BentoSentenceRenderItem(
                            id: .text(
                                componentIndex: componentIndex,
                                wordIndex: wordIndex,
                                explicitID: payload.id
                            ),
                            signature: .text(
                                componentIndex: componentIndex,
                                wordIndex: wordIndex,
                                value: payload.value,
                                explicitID: payload.id
                            ),
                            content: .word(
                                value: word,
                                accessibilityLabel:
                                    announcement
                            ),
                            joinsPrevious:
                                isFirstWord
                                && payload.spacing
                                .joinsPrevious,
                            joinsNext:
                                isLastWord
                                && payload.spacing
                                .joinsNext,
                            isGap: false,
                            isLineBreak: false,
                            leadingSpacing: 0
                        )
                    )
                }

            case .custom(let payload):
                let occurrence =
                    customOccurrences[payload.id, default: 0]

                customOccurrences[payload.id] =
                    occurrence + 1

                result.append(
                    BentoSentenceRenderItem(
                        id: .custom(
                            id: payload.id,
                            occurrence: occurrence
                        ),
                        signature: .custom(
                            id: payload.id,
                            occurrence: occurrence,
                            revision: payload.revision
                        ),
                        content: .custom(payload.makeView),
                        joinsPrevious:
                            payload.spacing.joinsPrevious,
                        joinsNext:
                            payload.spacing.joinsNext,
                        isGap: true,
                        isLineBreak: false,
                        leadingSpacing: 0
                    )
                )

            case .lineBreak(let payload):
                result.append(
                    BentoSentenceRenderItem(
                        id: .lineBreak(
                            componentIndex: componentIndex,
                            explicitID: payload.id
                        ),
                        signature: .lineBreak(
                            componentIndex: componentIndex,
                            explicitID: payload.id
                        ),
                        content: .lineBreak,
                        joinsPrevious: false,
                        joinsNext: false,
                        isGap: false,
                        isLineBreak: true,
                        leadingSpacing: 0
                    )
                )
            }
        }

        var previousJoinsNext = false

        for index in result.indices {
            if result[index].isLineBreak {
                result[index].leadingSpacing = 0
                previousJoinsNext = false
                continue
            }

            let joinsPrevious =
                result[index].joinsPrevious
                || previousJoinsNext

            result[index].leadingSpacing =
                joinsPrevious ? 0 : wordSpacing

            previousJoinsNext = result[index].joinsNext
        }

        return result
    }
}

// MARK: - Prompt card template

public struct BentoSentencePromptCard<
    Sentence: View,
    Supporting: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let eyebrow: Text?
    private let prompt: Text?
    private let tone: BentoTone
    private let sentence: Sentence
    private let supporting: Supporting

    public init(
        eyebrow: Text? = nil,
        prompt: Text? = nil,
        tone: BentoTone = .blue,
        @ViewBuilder sentence: () -> Sentence,
        @ViewBuilder supporting: () -> Supporting
    ) {
        self.eyebrow = eyebrow
        self.prompt = prompt
        self.tone = tone
        self.sentence = sentence()
        self.supporting = supporting()
    }

    public var body: some View {
        BentoCard(
            tone: tone,
            style: .outlined,
            padding: .lg,
            radius: .extraLarge
        ) {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.lg
            ) {
                if eyebrow != nil || prompt != nil {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.xs
                    ) {
                        if let eyebrow {
                            eyebrow
                                .bentoTextStyle(.overline)
                                .textCase(.uppercase)
                        }

                        if let prompt {
                            prompt.bentoTextStyle(.headline)
                        }
                    }
                }

                sentence

                supporting
            }
        }
    }
}

public extension BentoSentencePromptCard
where Supporting == EmptyView {
    init(
        eyebrow: Text? = nil,
        prompt: Text? = nil,
        tone: BentoTone = .blue,
        @ViewBuilder sentence: () -> Sentence
    ) {
        self.init(
            eyebrow: eyebrow,
            prompt: prompt,
            tone: tone,
            sentence: sentence
        ) {
            EmptyView()
        }
    }
}

// MARK: - Gap environment

private struct BentoSentenceEnvironmentConfiguration {
    let textStyle: BentoTextStyle
    let gapHorizontalPadding: CGFloat
    let gapVerticalPadding: CGFloat

    static let defaultValue =
        BentoSentenceEnvironmentConfiguration(
            textStyle: .title2,
            gapHorizontalPadding: 12,
            gapVerticalPadding: 8
        )
}

private struct BentoSentenceConfigurationKey:
    EnvironmentKey {
    static let defaultValue =
        BentoSentenceEnvironmentConfiguration.defaultValue
}

private extension EnvironmentValues {
    var bentoSentenceConfiguration:
        BentoSentenceEnvironmentConfiguration {
        get {
            self[BentoSentenceConfigurationKey.self]
        }
        set {
            self[BentoSentenceConfigurationKey.self] =
                newValue
        }
    }
}

// MARK: - Gap surface

private struct BentoSentenceGapSurface<
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.bentoSentenceConfiguration)
    private var configuration

    let tone: BentoTone
    let status: BentoSentenceGapStatus
    let sizing: BentoSentenceGapSizing
    let isFocused: Bool
    let content: Content

    init(
        tone: BentoTone,
        status: BentoSentenceGapStatus,
        sizing: BentoSentenceGapSizing,
        isFocused: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.status = status
        self.sizing = sizing
        self.isFocused = isFocused
        self.content = content()
    }

    private var effectiveStatus: BentoSentenceGapStatus {
        if !isEnabled || status == .disabled {
            return .disabled
        }

        return status
    }

    private var foregroundColor: Color {
        theme.colors.foreground(for: tone)
    }

    private var fillColor: Color {
        let base = theme.colors.fill(for: tone)

        switch effectiveStatus {
        case .empty:
            return base.opacity(0.68)
        case .disabled:
            return base.opacity(0.42)
        case .loading:
            return base.opacity(0.82)
        case .filled, .warning, .error:
            return base
        }
    }

    private var borderColor: Color {
        if isFocused {
            return theme.colors.focus
        }

        switch effectiveStatus {
        case .warning:
            return theme.colors.warning
        case .error:
            return theme.colors.danger
        case .disabled:
            return theme.colors.disabled
        case .empty, .filled, .loading:
            return foregroundColor.opacity(0.68)
        }
    }

    private var borderWidth: CGFloat {
        if isFocused
            || effectiveStatus == .warning
            || effectiveStatus == .error {
            return theme.borders.strong
        }

        return theme.borders.regular
    }

    private var borderDash: [CGFloat] {
        guard effectiveStatus == .empty,
              !isFocused else {
            return []
        }

        return [6, 4]
    }

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.medium,
            style: .continuous
        )

        HStack(spacing: theme.spacing.xs) {
            if effectiveStatus == .loading {
                BentoSpinner(
                    size: 18,
                    color: foregroundColor
                )
                .accessibilityHidden(true)
            }

            content
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .bentoTextStyle(configuration.textStyle)
        .lineLimit(sizing.lineLimit)
        .multilineTextAlignment(.leading)
        .padding(
            .horizontal,
            configuration.gapHorizontalPadding
        )
        .padding(
            .vertical,
            configuration.gapVerticalPadding
        )
        .frame(
            minWidth: sizing.minimumWidth,
            maxWidth: sizing.maximumWidth,
            minHeight: theme.sizing.minimumTouchTarget,
            alignment: .leading
        )
        .foregroundStyle(foregroundColor)
        .background(fillColor, in: shape)
        .overlay {
            shape.strokeBorder(
                borderColor,
                style: StrokeStyle(
                    lineWidth: borderWidth,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: borderDash
                )
            )
        }
        .shadow(
            color: isFocused
                ? theme.colors.focus.opacity(0.2)
                : .clear,
            radius: isFocused ? 8 : 0
        )
        .opacity(
            effectiveStatus == .disabled ? 0.65 : 1
        )
        .contentShape(shape)
    }
}

private struct BentoSentenceActionGap<
    Label: View
>: View {
    let tone: BentoTone
    let status: BentoSentenceGapStatus
    let required: Bool
    let sizing: BentoSentenceGapSizing
    let accessibilityLabel: Text
    let accessibilityValue: Text?
    let accessibilityHint: Text?
    let action: (() -> Void)?
    let label: Label

    private var disablesInteraction: Bool {
        status == .disabled || status == .loading
    }

    private var surface: some View {
        BentoSentenceGapSurface(
            tone: tone,
            status: status,
            sizing: sizing
        ) {
            label
        }
    }

    @ViewBuilder
    var body: some View {
        if let action {
            Button(action: action) {
                surface
            }
            .buttonStyle(BentoSentenceGapButtonStyle())
            .disabled(disablesInteraction)
            .modifier(
                BentoSentenceGapAccessibilityModifier(
                    label: accessibilityLabel,
                    value: accessibilityValue,
                    hint: accessibilityHint,
                    status: status,
                    required: required
                )
            )
        } else {
            surface
                .modifier(
                    BentoSentenceGapAccessibilityModifier(
                        label: accessibilityLabel,
                        value: accessibilityValue,
                        hint: accessibilityHint,
                        status: status,
                        required: required
                    )
                )
        }
    }
}

private struct BentoSentenceGapButtonStyle: ButtonStyle {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                    ? 0.965
                    : 1
            )
            .opacity(
                configuration.isPressed ? 0.88 : 1
            )
            .animation(
                reduceMotion ? nil : theme.motion.fast,
                value: configuration.isPressed
            )
    }
}

// MARK: - Inline field implementation

private struct BentoSentenceMeasuredWidthKey:
    PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}

private struct BentoSentenceInlineTextField: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.bentoSentenceConfiguration)
    private var configuration

    @Binding var text: String
    @FocusState private var isFocused: Bool

    let placeholder: String
    let tone: BentoTone
    let status: BentoSentenceGapStatus
    let required: Bool
    let sizing: BentoSentenceGapSizing
    let maximumLength: Int?
    let keyboardType: UIKeyboardType
    let contentType: UITextContentType?
    let capitalization: TextInputAutocapitalization
    let autocorrectionDisabled: Bool
    let submitLabel: SubmitLabel
    let externalFocus: Binding<Bool>?
    let accessibilityLabel: Text
    let onSubmit: () -> Void

    @State private var measuredWidth: CGFloat = 0

    private var measurementValue: String {
        text.isEmpty ? placeholder : text + " "
    }

    private var contentWidth: CGFloat {
        let horizontalInsets =
            configuration.gapHorizontalPadding * 2

        let minimum =
            max(24, sizing.minimumWidth - horizontalInsets)

        let maximum = max(
            minimum,
            (sizing.maximumWidth ?? 320)
                - horizontalInsets
        )

        return min(
            maximum,
            max(minimum, measuredWidth + 4)
        )
    }

    var body: some View {
        BentoSentenceGapSurface(
            tone: tone,
            status: status,
            sizing: sizing,
            isFocused: isFocused
        ) {
            ZStack(alignment: .leading) {
                Text(verbatim: measurementValue)
                    .bentoTextStyle(
                        configuration.textStyle
                    )
                    .fixedSize()
                    .hidden()
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key:
                                    BentoSentenceMeasuredWidthKey.self,
                                value: geometry.size.width
                            )
                        }
                    }

                TextField(
                    "",
                    text: $text,
                    prompt: Text(verbatim: placeholder)
                )
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .textInputAutocapitalization(
                    capitalization
                )
                .autocorrectionDisabled(
                    autocorrectionDisabled
                )
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .bentoTextStyle(
                    configuration.textStyle
                )
                .tint(
                    theme.colors.foreground(for: tone)
                )
                .frame(width: contentWidth)
                .accessibilityLabel(
                    accessibilityLabel
                )
                .modifier(
                    BentoSentenceOptionalAccessibilityHintModifier(
                        hint: required
                            ? Text("Required")
                            : nil
                    )
                )
            }
            .frame(width: contentWidth)
        }
        .disabled(status == .disabled || status == .loading)
        .onPreferenceChange(
            BentoSentenceMeasuredWidthKey.self
        ) {
            measuredWidth = $0
        }
        .onAppear {
            sanitizeText()

            if let externalFocus {
                isFocused = externalFocus.wrappedValue
            }
        }
        .onChange(of: text) {
            sanitizeText()
        }
        .onChange(of: isFocused) { _, newValue in
            externalFocus?.wrappedValue = newValue
        }
        .onChange(
            of: externalFocus?.wrappedValue
        ) { _, newValue in
            guard let newValue,
                  newValue != isFocused else {
                return
            }

            isFocused = newValue
        }
    }

    private func sanitizeText() {
        var sanitized = text
            .replacingOccurrences(
                of: "\n",
                with: " "
            )

        if let maximumLength,
           sanitized.count > maximumLength {
            sanitized = String(
                sanitized.prefix(maximumLength)
            )
        }

        if sanitized != text {
            text = sanitized
        }
    }
}

// MARK: - Accessibility

private struct BentoSentenceGapAccessibilityModifier:
    ViewModifier {
    let label: Text
    let value: Text?
    let hint: Text?
    let status: BentoSentenceGapStatus
    let required: Bool

    private var fallbackValue: Text {
        switch status {
        case .empty:
            return required
                ? Text("Required. Not selected.")
                : Text("Not selected")
        case .filled:
            return Text("Selected")
        case .warning:
            return Text("Selected with warning")
        case .error:
            return Text("Invalid value")
        case .loading:
            return Text("Loading")
        case .disabled:
            return Text("Disabled")
        }
    }

    private var resolvedHint: Text? {
        if let hint {
            return hint
        }

        switch status {
        case .error:
            return Text("Invalid value")
        case .warning:
            return Text("Check this value")
        case .empty where required:
            return Text("Required")
        case .empty, .filled, .loading, .disabled:
            return nil
        }
    }

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(
                value ?? fallbackValue
            )
            .modifier(
                BentoSentenceOptionalAccessibilityHintModifier(
                    hint: resolvedHint
                )
            )
    }
}

private struct BentoSentenceOptionalAccessibilityHintModifier:
    ViewModifier {
    let hint: Text?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

private struct BentoSentenceContainerAccessibilityModifier:
    ViewModifier {
    let label: Text?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label)
        } else {
            content
        }
    }
}

private struct BentoSentenceWordView: View {
    let value: String
    let textStyle: BentoTextStyle
    let accessibilityLabel: Text?

    @ViewBuilder
    var body: some View {
        if let accessibilityLabel {
            Text(verbatim: value)
                .bentoTextStyle(textStyle)
                .accessibilityLabel(
                    accessibilityLabel
                )
        } else {
            Text(verbatim: value)
                .bentoTextStyle(textStyle)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Render items

private enum BentoSentenceRenderID: Hashable {
    case text(
        componentIndex: Int,
        wordIndex: Int,
        explicitID: AnyHashable?
    )

    case custom(
        id: AnyHashable,
        occurrence: Int
    )

    case lineBreak(
        componentIndex: Int,
        explicitID: AnyHashable?
    )
}

private enum BentoSentenceRenderSignature: Hashable {
    case text(
        componentIndex: Int,
        wordIndex: Int,
        value: String,
        explicitID: AnyHashable?
    )

    case custom(
        id: AnyHashable,
        occurrence: Int,
        revision: AnyHashable?
    )

    case lineBreak(
        componentIndex: Int,
        explicitID: AnyHashable?
    )
}

private enum BentoSentenceRenderContent {
    case word(
        value: String,
        accessibilityLabel: Text?
    )

    case custom(() -> AnyView)
    case lineBreak
}

private struct BentoSentenceRenderItem: Identifiable {
    let id: BentoSentenceRenderID
    let signature: BentoSentenceRenderSignature
    let content: BentoSentenceRenderContent
    let joinsPrevious: Bool
    let joinsNext: Bool
    let isGap: Bool
    let isLineBreak: Bool
    var leadingSpacing: CGFloat

    func makeView(
        textStyle: BentoTextStyle
    ) -> AnyView {
        switch content {
        case .word(
            let value,
            let accessibilityLabel
        ):
            return AnyView(
                BentoSentenceWordView(
                    value: value,
                    textStyle: textStyle,
                    accessibilityLabel:
                        accessibilityLabel
                )
            )

        case .custom(let makeView):
            return makeView()

        case .lineBreak:
            return AnyView(
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            )
        }
    }
}

// MARK: - Flow layout values

private struct BentoSentenceLeadingSpacingKey:
    LayoutValueKey {
    static let defaultValue: CGFloat = 0
}

private struct BentoSentenceLineBreakKey:
    LayoutValueKey {
    static let defaultValue = false
}

private struct BentoSentenceBaselineInsetKey:
    LayoutValueKey {
    static let defaultValue: CGFloat = -1
}

// MARK: - Flow layout

private struct BentoSentenceFlowLayout: Layout {
    typealias Cache = Void

    let lineSpacing: CGFloat
    let horizontalAlignment:
        BentoSentenceHorizontalAlignment
    let lineAlignment: BentoSentenceLineAlignment
    let isRightToLeft: Bool

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        arrangement(
            proposal: proposal,
            subviews: subviews
        ).size
    }

    func placeSubviews(
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

        for index in subviews.indices {
            guard arrangement.frames.indices
                    .contains(index),
                  let frame =
                    arrangement.frames[index] else {
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
    ) -> BentoSentenceArrangement {
        guard !subviews.isEmpty else {
            return BentoSentenceArrangement(
                size: CGSize(
                    width: proposal.width ?? 0,
                    height: 0
                ),
                frames: []
            )
        }

        let proposedWidth = proposal.width

        let availableWidth: CGFloat = {
            guard let proposedWidth,
                  proposedWidth.isFinite else {
                return .greatestFiniteMagnitude
            }

            return max(0, proposedWidth)
        }()

        var rows: [BentoSentenceMeasuredRow] = []
        var currentItems: [BentoSentenceMeasuredItem] = []
        var currentWidth: CGFloat = 0

        func flushCurrentRow() {
            guard !currentItems.isEmpty else {
                return
            }

            rows.append(
                makeRow(
                    items: currentItems,
                    width: currentWidth
                )
            )

            currentItems.removeAll(
                keepingCapacity: true
            )
            currentWidth = 0
        }

        for index in subviews.indices {
            let subview = subviews[index]

            if subview[BentoSentenceLineBreakKey.self] {
                flushCurrentRow()
                continue
            }

            var item = measure(
                subview: subview,
                index: index,
                maximumWidth: availableWidth
            )

            var leadingSpacing =
                currentItems.isEmpty
                ? 0
                : max(
                    0,
                    subview[
                        BentoSentenceLeadingSpacingKey.self
                    ]
                )

            if !currentItems.isEmpty,
               currentWidth
                + leadingSpacing
                + item.size.width
                > availableWidth {
                flushCurrentRow()
                leadingSpacing = 0
            }

            item.leadingSpacing = leadingSpacing

            if currentItems.isEmpty {
                currentWidth = item.size.width
            } else {
                currentWidth +=
                    leadingSpacing + item.size.width
            }

            currentItems.append(item)
        }

        flushCurrentRow()

        let maximumRowWidth =
            rows.map(\.width).max() ?? 0

        let contentWidth: CGFloat = {
            guard let proposedWidth,
                  proposedWidth.isFinite else {
                return maximumRowWidth
            }

            return max(0, proposedWidth)
        }()

        var frames = Array<CGRect?>(
            repeating: nil,
            count: subviews.count
        )

        var currentY: CGFloat = 0

        for row in rows {
            let rowOriginX = horizontalOrigin(
                rowWidth: row.width,
                containerWidth: contentWidth
            )

            if isRightToLeft {
                var currentX =
                    rowOriginX + row.width

                for (
                    logicalIndex,
                    item
                ) in row.items.enumerated() {
                    if logicalIndex > 0 {
                        currentX -= item.leadingSpacing
                    }

                    currentX -= item.size.width

                    frames[item.index] = CGRect(
                        x: currentX,
                        y: currentY
                            + verticalOffset(
                                item: item,
                                row: row
                            ),
                        width: item.size.width,
                        height: item.size.height
                    )
                }
            } else {
                var currentX = rowOriginX

                for (
                    logicalIndex,
                    item
                ) in row.items.enumerated() {
                    if logicalIndex > 0 {
                        currentX += item.leadingSpacing
                    }

                    frames[item.index] = CGRect(
                        x: currentX,
                        y: currentY
                            + verticalOffset(
                                item: item,
                                row: row
                            ),
                        width: item.size.width,
                        height: item.size.height
                    )

                    currentX += item.size.width
                }
            }

            currentY += row.height + lineSpacing
        }

        let contentHeight = rows.isEmpty
            ? 0
            : max(0, currentY - lineSpacing)

        return BentoSentenceArrangement(
            size: CGSize(
                width: contentWidth,
                height: contentHeight
            ),
            frames: frames
        )
    }

    private func measure(
        subview: LayoutSubview,
        index: Int,
        maximumWidth: CGFloat
    ) -> BentoSentenceMeasuredItem {
        var dimensions =
            subview.dimensions(in: .unspecified)

        if maximumWidth.isFinite,
           dimensions.width > maximumWidth {
            dimensions = subview.dimensions(
                in: ProposedViewSize(
                    width: maximumWidth,
                    height: nil
                )
            )
        }

        let rawWidth = dimensions.width.isFinite
            ? max(0, dimensions.width)
            : 0

        let width = maximumWidth.isFinite
            ? min(maximumWidth, rawWidth)
            : rawWidth

        let height = dimensions.height.isFinite
            ? max(0, dimensions.height)
            : 0

        let customBaselineInset =
            subview[BentoSentenceBaselineInsetKey.self]

        let baseline: CGFloat

        if customBaselineInset >= 0 {
            baseline = max(
                0,
                height - customBaselineInset
            )
        } else {
            let proposedBaseline =
                dimensions[
                    VerticalAlignment.firstTextBaseline
                ]

            if proposedBaseline.isFinite {
                baseline = min(
                    height,
                    max(0, proposedBaseline)
                )
            } else {
                baseline = height
            }
        }

        return BentoSentenceMeasuredItem(
            index: index,
            size: CGSize(
                width: width,
                height: height
            ),
            baseline: baseline,
            leadingSpacing: 0
        )
    }

    private func makeRow(
        items: [BentoSentenceMeasuredItem],
        width: CGFloat
    ) -> BentoSentenceMeasuredRow {
        switch lineAlignment {
        case .center:
            return BentoSentenceMeasuredRow(
                items: items,
                width: width,
                height:
                    items.map(\.size.height).max()
                    ?? 0,
                baseline: 0
            )

        case .firstTextBaseline:
            let baseline =
                items.map(\.baseline).max() ?? 0

            let maximumDescent =
                items.map {
                    max(
                        0,
                        $0.size.height - $0.baseline
                    )
                }
                .max() ?? 0

            return BentoSentenceMeasuredRow(
                items: items,
                width: width,
                height: baseline + maximumDescent,
                baseline: baseline
            )
        }
    }

    private func verticalOffset(
        item: BentoSentenceMeasuredItem,
        row: BentoSentenceMeasuredRow
    ) -> CGFloat {
        switch lineAlignment {
        case .center:
            return max(
                0,
                (row.height - item.size.height) / 2
            )

        case .firstTextBaseline:
            return max(
                0,
                row.baseline - item.baseline
            )
        }
    }

    private func horizontalOrigin(
        rowWidth: CGFloat,
        containerWidth: CGFloat
    ) -> CGFloat {
        let remainingWidth = max(
            0,
            containerWidth - rowWidth
        )

        switch horizontalAlignment {
        case .center:
            return remainingWidth / 2

        case .leading:
            return isRightToLeft
                ? remainingWidth
                : 0

        case .trailing:
            return isRightToLeft
                ? 0
                : remainingWidth
        }
    }
}

private struct BentoSentenceMeasuredItem {
    let index: Int
    let size: CGSize
    let baseline: CGFloat
    var leadingSpacing: CGFloat
}

private struct BentoSentenceMeasuredRow {
    let items: [BentoSentenceMeasuredItem]
    let width: CGFloat
    let height: CGFloat
    let baseline: CGFloat
}

private struct BentoSentenceArrangement {
    let size: CGSize
    let frames: [CGRect?]
}