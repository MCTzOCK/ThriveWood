import SwiftUI

public struct BentoDesignSystemDemo: View {
    @State private var selectedTab: DemoTab = .dashboard
    @State private var selectedTheme: DemoTheme = .paper
    @State private var themeMode: BentoThemeMode = .system
    @State private var contrastMode: BentoContrastMode = .system
    @State private var toast: BentoToastData?

    public init() {}

    public var body: some View {
        BentoThemeHost(
            family: selectedTheme.family,
            mode: themeMode,
            contrastMode: contrastMode
        ) {
            BentoTabScaffold(
                selection: $selectedTab,
                items: DemoTab.tabItems
            ) {
                NavigationStack {
                    switch selectedTab {
                    case .dashboard:
                        DemoDashboardView()

                    case .components:
                        DemoComponentsView(
                            selectedTheme: $selectedTheme,
                            themeMode: $themeMode,
                            contrastMode: $contrastMode
                        )

                    case .forms:
                        DemoFormsView()

                    case .states:
                        DemoStatesView { toast in
                            self.toast = toast
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .bentoToast($toast)
        }
    }
}

private enum DemoTab: Hashable {
    case dashboard
    case components
    case forms
    case states

    static let tabItems: [BentoTabItem<DemoTab>] = [
        BentoTabItem(
            id: .dashboard,
            title: Text("Dashboard"),
            systemImage: "square.grid.2x2.fill"
        ),
        BentoTabItem(
            id: .components,
            title: Text("Components"),
            systemImage: "sparkles"
        ),
        BentoTabItem(
            id: .forms,
            title: Text("Forms"),
            systemImage: "slider.horizontal.3"
        ),
        BentoTabItem(
            id: .states,
            title: Text("States"),
            systemImage: "bell.fill",
            badge: 3
        )
    ]
}

private enum DemoTheme: String, CaseIterable, Hashable {
    case paper
    case berry

    var title: String {
        switch self {
        case .paper:
            "Paper"
        case .berry:
            "Berry"
        }
    }

    var family: BentoThemeFamily {
        switch self {
        case .paper:
            .paper
        case .berry:
            .berry
        }
    }
}

// MARK: - Dashboard

private struct DemoDashboardView: View {
    @Environment(\.bentoTheme) private var theme

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.xs) {
                BentoPageHeader(
                    eyebrow: Text("Wednesday"),
                    title: Text("Today"),
                    subtitle: Text("A compact overview of your day")
                )

                nutritionCard

                BentoAdaptiveGrid(minimumItemWidth: 160) {
                    BentoMetricTile(
                        title: Text("Weight"),
                        value: Text("70,1"),
                        unit: Text("kg"),
                        delta: Text("−0,9"),
                        deltaTone: .success,
                        systemImage: "arrow.down",
                        tone: .yellow,
                        trendValues: [72, 71.5, 72.2, 69.8, 71.4, 70.3, 70.1]
                    )

                    BentoMetricTile(
                        title: Text("Activity"),
                        value: Text("4.209"),
                        unit: Text("average"),
                        delta: Text("+12%"),
                        deltaTone: .success,
                        systemImage: "figure.walk",
                        tone: .green,
                        trendValues: [2.100, 3.000, 2.700, 3.800, 3.500, 4.100, 4.209]
                    )
                }

                progressCard
                weeklyCard
            }
        }
    }

    private var nutritionCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(
                    title: Text("Nutrition"),
                    subtitle: Text("Daily targets")
                ) {
                    BentoBadge(
                        Text("On track"),
                        tone: .success,
                        systemImage: "checkmark"
                    )
                }

                BentoStatStrip(
                    values: [
                        BentoStatValue(
                            id: "calories",
                            title: Text("Kcal"),
                            value: Text("210"),
                            detail: Text("/ 1.883")
                        ),
                        BentoStatValue(
                            id: "carbs",
                            title: Text("Carbs"),
                            value: Text("29 g"),
                            detail: Text("/ 180 g")
                        ),
                        BentoStatValue(
                            id: "protein",
                            title: Text("Protein"),
                            value: Text("15 g"),
                            detail: Text("/ 140 g")
                        ),
                        BentoStatValue(
                            id: "fat",
                            title: Text("Fat"),
                            value: Text("5 g"),
                            detail: Text("/ 62 g")
                        )
                    ]
                )

                BentoDivider()

                BentoActivityRow(
                    systemImage: "figure.run",
                    title: Text("Running"),
                    detail: Text("300 kcal burned · 30 min"),
                    trailing: Text("08:30"),
                    tone: .success
                )

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text("Cottage cheese with blueberries and banana")
                        .bentoTextStyle(.bodyStrong)

                    Text("210 kcal · 29 g carbs · 5 g fat · 15 g protein")
                        .bentoTextStyle(
                            .caption,
                            color: theme.colors.onSurfaceMuted
                        )
                }

