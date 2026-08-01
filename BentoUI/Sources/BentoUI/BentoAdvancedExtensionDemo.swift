import SwiftUI

public struct BentoAdvancedExtensionDemo: View {
    public init() {}

    public var body: some View {
        BentoThemeHost(
            family: .paper,
            mode: .system
        ) {
            NavigationStack {
                BentoAdvancedGalleryHome()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct BentoAdvancedGalleryHome: View {
    @Environment(\.bentoTheme) private var theme

    @State private var carouselSelection: Int?
    @State private var expandedCard = true
    @State private var rating = 4
    @State private var currentPage = 1
    @State private var selectedTone = BentoTone.blue
    @State private var selectedTags: Set<String> = [
        "SwiftUI"
    ]

    @State private var otpCode = ""
    @State private var tags = [
        "Design System",
        "Bento"
    ]
    @State private var selectedRange = 20.0...75.0
    @State private var selectedDate = Date.now

    @State private var showSheet = false
    @State private var showDialog = false
    @State private var showTooltip = false
    @State private var snackbar: BentoSnackbarData?

    private let masonryItems = [
        DemoMasonryItem(id: 0, title: "Focus", height: 120, tone: .yellow),
        DemoMasonryItem(id: 1, title: "Activity", height: 190, tone: .green),
        DemoMasonryItem(id: 2, title: "Sleep", height: 170, tone: .blue),
        DemoMasonryItem(id: 3, title: "Recovery", height: 130, tone: .pink)
    ]

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.lg) {
                BentoPageHeader(
                    eyebrow: Text("Extension pack"),
                    title: Text("Advanced Bento UI"),
                    subtitle: Text(
                        "Advanced controls, data visualization, overlays and templates"
                    )
                )

                layoutsSection
                controlsSection
                inputsSection
                dataSection
                overlaysSection
                templatesSection
            }
        }
        .bentoSheet(
            isPresented: $showSheet,
            title: Text("Advanced sheet"),
            subtitle: Text(
                "Supports custom detents and theme propagation"
            )
        ) {
            VStack(spacing: theme.spacing.sm) {
                BentoCallout(
                    kind: .info,
                    title: Text("Native presentation"),
                    message: Text(
                        "The sheet uses native iOS presentation APIs."
                    )
                )

                BentoActionRow(
                    title: Text("Account"),
                    subtitle: Text("Manage your profile"),
                    systemImage: "person.fill",
                    tone: .blue
                ) {}

                BentoActionRow(
                    title: Text("Notifications"),
                    subtitle: Text("Configure reminders"),
                    systemImage: "bell.fill",
                    tone: .yellow
                ) {}
            }
            .padding(theme.spacing.md)
        }
        .bentoDialog(
            isPresented: $showDialog,
            systemImage: "trash.fill",
            title: Text("Delete entry?"),
            message: Text(
                "This operation cannot be undone."
            ),
            actions: [
                BentoDialogAction(
                    title: Text("Cancel"),
                    variant: .secondary
                ) {},
                BentoDialogAction(
                    title: Text("Delete"),
                    systemImage: "trash",
                    variant: .destructive,
                    role: .destructive
                ) {
                    snackbar = BentoSnackbarData(
                        title: Text("Entry deleted"),
                        tone: .success
                    )
                }
            ],
            dismissesOnBackgroundTap: false
        )
        .bentoSnackbar($snackbar)
    }

    private var layoutsSection: some View {
        BentoSection(
            title: Text("Advanced layouts"),
            subtitle: Text("Masonry and snapping carousel")
        ) {
            BentoMasonryGrid(
                items: masonryItems,
                columns: 2,
                spacing: theme.spacing.xs
            ) { item in
                BentoTile(
                    tone: item.tone,
                    minimumHeight: item.height
                ) {
                    VStack(alignment: .leading) {
                        Text(verbatim: item.title)
                            .bentoTextStyle(.title3)

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.title2)
                    }
                }
            }

            BentoCarousel(
                items: masonryItems,
                selection: $carouselSelection,
                itemWidth: 245
            ) { item in
                BentoTile(
                    tone: item.tone,
                    minimumHeight: 150
                ) {
                    Text(verbatim: item.title)
                        .bentoTextStyle(.title2)
                }
            }
        }
    }

