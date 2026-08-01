import SwiftUI

public enum BentoAvatarSource {
    case initials(String)
    case systemImage(String)
    case image(Image)
    case remote(URL)
}

public struct BentoAvatar: View {
    @Environment(\.bentoTheme) private var theme

    private let source: BentoAvatarSource
    private let size: CGFloat
    private let tone: BentoTone
    private let accessibilityLabel: Text

    public init(
        source: BentoAvatarSource,
        size: CGFloat = 48,
        tone: BentoTone = .blue,
        accessibilityLabel: Text = Text("Avatar")
    ) {
        self.source = source
        self.size = max(28, size)
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }

    @ViewBuilder
    private var avatarContent: some View {
        switch source {
        case .initials(let initials):
            Text(verbatim: String(initials.prefix(2)).uppercased())
                .bentoTextStyle(.headline)

        case .systemImage(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .padding(size * 0.23)

        case .image(let image):
            image
                .resizable()
                .scaledToFill()

        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    BentoSpinner(size: size * 0.34)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.2)

                @unknown default:
                    Image(systemName: "person.fill")
                }
            }
        }
    }

    public var body: some View {
        ZStack {
            theme.colors.fill(for: tone)
            avatarContent
        }
        .foregroundStyle(theme.colors.foreground(for: tone))
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(
                    theme.colors.outline,
                    lineWidth: theme.borders.regular
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

public struct BentoAvatarStack: View {
    @Environment(\.bentoTheme) private var theme

    private let sources: [BentoAvatarSource]
    private let size: CGFloat
    private let maximumVisible: Int

    public init(
        sources: [BentoAvatarSource],
        size: CGFloat = 42,
        maximumVisible: Int = 4
    ) {
        self.sources = sources
        self.size = max(28, size)
        self.maximumVisible = max(1, maximumVisible)
    }

    public var body: some View {
        let visibleCount = min(sources.count, maximumVisible)
        let hiddenCount = max(0, sources.count - visibleCount)
        let overlap = size * 0.68
        let slotCount = visibleCount + (hiddenCount > 0 ? 1 : 0)

        ZStack(alignment: .leading) {
            ForEach(0..<visibleCount, id: \.self) { index in
                BentoAvatar(
                    source: sources[index],
                    size: size,
                    tone: BentoTone.allCases[
                        index % BentoTone.allCases.count
                    ]
                )
                .offset(x: CGFloat(index) * overlap)
                .zIndex(Double(slotCount - index))
            }

            if hiddenCount > 0 {
                Text("+\(hiddenCount)")
                    .bentoTextStyle(.caption)
                    .frame(width: size, height: size)
                    .foregroundStyle(theme.colors.onSurface)
                    .background(theme.colors.surfaceSecondary)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(
                                theme.colors.outline,
                                lineWidth: theme.borders.regular
                            )
                    }
                    .offset(x: CGFloat(visibleCount) * overlap)
                    .zIndex(0)
                    .accessibilityLabel(
                        Text("\(hiddenCount) more people")
                    )
            }
        }
        .frame(
            width: slotCount > 0
                ? size + CGFloat(slotCount - 1) * overlap
                : 0,
            height: size,
            alignment: .leading
        )
    }
}

public struct BentoListRow<Trailing: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let systemImage: String?
    private let tone: BentoTone
    private let trailing: Trailing

    public init(
        title: Text,
        subtitle: Text? = nil,
        systemImage: String? = nil,
        tone: BentoTone = .neutral,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tone = tone
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.headline)
                    .frame(
                        width: theme.sizing.minimumTouchTarget,
                        height: theme.sizing.minimumTouchTarget
                    )
                    .foregroundStyle(theme.colors.foreground(for: tone))
                    .background(
                        theme.colors.fill(for: tone),
                        in: RoundedRectangle(
                            cornerRadius: theme.radii.small,
                            style: .continuous
                        )
                    )
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

            Spacer(minLength: theme.spacing.sm)
            trailing
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
    }
}

public extension BentoListRow where Trailing == EmptyView {
    init(
        title: Text,
        subtitle: Text? = nil,
        systemImage: String? = nil,
        tone: BentoTone = .neutral
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tone: tone
        ) {
            EmptyView()
        }
    }
}

public struct BentoActionRow: View {
    private let title: Text
    private let subtitle: Text?
    private let systemImage: String?
    private let tone: BentoTone
    private let action: () -> Void