                BentoButton(
                    Text("My meals"),
                    systemImage: "fork.knife",
                    variant: .primary,
                    expands: true
                ) {}
            }
        }
    }

    private var progressCard: some View {
        BentoCard(tone: .blue) {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                HStack {
                    BentoBadge(
                        Text("Month"),
                        tone: .accent
                    )

                    Spacer()

                    BentoBadge(
                        Text("7 day streak"),
                        tone: .warning,
                        systemImage: "flame.fill"
                    )
                }

                HStack(alignment: .lastTextBaseline) {
                    Text("Making steady\nprogress now!")
                        .bentoTextStyle(.title2)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("25%")
                            .bentoTextStyle(.metric)

                        Text("Days succeeded")
                            .bentoTextStyle(.caption)
                    }
                }

                BentoProgressBar(
                    progress: 0.25,
                    tone: .accent,
                    height: 14
                )
            }
        }
    }

    private var weeklyCard: some View {
        BentoCard(tone: .pink) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(
                    title: Text("Weekly activity"),
                    subtitle: Text("Minutes per day")
                )

                BentoBarChart(
                    data: [
                        BentoBarDatum(id: "mo", label: "Mo", value: 22),
                        BentoBarDatum(id: "tu", label: "Tu", value: 46),
                        BentoBarDatum(id: "we", label: "We", value: 31),
                        BentoBarDatum(id: "th", label: "Th", value: 58),
                        BentoBarDatum(id: "fr", label: "Fr", value: 42),
                        BentoBarDatum(id: "sa", label: "Sa", value: 70),
                        BentoBarDatum(id: "su", label: "Su", value: 35)
                    ],
                    tone: .accent
                )
            }
        }
    }
}

// MARK: - Components

private struct DemoComponentsView: View {
    @Environment(\.bentoTheme) private var theme

    @Binding var selectedTheme: DemoTheme
    @Binding var themeMode: BentoThemeMode
    @Binding var contrastMode: BentoContrastMode

