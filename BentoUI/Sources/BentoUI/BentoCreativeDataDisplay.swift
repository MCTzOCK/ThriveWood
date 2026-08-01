import SwiftUI

// MARK: - Before and after comparison

public struct BentoBeforeAfterSlider<
    Before: View,
    After: View
>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection

    @Binding private var position: Double

    private let beforeLabel: Text?
    private let afterLabel: Text?
    private let accessibilityLabel: Text
    private let height: CGFloat
    private let before: Before
    private let after: After

    public init(
        position: Binding<Double>,
        beforeLabel: Text? = Text("Before"),
        afterLabel: Text? = Text("After"),
        accessibilityLabel: Text = Text("Before and after comparison"),
        height: CGFloat = 280,
        @ViewBuilder before: () -> Before,
        @ViewBuilder after: () -> After
    ) {
        self._position = position
        self.beforeLabel = beforeLabel
        self.afterLabel = afterLabel
        self.accessibilityLabel =
            accessibilityLabel
        self.height = max(160, height)
        self.before = before()
        self.after = after()
    }

    private var normalizedPosition: Double {
        guard position.isFinite else {
            return 0.5
        }

        return min(
            1,
            max(0, position)
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let width =
                proxy.size.width

            let physicalPosition =
                layoutDirection == .rightToLeft
                ? 1 - normalizedPosition
                : normalizedPosition

            let rawHandleX =
                width * CGFloat(
                    physicalPosition
                )

            let handleX = min(
                max(24, rawHandleX),
                max(24, width - 24)
            )

            let shape = RoundedRectangle(
                cornerRadius: theme.radii.large,
                style: .continuous
            )

            ZStack {
                after
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                before
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .mask {
                        comparisonMask(
                            width: width
                        )
                    }

                Rectangle()
                    .fill(theme.colors.surface)
                    .frame(width: 3)
                    .shadow(
                        color:
                            theme.colors.chrome.opacity(0.3),
                        radius: 3
                    )
                    .position(
                        x: handleX,
                        y: proxy.size.height / 2
                    )
                    .accessibilityHidden(true)

                Capsule()
                    .fill(theme.colors.surface)
                    .frame(width: 42, height: 62)
                    .overlay {
                        Image(
                            systemName:
                                "arrow.left.and.right"
                        )
                        .font(.headline)
                        .foregroundStyle(
                            theme.colors.onSurface
                        )
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                theme.colors.outline,
                                lineWidth:
                                    theme.borders.regular
                            )
                    }
                    .shadow(
                        color:
                            theme.colors.chrome.opacity(0.25),
                        radius: 7,
                        y: 3
                    )
                    .position(
                        x: handleX,
                        y: proxy.size.height / 2
                    )
                    .accessibilityHidden(true)

                VStack {
                    HStack {
                        if let beforeLabel {
                            BentoBadge(
                                beforeLabel,
                                tone: .neutral
                            )
                        }

                        Spacer()

                        if let afterLabel {
                            BentoBadge(
                                afterLabel,
                                tone: .neutral
                            )
                        }
                    }

                    Spacer()
                }
                .padding(theme.spacing.sm)
                .allowsHitTesting(false)
            }
            .background(theme.colors.surface)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    theme.colors.outline,
                    lineWidth:
                        theme.borders.regular
                )
            }
            .contentShape(shape)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard width > 0 else {
                            return
                        }

                        var physical =
                            Double(
                                gesture.location.x
                                / width
                            )

                        physical = min(
                            1,
                            max(0, physical)
                        )

                        position =
                            layoutDirection
                            == .rightToLeft
                            ? 1 - physical
                            : physical
                    }
            )
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            accessibilityLabel
        )
        .accessibilityValue(
            Text(
                "\(Int(normalizedPosition * 100)) percent before"
            )
        )
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                position = min(
                    1,
                    normalizedPosition + 0.05
                )

            case .decrement:
                position = max(
                    0,
                    normalizedPosition - 0.05
                )

            @unknown default:
                break
            }
        }
        .onAppear(perform: sanitizePosition)
        .onChange(of: position) { _, _ in
            sanitizePosition()
        }
    }

    private func comparisonMask(
        width: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            if layoutDirection == .rightToLeft {
                Spacer(minLength: 0)
            }

            Rectangle()
                .frame(
                    width:
                        width
                        * CGFloat(
                            normalizedPosition
                        )
                )

            if layoutDirection != .rightToLeft {
                Spacer(minLength: 0)
            }
        }
    }

    private func sanitizePosition() {
        let sanitized: Double

        if position.isFinite {
            sanitized = min(
                1,
                max(0, position)
            )
        } else {
            sanitized = 0.5
        }

        if position != sanitized {
            position = sanitized
        }
    }
}