    public init(
        title: Text,
        subtitle: Text? = nil,
        systemImage: String? = nil,
        tone: BentoTone = .neutral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            BentoListRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tone: tone
            ) {
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct BentoSparkline: View {
    @Environment(\.bentoTheme) private var theme

    private let values: [Double]
    private let color: Color?
    private let lineWidth: CGFloat
    private let fillsArea: Bool

    public init(
        values: [Double],
        color: Color? = nil,
        lineWidth: CGFloat = 3,
        fillsArea: Bool = true
    ) {
        self.values = values
        self.color = color
        self.lineWidth = max(1, lineWidth)
        self.fillsArea = fillsArea
    }

    public var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints(in: geometry.size)
            let resolvedColor = color ?? theme.colors.accent

            if points.count > 1 {
                if fillsArea {
                    areaPath(points: points, size: geometry.size)
                        .fill(
                            LinearGradient(
                                colors: [
                                    resolvedColor.opacity(0.42),
                                    resolvedColor.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                linePath(points: points)
                    .stroke(
                        resolvedColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            } else if let point = points.first {
                Circle()
                    .fill(resolvedColor)
                    .frame(
                        width: lineWidth * 2,
                        height: lineWidth * 2
                    )
                    .position(point)
            }
        }
        .accessibilityHidden(true)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else {
            return []
        }

        let sanitized = values.map {
            $0.isFinite ? $0 : 0
        }

        guard let minimum = sanitized.min(),
              let maximum = sanitized.max() else {
            return []
        }

        let range = maximum - minimum

        return sanitized.enumerated().map { index, value in
            let x: CGFloat

            if sanitized.count == 1 {
                x = size.width / 2
            } else {
                x = CGFloat(index)
                    / CGFloat(sanitized.count - 1)
                    * size.width
            }

            let y: CGFloat

            if range == 0 {
                y = size.height / 2
            } else {
                y = size.height
                    - CGFloat((value - minimum) / range)
                    * size.height
            }

            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        var path = Path()

        guard let first = points.first else {
            return path
        }

        path.move(to: first)

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }

    private func areaPath(
        points: [CGPoint],
        size: CGSize
    ) -> Path {
        var path = linePath(points: points)

        guard let first = points.first,
              let last = points.last else {
            return path
        }

        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()

        return path
    }
}

public struct BentoMetricTile: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let value: Text
    private let unit: Text?
    private let delta: Text?
    private let deltaTone: BentoTone
    private let systemImage: String?
    private let tone: BentoTone
    private let trendValues: [Double]

    public init(
        title: Text,
        value: Text,
        unit: Text? = nil,
        delta: Text? = nil,
        deltaTone: BentoTone = .success,
        systemImage: String? = nil,
        tone: BentoTone,
        trendValues: [Double] = []
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.delta = delta
        self.deltaTone = deltaTone
        self.systemImage = systemImage
        self.tone = tone
        self.trendValues = trendValues
    }

    public var body: some View {
        BentoTile(
            tone: tone,
            minimumHeight: 170
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(alignment: .top) {
                    title.bentoTextStyle(.title3)
                    Spacer()

                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.headline)
                            .frame(
                                width: theme.sizing.minimumTouchTarget,
                                height: theme.sizing.minimumTouchTarget
                            )
                            .background(
                                theme.colors.onTile.opacity(0.09),
                                in: Circle()
                            )
                            .accessibilityHidden(true)
                    }
                }

                if !trendValues.isEmpty {
                    BentoSparkline(
                        values: trendValues,
                        color: theme.colors.onTile.opacity(0.55),
                        lineWidth: 2.5
                    )
                    .frame(height: 48)
                } else {
                    Spacer(minLength: 24)
                }

                Spacer(minLength: 0)

                value
                    .bentoTextStyle(.metric)
                    .contentTransition(.numericText())
                
                HStack(alignment: .lastTextBaseline, spacing: theme.spacing.xs) {
                    if let unit {
                        unit
                            .bentoTextStyle(
                                .caption,
                                color: theme.colors.onTile.opacity(0.7)
                            )
                    }
                    
                    Spacer()

                    if let delta {
                        BentoBadge(
                            delta,
                            tone: deltaTone
                        )
                    }
                }
            }
        }
    }
}

public struct BentoStatValue: Identifiable {
    public let id: String
    public let title: Text
    public let value: Text
    public let detail: Text?

    public init(
        id: String,
        title: Text,
        value: Text,
        detail: Text? = nil
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.detail = detail
    }
}

public struct BentoStatStrip: View {
    @Environment(\.bentoTheme) private var theme

    private let values: [BentoStatValue]

    public init(values: [BentoStatValue]) {
        self.values = values
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                ForEach(values) { value in
                    stat(value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 120), alignment: .leading)
                ],
                alignment: .leading,
                spacing: theme.spacing.sm
            ) {
                ForEach(values) { value in
                    stat(value)
                }
            }
        }
    }

    private func stat(_ value: BentoStatValue) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            value.title.bentoTextStyle(
                .caption,
                color: theme.colors.onSurfaceMuted
            )

            value.value.bentoTextStyle(.headline)

            if let detail = value.detail {
                detail.bentoTextStyle(
                    .caption,
                    color: theme.colors.onSurfaceMuted
                )
            }
        }
        .accessibilityElement(children: .combine)
    }
}

