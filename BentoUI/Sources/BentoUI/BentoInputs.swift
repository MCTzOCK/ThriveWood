import SwiftUI
import UIKit

public struct BentoFieldStatus {
    public enum Kind {
        case normal
        case success
        case warning
        case error
    }

    public let kind: Kind
    public let message: Text?

    public init(
        kind: Kind,
        message: Text? = nil
    ) {
        self.kind = kind
        self.message = message
    }

    public static var normal: BentoFieldStatus {
        BentoFieldStatus(kind: .normal)
    }

    public static func success(
        _ message: Text? = nil
    ) -> BentoFieldStatus {
        BentoFieldStatus(kind: .success, message: message)
    }

    public static func warning(
        _ message: Text? = nil
    ) -> BentoFieldStatus {
        BentoFieldStatus(kind: .warning, message: message)
    }

    public static func error(
        _ message: Text? = nil
    ) -> BentoFieldStatus {
        BentoFieldStatus(kind: .error, message: message)
    }

    fileprivate func color(in theme: BentoTheme) -> Color {
        switch kind {
        case .normal:
            theme.colors.outline
        case .success:
            theme.colors.success
        case .warning:
            theme.colors.warning
        case .error:
            theme.colors.danger
        }
    }

    fileprivate var symbol: String? {
        switch kind {
        case .normal:
            nil
        case .success:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.circle.fill"
        }
    }
}

private struct BentoFieldLabel: View {
    @Environment(\.bentoTheme) private var theme

    let label: Text
    let required: Bool

    var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            label.bentoTextStyle(.callout)

            if required {
                Text("*")
                    .bentoTextStyle(
                        .callout,
                        color: theme.colors.danger
                    )
                    .accessibilityLabel(Text("Required"))
            }
        }
    }
}

private struct BentoFieldFooter: View {
    @Environment(\.bentoTheme) private var theme

    let status: BentoFieldStatus
    let count: Int
    let maximumCount: Int?

    var body: some View {
        if status.message != nil || maximumCount != nil {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.xs) {
                if let message = status.message {
                    HStack(spacing: theme.spacing.xxs) {
                        if let symbol = status.symbol {
                            Image(systemName: symbol)
                                .accessibilityHidden(true)
                        }

                        message
                    }
                    .bentoTextStyle(
                        .caption,
                        color: status.kind == .normal
                            ? theme.colors.onSurfaceMuted
                            : status.color(in: theme)
                    )
                }

                Spacer(minLength: theme.spacing.xs)

                if let maximumCount {
                    Text("\(count)/\(maximumCount)")
                        .bentoTextStyle(
                            .caption,
                            color: count > maximumCount
                                ? theme.colors.danger
                                : theme.colors.onSurfaceMuted
                        )
                        .accessibilityLabel(
                            Text("\(count) of \(maximumCount) characters")
                        )
                }
            }
        }
    }
}

