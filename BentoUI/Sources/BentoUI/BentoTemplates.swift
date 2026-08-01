import SwiftUI

// MARK: - Loadable content

public struct BentoErrorDescriptor {
    public let title: Text
    public let message: Text
    public let systemImage: String

    public init(
        title: Text,
        message: Text,
        systemImage: String = "exclamationmark.triangle.fill"
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }
}

public enum BentoLoadableState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(BentoErrorDescriptor)
}

public struct BentoLoadableContainer<
    Value,
    LoadedContent: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let state: BentoLoadableState<Value>
    private let emptyTitle: Text
    private let emptyMessage: Text
    private let emptySystemImage: String
    private let retry: (() -> Void)?
    private let loadedContent: (Value) -> LoadedContent

    public init(
        state: BentoLoadableState<Value>,
        emptyTitle: Text = Text("Nothing here yet"),
        emptyMessage: Text = Text(
            "Content will appear here when it becomes available."
        ),
        emptySystemImage: String = "tray.fill",
        retry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> LoadedContent
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptySystemImage = emptySystemImage
        self.retry = retry
        self.loadedContent = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading:
            loadingView

        case .loaded(let value):
            loadedContent(value)

        case .empty:
            BentoEmptyState(
                systemImage: emptySystemImage,
                title: emptyTitle,
                message: emptyMessage
            )

        case .failed(let error):
            BentoEmptyState(
                systemImage: error.systemImage,
                title: error.title,
                message: error.message,
                actionTitle: retry == nil
                    ? nil
                    : Text("Try again"),
                action: retry
            )
        }
    }

    private var loadingView: some View {
        BentoCard {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.sm
            ) {
                BentoSkeleton(height: 28)

                BentoSkeleton(height: 18)
                    .frame(maxWidth: 260)

                BentoSkeleton(height: 92, radius: .medium)

                HStack {
                    BentoSkeleton(height: 54, radius: .medium)
                    BentoSkeleton(height: 54, radius: .medium)
                }
            }
        }
        .accessibilityLabel(Text("Loading"))
    }
}

// MARK: - Dashboard template

public struct BentoDashboardTemplate<
    Header: View,
    Hero: View,
    Metrics: View,
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let header: Header
    private let hero: Hero
    private let metrics: Metrics
    private let content: Content

    public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder metrics: () -> Metrics,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.hero = hero()
        self.metrics = metrics()
        self.content = content()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                header
                hero
                metrics
                content
            }
        }
    }
}

// MARK: - Collection template

public struct BentoCollectionTemplate<
    HeaderAction: View,
    Filters: View,
    CollectionContent: View,
    EmptyContent: View
>: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var searchText: String

    private let title: Text
    private let subtitle: Text?
    private let searchPrompt: Text
    private let isEmpty: Bool
    private let headerAction: HeaderAction
    private let filters: Filters
    private let collectionContent: CollectionContent
    private let emptyContent: EmptyContent

    public init(
        title: Text,
        subtitle: Text? = nil,
        searchText: Binding<String>,
        searchPrompt: Text = Text("Search"),
        isEmpty: Bool,
        @ViewBuilder headerAction: () -> HeaderAction,
        @ViewBuilder filters: () -> Filters,
        @ViewBuilder content: () -> CollectionContent,
        @ViewBuilder empty: () -> EmptyContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self._searchText = searchText
        self.searchPrompt = searchPrompt
        self.isEmpty = isEmpty
        self.headerAction = headerAction()
        self.filters = filters()
        self.collectionContent = content()
        self.emptyContent = empty()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    title: title,
                    subtitle: subtitle
                ) {
                    headerAction
                }

                BentoSearchField(
                    text: $searchText,
                    prompt: searchPrompt
                )

                filters
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                if isEmpty {
                    emptyContent
                } else {
                    collectionContent
                }
            }
        }
    }
}

// MARK: - Detail template

public struct BentoDetailTemplate<
    Hero: View,
    Metadata: View,
    DetailContent: View,
    Actions: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let eyebrow: Text?
    private let title: Text
    private let subtitle: Text?
    private let showsActionBar: Bool
    private let hero: Hero
    private let metadata: Metadata
    private let detailContent: DetailContent
    private let actions: Actions

    public init(
        eyebrow: Text? = nil,
        title: Text,
        subtitle: Text? = nil,
        showsActionBar: Bool = true,
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder metadata: () -> Metadata,
        @ViewBuilder content: () -> DetailContent,
        @ViewBuilder actions: () -> Actions
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.showsActionBar = showsActionBar
        self.hero = hero()
        self.metadata = metadata()
        self.detailContent = content()
        self.actions = actions()
    }

    @ViewBuilder
    public var body: some View {
        if showsActionBar {
            page
                .bentoActionBar {
                    actions
                }
        } else {
            page
        }
    }

    private var page: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle
                )

                hero
                metadata
                detailContent
            }
        }
    }
}

