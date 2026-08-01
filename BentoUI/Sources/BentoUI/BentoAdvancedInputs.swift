import SwiftUI
import CoreTransferable
import UIKit

// MARK: - OTP field

public enum BentoOTPAlphabet: Sendable {
    case digits
    case alphanumeric

    fileprivate var keyboardType: UIKeyboardType {
        switch self {
        case .digits:
            .numberPad
        case .alphanumeric:
            .asciiCapable
        }
    }
}

public struct BentoOTPField: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var code: String
    @FocusState private var isFocused: Bool

    private let length: Int
    private let alphabet: BentoOTPAlphabet
    private let isSecure: Bool
    private let uppercasesInput: Bool
    private let accessibilityLabel: Text
    private let onComplete: (String) -> Void

    @State private var lastCompletedCode: String?

    public init(
        code: Binding<String>,
        length: Int = 6,
        alphabet: BentoOTPAlphabet = .digits,
        isSecure: Bool = false,
        uppercasesInput: Bool = true,
        accessibilityLabel: Text = Text("Verification code"),
        onComplete: @escaping (String) -> Void = { _ in }
    ) {
        self._code = code
        self.length = min(max(1, length), 12)
        self.alphabet = alphabet
        self.isSecure = isSecure
        self.uppercasesInput = uppercasesInput
        self.accessibilityLabel = accessibilityLabel
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(0..<length, id: \.self) { index in
                        characterBox(at: index)
                    }
                }
                .padding(.vertical, theme.spacing.xxs)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            .accessibilityHidden(true)

            TextField("", text: $code)
                .focused($isFocused)
                .keyboardType(alphabet.keyboardType)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(
                    Text("\(code.count) of \(length) characters")
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            sanitizeCode()
        }
        .onChange(of: code) {
            sanitizeCode()
            reportCompletionIfNeeded()
        }
    }

    private var characters: [Character] {
        Array(code)
    }

    private var activeIndex: Int {
        min(code.count, length - 1)
    }

    private func characterBox(
        at index: Int
    ) -> some View {
        let character = characters.indices.contains(index)
            ? String(characters[index])
            : ""

        let displaysFocus = isFocused
            && index == activeIndex
            && code.count < length

        return Text(
            verbatim: isSecure && !character.isEmpty
                ? "•"
                : character
        )
        .bentoTextStyle(.title2)
        .frame(width: 48, height: 56)
        .foregroundStyle(theme.colors.onSurface)
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
                displaysFocus
                    ? theme.colors.focus
                    : theme.colors.outline,
                lineWidth: displaysFocus
                    ? theme.borders.strong
                    : theme.borders.regular
            )
        }
    }

    private func sanitizeCode() {
        var sanitized = code.filter(isAllowed)

        if uppercasesInput {
            sanitized = sanitized.uppercased()
        }

        sanitized = String(sanitized.prefix(length))

        if code != sanitized {
            code = sanitized
        }

        if sanitized.count < length {
            lastCompletedCode = nil
        }
    }

    private func isAllowed(_ character: Character) -> Bool {
        switch alphabet {
        case .digits:
            return character.wholeNumberValue != nil

        case .alphanumeric:
            return String(character)
                .unicodeScalars
                .allSatisfy {
                    CharacterSet.alphanumerics.contains($0)
                }
        }
    }

    private func reportCompletionIfNeeded() {
        guard code.count == length,
              lastCompletedCode != code else {
            return
        }

        lastCompletedCode = code
        onComplete(code)
    }
}

// MARK: - Tag input

public enum BentoTagRejectionReason {
    case empty
    case duplicate
    case invalid
    case limitReached
}