public struct BentoTextField: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var text: String
    @FocusState private var internallyFocused: Bool

    private let label: Text?
    private let prompt: Text?
    private let accessibilityLabel: Text?
    private let leadingSystemImage: String?
    private let isSecure: Bool
    private let required: Bool
    private let showsClearButton: Bool
    private let status: BentoFieldStatus
    private let maximumLength: Int?
    private let keyboardType: UIKeyboardType
    private let contentType: UITextContentType?
    private let capitalization: TextInputAutocapitalization
    private let autocorrectionDisabled: Bool
    private let submitLabel: SubmitLabel
    private let externalFocus: Binding<Bool>?
    private let onSubmit: () -> Void

    @State private var revealsSecureValue = false

    public init(
        label: Text? = nil,
        text: Binding<String>,
        prompt: Text? = nil,
        accessibilityLabel: Text? = nil,
        leadingSystemImage: String? = nil,
        isSecure: Bool = false,
        required: Bool = false,
        showsClearButton: Bool = true,
        status: BentoFieldStatus = .normal,
        maximumLength: Int? = nil,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        submitLabel: SubmitLabel = .done,
        isFocused: Binding<Bool>? = nil,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.label = label
        self._text = text
        self.prompt = prompt
        self.accessibilityLabel = accessibilityLabel
        self.leadingSystemImage = leadingSystemImage
        self.isSecure = isSecure
        self.required = required
        self.showsClearButton = showsClearButton
        self.status = status
        self.maximumLength = maximumLength.map { max(0, $0) }
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.capitalization = capitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.submitLabel = submitLabel
        self.externalFocus = isFocused
        self.onSubmit = onSubmit
    }

    private var resolvedAccessibilityLabel: Text {
        accessibilityLabel
            ?? label
            ?? prompt
            ?? Text("Text field")
    }

    private var borderColor: Color {
        if status.kind != .normal {
            return status.color(in: theme)
        }

        return internallyFocused
            ? theme.colors.focus
            : theme.colors.outline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                BentoFieldLabel(
                    label: label,
                    required: required
                )
            }

            HStack(spacing: theme.spacing.xs) {
                if let leadingSystemImage {
                    Image(systemName: leadingSystemImage)
                        .frame(width: 22)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                        .accessibilityHidden(true)
                }

                Group {
                    if isSecure && !revealsSecureValue {
                        SecureField(
                            "",
                            text: $text,
                            prompt: prompt
                        )
                    } else {
                        TextField(
                            "",
                            text: $text,
                            prompt: prompt
                        )
                    }
                }
                .focused($internallyFocused)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .bentoTextStyle(.body, color: theme.colors.onSurface)
                .foregroundStyle(theme.colors.onSurface)
                .accessibilityLabel(resolvedAccessibilityLabel)

                if showsClearButton, !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                            .frame(
                                width: theme.sizing.minimumTouchTarget,
                                height: theme.sizing.minimumTouchTarget
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear text"))
                }

                if isSecure {
                    Button {
                        revealsSecureValue.toggle()
                        internallyFocused = true
                    } label: {
                        Image(
                            systemName: revealsSecureValue
                                ? "eye.slash.fill"
                                : "eye.fill"
                        )
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                        .frame(
                            width: theme.sizing.minimumTouchTarget,
                            height: theme.sizing.minimumTouchTarget
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        revealsSecureValue
                            ? Text("Hide password")
                            : Text("Show password")
                    )
                }
            }
            .padding(.leading, theme.spacing.sm)
            .padding(.trailing, theme.spacing.xxs)
            .frame(minHeight: theme.sizing.controlMedium)
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
                    borderColor,
                    lineWidth: internallyFocused
                        ? theme.borders.strong
                        : theme.borders.regular
                )
            }

            BentoFieldFooter(
                status: status,
                count: text.count,
                maximumCount: maximumLength
            )
        }
        .onAppear {
            if let externalFocus {
                internallyFocused = externalFocus.wrappedValue
            }

            enforceMaximumLength()
        }
        .onChange(of: text) {
            enforceMaximumLength()
        }
        .onChange(of: internallyFocused) { _, newValue in
            externalFocus?.wrappedValue = newValue
        }
        .onChange(of: externalFocus?.wrappedValue) { _, newValue in
            if let newValue, internallyFocused != newValue {
                internallyFocused = newValue
            }
        }
    }

    private func enforceMaximumLength() {
        guard let maximumLength,
              text.count > maximumLength else {
            return
        }

        text = String(text.prefix(maximumLength))
    }
}

public struct BentoTextArea: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var text: String
    @FocusState private var focused: Bool

    private let label: Text?
    private let prompt: Text
    private let required: Bool
    private let status: BentoFieldStatus
    private let maximumLength: Int?
    private let minimumHeight: CGFloat

    public init(
        label: Text? = nil,
        text: Binding<String>,
        prompt: Text,
        required: Bool = false,
        status: BentoFieldStatus = .normal,
        maximumLength: Int? = nil,
        minimumHeight: CGFloat = 130
    ) {
        self.label = label
        self._text = text
        self.prompt = prompt
        self.required = required
        self.status = status
        self.maximumLength = maximumLength.map { max(0, $0) }
        self.minimumHeight = max(90, minimumHeight)
    }

    private var borderColor: Color {
        if status.kind != .normal {
            return status.color(in: theme)
        }

        return focused ? theme.colors.focus : theme.colors.outline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                BentoFieldLabel(
                    label: label,
                    required: required
                )
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    prompt
                        .bentoTextStyle(
                            .body,
                            color: theme.colors.onSurfaceMuted
                        )
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.sm + 1)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .bentoTextStyle(.body, color: theme.colors.onSurface)
                    .foregroundStyle(theme.colors.onSurface)
                    .padding(.horizontal, theme.spacing.xs)
                    .padding(.vertical, theme.spacing.xxs)
                    .frame(minHeight: minimumHeight)
                    .accessibilityLabel(label ?? prompt)
            }
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
                    borderColor,
                    lineWidth: focused
                        ? theme.borders.strong
                        : theme.borders.regular
                )
            }

            BentoFieldFooter(
                status: status,
                count: text.count,
                maximumCount: maximumLength
            )
        }
        .onAppear(perform: enforceMaximumLength)
        .onChange(of: text) {
            enforceMaximumLength()
        }
    }

    private func enforceMaximumLength() {
        guard let maximumLength,
              text.count > maximumLength else {
            return
        }

        text = String(text.prefix(maximumLength))
    }
}