    @State private var selectedChip = "SwiftUI"
    @State private var buttonLoading = false

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    eyebrow: Text("Design system"),
                    title: Text("Components"),
                    subtitle: Text("Tokens, typography, cards and controls")
                )

                themeCard
                typographyCard
                paletteCard
                cardsCard
                buttonsCard
                chipsCard
                dataCard
            }
        }
    }

    private var themeCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(
                    title: Text("Theme"),
                    subtitle: Text("Runtime-switchable without global state")
                )

                BentoSegmentedPicker(
                    options: DemoTheme.allCases,
                    selection: $selectedTheme
                ) {
                    Text(verbatim: $0.title)
                }

                BentoSegmentedPicker(
                    options: BentoThemeMode.allCases,
                    selection: $themeMode
                ) {
                    Text(verbatim: $0.rawValue.capitalized)
                }

                BentoSegmentedPicker(
                    options: BentoContrastMode.allCases,
                    selection: $contrastMode
                ) {
                    Text(verbatim: $0.rawValue.capitalized)
                }
            }
        }
    }

    private var typographyCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoSectionHeader(title: Text("Typography"))

                Text("Display")
                    .bentoTextStyle(.display)

                Text("Title one")
                    .bentoTextStyle(.title1)

                Text("Title two")
                    .bentoTextStyle(.title2)

                Text("Metric 12.450")
                    .bentoTextStyle(.metric)

                Text("Body strong")
                    .bentoTextStyle(.bodyStrong)

                Text("Regular body text automatically scales with Dynamic Type.")
                    .bentoTextStyle(.body)

                Text("OVERLINE")
                    .bentoTextStyle(.overline)
            }
        }
    }

    private var paletteCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(title: Text("Semantic palette"))

                BentoFlowLayout(spacing: theme.spacing.xs) {
                    ForEach(BentoTone.allCases) { tone in
                        BentoBadge(
                            Text(verbatim: tone.rawValue.capitalized),
                            tone: tone
                        )
                    }
                }
            }
        }
    }

    private var cardsCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(title: Text("Cards"))

                BentoCard(style: .flat) {
                    Text("Flat surface").bentoTextStyle(.bodyStrong)
                }

                BentoCard(tone: .yellow, style: .outlined) {
                    Text("Outlined pastel tile")
                        .bentoTextStyle(.bodyStrong)
                }

                BentoCard(tone: .green, style: .elevated) {
                    Text("Elevated tile")
                        .bentoTextStyle(.bodyStrong)
                }
            }
        }
    }

    private var buttonsCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoSectionHeader(title: Text("Buttons"))

                BentoButton(
                    Text("Primary action"),
                    systemImage: "sparkles",
                    variant: .primary,
                    expands: true
                ) {}

                BentoButton(
                    Text("Secondary"),
                    systemImage: "arrow.right",
                    iconPlacement: .trailing,
                    variant: .secondary,
                    expands: true
                ) {}

                BentoButton(
                    Text("Delete"),
                    systemImage: "trash",
                    variant: .destructive,
                    expands: true,
                    role: .destructive
                ) {}

                BentoButton(
                    Text("Async action"),
                    systemImage: "arrow.clockwise",
                    variant: .tonal(.blue),
                    expands: true,
                    isLoading: buttonLoading
                ) {
                    buttonLoading = true

                    Task {
                        try? await ContinuousClock()
                            .sleep(for: .seconds(1.2))

                        buttonLoading = false
                    }
                }

                HStack {
                    BentoIconButton(
                        systemImage: "heart.fill",
                        accessibilityLabel: Text("Favorite"),
                        variant: .tonal(.pink)
                    ) {}

                    BentoIconButton(
                        systemImage: "square.and.arrow.up",
                        accessibilityLabel: Text("Share"),
                        variant: .secondary
                    ) {}

                    BentoFloatingActionButton(
                        systemImage: "plus",
                        accessibilityLabel: Text("Add")
                    ) {}
                }
            }
        }
    }

    private var chipsCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(title: Text("Chips and badges"))

                BentoFlowLayout(spacing: theme.spacing.xs) {
                    ForEach(["SwiftUI", "Design", "Health", "Charts"], id: \.self) { value in
                        BentoChip(
                            Text(verbatim: value),
                            systemImage: value == "SwiftUI"
                                ? "swift"
                                : nil,
                            tone: .accent,
                            isSelected: selectedChip == value
                        ) {
                            selectedChip = value
                        }
                    }
                }

                BentoFlowLayout(spacing: theme.spacing.xs) {
                    BentoBadge(Text("New"), tone: .accent)
                    BentoBadge(Text("Success"), tone: .success)
                    BentoBadge(Text("Warning"), tone: .warning)
                    BentoBadge(Text("Error"), tone: .danger)
                }
            }
        }
    }

    private var dataCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoSectionHeader(title: Text("Data display"))

                HStack {
                    BentoAvatar(
                        source: .initials("AM"),
                        tone: .pink,
                        accessibilityLabel: Text("Anna Müller")
                    )

                    BentoAvatarStack(
                        sources: [
                            .initials("AM"),
                            .initials("JS"),
                            .systemImage("person.fill"),
                            .initials("LT"),
                            .initials("MK"),
                            .initials("SO")
                        ]
                    )
                }

                BentoListRow(
                    title: Text("Static list row"),
                    subtitle: Text("With semantic icon"),
                    systemImage: "heart.fill",
                    tone: .pink
                )

                BentoActionRow(
                    title: Text("Interactive row"),
                    subtitle: Text("Minimum 44 pt touch target"),
                    systemImage: "gearshape.fill",
                    tone: .blue
                ) {}

                BentoSparkline(
                    values: [3, 8, 5, 11, 9, 14, 13, 18]
                )
                .frame(height: 80)
            }
        }
    }
}

// MARK: - Forms

private enum DemoGoal: String, CaseIterable, Hashable {
    case lose
    case maintain
    case gain

    var label: String {
        switch self {
        case .lose:
            "Lose"
        case .maintain:
            "Maintain"
        case .gain:
            "Gain"
        }
    }
}

private struct DemoFormsView: View {
    @Environment(\.bentoTheme) private var theme

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var search = ""
    @State private var notes = ""
    @State private var notifications = true
    @State private var acceptedTerms = false
    @State private var goal: DemoGoal? = .maintain
    @State private var segment: DemoGoal = .maintain
    @State private var menuGoal: DemoGoal = .maintain
    @State private var servings = 2
    @State private var intensity = 65.0