// MARK: - Form template

public struct BentoFormPageTemplate<
    FormContent: View,
    Actions: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let formContent: FormContent
    private let actions: Actions

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder content: () -> FormContent,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.formContent = content()
        self.actions = actions()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    title: title,
                    subtitle: subtitle
                )

                BentoCard {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.md
                    ) {
                        formContent
                    }
                }
            }
        }
        .bentoActionBar {
            actions
        }
    }
}

// MARK: - Authentication template

public struct BentoAuthTemplate<
    Brand: View,
    FormContent: View,
    Footer: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let message: Text?
    private let brand: Brand
    private let formContent: FormContent
    private let footer: Footer

    public init(
        title: Text,
        message: Text? = nil,
        @ViewBuilder brand: () -> Brand,
        @ViewBuilder form: () -> FormContent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.message = message
        self.brand = brand()
        self.formContent = form()
        self.footer = footer()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.xl) {
                brand
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )

                BentoCard(
                    style: .elevated,
                    padding: .lg,
                    radius: .extraLarge
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.lg
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing: theme.spacing.xs
                        ) {
                            title.bentoTextStyle(.title1)

                            if let message {
                                message.bentoTextStyle(
                                    .body,
                                    color:
                                        theme.colors.onSurfaceMuted
                                )
                            }
                        }

                        formContent
                    }
                }
                .frame(maxWidth: 540)

                footer
                    .frame(
                        maxWidth: 540,
                        alignment: .center
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.xl)
        }
    }
}

// MARK: - Settings templates

public struct BentoSettingsGroup<
    Content: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let content: Content

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            BentoSectionHeader(
                title: title,
                subtitle: subtitle
            )

            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.sm
                ) {
                    content
                }
            }
        }
    }
}

public struct BentoSettingsTemplate<
    Profile: View,
    Sections: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let profile: Profile
    private let sections: Sections

    public init(
        title: Text = Text("Settings"),
        @ViewBuilder profile: () -> Profile,
        @ViewBuilder sections: () -> Sections
    ) {
        self.title = title
        self.profile = profile()
        self.sections = sections()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.lg) {
                BentoPageHeader(title: title)
                profile
                sections
            }
        }
    }
}

// MARK: - Split navigation template

public struct BentoSplitNavigationTemplate<
    Sidebar: View,
    Detail: View