public struct BentoBarDatum: Identifiable {
    public let id: String
    public let label: String
    public let value: Double
    public let valueLabel: String?

    public init(
        id: String,
        label: String,
        value: Double,
        valueLabel: String? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.valueLabel = valueLabel
    }
}

public struct BentoBarChart: View {
    @Environment(\.bentoTheme) private var theme

    private let data: [BentoBarDatum]
    private let tone: BentoTone
    private let height: CGFloat

    public init(
        data: [BentoBarDatum],
        tone: BentoTone = .accent,
        height: CGFloat = 150
    ) {
        self.data = data
        self.tone = tone
        self.height = max(80, height)
    }

    private var maximum: Double {
        let candidate = data
            .map { $0.value.isFinite ? max(0, $0.value) : 0 }
            .max() ?? 0

        return max(candidate, 1)
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.xs) {
            ForEach(data) { item in
                let safeValue = item.value.isFinite
                    ? max(0, item.value)
                    : 0

                let normalized = safeValue / maximum

                VStack(spacing: theme.spacing.xxs) {
                    Spacer(minLength: 0)

                    RoundedRectangle(
                        cornerRadius: theme.radii.small,
                        style: .continuous
                    )
                    .fill(theme.colors.fill(for: tone))
                    .frame(
                        height: max(
                            3,
                            CGFloat(normalized) * (height - 28)
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: theme.radii.small,
                            style: .continuous
                        )
                        .strokeBorder(
                            theme.colors.outline,
                            lineWidth: theme.borders.thin
                        )
                    }

                    Text(verbatim: item.label)
                        .bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: item.label))
                .accessibilityValue(
                    Text(
                        verbatim: item.valueLabel
                            ?? safeValue.formatted()
                    )
                )
            }
        }
        .frame(height: height)
    }
}

public struct BentoActivityRow: View {
    @Environment(\.bentoTheme) private var theme

    private let systemImage: String
    private let title: Text
    private let detail: Text
    private let trailing: Text?
    private let tone: BentoTone

    public init(
        systemImage: String,
        title: Text,
        detail: Text,
        trailing: Text? = nil,
        tone: BentoTone = .success
    ) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
        self.trailing = trailing
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(theme.colors.foreground(for: tone))
                .frame(
                    width: theme.sizing.minimumTouchTarget,
                    height: theme.sizing.minimumTouchTarget
                )
                .background(
                    theme.colors.fill(for: tone),
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                title.bentoTextStyle(.bodyStrong)

                detail.bentoTextStyle(
                    .caption,
                    color: theme.colors.onSurfaceMuted
                )
            }

            Spacer()

            if let trailing {
                trailing.bentoTextStyle(.headline)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

public struct BentoTimelineRow: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let detail: Text
    private let time: Text?
    private let tone: BentoTone
    private let isLast: Bool

    public init(
        title: Text,
        detail: Text,
        time: Text? = nil,
        tone: BentoTone = .accent,
        isLast: Bool = false
    ) {
        self.title = title
        self.detail = detail
        self.time = time
        self.tone = tone
        self.isLast = isLast
    }

    public var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            VStack(spacing: 0) {
                Circle()
                    .fill(theme.colors.fill(for: tone))
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                theme.colors.outline,
                                lineWidth: theme.borders.thin
                            )
                    }

                if !isLast {
                    Rectangle()
                        .fill(theme.colors.outlineSubtle)
                        .frame(width: theme.borders.thin)
                        .frame(minHeight: 48)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(alignment: .firstTextBaseline) {
                    title.bentoTextStyle(.bodyStrong)
                    Spacer()

                    if let time {
                        time.bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                }

                detail.bentoTextStyle(
                    .callout,
                    color: theme.colors.onSurfaceMuted
                )
            }
            .padding(.bottom, isLast ? 0 : theme.spacing.sm)
        }
        .accessibilityElement(children: .combine)
    }
}