    private var emailStatus: BentoFieldStatus {
        if email.isEmpty {
            return .normal
        }

        if email.contains("@") && email.contains(".") {
            return .success(Text("Address looks valid"))
        }

        return .error(Text("Enter a valid email address"))
    }

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    eyebrow: Text("Input"),
                    title: Text("Forms"),
                    subtitle: Text("Validation, limits, focus and accessibility")
                )

                BentoCard {
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        BentoSearchField(
                            text: $search,
                            prompt: Text("Search meals")
                        )

                        BentoTextField(
                            label: Text("Name"),
                            text: $name,
                            prompt: Text("Jane Doe"),
                            leadingSystemImage: "person.fill",
                            required: true,
                            maximumLength: 40,
                            contentType: .name
                        )

                        BentoTextField(
                            label: Text("Email"),
                            text: $email,
                            prompt: Text("name@example.com"),
                            leadingSystemImage: "envelope.fill",
                            required: true,
                            status: emailStatus,
                            maximumLength: 100,
                            keyboardType: .emailAddress,
                            contentType: .emailAddress,
                            capitalization: .never,
                            autocorrectionDisabled: true
                        )

                        BentoTextField(
                            label: Text("Password"),
                            text: $password,
                            prompt: Text("At least 8 characters"),
                            leadingSystemImage: "lock.fill",
                            isSecure: true,
                            required: true,
                            status: password.count >= 8
                                ? .success(Text("Strong enough"))
                                : .normal,
                            maximumLength: 64,
                            contentType: .newPassword,
                            capitalization: .never,
                            autocorrectionDisabled: true
                        )

                        BentoTextArea(
                            label: Text("Notes"),
                            text: $notes,
                            prompt: Text("Add optional notes…"),
                            maximumLength: 280
                        )
                    }
                }

                BentoCard {
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        BentoSectionHeader(title: Text("Selection"))

                        BentoToggleRow(
                            Text("Notifications"),
                            subtitle: Text("Receive daily progress reminders"),
                            systemImage: "bell.fill",
                            isOn: $notifications
                        )

                        BentoCheckbox(
                            Text("Accept terms"),
                            subtitle: Text("Required before continuing"),
                            isOn: $acceptedTerms
                        )

                        BentoSectionHeader(title: Text("Goal"))

                        BentoRadioGroup(
                            options: DemoGoal.allCases,
                            selection: $goal
                        ) {
                            Text(verbatim: $0.label)
                                .bentoTextStyle(.body)
                        }

                        BentoSegmentedPicker(
                            options: DemoGoal.allCases,
                            selection: $segment
                        ) {
                            Text(verbatim: $0.label)
                        }

                        BentoMenuPicker(
                            Text("Goal menu"),
                            options: DemoGoal.allCases,
                            selection: $menuGoal
                        ) {
                            Text(verbatim: $0.label)
                        }
                    }
                }

                BentoCard {
                    VStack(alignment: .leading, spacing: theme.spacing.lg) {
                        BentoSectionHeader(title: Text("Numeric input"))

                        BentoStepper(
                            Text("Servings"),
                            value: $servings,
                            in: 1...12
                        )

                        BentoSlider(
                            Text("Intensity"),
                            value: $intensity,
                            in: 0...100,
                            step: 5
                        ) {
                            Text("\(Int($0))%")
                        }
                    }
                }

                BentoButton(
                    Text("Continue"),
                    systemImage: "arrow.right",
                    iconPlacement: .trailing,
                    variant: .primary,
                    size: .large,
                    expands: true
                ) {}
                .disabled(
                    name.isEmpty
                        || emailStatus.kind == .error
                        || password.count < 8
                        || !acceptedTerms
                )
            }
        }
    }
}

// MARK: - Feedback and states

private struct DemoStatesView: View {
    @Environment(\.bentoTheme) private var theme

    @State private var isLoading = false
    @State private var progress = 0.67
    @State private var hidesInfo = false