>: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var columnVisibility:
        NavigationSplitViewVisibility

    private let sidebar: Sidebar
    private let detail: Detail

    public init(
        columnVisibility:
            Binding<NavigationSplitViewVisibility>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self._columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            sidebar
                .background(theme.colors.background)
        } detail: {
            detail
                .background(theme.colors.background)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Onboarding

public struct BentoOnboardingPage: Identifiable {
    public let id: String
    public let eyebrow: Text?
    public let title: Text
    public let message: Text
    public let systemImage: String
    public let tone: BentoTone

    public init(
        id: String,
        eyebrow: Text? = nil,
        title: Text,
        message: Text,
        systemImage: String,
        tone: BentoTone
    ) {
        self.id = id
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.tone = tone
    }
}

public struct BentoOnboardingTemplate: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selection: Int

    private let pages: [BentoOnboardingPage]
    private let nextTitle: Text
    private let finishTitle: Text
    private let skipTitle: Text?
    private let onSkip: (() -> Void)?
    private let onFinish: () -> Void

    public init(
        pages: [BentoOnboardingPage],
        selection: Binding<Int>,
        nextTitle: Text = Text("Continue"),
        finishTitle: Text = Text("Get started"),
        skipTitle: Text? = Text("Skip"),
        onSkip: (() -> Void)? = nil,
        onFinish: @escaping () -> Void
    ) {
        self.pages = pages
        self._selection = selection
        self.nextTitle = nextTitle
        self.finishTitle = finishTitle
        self.skipTitle = skipTitle
        self.onSkip = onSkip
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            if pages.isEmpty {
                BentoEmptyState(
                    systemImage: "rectangle.stack.badge.xmark",
                    title: Text("No onboarding pages"),
                    message: Text(
                        "Provide at least one onboarding page."
                    )
                )
            } else {
                VStack(spacing: theme.spacing.md) {
                    HStack {
                        Spacer()

                        if let skipTitle, let onSkip {
                            BentoButton(
                                skipTitle,
                                variant: .chrome,
                                size: .small,
                                action: onSkip
                            )
                        }
                    }

                    TabView(selection: $selection) {
                        ForEach(
                            Array(pages.enumerated()),
                            id: \.element.id
                        ) { index, page in
                            onboardingPage(page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(
                        .page(indexDisplayMode: .never)
                    )

                    BentoPageIndicator(
                        count: pages.count,
                        current: $selection
                    )

                    HStack(spacing: theme.spacing.xs) {
                        if selection > 0 {
                            BentoButton(
                                Text("Back"),
                                systemImage: "arrow.left",
                                variant: .secondary,
                                expands: true
                            ) {
                                selection = max(
                                    0,
                                    selection - 1
                                )
                            }
                        }

                        BentoButton(
                            selection == pages.count - 1
                                ? finishTitle
                                : nextTitle,
                            systemImage: selection
                                == pages.count - 1
                                ? "checkmark"
                                : "arrow.right",
                            iconPlacement: .trailing,
                            variant: .primary,
                            size: .large,
                            expands: true,
                            action: advance
                        )
                    }
                }
                .padding(theme.spacing.sm)
                .frame(
                    maxWidth: theme.sizing.contentMaxWidth
                )
            }
        }
        .foregroundStyle(theme.colors.onBackground)
        .onAppear(perform: sanitizeSelection)
        .onChange(of: pages.map(\.id)) {
            sanitizeSelection()
        }
    }

    private func onboardingPage(
        _ page: BentoOnboardingPage
    ) -> some View {
        ScrollView {
            BentoCard(
                tone: page.tone,
                padding: .lg,
                radius: .extraLarge
            ) {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.xl
                ) {
                    Image(systemName: page.systemImage)
                        .font(
                            .system(
                                size: 76,
                                weight: .black
                            )
                        )
                        .accessibilityHidden(true)

                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.sm
                    ) {
                        if let eyebrow = page.eyebrow {
                            eyebrow
                                .bentoTextStyle(.overline)
                                .textCase(.uppercase)
                        }

                        page.title.bentoTextStyle(.display)
                        page.message.bentoTextStyle(.body)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 430,
                    alignment: .leading
                )
            }
        }
        .scrollIndicators(.hidden)
    }

    private func advance() {
        guard selection < pages.count - 1 else {
            onFinish()
            return
        }

        selection += 1
    }

    private func sanitizeSelection() {
        guard !pages.isEmpty else {
            selection = 0
            return
        }

        selection = min(
            pages.count - 1,
            max(0, selection)
        )
    }
}

// MARK: - Wizard

public struct BentoWizardStep: Identifiable {
    public let id: String
    public let title: Text
    public let subtitle: Text?

    public init(
        id: String,
        title: Text,
        subtitle: Text? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

public struct BentoWizardTemplate<
    StepContent: View
>: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var currentStep: Int

    private let steps: [BentoWizardStep]
    private let canAdvance: (Int) -> Bool
    private let onFinish: () -> Void
    private let content: (BentoWizardStep) -> StepContent

    public init(
        steps: [BentoWizardStep],
        currentStep: Binding<Int>,
        canAdvance: @escaping (Int) -> Bool = { _ in true },
        onFinish: @escaping () -> Void,
        @ViewBuilder content:
            @escaping (BentoWizardStep) -> StepContent
    ) {
        self.steps = steps
        self._currentStep = currentStep
        self.canAdvance = canAdvance
        self.onFinish = onFinish
        self.content = content
    }

    public var body: some View {
        if steps.isEmpty {
            BentoScreen {
                BentoEmptyState(
                    systemImage: "list.number",
                    title: Text("No steps"),
                    message: Text(
                        "Provide at least one wizard step."
                    )
                )
            }
        } else {
            BentoScreen {
                VStack(spacing: theme.spacing.md) {
                    BentoPageHeader(
                        eyebrow: Text(
                            "Step \(safeStep + 1) of \(steps.count)"
                        ),
                        title: steps[safeStep].title,
                        subtitle: steps[safeStep].subtitle
                    )

                    BentoProgressBar(
                        progress:
                            Double(safeStep + 1)
                            / Double(steps.count),
                        tone: .accent
                    )

                    BentoCard {
                        content(steps[safeStep])
                    }
                }
            }
            .bentoActionBar {
                HStack(spacing: theme.spacing.xs) {
                    if safeStep > 0 {
                        BentoButton(
                            Text("Back"),
                            systemImage: "arrow.left",
                            variant: .chrome,
                            expands: true
                        ) {
                            currentStep = max(
                                0,
                                safeStep - 1
                            )
                        }
                    }

                    BentoButton(
                        safeStep == steps.count - 1
                            ? Text("Finish")
                            : Text("Continue"),
                        systemImage: safeStep
                            == steps.count - 1
                            ? "checkmark"
                            : "arrow.right",
                        iconPlacement: .trailing,
                        variant: .primary,
                        expands: true
                    ) {
                        advance()
                    }
                    .disabled(!canAdvance(safeStep))
                }
            }
            .onAppear(perform: sanitizeStep)
            .onChange(of: steps.map(\.id)) {
                sanitizeStep()
            }
        }
    }

    private var safeStep: Int {
        guard !steps.isEmpty else {
            return 0
        }

        return min(
            steps.count - 1,
            max(0, currentStep)
        )
    }

    private func advance() {
        guard canAdvance(safeStep) else {
            return
        }

        guard safeStep < steps.count - 1 else {
            onFinish()
            return
        }

        currentStep = safeStep + 1
    }

    private func sanitizeStep() {
        currentStep = safeStep
    }
}

// MARK: - Profile template

public struct BentoProfileTemplate<
    Stats: View,
    ProfileContent: View,
    Actions: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let avatar: BentoAvatarSource
    private let name: Text
    private let subtitle: Text?
    private let biography: Text?
    private let tone: BentoTone
    private let stats: Stats
    private let profileContent: ProfileContent
    private let actions: Actions

    public init(
        avatar: BentoAvatarSource,
        name: Text,
        subtitle: Text? = nil,
        biography: Text? = nil,
        tone: BentoTone = .pink,
        @ViewBuilder stats: () -> Stats,
        @ViewBuilder content: () -> ProfileContent,
        @ViewBuilder actions: () -> Actions
    ) {
        self.avatar = avatar
        self.name = name
        self.subtitle = subtitle
        self.biography = biography
        self.tone = tone
        self.stats = stats()
        self.profileContent = content()
        self.actions = actions()
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoCard(tone: tone) {
                    VStack(spacing: theme.spacing.md) {
                        BentoAvatar(
                            source: avatar,
                            size: 96,
                            tone: tone,
                            accessibilityLabel: name
                        )

                        VStack(spacing: theme.spacing.xs) {
                            name
                                .bentoTextStyle(.title1)
                                .multilineTextAlignment(.center)

                            if let subtitle {
                                subtitle
                                    .bentoTextStyle(.callout)
                                    .multilineTextAlignment(.center)
                            }

                            if let biography {
                                biography
                                    .bentoTextStyle(.body)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        actions
                    }
                    .frame(maxWidth: .infinity)
                }

                BentoCard {
                    stats
                }

                profileContent
            }
        }
    }
}

// MARK: - Paywall

public struct BentoPaywallPlan: Identifiable {
    public let id: String
    public let title: Text
    public let subtitle: Text?
    public let price: Text
    public let badge: Text?
    public let tone: BentoTone

    public init(
        id: String,
        title: Text,
        subtitle: Text? = nil,
        price: Text,
        badge: Text? = nil,
        tone: BentoTone = .blue
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.badge = badge
        self.tone = tone
    }
}

public struct BentoPaywallFeature: Identifiable {
    public let id: String
    public let title: Text
    public let systemImage: String
    public let tone: BentoTone

    public init(
        id: String,
        title: Text,
        systemImage: String = "checkmark",
        tone: BentoTone = .success
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
    }
}

public struct BentoPaywallTemplate: View {
    @Environment(\.bentoTheme) private var theme

    @Binding private var selectedPlanID: String?

    private let title: Text
    private let message: Text?
    private let plans: [BentoPaywallPlan]
    private let features: [BentoPaywallFeature]
    private let purchaseTitle: Text
    private let restoreTitle: Text
    private let purchase:
        @MainActor (BentoPaywallPlan) async throws -> Void
    private let restore:
        (@MainActor () async throws -> Void)?
    private let onError:
        @MainActor (Error) -> Void

    public init(
        title: Text,
        message: Text? = nil,
        plans: [BentoPaywallPlan],
        features: [BentoPaywallFeature],
        selectedPlanID: Binding<String?>,
        purchaseTitle: Text = Text("Continue"),
        restoreTitle: Text = Text("Restore purchases"),
        purchase:
            @escaping @MainActor
            (BentoPaywallPlan) async throws -> Void,
        restore:
            (@MainActor () async throws -> Void)? = nil,
        onError:
            @escaping @MainActor
            (Error) -> Void = { _ in }
    ) {
        self.title = title
        self.message = message
        self.plans = plans
        self.features = features
        self._selectedPlanID = selectedPlanID
        self.purchaseTitle = purchaseTitle
        self.restoreTitle = restoreTitle
        self.purchase = purchase
        self.restore = restore
        self.onError = onError
    }

    private var selectedPlan: BentoPaywallPlan? {
        plans.first {
            $0.id == selectedPlanID
        }
    }

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.md) {
                BentoPageHeader(
                    eyebrow: Text("Premium"),
                    title: title,
                    subtitle: message
                )

                BentoHeroCard(
                    eyebrow: Text("Unlock everything"),
                    title: Text("Your best experience"),
                    message: Text(
                        "Flexible plans with a native, accessible purchase flow."
                    ),
                    tone: .pink
                ) {
                    Image(systemName: "crown.fill")
                        .font(
                            .system(
                                size: 76,
                                weight: .black
                            )
                        )
                } actions: {
                    EmptyView()
                }

                VStack(spacing: theme.spacing.xs) {
                    ForEach(plans) { plan in
                        planView(plan)
                    }
                }

                BentoCard {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.sm
                    ) {
                        BentoSectionHeader(
                            title: Text("Included")
                        )

                        ForEach(features) { feature in
                            HStack(spacing: theme.spacing.sm) {
                                Image(
                                    systemName:
                                        feature.systemImage
                                )
                                .foregroundStyle(
                                    theme.colors.fill(
                                        for: feature.tone
                                    )
                                )
                                .frame(width: 24)
                                .accessibilityHidden(true)

                                feature.title.bentoTextStyle(.body)

                                Spacer()
                            }
                            .frame(
                                minHeight:
                                    theme.sizing.minimumTouchTarget
                            )
                        }
                    }
                }
            }
        }
        .bentoActionBar {
            VStack(spacing: theme.spacing.xs) {
                BentoAsyncButton(
                    purchaseTitle,
                    systemImage: "arrow.right",
                    variant: .primary,
                    size: .large,
                    expands: true
                ) {
                    guard let selectedPlan else {
                        return
                    }

                    try await purchase(selectedPlan)
                } onError: {
                    onError($0)
                }
                .disabled(selectedPlan == nil)

                if let restore {
                    BentoAsyncButton(
                        restoreTitle,
                        variant: .chrome,
                        size: .small,
                        expands: true,
                        action: restore,
                        onError: onError
                    )
                }
            }
        }
        .onAppear(perform: sanitizeSelection)
        .onChange(of: plans.map(\.id)) {
            sanitizeSelection()
        }
    }

    private func planView(
        _ plan: BentoPaywallPlan
    ) -> some View {
        let isSelected = selectedPlanID == plan.id

        return Button {
            selectedPlanID = plan.id
        } label: {
            BentoCard(
                tone: isSelected ? plan.tone : nil,
                style: .outlined,
                padding: .sm,
                radius: .medium
            ) {
                HStack(spacing: theme.spacing.sm) {
                    Image(
                        systemName: isSelected
                            ? "largecircle.fill.circle"
                            : "circle"
                    )
                    .font(.title3)
                    .accessibilityHidden(true)

                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.xxs
                    ) {
                        HStack {
                            plan.title.bentoTextStyle(.bodyStrong)

                            if let badge = plan.badge {
                                BentoBadge(
                                    badge,
                                    tone: .warning
                                )
                            }
                        }

                        if let subtitle = plan.subtitle {
                            subtitle.bentoTextStyle(.caption)
                        }
                    }

                    Spacer()

                    plan.price.bentoTextStyle(.headline)
                }
                .frame(
                    minHeight: theme.sizing.minimumTouchTarget
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private func sanitizeSelection() {
        guard !plans.isEmpty else {
            selectedPlanID = nil
            return
        }

        guard plans.contains(
            where: {
                $0.id == selectedPlanID
            }
        ) else {
            selectedPlanID = plans[0].id
            return
        }
    }
}