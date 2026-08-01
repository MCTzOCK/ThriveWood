import SwiftUI
import Charts

// MARK: - Hero card

public struct BentoHeroCard<
    Visual: View,
    Actions: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let eyebrow: Text?
    private let title: Text
    private let message: Text?
    private let tone: BentoTone
    private let visual: Visual
    private let actions: Actions

    public init(
        eyebrow: Text? = nil,
        title: Text,
        message: Text? = nil,
        tone: BentoTone = .blue,
        @ViewBuilder visual: () -> Visual,
        @ViewBuilder actions: () -> Actions
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.tone = tone
        self.visual = visual()
        self.actions = actions()
    }

    public var body: some View {
        BentoCard(tone: tone) {
            BentoResponsiveStack(
                compactAxis: .vertical,
                regularAxis: .horizontal,
                spacing: theme.spacing.xl,
                horizontalAlignment: .center
            ) {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    if let eyebrow {
                        eyebrow
                            .bentoTextStyle(.overline)
                            .textCase(.uppercase)
                    }

                    title.bentoTextStyle(.title1)

                    if let message {
                        message.bentoTextStyle(.body)
                    }

                    actions
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                visual
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
            }
        }
    }
}

// MARK: - Media card

public struct BentoMediaCard<
    Media: View,
    Footer: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let mediaHeight: CGFloat
    private let media: Media
    private let footer: Footer

    public init(
        title: Text,
        subtitle: Text? = nil,
        mediaHeight: CGFloat = 190,
        @ViewBuilder media: () -> Media,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.mediaHeight = max(100, mediaHeight)
        self.media = media()
        self.footer = footer()
    }

    public var body: some View {
        BentoCard(padding: .none) {
            VStack(alignment: .leading, spacing: 0) {
                media
                    .frame(
                        maxWidth: .infinity,
                        minHeight: mediaHeight,
                        maxHeight: mediaHeight
                    )
                    .clipped()

                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.sm
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.xxs
                    ) {
                        title.bentoTextStyle(.title3)

                        if let subtitle {
                            subtitle.bentoTextStyle(
                                .callout,
                                color: theme.colors.onSurfaceMuted
                            )
                        }
                    }

                    footer
                }
                .padding(theme.spacing.md)
            }
        }
    }
}

// MARK: - Status and key-value rows

public struct BentoStatusIndicator: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let tone: BentoTone
    private let pulses: Bool

    public init(
        _ title: Text,
        tone: BentoTone,
        pulses: Bool = false
    ) {
        self.title = title
        self.tone = tone
        self.pulses = pulses
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ZStack {
                if pulses {
                    TimelineView(.animation) { context in
                        let seconds = context.date
                            .timeIntervalSinceReferenceDate

                        let phase = seconds
                            .truncatingRemainder(dividingBy: 1.4)
                            / 1.4

                        Circle()
                            .fill(
                                theme.colors.fill(for: tone)
                                    .opacity(1 - phase)
                            )
                            .scaleEffect(1 + phase)
                    }
                }

                Circle()
                    .fill(theme.colors.fill(for: tone))
            }
            .frame(width: 10, height: 10)
            .accessibilityHidden(true)

            title.bentoTextStyle(.callout)
        }
        .accessibilityElement(children: .combine)
    }
}

public struct BentoKeyValueRow: View {
    @Environment(\.bentoTheme) private var theme

    private let key: Text
    private let value: Text
    private let valueTone: BentoTone?

    public init(
        key: Text,
        value: Text,
        valueTone: BentoTone? = nil
    ) {
        self.key = key
        self.value = value
        self.valueTone = valueTone
    }