public struct BentoSearchField: View {
    @Binding private var text: String

    private let prompt: Text
    private let onSubmit: () -> Void

    public init(
        text: Binding<String>,
        prompt: Text = Text("Search"),
        onSubmit: @escaping () -> Void = {}
    ) {
        self._text = text
        self.prompt = prompt
        self.onSubmit = onSubmit
    }

    public var body: some View {
        BentoTextField(
            text: $text,
            prompt: prompt,
            accessibilityLabel: Text("Search"),
            leadingSystemImage: "magnifyingglass",
            capitalization: .never,
            submitLabel: .search,
            onSubmit: onSubmit
        )
    }
}

public struct BentoToggleRow: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var isOn: Bool

    private let title: Text
    private let subtitle: Text?
    private let systemImage: String?

    public init(
        _ title: Text,
        subtitle: Text? = nil,
        systemImage: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: theme.spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    title.bentoTextStyle(.bodyStrong)

                    if let subtitle {
                        subtitle.bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                }
            }
        }
        .toggleStyle(.switch)
        .tint(theme.colors.accent)
        .padding(theme.spacing.sm)
        .background(
            theme.colors.surfaceSecondary,
            in: RoundedRectangle(
                cornerRadius: theme.radii.medium,
                style: .continuous
            )
        )
    }
}

public struct BentoCheckbox: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var isOn: Bool

    private let title: Text
    private let subtitle: Text?

    public init(
        _ title: Text,
        subtitle: Text? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(
                        isOn
                            ? theme.colors.accent
                            : theme.colors.onSurfaceMuted
                    )

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    title.bentoTextStyle(.bodyStrong)

                    if let subtitle {
                        subtitle.bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                }

                Spacer()
            }
            .frame(minHeight: theme.sizing.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: $isOn) {
                title
            }
        }
    }
}

public struct BentoRadioGroup<Option: Hashable, Label: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let options: [Option]
    @Binding private var selection: Option?
    private let label: (Option) -> Label

    public init(
        options: [Option],
        selection: Binding<Option?>,
        @ViewBuilder label: @escaping (Option) -> Label
    ) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        VStack(spacing: theme.spacing.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option

                Button {
                    selection = option
                } label: {
                    HStack(spacing: theme.spacing.sm) {
                        Image(
                            systemName: isSelected
                                ? "largecircle.fill.circle"
                                : "circle"
                        )
                        .foregroundStyle(
                            isSelected
                                ? theme.colors.accent
                                : theme.colors.onSurfaceMuted
                        )

                        label(option)
                        Spacer()
                    }
                    .frame(minHeight: theme.sizing.minimumTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

public struct BentoSegmentedPicker<Option: Hashable, Label: View>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var selectionNamespace

    private let options: [Option]
    @Binding private var selection: Option
    private let label: (Option) -> Label

    public init(
        options: [Option],
        selection: Binding<Option>,
        @ViewBuilder label: @escaping (Option) -> Label
    ) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option

                Button {
                    withAnimation(
                        reduceMotion ? nil : theme.motion.snappy
                    ) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .bentoTextStyle(.callout)
                        .foregroundStyle(
                            isSelected
                                ? theme.colors.onSurface
                                : theme.colors.onChrome.opacity(0.78)
                        )
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: theme.sizing.minimumTouchTarget)
                        .padding(.horizontal, theme.spacing.xs)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(theme.colors.surface)
                                    .matchedGeometryEffect(
                                        id: "selected-segment",
                                        in: selectionNamespace
                                    )
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(theme.spacing.xxs)
        .background(
            theme.colors.chrome,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    theme.colors.outline.opacity(0.5),
                    lineWidth: theme.borders.thin
                )
        }
    }
}

