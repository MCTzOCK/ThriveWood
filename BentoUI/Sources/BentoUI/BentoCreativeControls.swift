import SwiftUI

// MARK: - Radial dial

public struct BentoRadialDial: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var value: Double

    private let bounds: ClosedRange<Double>
    private let step: Double
    private let title: Text
    private let tone: BentoTone
    private let diameter: CGFloat
    private let trackWidth: CGFloat
    private let sweepDegrees: Double
    private let formatValue: (Double) -> Text

    @State private var isDragging = false

    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double>,
        step: Double = 1,
        title: Text,
        tone: BentoTone = .accent,
        diameter: CGFloat = 240,
        trackWidth: CGFloat = 18,
        sweepDegrees: Double = 280,
        formatValue: @escaping (Double) -> Text = {
            Text(
                verbatim: $0.formatted(
                    .number.precision(
                        .fractionLength(0...2)
                    )
                )
            )
        }
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.title = title
        self.tone = tone
        self.diameter = max(150, diameter)
        self.trackWidth = max(8, trackWidth)
        self.sweepDegrees = min(max(180, sweepDegrees), 340)
        self.formatValue = formatValue
    }

    private var span: Double {
        bounds.upperBound - bounds.lowerBound
    }

    private var hasValidRange: Bool {
        bounds.lowerBound.isFinite
            && bounds.upperBound.isFinite
            && span > 0
    }

    private var safeStep: Double {
        guard hasValidRange else {
            return 1
        }

        guard step.isFinite, step > 0 else {
            return span / 100
        }

        return min(step, span)
    }

    private var displayValue: Double {
        guard hasValidRange, value.isFinite else {
            return hasValidRange ? bounds.lowerBound : 0
        }

        return min(
            bounds.upperBound,
            max(bounds.lowerBound, value)
        )
    }

    private var progress: Double {
        guard hasValidRange else {
            return 0
        }

        return min(
            1,
            max(
                0,
                (displayValue - bounds.lowerBound) / span
            )
        )
    }

    private var startDegrees: Double {
        90 + (360 - sweepDegrees) / 2
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(
                proxy.size.width,
                proxy.size.height
            )

            let center = CGPoint(
                x: proxy.size.width / 2,
                y: proxy.size.height / 2
            )

            let radius = max(
                20,
                side / 2 - trackWidth / 2 - 10
            )

            let angle =
                startDegrees + sweepDegrees * progress

            let radians = angle * .pi / 180

            let thumbPosition = CGPoint(
                x: center.x
                    + radius * CGFloat(cos(radians)),
                y: center.y
                    + radius * CGFloat(sin(radians))
            )

            let trackFraction = CGFloat(
                sweepDegrees / 360
            )

            let progressFraction = CGFloat(
                progress * sweepDegrees / 360
            )

            ZStack {
                Circle()
                    .fill(theme.colors.surfaceSecondary)

                Circle()
                    .trim(
                        from: 0,
                        to: trackFraction
                    )
                    .stroke(
                        theme.colors.outlineSubtle,
                        style: StrokeStyle(
                            lineWidth: trackWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(startDegrees)
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: progressFraction
                    )
                    .stroke(
                        theme.colors.fill(for: tone),
                        style: StrokeStyle(
                            lineWidth: trackWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(startDegrees)
                    )

                dialTicks(
                    center: center,
                    radius: radius
                )

                VStack(spacing: theme.spacing.xs) {
                    formatValue(displayValue)
                        .bentoTextStyle(.title1)
                        .contentTransition(
                            .numericText()
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    title
                        .bentoTextStyle(
                            .caption,
                            color:
                                theme.colors.onSurfaceMuted
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(
                    width: side * 0.56
                )

                Circle()
                    .fill(theme.colors.surface)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isDragging
                                    ? theme.colors.focus
                                    : theme.colors.outline,
                                lineWidth: isDragging
                                    ? theme.borders.strong
                                    : theme.borders.regular
                            )
                    }
                    .shadow(
                        color:
                            theme.colors.chrome.opacity(0.2),
                        radius: 5,
                        y: 2
                    )
                    .position(thumbPosition)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled,
                              hasValidRange else {
                            return
                        }

                        isDragging = true

                        updateValue(
                            at: gesture.location,
                            center: center
                        )
                    }
                    .onEnded { _ in
                        withAnimation(
                            reduceMotion
                                ? nil
                                : theme.motion.fast
                        ) {
                            isDragging = false
                        }
                    }
            )
        }
        .frame(
            width: diameter,
            height: diameter
        )
        .opacity(
            isEnabled && hasValidRange ? 1 : 0.55
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(
            formatValue(displayValue)
        )
        .accessibilityAdjustableAction { direction in
            adjust(direction)
        }
        .onAppear(perform: sanitizeValue)
        .onChange(of: value) { _, _ in
            sanitizeValue()
        }
    }

    private func dialTicks(
        center: CGPoint,
        radius: CGFloat
    ) -> some View {
        ZStack {
            ForEach(0...10, id: \.self) { index in
                let fraction =
                    Double(index) / 10

                let angle =
                    startDegrees
                    + sweepDegrees * fraction

                let radians =
                    angle * .pi / 180

                Capsule()
                    .fill(
                        theme.colors.onSurfaceMuted
                            .opacity(0.42)
                    )
                    .frame(
                        width: 2,
                        height: index.isMultiple(of: 5)
                            ? 8
                            : 5
                    )
                    .rotationEffect(
                        .degrees(angle + 90)
                    )
                    .position(
                        x: center.x
                            + radius
                            * CGFloat(cos(radians)),
                        y: center.y
                            + radius
                            * CGFloat(sin(radians))
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private func updateValue(
        at location: CGPoint,
        center: CGPoint
    ) {
        let deltaX =
            Double(location.x - center.x)

        let deltaY =
            Double(location.y - center.y)

        var angle =
            atan2(deltaY, deltaX) * 180 / .pi

        if angle < 0 {
            angle += 360
        }

        let normalizedStart =
            startDegrees
            .truncatingRemainder(
                dividingBy: 360
            )

        var delta =
            (angle - normalizedStart + 360)
            .truncatingRemainder(
                dividingBy: 360
            )

        if delta > sweepDegrees {
            let distanceToEnd =
                delta - sweepDegrees

            let distanceToStart =
                360 - delta

            delta = distanceToStart
                < distanceToEnd
                ? 0
                : sweepDegrees
        }

        let fraction = min(
            1,
            max(0, delta / sweepDegrees)
        )

        let rawValue =
            bounds.lowerBound
            + fraction * span

        setValue(
            quantized(rawValue)
        )
    }

    private func adjust(
        _ direction:
            AccessibilityAdjustmentDirection
    ) {
        guard isEnabled, hasValidRange else {
            return
        }

        switch direction {
        case .increment:
            setValue(
                quantized(
                    displayValue + safeStep
                )
            )

        case .decrement:
            setValue(
                quantized(
                    displayValue - safeStep
                )
            )

        @unknown default:
            break
        }
    }

    private func quantized(
        _ rawValue: Double
    ) -> Double {
        guard hasValidRange else {
            return bounds.lowerBound
        }

        let steps = (
            (rawValue - bounds.lowerBound)
            / safeStep
        ).rounded()

        let result =
            bounds.lowerBound
            + steps * safeStep

        return min(
            bounds.upperBound,
            max(bounds.lowerBound, result)
        )
    }

    private func setValue(
        _ newValue: Double
    ) {
        guard newValue.isFinite else {
            return
        }

        if value != newValue {
            value = newValue
        }
    }

    private func sanitizeValue() {
        guard hasValidRange else {
            return
        }

        let sanitized = quantized(
            value.isFinite
                ? value
                : bounds.lowerBound
        )

        if value != sanitized {
            value = sanitized
        }
    }
}

// MARK: - Spatial picker

public struct BentoSpatialValue:
    Equatable,
    Sendable {
    public var x: Double
    public var y: Double

    public init(
        x: Double,
        y: Double
    ) {
        self.x = x
        self.y = y
    }
}

public struct BentoSpatialAxis {
    public let title: Text
    public let minimumLabel: Text
    public let maximumLabel: Text
    public let step: Double

    public init(
        title: Text,
        minimumLabel: Text,
        maximumLabel: Text,
        step: Double = 0.05
    ) {
        self.title = title
        self.minimumLabel = minimumLabel
        self.maximumLabel = maximumLabel
        self.step = step
    }

    fileprivate var safeStep: Double {
        guard step.isFinite, step > 0 else {
            return 0.05
        }

        return min(1, step)
    }
}

public struct BentoSpatialPalette {
    public let topLeading: BentoTone
    public let topTrailing: BentoTone
    public let bottomLeading: BentoTone
    public let bottomTrailing: BentoTone

    public init(
        topLeading: BentoTone,
        topTrailing: BentoTone,
        bottomLeading: BentoTone,
        bottomTrailing: BentoTone
    ) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
    }

    public static let focusEnergy =
        BentoSpatialPalette(
            topLeading: .green,
            topTrailing: .accent,
            bottomLeading: .blue,
            bottomTrailing: .pink
        )

    public static let priority =
        BentoSpatialPalette(
            topLeading: .warning,
            topTrailing: .danger,
            bottomLeading: .neutral,
            bottomTrailing: .blue
        )
}

public struct BentoSpatialPicker: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var value: BentoSpatialValue

    private let title: Text
    private let xAxis: BentoSpatialAxis
    private let yAxis: BentoSpatialAxis
    private let palette: BentoSpatialPalette
    private let height: CGFloat
    private let formatValue:
        (BentoSpatialValue) -> Text

    @State private var isDragging = false

    public init(
        value: Binding<BentoSpatialValue>,
        title: Text,
        xAxis: BentoSpatialAxis,
        yAxis: BentoSpatialAxis,
        palette: BentoSpatialPalette = .focusEnergy,
        height: CGFloat = 250,
        formatValue:
            @escaping (BentoSpatialValue) -> Text = {
                Text(
                    "\(Int($0.x * 100)) · "
                    + "\(Int($0.y * 100))"
                )
            }
    ) {
        self._value = value
        self.title = title
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.palette = palette
        self.height = max(180, height)
        self.formatValue = formatValue
    }

    private var normalizedValue: BentoSpatialValue {
        BentoSpatialValue(
            x: quantized(
                value.x,
                step: xAxis.safeStep
            ),
            y: quantized(
                value.y,
                step: yAxis.safeStep
            )
        )
    }

    private var xBinding: Binding<Double> {
        Binding(
            get: {
                normalizedValue.x
            },
            set: { newValue in
                value = BentoSpatialValue(
                    x: quantized(
                        newValue,
                        step: xAxis.safeStep
                    ),
                    y: normalizedValue.y
                )
            }
        )
    }

    private var yBinding: Binding<Double> {
        Binding(
            get: {
                normalizedValue.y
            },
            set: { newValue in
                value = BentoSpatialValue(
                    x: normalizedValue.x,
                    y: quantized(
                        newValue,
                        step: yAxis.safeStep
                    )
                )
            }
        )
    }

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: theme.spacing.sm
        ) {
            HStack(
                alignment: .firstTextBaseline,
                spacing: theme.spacing.sm
            ) {
                title.bentoTextStyle(.headline)

                Spacer()

                formatValue(normalizedValue)
                    .bentoTextStyle(.callout)
                    .contentTransition(
                        .numericText()
                    )
            }

            GeometryReader { proxy in
                let horizontalInset: CGFloat = 18
                let verticalInset: CGFloat = 18

                let usableWidth = max(
                    0,
                    proxy.size.width
                        - horizontalInset * 2
                )

                let usableHeight = max(
                    0,
                    proxy.size.height
                        - verticalInset * 2
                )

                let logicalX =
                    normalizedValue.x

                let physicalX =
                    layoutDirection == .rightToLeft
                    ? 1 - logicalX
                    : logicalX

                let knobPosition = CGPoint(
                    x: horizontalInset
                        + usableWidth
                        * CGFloat(physicalX),
                    y: verticalInset
                        + usableHeight
                        * CGFloat(
                            1 - normalizedValue.y
                        )
                )

                ZStack {
                    paletteBackground

                    spatialGrid(
                        size: proxy.size
                    )

                    VStack {
                        HStack {
                            axisLabel(
                                yAxis.maximumLabel
                            )

                            Spacer()
                        }

                        Spacer()

                        HStack {
                            axisLabel(
                                yAxis.minimumLabel
                            )

                            Spacer()
                        }
                    }
                    .padding(theme.spacing.xs)
                    .allowsHitTesting(false)

                    Circle()
                        .fill(theme.colors.surface)
                        .frame(
                            width: isDragging ? 42 : 36,
                            height: isDragging ? 42 : 36
                        )
                        .overlay {
                            Circle()
                                .fill(theme.colors.accent)
                                .frame(width: 12, height: 12)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    isDragging
                                        ? theme.colors.focus
                                        : theme.colors.outline,
                                    lineWidth: isDragging
                                        ? theme.borders.strong
                                        : theme.borders.regular
                                )
                        }
                        .shadow(
                            color:
                                theme.colors.chrome.opacity(0.28),
                            radius: 8,
                            y: 4
                        )
                        .position(knobPosition)
                        .allowsHitTesting(false)
                }
                .clipShape(
                    RoundedRectangle(
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
                        isDragging
                            ? theme.colors.focus
                            : theme.colors.outline,
                        lineWidth: isDragging
                            ? theme.borders.strong
                            : theme.borders.regular
                    )
                }
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: theme.radii.large,
                        style: .continuous
                    )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            guard isEnabled else {
                                return
                            }

                            isDragging = true

                            updateValue(
                                at: gesture.location,
                                size: proxy.size,
                                horizontalInset:
                                    horizontalInset,
                                verticalInset:
                                    verticalInset
                            )
                        }
                        .onEnded { _ in
                            withAnimation(
                                reduceMotion
                                    ? nil
                                    : theme.motion.fast
                            ) {
                                isDragging = false
                            }
                        }
                )
            }
            .frame(height: height)

            HStack(
                alignment: .firstTextBaseline,
                spacing: theme.spacing.xs
            ) {
                xAxis.minimumLabel
                    .bentoTextStyle(
                        .caption,
                        color:
                            theme.colors.onSurfaceMuted
                    )

                Spacer()

                xAxis.title
                    .bentoTextStyle(
                        .overline,
                        color:
                            theme.colors.onSurfaceMuted
                    )

                Spacer()

                xAxis.maximumLabel
                    .bentoTextStyle(
                        .caption,
                        color:
                            theme.colors.onSurfaceMuted
                    )
            }
        }
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityRepresentation {
            VStack {
                Slider(
                    value: xBinding,
                    in: 0...1,
                    step: xAxis.safeStep
                ) {
                    xAxis.title
                }
                .accessibilityValue(
                    Text(
                        "\(Int(normalizedValue.x * 100)) percent"
                    )
                )

                Slider(
                    value: yBinding,
                    in: 0...1,
                    step: yAxis.safeStep
                ) {
                    yAxis.title
                }
                .accessibilityValue(
                    Text(
                        "\(Int(normalizedValue.y * 100)) percent"
                    )
                )
            }
        }
        .onAppear(perform: sanitizeValue)
        .onChange(of: value) { _, _ in
            sanitizeValue()
        }
    }

    private var paletteBackground: some View {
        ZStack {
            theme.colors.surfaceSecondary

            RadialGradient(
                colors: [
                    theme.colors
                        .fill(for: palette.topLeading)
                        .opacity(0.9),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 280
            )

            RadialGradient(
                colors: [
                    theme.colors
                        .fill(for: palette.topTrailing)
                        .opacity(0.78),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 280
            )

            RadialGradient(
                colors: [
                    theme.colors
                        .fill(for: palette.bottomLeading)
                        .opacity(0.8),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 280
            )

            RadialGradient(
                colors: [
                    theme.colors
                        .fill(for: palette.bottomTrailing)
                        .opacity(0.72),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )
        }
    }

    private func spatialGrid(
        size: CGSize
    ) -> some View {
        Path { path in
            for index in 1..<4 {
                let fraction =
                    CGFloat(index) / 4

                let x =
                    size.width * fraction

                let y =
                    size.height * fraction

                path.move(
                    to: CGPoint(x: x, y: 0)
                )

                path.addLine(
                    to: CGPoint(
                        x: x,
                        y: size.height
                    )
                )

                path.move(
                    to: CGPoint(x: 0, y: y)
                )

                path.addLine(
                    to: CGPoint(
                        x: size.width,
                        y: y
                    )
                )
            }
        }
        .stroke(
            theme.colors.outline.opacity(0.16),
            lineWidth: theme.borders.thin
        )
        .accessibilityHidden(true)
    }

    private func axisLabel(
        _ label: Text
    ) -> some View {
        label
            .bentoTextStyle(.caption)
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xxs)
            .foregroundStyle(theme.colors.onSurface)
            .background(
                theme.colors.surface.opacity(0.82),
                in: Capsule()
            )
    }

    private func updateValue(
        at location: CGPoint,
        size: CGSize,
        horizontalInset: CGFloat,
        verticalInset: CGFloat
    ) {
        let width = max(
            1,
            size.width - horizontalInset * 2
        )

        let height = max(
            1,
            size.height - verticalInset * 2
        )

        var physicalX = Double(
            (location.x - horizontalInset)
            / width
        )

        physicalX = min(
            1,
            max(0, physicalX)
        )

        let logicalX =
            layoutDirection == .rightToLeft
            ? 1 - physicalX
            : physicalX

        let logicalY = min(
            1,
            max(
                0,
                1 - Double(
                    (location.y - verticalInset)
                    / height
                )
            )
        )

        value = BentoSpatialValue(
            x: quantized(
                logicalX,
                step: xAxis.safeStep
            ),
            y: quantized(
                logicalY,
                step: yAxis.safeStep
            )
        )
    }

    private func quantized(
        _ rawValue: Double,
        step: Double
    ) -> Double {
        guard rawValue.isFinite else {
            return 0
        }

        let clamped = min(
            1,
            max(0, rawValue)
        )

        let steps =
            (clamped / step).rounded()

        return min(
            1,
            max(0, steps * step)
        )
    }

    private func sanitizeValue() {
        let sanitized = BentoSpatialValue(
            x: quantized(
                value.x,
                step: xAxis.safeStep
            ),
            y: quantized(
                value.y,
                step: yAxis.safeStep
            )
        )

        if value != sanitized {
            value = sanitized
        }
    }
}

// MARK: - Slide to confirm

private enum BentoSlideToConfirmPhase:
    Equatable {
    case idle
    case working
    case success
    case failure
}

public struct BentoSlideToConfirm: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let title: Text
    private let successTitle: Text
    private let failureTitle: Text
    private let systemImage: String
    private let tone: BentoTone
    private let height: CGFloat
    private let completionThreshold: Double
    private let successDisplayDuration: Double
    private let providesHaptics: Bool
    private let action:
        @MainActor () async throws -> Void
    private let onError:
        @MainActor (Error) -> Void

    @State private var progress = 0.0
    @State private var phase =
        BentoSlideToConfirmPhase.idle
    @State private var task:
        Task<Void, Never>?

    public init(
        _ title: Text,
        successTitle: Text = Text("Completed"),
        failureTitle: Text = Text("Try again"),
        systemImage: String = "chevron.right.2",
        tone: BentoTone = .accent,
        height: CGFloat = 64,
        completionThreshold: Double = 0.9,
        successDisplayDuration: Double = 1,
        providesHaptics: Bool = true,
        action:
            @escaping @MainActor
            () async throws -> Void,
        onError:
            @escaping @MainActor
            (Error) -> Void = { _ in }
    ) {
        self.title = title
        self.successTitle = successTitle
        self.failureTitle = failureTitle
        self.systemImage = systemImage
        self.tone = tone
        self.height = max(56, height)
        self.completionThreshold = min(
            1,
            max(0.6, completionThreshold)
        )
        self.successDisplayDuration = max(
            0,
            successDisplayDuration
        )
        self.providesHaptics = providesHaptics
        self.action = action
        self.onError = onError
    }

    private var effectiveHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? max(76, height)
            : height
    }

    private var effectiveTone: BentoTone {
        phase == .failure
            ? .danger
            : tone
    }

    private var currentTitle: Text {
        switch phase {
        case .idle, .working:
            title
        case .success:
            successTitle
        case .failure:
            failureTitle
        }
    }

    private var accessibilityValue: Text {
        switch phase {
        case .idle:
            Text("Slide to confirm")
        case .working:
            Text("In progress")
        case .success:
            Text("Completed")
        case .failure:
            Text("Failed")
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 5

            let knobSize = max(
                44,
                effectiveHeight - inset * 2
            )

            let availableWidth = max(
                0,
                proxy.size.width - inset * 2
            )

            let travel = max(
                0,
                availableWidth - knobSize
            )

            let alignment: Alignment =
                layoutDirection == .rightToLeft
                ? .trailing
                : .leading

            let visualOffset =
                CGFloat(progress) * travel
                * (
                    layoutDirection == .rightToLeft
                    ? -1
                    : 1
                )

            ZStack {
                Capsule()
                    .fill(theme.colors.surfaceSecondary)

                ZStack(alignment: alignment) {
                    Capsule()
                        .fill(
                            theme.colors.fill(
                                for: effectiveTone
                            )
                        )
                        .frame(
                            width:
                                knobSize
                                + travel
                                * CGFloat(progress),
                            height: knobSize
                        )

                    currentTitle
                        .bentoTextStyle(
                            .bodyStrong,
                            color: progress > 0.58
                                || phase != .idle
                                ? theme.colors.foreground(
                                    for: effectiveTone
                                )
                                : theme.colors.onSurface
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: knobSize
                        )
                        .padding(
                            .horizontal,
                            knobSize + theme.spacing.xs
                        )

                    knob(
                        size: knobSize
                    )
                    .offset(x: visualOffset)
                }
                .padding(inset)
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        phase == .failure
                            ? theme.colors.danger
                            : theme.colors.outline,
                        lineWidth:
                            theme.borders.regular
                    )
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled,
                              phase == .idle,
                              travel > 0 else {
                            return
                        }

                        let logicalTranslation =
                            Double(
                                gesture.translation.width
                            )
                            * (
                                layoutDirection
                                    == .rightToLeft
                                ? -1
                                : 1
                            )

                        let nextProgress = min(
                            1,
                            max(
                                0,
                                logicalTranslation
                                / Double(travel)
                            )
                        )

                        progress = nextProgress

                        if nextProgress
                            >= completionThreshold {
                            commit()
                        }
                    }
                    .onEnded { _ in
                        guard phase == .idle else {
                            return
                        }

                        resetProgress()
                    }
            )
        }
        .frame(height: effectiveHeight)
        .opacity(isEnabled ? 1 : 0.48)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(
            Text("Activate to confirm")
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            commit()
        }
        .onDisappear {
            task?.cancel()
            task = nil
            phase = .idle
            progress = 0
        }
    }

    private func knob(
        size: CGFloat
    ) -> some View {
        Circle()
            .fill(theme.colors.surface)
            .frame(width: size, height: size)
            .overlay {
                Group {
                    switch phase {
                    case .idle:
                        Image(
                            systemName:
                                layoutDirection
                                == .rightToLeft
                                ? "chevron.left.2"
                                : systemImage
                        )

                    case .working:
                        BentoSpinner(size: 22)

                    case .success:
                        Image(
                            systemName:
                                "checkmark"
                        )

                    case .failure:
                        Image(
                            systemName:
                                "exclamationmark"
                        )
                    }
                }
                .font(.headline.bold())
                .foregroundStyle(
                    phase == .failure
                        ? theme.colors.danger
                        : theme.colors.onSurface
                )
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        theme.colors.outline,
                        lineWidth:
                            theme.borders.regular
                    )
            }
            .shadow(
                color:
                    theme.colors.chrome.opacity(0.2),
                radius: 5,
                y: 2
            )
    }

    private func commit() {
        guard isEnabled,
              phase == .idle else {
            return
        }

        withAnimation(
            reduceMotion
                ? nil
                : theme.motion.snappy
        ) {
            progress = 1
            phase = .working
        }

        task?.cancel()

        task = Task { @MainActor in
            do {
                try await action()

                guard !Task.isCancelled else {
                    resetToIdle()
                    return
                }

                phase = .success

                if providesHaptics {
                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.success)
                }

                try? await ContinuousClock()
                    .sleep(
                        for: .seconds(
                            successDisplayDuration
                        )
                    )

                guard !Task.isCancelled else {
                    return
                }

                resetToIdle()
                task = nil
            } catch is CancellationError {
                resetToIdle()
                task = nil
            } catch {
                phase = .failure
                onError(error)

                if providesHaptics {
                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.error)
                }

                try? await ContinuousClock()
                    .sleep(for: .seconds(0.9))

                guard !Task.isCancelled else {
                    return
                }

                resetToIdle()
                task = nil
            }
        }
    }

    private func resetProgress() {
        withAnimation(
            reduceMotion
                ? nil
                : theme.motion.snappy
        ) {
            progress = 0
        }
    }

    private func resetToIdle() {
        withAnimation(
            reduceMotion
                ? nil
                : theme.motion.snappy
        ) {
            progress = 0
            phase = .idle
        }
    }
}