    public var body: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: theme.spacing.sm
        ) {
            key.bentoTextStyle(
                .callout,
                color: theme.colors.onSurfaceMuted
            )

            Spacer(minLength: theme.spacing.sm)

            if let valueTone {
                BentoBadge(
                    value,
                    tone: valueTone
                )
            } else {
                value
                    .bentoTextStyle(.bodyStrong)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minHeight: theme.sizing.minimumTouchTarget)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Interactive line chart

public struct BentoLineDatum: Identifiable {
    public let id: String
    public let category: String
    public let value: Double

    public init(
        id: String,
        category: String,
        value: Double
    ) {
        self.id = id
        self.category = category
        self.value = value
    }
}

public struct BentoLineChart: View {
    @Environment(\.bentoTheme) private var theme

    private let data: [BentoLineDatum]
    private let tone: BentoTone
    private let height: CGFloat
    private let fillsArea: Bool
    private let smoothsLine: Bool
    private let label: Text?
    private let externalSelection: Binding<String?>?
    private let formatValue: (Double) -> Text

    @State private var internalSelection: String?

    public init(
        data: [BentoLineDatum],
        tone: BentoTone = .accent,
        height: CGFloat = 220,
        fillsArea: Bool = true,
        smoothsLine: Bool = true,
        label: Text? = nil,
        selection: Binding<String?>? = nil,
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
        self.data = data
        self.tone = tone
        self.height = max(120, height)
        self.fillsArea = fillsArea
        self.smoothsLine = smoothsLine
        self.label = label
        self.externalSelection = selection
        self.formatValue = formatValue
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: {
                if let externalSelection {
                    return externalSelection.wrappedValue
                }

                return internalSelection
            },
            set: { newValue in
                if let externalSelection {
                    externalSelection.wrappedValue = newValue
                } else {
                    internalSelection = newValue
                }
            }
        )
    }

    private var currentSelection: String? {
        selectionBinding.wrappedValue
    }

    public var body: some View {
        if data.isEmpty {
            BentoEmptyState(
                systemImage: "chart.xyaxis.line",
                title: Text("No chart data"),
                message: Text("Data points will appear here.")
            )
        } else {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                if let selectedItem = data.first(
                    where: {
                        $0.category == currentSelection
                    }
                ) {
                    HStack {
                        Text(verbatim: selectedItem.category)
                            .bentoTextStyle(.callout)

                        Spacer()

                        formatValue(selectedItem.value)
                            .bentoTextStyle(.headline)
                    }
                    .accessibilityElement(children: .combine)
                }

                Chart(data) { item in
                    let safeValue = item.value.isFinite
                        ? item.value
                        : 0

                    if fillsArea {
                        AreaMark(
                            x: .value("Category", item.category),
                            y: .value("Value", safeValue)
                        )
                        .interpolationMethod(
                            smoothsLine ? .catmullRom : .linear
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.colors
                                        .fill(for: tone)
                                        .opacity(0.4),
                                    theme.colors
                                        .fill(for: tone)
                                        .opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    LineMark(
                        x: .value("Category", item.category),
                        y: .value("Value", safeValue)
                    )
                    .interpolationMethod(
                        smoothsLine ? .catmullRom : .linear
                    )
                    .foregroundStyle(
                        theme.colors.fill(for: tone)
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                    PointMark(
                        x: .value("Category", item.category),
                        y: .value("Value", safeValue)
                    )
                    .foregroundStyle(
                        theme.colors.fill(for: tone)
                    )
                    .symbolSize(
                        item.category == currentSelection
                            ? 90
                            : 32
                    )
                }
                .chartLegend(.hidden)
                .chartXSelection(value: selectionBinding)
                .chartXAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(
                                theme.colors.outlineSubtle
                            )

                        AxisValueLabel()
                            .foregroundStyle(
                                theme.colors.onSurfaceMuted
                            )
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine()
                            .foregroundStyle(
                                theme.colors.outlineSubtle
                            )

                        AxisValueLabel()
                            .foregroundStyle(
                                theme.colors.onSurfaceMuted
                            )
                    }
                }
                .frame(height: height)
                .accessibilityLabel(
                    label ?? Text("Line chart")
                )
            }
        }
    }
}

// MARK: - Donut chart

public struct BentoDonutDatum: Identifiable {
    public let id: String
    public let label: Text
    public let value: Double
    public let tone: BentoTone

    public init(
        id: String,
        label: Text,
        value: Double,
        tone: BentoTone
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.tone = tone
    }
}

public struct BentoDonutChart: View {
    @Environment(\.bentoTheme) private var theme

    private let data: [BentoDonutDatum]
    private let centerTitle: Text?
    private let centerValue: Text?
    private let innerRadius: Double
    private let height: CGFloat
    private let showsLegend: Bool