// MARK: - Day timeline

public struct BentoTimelineEvent:
    Identifiable {
    public let id: AnyHashable
    public let start: Date
    public let end: Date
    public let title: Text
    public let subtitle: Text?
    public let systemImage: String?
    public let tone: BentoTone

    public init<ID: Hashable>(
        id: ID,
        start: Date,
        end: Date,
        title: Text,
        subtitle: Text? = nil,
        systemImage: String? = nil,
        tone: BentoTone = .blue
    ) {
        self.id = AnyHashable(id)
        self.start = start
        self.end = end
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tone = tone
    }
}

public struct BentoDayTimeline: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection

    private let date: Date
    private let events: [BentoTimelineEvent]
    private let calendar: Calendar
    private let startHour: Int
    private let endHour: Int
    private let hourHeight: CGFloat
    private let showsCurrentTime: Bool
    private let onSelect:
        ((BentoTimelineEvent) -> Void)?

    public init(
        date: Date,
        events: [BentoTimelineEvent],
        calendar: Calendar = .autoupdatingCurrent,
        startHour: Int = 7,
        endHour: Int = 22,
        hourHeight: CGFloat = 72,
        showsCurrentTime: Bool = true,
        onSelect:
            ((BentoTimelineEvent) -> Void)? = nil
    ) {
        let safeStart = min(
            23,
            max(0, startHour)
        )

        let safeEnd = min(
            24,
            max(safeStart + 1, endHour)
        )

        self.date = date
        self.events = events
        self.calendar = calendar
        self.startHour = safeStart
        self.endHour = safeEnd
        self.hourHeight = max(52, hourHeight)
        self.showsCurrentTime =
            showsCurrentTime
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if let window {
                timelinePlot(window)
            } else {
                BentoEmptyState(
                    systemImage: "calendar.badge.exclamationmark",
                    title: Text("Timeline unavailable"),
                    message: Text(
                        "The selected day could not be represented."
                    )
                )
            }
        }
    }

    private var window:
        (start: Date, end: Date)? {
        let dayStart =
            calendar.startOfDay(for: date)

        guard let start = calendar.date(
            byAdding: .hour,
            value: startHour,
            to: dayStart
        ),
        let end = calendar.date(
            byAdding: .hour,
            value: endHour,
            to: dayStart
        ),
        end > start else {
            return nil
        }

        return (start, end)
    }

    private func timelinePlot(
        _ window: (
            start: Date,
            end: Date
        )
    ) -> some View {
        let totalHeight = max(
            hourHeight,
            CGFloat(
                window.end.timeIntervalSince(
                    window.start
                ) / 3_600
            ) * hourHeight
        )

        let placements =
            makePlacements(in: window)

        return GeometryReader { proxy in
            let gutterWidth: CGFloat = 52

            let plotWidth = max(
                0,
                proxy.size.width - gutterWidth
            )

            let plotOriginX =
                layoutDirection == .rightToLeft
                ? 0
                : gutterWidth

            let labelOriginX =
                layoutDirection == .rightToLeft
                ? plotWidth
                : 0

            ZStack(alignment: .topLeading) {
                theme.colors.surfaceSecondary

                ForEach(
                    hourDates(in: window),
                    id: \.self
                ) { hour in
                    let y = yPosition(
                        for: hour,
                        window: window
                    )

                    Rectangle()
                        .fill(
                            theme.colors.outlineSubtle
                        )
                        .frame(
                            width: plotWidth,
                            height:
                                theme.borders.thin
                        )
                        .offset(
                            x: plotOriginX,
                            y: y
                        )
                        .accessibilityHidden(true)

                    Text(
                        hour,
                        format: .dateTime
                            .hour()
                            .minute()
                    )
                    .bentoTextStyle(
                        .caption,
                        color:
                            theme.colors.onSurfaceMuted
                    )
                    .frame(
                        width: gutterWidth - 10,
                        alignment:
                            layoutDirection
                            == .rightToLeft
                            ? .leading
                            : .trailing
                    )
                    .offset(
                        x: labelOriginX + 5,
                        y: min(
                            max(0, y - 9),
                            max(0, totalHeight - 18)
                        )
                    )
                }

                ForEach(placements) { placement in
                    eventView(
                        placement,
                        plotOriginX: plotOriginX,
                        plotWidth: plotWidth,
                        plotHeight: totalHeight,
                        window: window
                    )
                }

                if showsCurrentTime {
                    TimelineView(
                        .periodic(
                            from: .now,
                            by: 60
                        )
                    ) { context in
                        currentTimeMarker(
                            now: context.date,
                            plotOriginX:
                                plotOriginX,
                            plotWidth: plotWidth,
                            window: window
                        )
                    }
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        theme.radii.medium,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        theme.radii.medium,
                    style: .continuous
                )
                .strokeBorder(
                    theme.colors.outline,
                    lineWidth:
                        theme.borders.regular
                )
            }
        }
        .frame(height: totalHeight)
    }

    @ViewBuilder
    private func eventView(
        _ placement:
            BentoTimelinePlacement,
        plotOriginX: CGFloat,
        plotWidth: CGFloat,
        plotHeight: CGFloat,
        window: (
            start: Date,
            end: Date
        )
    ) -> some View {
        let columnSpacing: CGFloat = 5

        let columnCount =
            max(1, placement.columnCount)

        let availableForCards = max(
            0,
            plotWidth
                - columnSpacing
                * CGFloat(columnCount - 1)
        )

        let columnWidth =
            availableForCards
            / CGFloat(columnCount)

        let visualColumn =
            layoutDirection == .rightToLeft
            ? columnCount
                - 1
                - placement.column
            : placement.column

        let x =
            plotOriginX
            + CGFloat(visualColumn)
            * (columnWidth + columnSpacing)

        let y = yPosition(
            for: placement.start,
            window: window
        )

        let naturalHeight = CGFloat(
            placement.end.timeIntervalSince(
                placement.start
            ) / 3_600
        ) * hourHeight

        let availableHeight = max(
            1,
            plotHeight - y - 2
        )

        let eventHeight = min(
            availableHeight,
            max(36, naturalHeight - 4)
        )

        let event = placement.event
        let compact =
            eventHeight < 62
            || columnWidth < 116

        if let onSelect {
            Button {
                onSelect(event)
            } label: {
                timelineEventCard(
                    event,
                    compact: compact
                )
            }
            .buttonStyle(.plain)
            .frame(
                width: columnWidth,
                height: eventHeight
            )
            .offset(
                x: x,
                y: y + 2
            )
        } else {
            timelineEventCard(
                event,
                compact: compact
            )
            .frame(
                width: columnWidth,
                height: eventHeight
            )
            .offset(
                x: x,
                y: y + 2
            )
        }
    }

    private func timelineEventCard(
        _ event: BentoTimelineEvent,
        compact: Bool
    ) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.radii.small,
            style: .continuous
        )

        return VStack(
            alignment: .leading,
            spacing: theme.spacing.xxs
        ) {
            HStack(spacing: theme.spacing.xs) {
                if let systemImage =
                        event.systemImage,
                   !compact {
                    Image(
                        systemName: systemImage
                    )
                    .accessibilityHidden(true)
                }

                event.title
                    .bentoTextStyle(
                        compact
                            ? .caption
                            : .bodyStrong
                    )
                    .lineLimit(
                        compact ? 1 : 2
                    )
            }

            if let subtitle = event.subtitle,
               !compact {
                subtitle
                    .bentoTextStyle(.caption)
                    .lineLimit(1)
                    .opacity(0.72)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(
            compact
                ? theme.spacing.xs
                : theme.spacing.sm
        )
        .foregroundStyle(
            theme.colors.foreground(
                for: event.tone
            )
        )
        .background(
            theme.colors.fill(
                for: event.tone
            ),
            in: shape
        )
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                theme.colors.outline,
                lineWidth:
                    theme.borders.regular
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            Text(
                verbatim:
                    event.start.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                    + " – "
                    + event.end.formatted(
                        date: .omitted,
                        time: .shortened
                    )
            )
        )
    }

    @ViewBuilder
    private func currentTimeMarker(
        now: Date,
        plotOriginX: CGFloat,
        plotWidth: CGFloat,
        window: (
            start: Date,
            end: Date
        )
    ) -> some View {
        if calendar.isDate(
            now,
            inSameDayAs: date
        ),
        now >= window.start,
        now <= window.end {
            let y = yPosition(
                for: now,
                window: window
            )

            Rectangle()
                .fill(theme.colors.danger)
                .frame(
                    width: plotWidth,
                    height: 2
                )
                .offset(
                    x: plotOriginX,
                    y: y
                )
                .accessibilityHidden(true)

            Circle()
                .fill(theme.colors.danger)
                .frame(width: 9, height: 9)
                .position(
                    x: layoutDirection
                        == .rightToLeft
                        ? plotOriginX
                            + plotWidth
                        : plotOriginX,
                    y: y + 1
                )
                .accessibilityHidden(true)
        }
    }

    private func yPosition(
        for date: Date,
        window: (
            start: Date,
            end: Date
        )
    ) -> CGFloat {
        max(
            0,
            CGFloat(
                date.timeIntervalSince(
                    window.start
                ) / 3_600
            ) * hourHeight
        )
    }

    private func hourDates(
        in window: (
            start: Date,
            end: Date
        )
    ) -> [Date] {
        var result: [Date] = []
        var current = window.start

        while current <= window.end,
              result.count < 27 {
            result.append(current)

            guard let next = calendar.date(
                byAdding: .hour,
                value: 1,
                to: current
            ),
            next > current else {
                break
            }

            current = next
        }

        return result
    }

    private func makePlacements(
        in window: (
            start: Date,
            end: Date
        )
    ) -> [BentoTimelinePlacement] {
        let rawEvents: [BentoRawTimelineEvent] =
            events.enumerated().compactMap {
                index,
                event in

                guard event.end > event.start,
                      event.end > window.start,
                      event.start < window.end else {
                    return nil
                }

                let clippedStart = max(
                    event.start,
                    window.start
                )

                let clippedEnd = min(
                    event.end,
                    window.end
                )

                guard clippedEnd
                        > clippedStart else {
                    return nil
                }

                return BentoRawTimelineEvent(
                    sourceIndex: index,
                    event: event,
                    start: clippedStart,
                    end: clippedEnd
                )
            }
            .sorted {
                if $0.start == $1.start {
                    return $0.end < $1.end
                }

                return $0.start < $1.start
            }

        var groups:
            [[BentoRawTimelineEvent]] = []

        var currentGroup:
            [BentoRawTimelineEvent] = []

        var currentGroupEnd: Date?

        for event in rawEvents {
            if let existingGroupEnd = currentGroupEnd,
               event.start >= existingGroupEnd {
                groups.append(currentGroup)
                currentGroup = []
                selfStartGroup(
                    event,
                    group: &currentGroup,
                    groupEnd: &currentGroupEnd
                )
            } else {
                currentGroup.append(event)

                currentGroupEnd = max(
                    currentGroupEnd
                        ?? event.end,
                    event.end
                )
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        var placements:
            [BentoTimelinePlacement] = []

        for group in groups {
            var columnEnds: [Date] = []
            var assignments:
                [(BentoRawTimelineEvent, Int)] = []

            for event in group {
                if let availableColumn =
                    columnEnds.firstIndex(
                        where: {
                            $0 <= event.start
                        }
                    ) {
                    columnEnds[availableColumn] =
                        event.end

                    assignments.append(
                        (
                            event,
                            availableColumn
                        )
                    )
                } else {
                    let column =
                        columnEnds.count

                    columnEnds.append(event.end)

                    assignments.append(
                        (
                            event,
                            column
                        )
                    )
                }
            }

            let columnCount =
                max(1, columnEnds.count)

            placements.append(
                contentsOf:
                    assignments.map {
                        event,
                        column in

                        BentoTimelinePlacement(
                            id:
                                BentoTimelinePlacementID(
                                    eventID:
                                        event.event.id,
                                    sourceIndex:
                                        event.sourceIndex
                                ),
                            event: event.event,
                            start: event.start,
                            end: event.end,
                            column: column,
                            columnCount:
                                columnCount
                        )
                    }
            )
        }

        return placements
    }

    private func selfStartGroup(
        _ event: BentoRawTimelineEvent,
        group:
            inout [BentoRawTimelineEvent],
        groupEnd: inout Date?
    ) {
        group.append(event)
        groupEnd = event.end
    }
}

private struct BentoRawTimelineEvent {
    let sourceIndex: Int
    let event: BentoTimelineEvent
    let start: Date
    let end: Date
}

private struct BentoTimelinePlacementID:
    Hashable {
    let eventID: AnyHashable
    let sourceIndex: Int
}

private struct BentoTimelinePlacement:
    Identifiable {
    let id: BentoTimelinePlacementID
    let event: BentoTimelineEvent
    let start: Date
    let end: Date
    let column: Int
    let columnCount: Int
}