public struct BentoStepper: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var value: Int

    private let title: Text
    private let range: ClosedRange<Int>
    private let step: Int
    private let valueLabel: (Int) -> Text

    public init(
        _ title: Text,
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1,
        valueLabel: @escaping (Int) -> Text = {
            Text(verbatim: String($0))
        }
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = max(1, step)
        self.valueLabel = valueLabel
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            title.bentoTextStyle(.bodyStrong, color: theme.colors.onSurface)

            Spacer()

            BentoIconButton(
                systemImage: "minus",
                accessibilityLabel: Text("Decrease"),
                variant: .secondary,
                size: .small,
                action: decrement
            )
            .disabled(value <= range.lowerBound)

            valueLabel(value)
                .bentoTextStyle(.headline, color: theme.colors.onSurface)
                .frame(minWidth: 44)
                .contentTransition(.numericText())

            BentoIconButton(
                systemImage: "plus",
                accessibilityLabel: Text("Increase"),
                variant: .secondary,
                size: .small,
                action: increment
            )
            .disabled(value >= range.upperBound)
        }
        .onAppear(perform: clampValue)
        .onChange(of: value) {
            clampValue()
        }
    }

    private func decrement() {
        let result = value.subtractingReportingOverflow(step)
        value = result.overflow
            ? range.lowerBound
            : max(range.lowerBound, result.partialValue)
    }

    private func increment() {
        let result = value.addingReportingOverflow(step)
        value = result.overflow
            ? range.upperBound
            : min(range.upperBound, result.partialValue)
    }

    private func clampValue() {
        value = min(max(value, range.lowerBound), range.upperBound)
    }
}

public struct BentoSlider: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var value: Double

    private let title: Text
    private let range: ClosedRange<Double>
    private let step: Double
    private let valueLabel: (Double) -> Text

    public init(
        _ title: Text,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        valueLabel: @escaping (Double) -> Text = {
            Text(verbatim: $0.formatted(.number.precision(.fractionLength(0))))
        }
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.valueLabel = valueLabel
    }

    private var hasValidRange: Bool {
        range.lowerBound.isFinite
            && range.upperBound.isFinite
            && range.upperBound > range.lowerBound
    }

    private var safeStep: Double {
        guard hasValidRange else {
            return 1
        }

        let span = range.upperBound - range.lowerBound

        guard step.isFinite, step > 0 else {
            return max(span / 100, Double.leastNonzeroMagnitude)
        }

        return min(step, span)
    }

    private var safeBinding: Binding<Double> {
        Binding(
            get: {
                guard hasValidRange, value.isFinite else {
                    return hasValidRange ? range.lowerBound : 0
                }

                return min(
                    max(value, range.lowerBound),
                    range.upperBound
                )
            },
            set: {
                value = $0
            }
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                title.bentoTextStyle(.bodyStrong, color: theme.colors.onSurface)
                Spacer()
                valueLabel(value).bentoTextStyle(.headline, color: theme.colors.onSurface)
            }

            Slider(
                value: safeBinding,
                in: hasValidRange ? range : 0...1,
                step: hasValidRange ? safeStep : 1
            )
            .tint(theme.colors.accent)
            .disabled(!hasValidRange)
        }
        .onAppear(perform: sanitizeValue)
        .onChange(of: value) {
            sanitizeValue()
        }
    }

    private func sanitizeValue() {
        guard hasValidRange else {
            return
        }

        let sanitized = value.isFinite
            ? min(max(value, range.lowerBound), range.upperBound)
            : range.lowerBound

        if value != sanitized {
            value = sanitized
        }
    }
}

public struct BentoMenuPicker<Option: Hashable>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let options: [Option]
    @Binding private var selection: Option
    private let optionLabel: (Option) -> Text

    public init(
        _ title: Text,
        options: [Option],
        selection: Binding<Option>,
        optionLabel: @escaping (Option) -> Text
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.optionLabel = optionLabel
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            title.bentoTextStyle(.bodyStrong)
            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    optionLabel(option)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(options.isEmpty)
        }
        .frame(minHeight: theme.sizing.minimumTouchTarget)
    }
}