    public init(
        data: [BentoDonutDatum],
        centerTitle: Text? = nil,
        centerValue: Text? = nil,
        innerRadius: Double = 0.62,
        height: CGFloat = 220,
        showsLegend: Bool = true
    ) {
        self.data = data
        self.centerTitle = centerTitle
        self.centerValue = centerValue
        self.innerRadius = min(max(0.2, innerRadius), 0.86)
        self.height = max(130, height)
        self.showsLegend = showsLegend
    }

    private var total: Double {
        data.reduce(0) {
            $0 + safeValue($1.value)
        }
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                if total > 0 {
                    Chart(data) { item in
                        SectorMark(
                            angle: .value(
                                "Value",
                                safeValue(item.value)
                            ),
                            innerRadius: .ratio(innerRadius),
                            angularInset: 2
                        )
                        .foregroundStyle(
                            theme.colors.fill(for: item.tone)
                        )
                    }
                    .chartLegend(.hidden)
                } else {
                    Circle()
                        .stroke(
                            theme.colors.surfaceSecondary,
                            lineWidth: 22
                        )
                        .padding(18)
                }

                VStack(spacing: theme.spacing.xxs) {
                    if let centerValue {
                        centerValue.bentoTextStyle(.title2)
                    }

                    if let centerTitle {
                        centerTitle.bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                    }
                }
                .multilineTextAlignment(.center)
            }
            .frame(height: height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Donut chart"))

            if showsLegend {
                BentoFlowLayout(spacing: theme.spacing.sm) {
                    ForEach(data) { item in
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(
                                    theme.colors.fill(
                                        for: item.tone
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .accessibilityHidden(true)

                            item.label.bentoTextStyle(.caption)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityValue(
                            Text(
                                verbatim: safeValue(item.value)
                                    .formatted()
                            )
                        )
                    }
                }
            }
        }
    }

    private func safeValue(_ value: Double) -> Double {
        value.isFinite ? max(0, value) : 0
    }
}

// MARK: - Gauge

public struct BentoGauge: View {
    @Environment(\.bentoTheme) private var theme

    private let value: Double
    private let range: ClosedRange<Double>
    private let title: Text
    private let valueLabel: Text
    private let tone: BentoTone
    private let size: CGFloat

    public init(
        value: Double,
        in range: ClosedRange<Double>,
        title: Text,
        valueLabel: Text,
        tone: BentoTone = .accent,
        size: CGFloat = 144
    ) {
        self.value = value
        self.range = range
        self.title = title
        self.valueLabel = valueLabel
        self.tone = tone
        self.size = max(80, size)
    }

    private var progress: Double {
        let span = range.upperBound - range.lowerBound

        guard value.isFinite,
              range.lowerBound.isFinite,
              range.upperBound.isFinite,
              span > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                (value - range.lowerBound) / span
            )
        )
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    theme.colors.surfaceSecondary,
                    lineWidth: 14
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.colors.fill(for: tone),
                    style: StrokeStyle(
                        lineWidth: 14,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: theme.spacing.xxs) {
                valueLabel.bentoTextStyle(.title2)

                title.bentoTextStyle(
                    .caption,
                    color: theme.colors.onSurfaceMuted
                )
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            Text("\(Int((progress * 100).rounded())) percent")
        )
    }
}

// MARK: - Calendar heatmap

public struct BentoHeatmapDatum: Identifiable {
    public let id: UUID
    public let date: Date
    public let intensity: Double

    public init(
        id: UUID = UUID(),
        date: Date,
        intensity: Double
    ) {
        self.id = id
        self.date = date
        self.intensity = intensity
    }
}

public struct BentoCalendarHeatmap: View {
    @Environment(\.bentoTheme) private var theme

    private let data: [BentoHeatmapDatum]
    private let numberOfWeeks: Int
    private let endDate: Date
    private let calendar: Calendar
    private let tone: BentoTone
    private let cellSize: CGFloat

    public init(
        data: [BentoHeatmapDatum],
        numberOfWeeks: Int = 16,
        endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        tone: BentoTone = .green,
        cellSize: CGFloat = 15
    ) {
        self.data = data
        self.numberOfWeeks = min(max(1, numberOfWeeks), 53)
        self.endDate = endDate
        self.calendar = calendar
        self.tone = tone
        self.cellSize = max(10, cellSize)
    }

