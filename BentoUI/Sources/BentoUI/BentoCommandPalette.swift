import SwiftUI

public struct BentoCommand:
    Identifiable {
    public let id: AnyHashable
    public let title: String
    public let subtitle: String?
    public let category: String?
    public let keywords: [String]
    public let systemImage: String
    public let tone: BentoTone
    public let role: ButtonRole?
    public let isEnabled: Bool
    public let isPinned: Bool
    public let keepsPalettePresented: Bool
    public let action:
        @MainActor () -> Void

    public init<ID: Hashable>(
        id: ID,
        title: String,
        subtitle: String? = nil,
        category: String? = nil,
        keywords: [String] = [],
        systemImage: String,
        tone: BentoTone = .neutral,
        role: ButtonRole? = nil,
        isEnabled: Bool = true,
        isPinned: Bool = false,
        keepsPalettePresented: Bool = false,
        action:
            @escaping @MainActor () -> Void
    ) {
        self.id = AnyHashable(id)
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.keywords = keywords
        self.systemImage = systemImage
        self.tone = tone
        self.role = role
        self.isEnabled = isEnabled
        self.isPinned = isPinned
        self.keepsPalettePresented =
            keepsPalettePresented
        self.action = action
    }
}

public struct BentoCommandPalette: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let commands: [BentoCommand]
    private let searchPrompt: Text
    private let pinnedTitle: String
    private let resultsTitle: String
    private let uncategorizedTitle: String
    private let automaticallyFocusesSearch: Bool
    private let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var searchIsFocused = false

    public init(
        title: Text = Text("Quick actions"),
        subtitle: Text? = Text(
            "Search commands, destinations and actions."
        ),
        commands: [BentoCommand],
        searchPrompt: Text = Text("Search commands"),
        pinnedTitle: String = "Pinned",
        resultsTitle: String = "Results",
        uncategorizedTitle: String = "Actions",
        automaticallyFocusesSearch: Bool = true,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.commands = commands
        self.searchPrompt = searchPrompt
        self.pinnedTitle = pinnedTitle
        self.resultsTitle = resultsTitle
        self.uncategorizedTitle =
            uncategorizedTitle
        self.automaticallyFocusesSearch =
            automaticallyFocusesSearch
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, theme.spacing.md)
                .padding(.top, theme.spacing.md)
                .padding(.bottom, theme.spacing.sm)

            BentoTextField(
                text: $searchText,
                prompt: searchPrompt,
                accessibilityLabel:
                    Text("Search commands"),
                leadingSystemImage:
                    "magnifyingglass",
                capitalization: .never,
                autocorrectionDisabled: true,
                submitLabel: .go,
                isFocused: $searchIsFocused,
                onSubmit: executeFirstResult
            )
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, theme.spacing.sm)

            BentoDivider()

            if sections.isEmpty {
                BentoEmptyState(
                    systemImage:
                        "magnifyingglass",
                    title: Text("No commands found"),
                    message: Text(
                        "Try another search term."
                    )
                )

                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(
                        alignment: .leading,
                        spacing: theme.spacing.lg
                    ) {
                        ForEach(sections) { section in
                            commandSection(section)
                        }
                    }
                    .padding(theme.spacing.md)
                }
                .scrollDismissesKeyboard(
                    .interactively
                )
            }
        }
        .foregroundStyle(theme.colors.onBackground)
        .background(
            theme.colors.background
                .ignoresSafeArea()
        )
        .task {
            guard automaticallyFocusesSearch else {
                return
            }

            await Task.yield()
            searchIsFocused = true
        }
    }

    private var header: some View {
        HStack(
            alignment: .top,
            spacing: theme.spacing.sm
        ) {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.xxs
            ) {
                title.bentoTextStyle(.title2)

                if let subtitle {
                    subtitle.bentoTextStyle(
                        .callout,
                        color:
                            theme.colors.onBackground
                            .opacity(0.7)
                    )
                }
            }

            Spacer()

            BentoIconButton(
                systemImage: "xmark",
                accessibilityLabel: Text("Close"),
                variant: .chrome,
                size: .small,
                action: onDismiss
            )
        }
    }

    private var normalizedQuery: String {
        normalize(searchText)
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    private var filteredCommands:
        [BentoCommand] {
        guard !normalizedQuery.isEmpty else {
            return commands
        }

        return commands
            .enumerated()
            .compactMap {
                index,
                command -> (
                    command: BentoCommand,
                    score: Int,
                    index: Int
                )? in

                guard let score = matchScore(
                    command,
                    query: normalizedQuery
                ) else {
                    return nil
                }

                return (
                    command,
                    score,
                    index
                )
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.index < $1.index
                }

                return $0.score > $1.score
            }
            .map(\.command)
    }

    private var sections:
        [BentoCommandSection] {
        if !normalizedQuery.isEmpty {
            guard !filteredCommands.isEmpty else {
                return []
            }

            return [
                BentoCommandSection(
                    id: "search-results",
                    title: resultsTitle,
                    commands: filteredCommands
                )
            ]
        }

        var result:
            [BentoCommandSection] = []

        let pinned = commands.filter(
            \.isPinned
        )

        if !pinned.isEmpty {
            result.append(
                BentoCommandSection(
                    id: "pinned",
                    title: pinnedTitle,
                    commands: pinned
                )
            )
        }

        let remaining = commands.filter {
            !$0.isPinned
        }

        var orderedCategories: [String] = []

        for command in remaining {
            let category =
                command.category?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            let resolvedCategory =
                category?.isEmpty == false
                ? category!
                : uncategorizedTitle

            if !orderedCategories.contains(
                resolvedCategory
            ) {
                orderedCategories.append(
                    resolvedCategory
                )
            }
        }

        for category in orderedCategories {
            let commandsInCategory =
                remaining.filter {
                    let rawCategory =
                        $0.category?
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )

                    let resolved =
                        rawCategory?.isEmpty == false
                        ? rawCategory!
                        : uncategorizedTitle

                    return resolved == category
                }

            result.append(
                BentoCommandSection(
                    id: "category-\(category)",
                    title: category,
                    commands:
                        commandsInCategory
                )
            )
        }

        return result
    }

    private func commandSection(
        _ section: BentoCommandSection
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: theme.spacing.xs
        ) {
            Text(verbatim: section.title)
                .bentoTextStyle(
                    .overline,
                    color:
                        theme.colors.onBackground
                        .opacity(0.65)
                )
                .textCase(.uppercase)

            ForEach(section.commands) { command in
                commandRow(command)
            }
        }
    }

    private func commandRow(
        _ command: BentoCommand
    ) -> some View {
        Button(role: command.role) {
            execute(command)
        } label: {
            HStack(spacing: theme.spacing.sm) {
                Image(
                    systemName:
                        command.systemImage
                )
                .font(.headline)
                .foregroundStyle(
                    theme.colors.foreground(
                        for: command.tone
                    )
                )
                .frame(
                    width:
                        theme.sizing.minimumTouchTarget,
                    height:
                        theme.sizing.minimumTouchTarget
                )
                .background(
                    theme.colors.fill(
                        for: command.tone
                    ),
                    in: RoundedRectangle(
                        cornerRadius:
                            theme.radii.small,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.xxs
                ) {
                    Text(verbatim: command.title)
                        .bentoTextStyle(.bodyStrong)

                    if let subtitle =
                            command.subtitle {
                        Text(verbatim: subtitle)
                            .bentoTextStyle(
                                .caption,
                                color:
                                    theme.colors
                                    .onSurfaceMuted
                            )
                    }
                }

                Spacer(minLength: theme.spacing.sm)

                if command.isPinned {
                    Image(
                        systemName: "pin.fill"
                    )
                    .foregroundStyle(
                        theme.colors.onSurfaceMuted
                    )
                    .accessibilityLabel(
                        Text("Pinned")
                    )
                } else {
                    Image(
                        systemName:
                            "arrow.up.right"
                    )
                    .foregroundStyle(
                        theme.colors.onSurfaceMuted
                    )
                    .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.sm)
            .frame(
                minHeight:
                    theme.sizing.minimumTouchTarget
            )
            .foregroundStyle(
                command.role == .destructive
                    ? theme.colors.danger
                    : theme.colors.onSurface
            )
            .background(
                theme.colors.surface,
                in: RoundedRectangle(
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
                    theme.colors.outlineSubtle,
                    lineWidth:
                        theme.borders.thin
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!command.isEnabled)
        .opacity(
            command.isEnabled ? 1 : 0.45
        )
    }

    private func executeFirstResult() {
        guard let command =
                filteredCommands.first(
                    where: \.isEnabled
                ) else {
            return
        }

        execute(command)
    }

    private func execute(
        _ command: BentoCommand
    ) {
        guard command.isEnabled else {
            return
        }

        if !command.keepsPalettePresented {
            onDismiss()
        }

        command.action()
    }

    private func matchScore(
        _ command: BentoCommand,
        query: String
    ) -> Int? {
        let tokens = query.split(
            whereSeparator: \.isWhitespace
        )

        let title =
            normalize(command.title)

        let subtitle =
            normalize(command.subtitle ?? "")

        let category =
            normalize(command.category ?? "")

        let keywords =
            command.keywords.map(normalize)

        var score = command.isPinned
            ? 8
            : 0

        for tokenSubstring in tokens {
            let token =
                String(tokenSubstring)

            if title.hasPrefix(token) {
                score += 120
            } else if title.contains(token) {
                score += 80
            } else if keywords.contains(
                where: {
                    $0.hasPrefix(token)
                }
            ) {
                score += 60
            } else if keywords.contains(
                where: {
                    $0.contains(token)
                }
            ) {
                score += 45
            } else if subtitle.contains(token) {
                score += 30
            } else if category.contains(token) {
                score += 20
            } else {
                return nil
            }
        }

        return score
    }

    private func normalize(
        _ value: String
    ) -> String {
        value
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ],
                locale: .autoupdatingCurrent
            )
            .lowercased()
    }
}

private struct BentoCommandSection:
    Identifiable {
    let id: String
    let title: String
    let commands: [BentoCommand]
}

// MARK: - Presentation modifier

private struct BentoCommandPaletteModifier:
    ViewModifier {
    @Environment(\.bentoTheme) private var theme

    @Binding var isPresented: Bool

    let title: Text
    let subtitle: Text?
    let commands: [BentoCommand]
    let detents: Set<PresentationDetent>
    let interactiveDismissDisabled: Bool

    private var resolvedDetents:
        Set<PresentationDetent> {
        detents.isEmpty
            ? [.large]
            : detents
    }

    func body(content: Content) -> some View {
        content.sheet(
            isPresented: $isPresented
        ) {
            BentoCommandPalette(
                title: title,
                subtitle: subtitle,
                commands: commands
            ) {
                isPresented = false
            }
            .presentationDetents(
                resolvedDetents
            )
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(
                theme.radii.extraLarge
            )
            .presentationBackground(
                theme.colors.background
            )
            .interactiveDismissDisabled(
                interactiveDismissDisabled
            )
        }
    }
}

public extension View {
    func bentoCommandPalette(
        isPresented: Binding<Bool>,
        title: Text = Text("Quick actions"),
        subtitle: Text? = Text(
            "Search commands, destinations and actions."
        ),
        commands: [BentoCommand],
        detents: Set<PresentationDetent> = [
            .large
        ],
        interactiveDismissDisabled: Bool = false
    ) -> some View {
        modifier(
            BentoCommandPaletteModifier(
                isPresented: isPresented,
                title: title,
                subtitle: subtitle,
                commands: commands,
                detents: detents,
                interactiveDismissDisabled:
                    interactiveDismissDisabled
            )
        )
    }
}