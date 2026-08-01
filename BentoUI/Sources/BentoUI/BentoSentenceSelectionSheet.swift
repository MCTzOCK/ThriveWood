import SwiftUI

public struct BentoSentenceSelectionSheet<
    Item: Identifiable,
    RowContent: View
>: View {
    @Environment(\.bentoTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Binding private var selection: Item.ID?

    private let items: [Item]
    private let showsSearch: Bool
    private let searchPrompt: Text
    private let allowsClearing: Bool
    private let clearTitle: Text
    private let dismissesOnSelection: Bool
    private let filter: (Item, String) -> Bool
    private let onSelection: (Item?) -> Void
    private let rowContent: (Item, Bool) -> RowContent

    @State private var searchText = ""

    public init(
        items: [Item],
        selection: Binding<Item.ID?>,
        showsSearch: Bool = false,
        searchPrompt: Text = Text("Search"),
        allowsClearing: Bool = false,
        clearTitle: Text = Text("No selection"),
        dismissesOnSelection: Bool = true,
        filter: @escaping (Item, String) -> Bool = {
            _, _ in true
        },
        onSelection: @escaping (Item?) -> Void = {
            _ in
        },
        @ViewBuilder row:
            @escaping (Item, Bool) -> RowContent
    ) {
        self.items = items
        self._selection = selection
        self.showsSearch = showsSearch
        self.searchPrompt = searchPrompt
        self.allowsClearing = allowsClearing
        self.clearTitle = clearTitle
        self.dismissesOnSelection =
            dismissesOnSelection
        self.filter = filter
        self.onSelection = onSelection
        self.rowContent = row
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var filteredItems: [Item] {
        guard !normalizedSearchText.isEmpty else {
            return items
        }

        return items.filter {
            filter($0, normalizedSearchText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showsSearch {
                BentoSearchField(
                    text: $searchText,
                    prompt: searchPrompt
                )
                .padding(.horizontal, theme.spacing.md)
                .padding(.bottom, theme.spacing.sm)
            }

            ScrollView {
                LazyVStack(spacing: theme.spacing.xs) {
                    if allowsClearing {
                        clearSelectionRow
                    }

                    if filteredItems.isEmpty {
                        BentoEmptyState(
                            systemImage: "magnifyingglass",
                            title: Text("No results"),
                            message: Text(
                                "Try a different search term."
                            )
                        )
                    } else {
                        ForEach(filteredItems) { item in
                            selectionRow(item)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.bottom, theme.spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var clearSelectionRow: some View {
        let isSelected = selection == nil

        return Button {
            selection = nil
            onSelection(nil)

            if dismissesOnSelection {
                dismiss()
            }
        } label: {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .frame(
                        width: theme.sizing.minimumTouchTarget,
                        height: theme.sizing.minimumTouchTarget
                    )
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .background(
                        theme.colors.surfaceSecondary,
                        in: RoundedRectangle(
                            cornerRadius: theme.radii.small,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)

                clearTitle.bentoTextStyle(.bodyStrong)

                Spacer()

                if isSelected {
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(theme.colors.accent)
                    .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.sm)
            .frame(
                minHeight:
                    theme.sizing.minimumTouchTarget
            )
            .foregroundStyle(theme.colors.onSurface)
            .background(
                isSelected
                    ? theme.colors.accent.opacity(0.14)
                    : theme.colors.surfaceSecondary,
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
                    isSelected
                        ? theme.colors.accent
                        : theme.colors.outlineSubtle,
                    lineWidth: isSelected
                        ? theme.borders.regular
                        : theme.borders.thin
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private func selectionRow(
        _ item: Item
    ) -> some View {
        let isSelected = selection == item.id

        return Button {
            selection = item.id
            onSelection(item)

            if dismissesOnSelection {
                dismiss()
            }
        } label: {
            HStack(spacing: theme.spacing.sm) {
                rowContent(item, isSelected)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                if isSelected {
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(theme.colors.accent)
                    .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.sm)
            .frame(
                minHeight:
                    theme.sizing.minimumTouchTarget
            )
            .foregroundStyle(theme.colors.onSurface)
            .background(
                isSelected
                    ? theme.colors.accent.opacity(0.14)
                    : theme.colors.surfaceSecondary,
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
                    isSelected
                        ? theme.colors.accent
                        : theme.colors.outlineSubtle,
                    lineWidth: isSelected
                        ? theme.borders.regular
                        : theme.borders.thin
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }
}

// MARK: - Reusable selection label

public struct BentoSentenceSelectionLabel<
    Leading: View
>: View {
    @Environment(\.bentoTheme) private var theme

    private let title: Text
    private let subtitle: Text?
    private let leading: Leading

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            leading

            VStack(
                alignment: .leading,
                spacing: theme.spacing.xxs
            ) {
                title.bentoTextStyle(.bodyStrong)

                if let subtitle {
                    subtitle.bentoTextStyle(
                        .caption,
                        color:
                            theme.colors.onSurfaceMuted
                    )
                }
            }
        }
    }
}

public extension BentoSentenceSelectionLabel
where Leading == EmptyView {
    init(
        title: Text,
        subtitle: Text? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle
        ) {
            EmptyView()
        }
    }
}