    public var body: some View {
        let spacing: CGFloat = 4
        let lookup = valuesByDay
        let days = displayedDays
        let symbols = weekdaySymbols
        let normalizedEndDate = calendar.startOfDay(
            for: endDate
        )

        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(alignment: .top, spacing: theme.spacing.xs) {
                VStack(spacing: spacing) {
                    ForEach(symbols.indices, id: \.self) { index in
                        Text(verbatim: symbols[index])
                            .bentoTextStyle(
                                .caption,
                                color: theme.colors.onSurfaceMuted
                            )
                            .frame(
                                width: 22,
                                height: cellSize
                            )
                    }
                }

                ScrollView(.horizontal) {
                    LazyHGrid(
                        rows: Array(
                            repeating: GridItem(
                                .fixed(cellSize),
                                spacing: spacing
                            ),
                            count: 7
                        ),
                        spacing: spacing
                    ) {
                        ForEach(days, id: \.self) { date in
                            if date <= normalizedEndDate {
                                heatmapCell(
                                    date: date,
                                    intensity: lookup[date] ?? 0
                                )
                            } else {
                                Color.clear
                                    .frame(
                                        width: cellSize,
                                        height: cellSize
                                    )
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            HStack(spacing: theme.spacing.xs) {
                Text("Less")
                    .bentoTextStyle(
                        .caption,
                        color: theme.colors.onSurfaceMuted
                    )

                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(
                        cornerRadius: 3,
                        style: .continuous
                    )
                    .fill(
                        cellColor(
                            intensity: Double(index) / 4
                        )
                    )
                    .frame(
                        width: cellSize,
                        height: cellSize
                    )
                }

                Text("More")
                    .bentoTextStyle(
                        .caption,
                        color: theme.colors.onSurfaceMuted
                    )
            }
        }
    }

    private var valuesByDay: [Date: Double] {
        var result: [Date: Double] = [:]

        for item in data {
            let day = calendar.startOfDay(for: item.date)
            let value = normalized(item.intensity)

            result[day] = max(result[day] ?? 0, value)
        }

        return result
    }

    private var displayedDays: [Date] {
        let normalizedEnd = calendar.startOfDay(
            for: endDate
        )

        let weekday = calendar.component(
            .weekday,
            from: normalizedEnd
        )

        let offset =
            (weekday - calendar.firstWeekday + 7) % 7

        guard let currentWeekStart = calendar.date(
            byAdding: .day,
            value: -offset,
            to: normalizedEnd
        ),
        let firstDay = calendar.date(
            byAdding: .day,
            value: -7 * (numberOfWeeks - 1),
            to: currentWeekStart
        ) else {
            return []
        }

        return (0..<(numberOfWeeks * 7)).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: firstDay
            )
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols

        guard symbols.count == 7 else {
            return symbols
        }

        let startIndex = max(
            0,
            min(6, calendar.firstWeekday - 1)
        )

        return Array(symbols[startIndex...])
            + Array(symbols[..<startIndex])
    }

    private func heatmapCell(
        date: Date,
        intensity: Double
    ) -> some View {
        RoundedRectangle(
            cornerRadius: 3,
            style: .continuous
        )
        .fill(cellColor(intensity: intensity))
        .frame(width: cellSize, height: cellSize)
        .overlay {
            RoundedRectangle(
                cornerRadius: 3,
                style: .continuous
            )
            .strokeBorder(
                theme.colors.outline.opacity(0.22),
                lineWidth: theme.borders.thin
            )
        }
        .accessibilityLabel(
            Text(
                date,
                format: .dateTime
                    .day()
                    .month()
                    .year()
            )
        )
        .accessibilityValue(
            Text("\(Int((normalized(intensity) * 100).rounded())) percent")
        )
    }

    private func cellColor(
        intensity: Double
    ) -> Color {
        let value = normalized(intensity)

        guard value > 0 else {
            return theme.colors.surfaceSecondary
        }

        return theme.colors
            .fill(for: tone)
            .opacity(0.2 + value * 0.8)
    }

    private func normalized(
        _ value: Double
    ) -> Double {
        guard value.isFinite else {
            return 0
        }

        return min(1, max(0, value))
    }
}

// MARK: - Data table

public struct BentoTableColumn<Row>: Identifiable {
    public let id: String
    public let title: Text
    public let width: CGFloat
    public let alignment: Alignment

    private let cell: (Row) -> AnyView

    public init<Cell: View>(
        id: String,
        title: Text,
        width: CGFloat = 150,
        alignment: Alignment = .leading,
        @ViewBuilder cell: @escaping (Row) -> Cell
    ) {
        self.id = id
        self.title = title
        self.width = max(72, width)
        self.alignment = alignment
        self.cell = {
            AnyView(cell($0))
        }
    }

    fileprivate func cellView(
        for row: Row
    ) -> AnyView {
        cell(row)
    }
}

public struct BentoDataTable<
    Row: Identifiable
>: View {
    @Environment(\.bentoTheme) private var theme

    private let rows: [Row]
    private let columns: [BentoTableColumn<Row>]
    private let onSelect: ((Row) -> Void)?

    public init(
        rows: [Row],
        columns: [BentoTableColumn<Row>],
        onSelect: ((Row) -> Void)? = nil
    ) {
        self.rows = rows
        self.columns = columns
        self.onSelect = onSelect
    }

    private var totalWidth: CGFloat {
        columns.reduce(0) {
            $0 + $1.width
        }
    }

    public var body: some View {
        ScrollView(.horizontal) {
            VStack(spacing: 0) {
                header

                ForEach(
                    Array(rows.enumerated()),
                    id: \.element.id
                ) { index, row in
                    rowView(row, index: index)

                    if index < rows.count - 1 {
                        BentoDivider()
                    }
                }
            }
            .frame(
                minWidth: totalWidth,
                alignment: .leading
            )
        }
        .scrollIndicators(.visible)
        .background(theme.colors.surface)
        .clipShape(
            RoundedRectangle(
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
    }

    private var header: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                column.title
                    .bentoTextStyle(.overline)
                    .frame(width: column.width, alignment: column.alignment)
                    .frame(minHeight: theme.sizing.minimumTouchTarget)
                    .padding(.horizontal, theme.spacing.xs)
            }
        }
        .background(theme.colors.surfaceSecondary)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func rowView(
        _ row: Row,
        index: Int
    ) -> some View {
        if let onSelect {
            Button {
                onSelect(row)
            } label: {
                rowContent(row, index: index)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(row, index: index)
        }
    }

    private func rowContent(
        _ row: Row,
        index: Int
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                column
                    .cellView(for: row)
                    .frame(width: column.width, alignment: column.alignment)
                    .frame(minHeight: theme.sizing.controlMedium)
                    .padding(.horizontal, theme.spacing.xs)
            }
        }
        .foregroundStyle(theme.colors.onSurface)
        .background(
            index.isMultiple(of: 2)
                ? theme.colors.surface
                : theme.colors.surfaceSecondary.opacity(0.58)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Comment card

public struct BentoCommentCard<Actions: View>: View {
    @Environment(\.bentoTheme) private var theme

    private let avatar: BentoAvatarSource
    private let author: Text
    private let metadata: Text?
    private let comment: Text
    private let tone: BentoTone
    private let actions: Actions

    public init(
        avatar: BentoAvatarSource,
        author: Text,
        metadata: Text? = nil,
        comment: Text,
        tone: BentoTone = .blue,
        @ViewBuilder actions: () -> Actions
    ) {
        self.avatar = avatar
        self.author = author
        self.metadata = metadata
        self.comment = comment
        self.tone = tone
        self.actions = actions()
    }

    public var body: some View {
        BentoCard {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                BentoAvatar(
                    source: avatar,
                    size: 44,
                    tone: tone,
                    accessibilityLabel: author
                )

                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.xs
                ) {
                    HStack(alignment: .firstTextBaseline) {
                        author.bentoTextStyle(.bodyStrong)

                        Spacer()

                        if let metadata {
                            metadata.bentoTextStyle(
                                .caption,
                                color: theme.colors.onSurfaceMuted
                            )
                        }
                    }

                    comment.bentoTextStyle(.body)

                    actions
                }
            }
        }
    }
}