public struct BentoTagInput: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var tags: [String]

    private let label: Text?
    private let placeholder: Text
    private let maximumCount: Int
    private let tone: BentoTone
    private let normalize: (String) -> String
    private let validate: (String) -> Bool
    private let onRejected: (String, BentoTagRejectionReason) -> Void

    @State private var draft = ""

    public init(
        tags: Binding<[String]>,
        label: Text? = nil,
        placeholder: Text = Text("Add tag"),
        maximumCount: Int = 20,
        tone: BentoTone = .accent,
        normalize: @escaping (String) -> String = {
            $0.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        },
        validate: @escaping (String) -> Bool = {
            !$0.isEmpty
        },
        onRejected: @escaping (
            String,
            BentoTagRejectionReason
        ) -> Void = { _, _ in }
    ) {
        self._tags = tags
        self.label = label
        self.placeholder = placeholder
        self.maximumCount = max(0, maximumCount)
        self.tone = tone
        self.normalize = normalize
        self.validate = validate
        self.onRejected = onRejected
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                label.bentoTextStyle(.callout)
            }

            BentoFlowLayout(spacing: theme.spacing.xs) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }

                if tags.count < maximumCount {
                    TextField(
                        "",
                        text: $draft,
                        prompt: placeholder
                    )
                    .bentoTextStyle(.body, color: theme.colors.onSurface)
                    .foregroundStyle(theme.colors.onSurface)
                    .submitLabel(.done)
                    .frame(
                        minWidth: 120,
                        minHeight: theme.sizing.minimumTouchTarget
                    )
                    .onSubmit(commitDraft)
                    .onChange(of: draft) {
                        consumeDelimiters()
                    }
                }
            }
            .padding(theme.spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    theme.colors.outline,
                    lineWidth: theme.borders.regular
                )
            }

            Text("\(tags.count) of \(maximumCount) tags")
                .bentoTextStyle(
                    .caption,
                    color: theme.colors.onSurfaceMuted
                )
        }
        .onAppear(perform: sanitizeExistingTags)
    }

    private func tagView(_ tag: String) -> some View {
        HStack(spacing: theme.spacing.xxs) {
            Text(verbatim: tag)
                .bentoTextStyle(.callout)

            Button {
                tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text("Remove \(tag)")
            )
        }
        .padding(.leading, theme.spacing.sm)
        .padding(.trailing, theme.spacing.xxs)
        .frame(minHeight: theme.sizing.minimumTouchTarget)
        .foregroundStyle(theme.colors.foreground(for: tone))
        .background(
            theme.colors.fill(for: tone),
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

    private func consumeDelimiters() {
        let components = draft.split(
            omittingEmptySubsequences: false
        ) {
            $0 == "," || $0 == ";"
        }

        guard components.count > 1 else {
            return
        }

        for component in components.dropLast() {
            _ = addTag(String(component))
        }

        draft = String(components.last ?? "")
    }

    private func commitDraft() {
        if addTag(draft) {
            draft = ""
        }
    }

    @discardableResult
    private func addTag(_ rawValue: String) -> Bool {
        let tag = normalize(rawValue)

        guard !tag.isEmpty else {
            onRejected(rawValue, .empty)
            return false
        }

        guard tags.count < maximumCount else {
            onRejected(tag, .limitReached)
            return false
        }

        guard validate(tag) else {
            onRejected(tag, .invalid)
            return false
        }

        guard !tags.contains(
            where: {
                $0.compare(
                    tag,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            }
        ) else {
            onRejected(tag, .duplicate)
            return false
        }

        tags.append(tag)
        return true
    }

    private func sanitizeExistingTags() {
        var sanitized: [String] = []

        for rawValue in tags {
            let tag = normalize(rawValue)

            guard !tag.isEmpty,
                  validate(tag),
                  sanitized.count < maximumCount,
                  !sanitized.contains(
                    where: {
                        $0.compare(
                            tag,
                            options: [
                                .caseInsensitive,
                                .diacriticInsensitive
                            ]
                        ) == .orderedSame
                    }
                  ) else {
                continue
            }

            sanitized.append(tag)
        }

        if sanitized != tags {
            tags = sanitized
        }
    }
}

// MARK: - Range slider

public struct BentoRangeSlider: View {
    private enum Thumb {
        case lower
        case upper
    }

    @Environment(\.bentoTheme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection

    @Namespace private var coordinateSpace

    @Binding private var selection: ClosedRange<Double>

    private let bounds: ClosedRange<Double>
    private let step: Double
    private let title: Text
    private let formatValue: (Double) -> String

    @State private var activeThumb: Thumb?

    public init(
        _ title: Text,
        selection: Binding<ClosedRange<Double>>,
        in bounds: ClosedRange<Double>,
        step: Double = 1,
        formatValue: @escaping (Double) -> String = {
            $0.formatted(
                .number.precision(
                    .fractionLength(0...2)
                )
            )
        }
    ) {
        self.title = title
        self._selection = selection
        self.bounds = bounds
        self.step = step
        self.formatValue = formatValue
    }

    private var span: Double {
        bounds.upperBound - bounds.lowerBound
    }

    private var isValid: Bool {
        bounds.lowerBound.isFinite
            && bounds.upperBound.isFinite
            && span > 0
    }

    private var safeStep: Double {
        guard isValid else {
            return 1
        }

        guard step.isFinite, step > 0 else {
            return span / 100
        }

        return min(step, span)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                title.bentoTextStyle(.bodyStrong)

                Spacer()

                Text(
                    verbatim:
                        "\(formatValue(selection.lowerBound)) – "
                        + "\(formatValue(selection.upperBound))"
                )
                .bentoTextStyle(.callout)
            }

            GeometryReader { geometry in
                let thumbDiameter: CGFloat = 30
                let thumbRadius = thumbDiameter / 2
                let usableWidth = max(
                    0,
                    geometry.size.width - thumbDiameter
                )

                let lowerX = thumbRadius + positionFraction(
                    for: selection.lowerBound
                ) * usableWidth

                let upperX = thumbRadius + positionFraction(
                    for: selection.upperBound
                ) * usableWidth

                let selectedMinimumX = min(lowerX, upperX)
                let selectedMaximumX = max(lowerX, upperX)

                ZStack {
                    Capsule()
                        .fill(theme.colors.surfaceSecondary)
                        .frame(
                            width: geometry.size.width,
                            height: 10
                        )

                    Capsule()
                        .fill(theme.colors.accent)
                        .frame(
                            width: max(
                                10,
                                selectedMaximumX - selectedMinimumX
                            ),
                            height: 10
                        )
                        .position(
                            x: (
                                selectedMinimumX
                                + selectedMaximumX
                            ) / 2,
                            y: geometry.size.height / 2
                        )

                    thumbView(
                        .lower,
                        value: selection.lowerBound,
                        x: lowerX,
                        usableWidth: usableWidth,
                        diameter: thumbDiameter
                    )

                    thumbView(
                        .upper,
                        value: selection.upperBound,
                        x: upperX,
                        usableWidth: usableWidth,
                        diameter: thumbDiameter
                    )
                }
                .coordinateSpace(name: coordinateSpace)
            }
            .frame(height: 52)
            .disabled(!isValid)
        }
        .onAppear(perform: sanitizeSelection)
        .onChange(of: selection) {
            sanitizeSelection()
        }
    }

    private func thumbView(
        _ thumb: Thumb,
        value: Double,
        x: CGFloat,
        usableWidth: CGFloat,
        diameter: CGFloat
    ) -> some View {
        Circle()
            .fill(theme.colors.surface)
            .frame(width: diameter, height: diameter)
            .overlay {
                Circle()
                    .strokeBorder(
                        activeThumb == thumb
                            ? theme.colors.focus
                            : theme.colors.outline,
                        lineWidth: activeThumb == thumb
                            ? theme.borders.strong
                            : theme.borders.regular
                    )
            }
            .shadow(
                color: theme.colors.chrome.opacity(0.16),
                radius: 4,
                y: 2
            )
            .position(
                x: x,
                y: 26
            )
            .gesture(
                DragGesture(
                    minimumDistance: 0,
                    coordinateSpace: .named(coordinateSpace)
                )
                .onChanged { gesture in
                    activeThumb = thumb

                    update(
                        thumb,
                        locationX: gesture.location.x,
                        usableWidth: usableWidth,
                        thumbRadius: diameter / 2
                    )
                }
                .onEnded { _ in
                    activeThumb = nil
                }
            )
            .accessibilityLabel(
                thumb == .lower
                    ? Text("Minimum")
                    : Text("Maximum")
            )
            .accessibilityValue(
                Text(verbatim: formatValue(value))
            )
            .accessibilityAdjustableAction { direction in
                adjust(thumb, direction: direction)
            }
    }

    private func positionFraction(
        for value: Double
    ) -> CGFloat {
        guard isValid else {
            return 0
        }

        let normalized = min(
            1,
            max(
                0,
                (value - bounds.lowerBound) / span
            )
        )

        let directionalValue = layoutDirection == .rightToLeft
            ? 1 - normalized
            : normalized

        return CGFloat(directionalValue)
    }

    private func update(
        _ thumb: Thumb,
        locationX: CGFloat,
        usableWidth: CGFloat,
        thumbRadius: CGFloat
    ) {
        guard isValid, usableWidth > 0 else {
            return
        }

        var fraction = Double(
            min(
                1,
                max(
                    0,
                    (locationX - thumbRadius) / usableWidth
                )
            )
        )

        if layoutDirection == .rightToLeft {
            fraction = 1 - fraction
        }

        let rawValue =
            bounds.lowerBound + fraction * span

        let value = quantized(rawValue)

        switch thumb {
        case .lower:
            selection = min(value, selection.upperBound)...selection.upperBound

        case .upper:
            selection = selection.lowerBound...max(value, selection.lowerBound)
        }
    }

    private func adjust(
        _ thumb: Thumb,
        direction: AccessibilityAdjustmentDirection
    ) {
        let delta: Double

        switch direction {
        case .increment:
            delta = safeStep

        case .decrement:
            delta = -safeStep

        @unknown default:
            return
        }

        switch thumb {
        case .lower:
            let next = min(
                selection.upperBound,
                max(
                    bounds.lowerBound,
                    selection.lowerBound + delta
                )
            )

            selection = quantized(next)...selection.upperBound

        case .upper:
            let next = max(
                selection.lowerBound,
                min(
                    bounds.upperBound,
                    selection.upperBound + delta
                )
            )

            selection = selection.lowerBound...quantized(next)
        }
    }

    private func quantized(_ value: Double) -> Double {
        guard isValid else {
            return bounds.lowerBound
        }

        let stepCount = (
            (value - bounds.lowerBound) / safeStep
        ).rounded()

        let quantized =
            bounds.lowerBound + stepCount * safeStep

        return min(
            bounds.upperBound,
            max(bounds.lowerBound, quantized)
        )
    }

    private func sanitizeSelection() {
        guard isValid else {
            return
        }

        let rawLower = selection.lowerBound.isFinite
            ? selection.lowerBound
            : bounds.lowerBound

        let rawUpper = selection.upperBound.isFinite
            ? selection.upperBound
            : bounds.upperBound

        let clampedLower = min(
            bounds.upperBound,
            max(bounds.lowerBound, rawLower)
        )

        let clampedUpper = min(
            bounds.upperBound,
            max(bounds.lowerBound, rawUpper)
        )

        let safeLower = min(clampedLower, clampedUpper)
        let safeUpper = max(clampedLower, clampedUpper)
        let sanitized = safeLower...safeUpper

        if selection != sanitized {
            selection = sanitized
        }
    }
}

// MARK: - Date picker field

public enum BentoDatePickerPresentation: Equatable, Sendable {
    case compact
    case graphical
    case wheel
}

public struct BentoDatePickerField: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selection: Date

    private let label: Text
    private let displayedComponents: DatePickerComponents
    private let allowedRange: ClosedRange<Date>?
    private let presentation: BentoDatePickerPresentation

    public init(
        _ label: Text,
        selection: Binding<Date>,
        in allowedRange: ClosedRange<Date>? = nil,
        displayedComponents: DatePickerComponents = [
            .date
        ],
        presentation: BentoDatePickerPresentation = .compact
    ) {
        self.label = label
        self._selection = selection
        self.allowedRange = allowedRange
        self.displayedComponents = displayedComponents
        self.presentation = presentation
    }

    public var body: some View {
        Group {
            if presentation == .graphical {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.sm
                ) {
                    label.bentoTextStyle(.bodyStrong)
                    configuredPicker
                }
            } else {
                HStack(spacing: theme.spacing.sm) {
                    label.bentoTextStyle(.bodyStrong)
                    Spacer()
                    configuredPicker
                }
            }
        }
        .padding(theme.spacing.sm)
        .foregroundStyle(theme.colors.onSurface)
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
                theme.colors.outline,
                lineWidth: theme.borders.regular
            )
        }
        .onAppear(perform: sanitizeSelection)
        .onChange(of: selection) {
            sanitizeSelection()
        }
    }

    @ViewBuilder
    private var picker: some View {
        if let allowedRange {
            DatePicker(
                "",
                selection: $selection,
                in: allowedRange,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
        } else {
            DatePicker(
                "",
                selection: $selection,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var configuredPicker: some View {
        switch presentation {
        case .compact:
            picker.datePickerStyle(.compact)

        case .graphical:
            picker.datePickerStyle(.graphical)

        case .wheel:
            picker.datePickerStyle(.wheel)
        }
    }

    private func sanitizeSelection() {
        guard let allowedRange else {
            return
        }

        selection = min(
            allowedRange.upperBound,
            max(allowedRange.lowerBound, selection)
        )
    }
}

// MARK: - Drop zone

public struct BentoDropZone<
    Item: Transferable
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let message: Text
    private let systemImage: String
    private let supportsMultipleItems: Bool
    private let onTap: (() -> Void)?
    private let onDrop: ([Item]) -> Bool

    @State private var isTargeted = false

    public init(
        for type: Item.Type = Item.self,
        title: Text,
        message: Text,
        systemImage: String = "square.and.arrow.down",
        supportsMultipleItems: Bool = true,
        onTap: (() -> Void)? = nil,
        onDrop: @escaping ([Item]) -> Bool
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.supportsMultipleItems = supportsMultipleItems
        self.onTap = onTap
        self.onDrop = onDrop
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.colors.accent)
                .accessibilityHidden(true)

            title
                .bentoTextStyle(.headline)
                .multilineTextAlignment(.center)

            message
                .bentoTextStyle(
                    .callout,
                    color: theme.colors.onSurfaceMuted
                )
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xl)
        .background(
            isTargeted
                ? theme.colors.accent.opacity(0.18)
                : theme.colors.surfaceSecondary,
            in: RoundedRectangle(
                cornerRadius: theme.radii.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: theme.radii.large,
                style: .continuous
            )
            .strokeBorder(
                isTargeted
                    ? theme.colors.focus
                    : theme.colors.outline,
                style: StrokeStyle(
                    lineWidth: isTargeted
                        ? theme.borders.strong
                        : theme.borders.regular,
                    dash: [8, 6]
                )
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(
            onTap == nil ? [] : .isButton
        )
        .accessibilityAction {
            onTap?()
        }
        .dropDestination(
            for: Item.self
        ) { items, _ in
            let acceptedItems = supportsMultipleItems
                ? items
                : Array(items.prefix(1))

            return onDrop(acceptedItems)
        } isTargeted: { targeted in
            withAnimation(theme.motion.fast) {
                isTargeted = targeted
            }
        }
    }
}