    private var controlsSection: some View {
        BentoSection(title: Text("Advanced controls")) {
            BentoDisclosureCard(
                isExpanded: $expandedCard,
                tone: .blue
            ) {
                VStack(alignment: .leading) {
                    Text("Disclosure card")
                        .bentoTextStyle(.headline)

                    Text("Tap to expand")
                        .bentoTextStyle(.caption)
                }
            } content: {
                BentoExpandableText(
                    Text(
                        "This component combines animated disclosure behavior, accessible state announcements and the full Bento card style. Long content can be expanded without introducing another dependency."
                    ),
                    lineLimit: 2
                )
            }

            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    BentoSectionHeader(
                        title: Text("Rating")
                    )

                    BentoRatingPicker(
                        value: $rating
                    )

                    BentoPageIndicator(
                        count: 5,
                        current: $currentPage
                    )

                    BentoTonePicker(
                        selection: $selectedTone
                    )

                    BentoSelectionChips(
                        options: [
                            "SwiftUI",
                            "Charts",
                            "Forms",
                            "Themes"
                        ],
                        selection: $selectedTags,
                        behavior: .multiple(maximum: 3),
                        tone: .accent
                    ) {
                        Text(verbatim: $0)
                    }

                    BentoCopyField(
                        value: "BENTO-2026-UI",
                        label: Text("Promo code")
                    )

                    BentoAsyncButton(
                        Text("Simulate async action"),
                        successTitle: Text("Completed"),
                        systemImage: "arrow.clockwise",
                        variant: .primary,
                        expands: true
                    ) {
                        try await ContinuousClock()
                            .sleep(for: .seconds(1))
                    }
                }
            }
        }
    }

    private var inputsSection: some View {
        BentoSection(title: Text("Advanced inputs")) {
            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.lg
                ) {
                    BentoSectionHeader(
                        title: Text("Verification code")
                    )

                    BentoOTPField(
                        code: $otpCode,
                        length: 6
                    ) { code in
                        snackbar = BentoSnackbarData(
                            title: Text("Code completed"),
                            message: Text(verbatim: code),
                            tone: .success
                        )
                    }

                    BentoTagInput(
                        tags: $tags,
                        label: Text("Topics"),
                        maximumCount: 8
                    )

                    BentoRangeSlider(
                        Text("Preferred range"),
                        selection: $selectedRange,
                        in: 0...100,
                        step: 5
                    )

                    BentoDatePickerField(
                        Text("Date"),
                        selection: $selectedDate,
                        presentation: .compact
                    )

                    BentoDropZone(
                        for: String.self,
                        title: Text("Drop text here"),
                        message: Text(
                            "Drag compatible text content onto this area."
                        )
                    ) { values in
                        snackbar = BentoSnackbarData(
                            title: Text("Drop accepted"),
                            message: Text(
                                "\(values.count) item received"
                            ),
                            tone: .success
                        )

                        return !values.isEmpty
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        BentoSection(title: Text("Advanced data display")) {
            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    BentoSectionHeader(
                        title: Text("Interactive trend")
                    )

                    BentoLineChart(
                        data: [
                            BentoLineDatum(
                                id: "mo",
                                category: "Mo",
                                value: 32
                            ),
                            BentoLineDatum(
                                id: "tu",
                                category: "Tu",
                                value: 48
                            ),
                            BentoLineDatum(
                                id: "we",
                                category: "We",
                                value: 41
                            ),
                            BentoLineDatum(
                                id: "th",
                                category: "Th",
                                value: 67
                            ),
                            BentoLineDatum(
                                id: "fr",
                                category: "Fr",
                                value: 59
                            ),
                            BentoLineDatum(
                                id: "sa",
                                category: "Sa",
                                value: 83
                            ),
                            BentoLineDatum(
                                id: "su",
                                category: "Su",
                                value: 72
                            )
                        ],
                        tone: .accent
                    )
                }
            }

            BentoAdaptiveGrid(minimumItemWidth: 250) {
                BentoCard {
                    BentoDonutChart(
                        data: [
                            BentoDonutDatum(
                                id: "protein",
                                label: Text("Protein"),
                                value: 35,
                                tone: .green
                            ),
                            BentoDonutDatum(
                                id: "carbs",
                                label: Text("Carbs"),
                                value: 45,
                                tone: .blue
                            ),
                            BentoDonutDatum(
                                id: "fat",
                                label: Text("Fat"),
                                value: 20,
                                tone: .yellow
                            )
                        ],
                        centerTitle: Text("Macros"),
                        centerValue: Text("100%")
                    )
                }

                BentoCard {
                    VStack(spacing: theme.spacing.md) {
                        BentoGauge(
                            value: 72,
                            in: 0...100,
                            title: Text("Readiness"),
                            valueLabel: Text("72"),
                            tone: .success
                        )

                        BentoStatusIndicator(
                            Text("All systems healthy"),
                            tone: .success,
                            pulses: true
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    BentoSectionHeader(
                        title: Text("Activity heatmap")
                    )

                    BentoCalendarHeatmap(
                        data: heatmapData,
                        numberOfWeeks: 18
                    )
                }
            }

            BentoDataTable(
                rows: demoPeople,
                columns: demoColumns
            )
        }
    }

    private var overlaysSection: some View {
        BentoSection(title: Text("Overlays")) {
            BentoCard {
                VStack(spacing: theme.spacing.xs) {
                    BentoButton(
                        Text("Open sheet"),
                        systemImage: "rectangle.bottomthird.inset.filled",
                        variant: .secondary,
                        expands: true
                    ) {
                        showSheet = true
                    }

                    BentoButton(
                        Text("Open dialog"),
                        systemImage: "exclamationmark.bubble.fill",
                        variant: .tonal(.warning),
                        expands: true
                    ) {
                        showDialog = true
                    }

                    BentoButton(
                        Text("Show tooltip"),
                        systemImage: "questionmark.circle.fill",
                        variant: .tonal(.info),
                        expands: true
                    ) {
                        showTooltip = true
                    }
                    .bentoTooltip(
                        isPresented: $showTooltip
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing: theme.spacing.xs
                        ) {
                            Text("Contextual help")
                                .bentoTextStyle(.headline)

                            Text(
                                "Tooltips stay popovers on compact devices."
                            )
                            .bentoTextStyle(.callout)
                        }
                    }

                    BentoButton(
                        Text("Show snackbar"),
                        systemImage: "bell.fill",
                        variant: .tonal(.success),
                        expands: true
                    ) {
                        snackbar = BentoSnackbarData(
                            title: Text("Changes saved"),
                            message: Text(
                                "You can undo this operation."
                            ),
                            tone: .success,
                            actionTitle: Text("Undo")
                        ) {
                            snackbar = BentoSnackbarData(
                                title: Text("Operation undone"),
                                tone: .info
                            )
                        }
                    }
                }
            }
        }
    }

    private var templatesSection: some View {
        BentoSection(
            title: Text("Templates"),
            subtitle: Text("Complete production-ready page compositions")
        ) {
            VStack(spacing: theme.spacing.xs) {
                NavigationLink {
                    DemoOnboardingView()
                } label: {
                    templateRow(
                        title: Text("Onboarding"),
                        subtitle: Text("Paged onboarding flow"),
                        systemImage: "rectangle.stack.fill",
                        tone: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DemoWizardView()
                } label: {
                    templateRow(
                        title: Text("Wizard"),
                        subtitle: Text("Multi-step validated form"),
                        systemImage: "list.number",
                        tone: .green
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DemoAuthView()
                } label: {
                    templateRow(
                        title: Text("Authentication"),
                        subtitle: Text("Sign-in and account flow"),
                        systemImage: "lock.fill",
                        tone: .yellow
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DemoPaywallView()
                } label: {
                    templateRow(
                        title: Text("Paywall"),
                        subtitle: Text("Plan selection and purchase actions"),
                        systemImage: "crown.fill",
                        tone: .pink
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func templateRow(
        title: Text,
        subtitle: Text,
        systemImage: String,
        tone: BentoTone
    ) -> some View {
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

    private var heatmapData: [BentoHeatmapDatum] {
        (0..<112).compactMap { offset in
            guard let date = Calendar.current.date(
                byAdding: .day,
                value: -offset,
                to: .now
            ) else {
                return nil
            }

            let value = Double(
                (offset * 37) % 100
            ) / 100

            return BentoHeatmapDatum(
                date: date,
                intensity: value
            )
        }
    }

    private var demoPeople: [DemoPerson] {
        [
            DemoPerson(
                id: "anna",
                name: "Anna",
                role: "Designer",
                status: "Online"
            ),
            DemoPerson(
                id: "jonas",
                name: "Jonas",
                role: "Developer",
                status: "Focused"
            ),
            DemoPerson(
                id: "mia",
                name: "Mia",
                role: "Product",
                status: "Away"
            )
        ]
    }

    private var demoColumns: [BentoTableColumn<DemoPerson>] {
        [
            BentoTableColumn(
                id: "name",
                title: Text("Name"),
                width: 160
            ) {
                Text(verbatim: $0.name)
                    .bentoTextStyle(.bodyStrong)
            },
            BentoTableColumn(
                id: "role",
                title: Text("Role"),
                width: 170
            ) {
                Text(verbatim: $0.role)
                    .bentoTextStyle(.body)
            },
            BentoTableColumn(
                id: "status",
                title: Text("Status"),
                width: 150
            ) {
                BentoStatusIndicator(
                    Text(verbatim: $0.status),
                    tone: $0.status == "Online"
                        ? .success
                        : .warning
                )
            }
        ]
    }
}

private struct DemoMasonryItem: Identifiable {
    let id: Int
    let title: String
    let height: CGFloat
    let tone: BentoTone
}

private struct DemoPerson: Identifiable {
    let id: String
    let name: String
    let role: String
    let status: String
}

// MARK: - Onboarding demo

private struct DemoOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    var body: some View {
        BentoOnboardingTemplate(
            pages: [
                BentoOnboardingPage(
                    id: "track",
                    eyebrow: Text("Welcome"),
                    title: Text("Track what matters"),
                    message: Text(
                        "Flexible Bento cards turn complex information into a clear daily overview."
                    ),
                    systemImage: "chart.bar.fill",
                    tone: .blue
                ),
                BentoOnboardingPage(
                    id: "focus",
                    eyebrow: Text("Stay focused"),
                    title: Text("One goal at a time"),
                    message: Text(
                        "Progress, reminders and activity remain visible without creating visual noise."
                    ),
                    systemImage: "scope",
                    tone: .yellow
                ),
                BentoOnboardingPage(
                    id: "start",
                    eyebrow: Text("Ready"),
                    title: Text("Build something great"),
                    message: Text(
                        "Every component supports themes, accessibility and Dynamic Type."
                    ),
                    systemImage: "sparkles",
                    tone: .green
                )
            ],
            selection: $page,
            onSkip: {
                dismiss()
            },
            onFinish: {
                dismiss()
            }
        )
    }
}

// MARK: - Wizard demo

private struct DemoWizardView: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var name = ""
    @State private var notifications = true
    @State private var goal = 50.0

    private let steps = [
        BentoWizardStep(
            id: "profile",
            title: Text("Your profile"),
            subtitle: Text("Tell us how we should address you")
        ),
        BentoWizardStep(
            id: "preferences",
            title: Text("Preferences"),
            subtitle: Text("Configure your experience")
        ),
        BentoWizardStep(
            id: "goal",
            title: Text("Choose a goal"),
            subtitle: Text("You can change this later")
        )
    ]

    var body: some View {
        BentoWizardTemplate(
            steps: steps,
            currentStep: $step,
            canAdvance: {
                $0 != 0 || !name.isEmpty
            },
            onFinish: {
                dismiss()
            }
        ) { currentStep in
            switch currentStep.id {
            case "profile":
                BentoTextField(
                    label: Text("Name"),
                    text: $name,
                    prompt: Text("Jane Doe"),
                    leadingSystemImage: "person.fill",
                    required: true
                )

            case "preferences":
                BentoToggleRow(
                    Text("Notifications"),
                    subtitle: Text("Receive progress reminders"),
                    systemImage: "bell.fill",
                    isOn: $notifications
                )

            default:
                BentoSlider(
                    Text("Goal"),
                    value: $goal,
                    in: 0...100,
                    step: 5
                ) {
                    Text("\(Int($0))%")
                }
            }
        }
    }
}

// MARK: - Auth demo

private struct DemoAuthView: View {
    @Environment(\.bentoTheme) private var theme

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        BentoAuthTemplate(
            title: Text("Welcome back"),
            message: Text(
                "Sign in to continue to your dashboard."
            )
        ) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(
                        .system(
                            size: 52,
                            weight: .black
                        )
                    )

                Text("BENTO")
                    .bentoTextStyle(.title2)
            }
        } form: {
            VStack(spacing: theme.spacing.md) {
                BentoTextField(
                    label: Text("Email"),
                    text: $email,
                    prompt: Text("name@example.com"),
                    leadingSystemImage: "envelope.fill",
                    keyboardType: .emailAddress,
                    contentType: .emailAddress,
                    capitalization: .never
                )

                BentoTextField(
                    label: Text("Password"),
                    text: $password,
                    prompt: Text("Password"),
                    leadingSystemImage: "lock.fill",
                    isSecure: true,
                    contentType: .password,
                    capitalization: .never
                )

                BentoAsyncButton(
                    Text("Sign in"),
                    systemImage: "arrow.right",
                    variant: .primary,
                    size: .large,
                    expands: true
                ) {
                    try await ContinuousClock()
                        .sleep(for: .seconds(1))
                }
                .disabled(email.isEmpty || password.isEmpty)
            }
        } footer: {
            Text("Privacy · Terms · Help")
                .bentoTextStyle(
                    .caption,
                    color: theme.colors.onBackground.opacity(0.7)
                )
        }
    }
}

// MARK: - Paywall demo

private struct DemoPaywallView: View {
    @State private var selectedPlan: String? = "annual"

    var body: some View {
        BentoPaywallTemplate(
            title: Text("Upgrade your experience"),
            message: Text(
                "Cancel anytime in your Apple ID settings."
            ),
            plans: [
                BentoPaywallPlan(
                    id: "monthly",
                    title: Text("Monthly"),
                    subtitle: Text("Flexible monthly billing"),
                    price: Text("€ 5,99"),
                    tone: .blue
                ),
                BentoPaywallPlan(
                    id: "annual",
                    title: Text("Annual"),
                    subtitle: Text("€ 3,33 per month"),
                    price: Text("€ 39,99"),
                    badge: Text("Best value"),
                    tone: .green
                )
            ],
            features: [
                BentoPaywallFeature(
                    id: "themes",
                    title: Text("All premium themes"),
                    systemImage: "paintpalette.fill"
                ),
                BentoPaywallFeature(
                    id: "charts",
                    title: Text("Advanced analytics"),
                    systemImage: "chart.xyaxis.line"
                ),
                BentoPaywallFeature(
                    id: "sync",
                    title: Text("Cloud synchronization"),
                    systemImage: "icloud.fill"
                )
            ],
            selectedPlanID: $selectedPlan
        ) { _ in
            try await ContinuousClock()
                .sleep(for: .seconds(1.2))
        } restore: {
            try await ContinuousClock()
                .sleep(for: .seconds(0.8))
        }
    }
}

#Preview("Advanced Extension") {
    BentoAdvancedExtensionDemo()
}