    let showToast: (BentoToastData) -> Void

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    eyebrow: Text("System feedback"),
                    title: Text("States"),
                    subtitle: Text("Loading, progress, alerts and empty states")
                )

                calloutsCard
                progressCard
                loadingCard
                timelineCard
                emptyCard
                toastCard
            }
        }
    }

    private var calloutsCard: some View {
        BentoCard {
            VStack(spacing: theme.spacing.sm) {
                if !hidesInfo {
                    BentoCallout(
                        kind: .info,
                        title: Text("Information"),
                        message: Text("This message can be dismissed.")
                    ) {
                        hidesInfo = true
                    }
                }

                BentoCallout(
                    kind: .success,
                    title: Text("Saved"),
                    message: Text("Your changes were synchronized.")
                )

                BentoCallout(
                    kind: .warning,
                    title: Text("Almost there"),
                    message: Text("One required field is still missing.")
                )

                BentoCallout(
                    kind: .error,
                    title: Text("Connection failed"),
                    message: Text("Check your network and try again.")
                )
            }
        }
    }

    private var progressCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                BentoSectionHeader(title: Text("Progress"))

                HStack(spacing: theme.spacing.xl) {
                    BentoProgressRing(
                        progress: progress,
                        tone: .accent
                    )

                    BentoProgressRing(
                        progress: 0.42,
                        tone: .info,
                        size: 84,
                        lineWidth: 9,
                        label: Text("42")
                    )
                }

                BentoProgressBar(
                    progress: progress,
                    tone: .success,
                    label: Text("Upload")
                )

                BentoSlider(
                    Text("Demo progress"),
                    value: $progress,
                    in: 0...1,
                    step: 0.05
                ) {
                    Text("\(Int($0 * 100))%")
                }
            }
        }
    }

    private var loadingCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BentoSectionHeader(title: Text("Loading and skeletons"))

                HStack(spacing: theme.spacing.md) {
                    BentoSpinner()
                    BentoSpinner(size: 44)
                    BentoSpinner(size: 58)
                }

                BentoSkeleton(height: 22)

                HStack {
                    BentoSkeleton(height: 72, radius: .medium)
                    BentoSkeleton(height: 72, radius: .medium)
                }

                BentoButton(
                    Text(isLoading ? "Loading…" : "Show overlay"),
                    variant: .secondary,
                    expands: true
                ) {
                    isLoading = true

                    Task {
                        try? await ContinuousClock()
                            .sleep(for: .seconds(1.5))

                        isLoading = false
                    }
                }
            }
        }
        .bentoLoading(
            isLoading,
            label: Text("Synchronizing")
        )
    }

    private var timelineCard: some View {
        BentoCard {
            VStack(spacing: 0) {
                BentoTimelineRow(
                    title: Text("Workout completed"),
                    detail: Text("Running · 5,2 km"),
                    time: Text("08:30"),
                    tone: .success
                )

                BentoTimelineRow(
                    title: Text("Breakfast logged"),
                    detail: Text("Cottage cheese and blueberries"),
                    time: Text("09:15"),
                    tone: .yellow
                )

                BentoTimelineRow(
                    title: Text("Goal updated"),
                    detail: Text("Daily target changed to 8.000 steps"),
                    time: Text("10:40"),
                    tone: .blue,
                    isLast: true
                )
            }
        }
    }

    private var emptyCard: some View {
        BentoCard {
            BentoEmptyState(
                systemImage: "tray.fill",
                title: Text("Nothing here yet"),
                message: Text("New items will appear here after your first activity."),
                actionTitle: Text("Create item") 
            ) {
                showToast(
                    BentoToastData(
                        kind: .success,
                        title: Text("Item created"),
                        message: Text("The empty state action was triggered.")
                    )
                )
            }
        }
    }

    private var toastCard: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                BentoSectionHeader(title: Text("Toasts"))

                BentoButton(
                    Text("Success toast"),
                    variant: .tonal(.success),
                    expands: true
                ) {
                    showToast(
                        BentoToastData(
                            kind: .success,
                            title: Text("Changes saved"),
                            message: Text("Everything is up to date.")
                        )
                    )
                }

                BentoButton(
                    Text("Error toast"),
                    variant: .tonal(.danger),
                    expands: true
                ) {
                    showToast(
                        BentoToastData(
                            kind: .error,
                            title: Text("Could not save"),
                            message: Text("Please try again.")
                        )
                    )
                }

                BentoButton(
                    Text("Persistent toast"),
                    variant: .tonal(.info),
                    expands: true
                ) {
                    showToast(
                        BentoToastData(
                            kind: .info,
                            title: Text("Persistent message"),
                            message: Text("Dismiss this message manually."),
                            duration: nil
                        )
                    )
                }
            }
        }
    }
}

#Preview("Bento Design System") {
    BentoDesignSystemDemo()
}
