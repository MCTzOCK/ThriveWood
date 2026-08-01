import SwiftUI

public struct BentoSentenceFormDemo: View {
    public init() {}

    public var body: some View {
        BentoThemeHost(
            family: .paper,
            mode: .system
        ) {
            NavigationStack {
                BentoSentenceFormDemoContent()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct BentoSentenceFormDemoContent: View {
    private enum GapID: Hashable {
        case activity
        case destination
        case contact
        case meetingTopic
        case duration
    }

    private enum PickerKind {
        case activity
        case destination
        case contact
    }

    @Environment(\.bentoTheme) private var theme

    @State private var activity: DemoActivity?
    @State private var destinationID: String?
    @State private var contactID: String?

    @State private var meetingTopic = ""
    @State private var duration = "45"

    @State private var activePicker: PickerKind?
    @State private var showsValidation = false
    @State private var snackbar: BentoSnackbarData?

    private let destinations = [
        DemoDestination(
            id: "destination-berlin",
            displayName: "Berlin",
            detail: "Deutschland",
            systemImage: "building.2.fill"
        ),
        DemoDestination(
            id: "destination-hamburg",
            displayName: "Hamburg",
            detail: "Deutschland",
            systemImage: "water.waves"
        ),
        DemoDestination(
            id: "destination-munich",
            displayName: "München",
            detail: "Deutschland",
            systemImage: "mountain.2.fill"
        ),
        DemoDestination(
            id: "destination-amsterdam",
            displayName: "Amsterdam",
            detail: "Niederlande",
            systemImage: "bicycle"
        )
    ]

    private let contacts = [
        DemoContact(
            id: "contact-anna-mueller",
            displayName: "Anna Müller",
            detail: "Favorit",
            initials: "AM",
            tone: .pink
        ),
        DemoContact(
            id: "contact-jonas-schmidt",
            displayName: "Jonas Schmidt",
            detail: "Arbeit",
            initials: "JS",
            tone: .blue
        ),
        DemoContact(
            id: "contact-lina-wagner",
            displayName: "Lina Wagner",
            detail: "Familie",
            initials: "LW",
            tone: .green
        ),
        DemoContact(
            id: "contact-mika-becker",
            displayName: "Mika Becker",
            detail: "Freunde",
            initials: "MB",
            tone: .yellow
        )
    ]

    private var selectedDestination: DemoDestination? {
        destinations.first {
            $0.id == destinationID
        }
    }

    private var selectedContact: DemoContact? {
        contacts.first {
            $0.id == contactID
        }
    }

    private var pickerIsPresented: Binding<Bool> {
        Binding(
            get: {
                activePicker != nil
            },
            set: { newValue in
                if !newValue {
                    activePicker = nil
                }
            }
        )
    }

    var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.sm) {
                BentoPageHeader(
                    eyebrow: Text("Sentence Form"),
                    title: Text("Was machst du?"),
                    subtitle: Text(
                        "Ein Formular, das sich wie ein natürlicher Satz verhält."
                    )
                )

                sentenceCard
                storedValuesCard
                behaviorCard
            }
        }
        .bentoActionBar {
            HStack(spacing: theme.spacing.xs) {
                BentoButton(
                    Text("Zurücksetzen"),
                    systemImage: "arrow.counterclockwise",
                    variant: .chrome,
                    expands: true,
                    action: reset
                )

                BentoButton(
                    Text("Speichern"),
                    systemImage: "checkmark",
                    variant: .primary,
                    expands: true,
                    action: save
                )
            }
        }
        .bentoSheet(
            isPresented: pickerIsPresented,
            title: pickerTitle,
            subtitle: Text(
                "Die Auswahl wird unabhängig von ihrer Anzeige gespeichert."
            ),
            detents: [
                .medium,
                .large
            ]
        ) {
            pickerContent
        }
        .bentoSnackbar($snackbar)
    }

    private var sentenceCard: some View {
        BentoSentencePromptCard(
            eyebrow: Text("Dein aktueller Plan"),
            prompt: Text(
                "Tippe auf die farbigen Lücken."
            ),
            tone: .blue
        ) {
            BentoSentenceForm(
                textStyle: .title1,
                wordSpacing: 9,
                lineSpacing: 14,
                horizontalAlignment: .leading,
                lineAlignment: .center,
                animatesChanges: true,
                accessibilityLabel:
                    Text("Aktivitätsformular")
            ) {
                BentoSentenceText(
                    "Ich mache gerade"
                )

                BentoSentenceValueGap(
                    id: GapID.activity,
                    value: activity?.displayName,
                    placeholder: "Was?",
                    systemImage:
                        activity?.systemImage
                        ?? "plus",
                    tone: activity?.tone ?? .yellow,
                    status: requiredStatus(
                        activity != nil
                    ),
                    required: true,
                    accessibilityLabel:
                        Text("Aktivität"),
                    accessibilityHint:
                        Text("Aktivität auswählen")
                ) {
                    activePicker = .activity
                }

                if activity == .ride {
                    BentoSentenceText("nach")

                    BentoSentenceValueGap(
                        id: GapID.destination,
                        value:
                            selectedDestination?
                            .displayName,
                        placeholder: "Ziel",
                        systemImage: "location.fill",
                        tone: .green,
                        status: requiredStatus(
                            selectedDestination != nil
                        ),
                        required: true,
                        accessibilityLabel:
                            Text("Reiseziel"),
                        accessibilityHint:
                            Text("Reiseziel auswählen")
                    ) {
                        activePicker = .destination
                    }

                    BentoSentenceText("mit")
                    contactGap
                }

                if activity == .meeting {
                    BentoSentenceText("mit")
                    contactGap
                    BentoSentenceText("über")

                    BentoSentenceInlineTextGap(
                        id: GapID.meetingTopic,
                        text: $meetingTopic,
                        placeholder: "Thema",
                        tone: .pink,
                        status: requiredStatus(
                            !meetingTopic
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                .isEmpty
                        ),
                        required: true,
                        sizing: .wide,
                        maximumLength: 80,
                        contentType: nil,
                        capitalization: .sentences,
                        submitLabel: .done,
                        accessibilityLabel:
                            Text("Meeting-Thema")
                    )
                }

                if activity == .workout {
                    BentoSentenceText("für")

                    BentoSentenceInlineTextGap(
                        id: GapID.duration,
                        text: $duration,
                        placeholder: "45",
                        tone: .green,
                        status: requiredStatus(
                            validDuration
                        ),
                        required: true,
                        sizing: BentoSentenceGapSizing(
                            minimumWidth: 74,
                            maximumWidth: 130,
                            lineLimit: 1
                        ),
                        maximumLength: 3,
                        keyboardType: .numberPad,
                        capitalization: .never,
                        autocorrectionDisabled: true,
                        accessibilityLabel:
                            Text("Trainingsdauer")
                    )

                    BentoSentenceText("Minuten")
                }

                BentoSentencePunctuation(".")
            }
        } supporting: {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.sm
            ) {
                BentoProgressBar(
                    progress: completionProgress,
                    tone: .accent,
                    label: Text("Vollständig")
                )

                if showsValidation && !isComplete {
                    BentoCallout(
                        kind: .error,
                        title: Text(
                            "Der Satz ist noch unvollständig"
                        ),
                        message: Text(
                            "Fülle alle hervorgehobenen Lücken aus."
                        )
                    )
                }
            }
        }
    }

    private var contactGap: some BentoSentenceComponent {
        BentoSentenceGap(
            id: GapID.contact,
            tone: .pink,
            status: requiredStatus(
                selectedContact != nil
            ),
            required: true,
            sizing: .wide,
            revision: contactID.map(
                AnyHashable.init
            ),
            accessibilityLabel:
                Text("Begleitperson"),
            accessibilityValue:
                selectedContact.map {
                    Text(verbatim: $0.displayName)
                },
            accessibilityHint:
                Text("Kontakt auswählen"),
            action: {
                activePicker = .contact
            }
        ) {
            if let contact = selectedContact {
                BentoSentenceEntityLabel(
                    title: Text(
                        verbatim: contact.displayName
                    ),
                    subtitle: Text(
                        verbatim: contact.detail
                    ),
                    visualSize: 32
                ) {
                    BentoAvatar(
                        source: .initials(
                            contact.initials
                        ),
                        size: 32,
                        tone: contact.tone,
                        accessibilityLabel: Text(
                            verbatim: contact.displayName
                        )
                    )
                }
            } else {
                Label {
                    Text("Begleitung")
                } icon: {
                    Image(
                        systemName:
                            "person.badge.plus"
                    )
                }
            }
        }
    }

    private var storedValuesCard: some View {
        BentoCard {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.sm
            ) {
                BentoSectionHeader(
                    title: Text(
                        "Domain-Werte und Anzeige"
                    ),
                    subtitle: Text(
                        "IDs werden niemals direkt im Satz dargestellt."
                    )
                )

                BentoKeyValueRow(
                    key: Text("Aktivitäts-ID"),
                    value: Text(
                        verbatim:
                            activity?.rawValue ?? "—"
                    )
                )

                BentoKeyValueRow(
                    key: Text("Angezeigte Aktivität"),
                    value: Text(
                        verbatim:
                            activity?.displayName ?? "—"
                    )
                )

                BentoDivider()

                BentoKeyValueRow(
                    key: Text("Kontakt-ID"),
                    value: Text(
                        verbatim:
                            contactID ?? "—"
                    )
                )

                BentoKeyValueRow(
                    key: Text("Display Name"),
                    value: Text(
                        verbatim:
                            selectedContact?
                            .displayName ?? "—"
                    )
                )

                BentoDivider()

                BentoKeyValueRow(
                    key: Text("Ziel-ID"),
                    value: Text(
                        verbatim:
                            destinationID ?? "—"
                    )
                )

                BentoKeyValueRow(
                    key: Text("Angezeigtes Ziel"),
                    value: Text(
                        verbatim:
                            selectedDestination?
                            .displayName ?? "—"
                    )
                )
            }
        }
    }

    private var behaviorCard: some View {
        BentoCard(tone: .yellow) {
            VStack(
                alignment: .leading,
                spacing: theme.spacing.md
            ) {
                BentoSectionHeader(
                    title: Text("Dynamisches Verhalten")
                )

                BentoActivityRow(
                    systemImage:
                        "rectangle.and.pencil.and.ellipsis",
                    title: Text("Inline-Eingabe"),
                    detail: Text(
                        "Workout-Dauer und Meeting-Thema werden direkt im Satz bearbeitet."
                    ),
                    tone: .green
                )

                BentoActivityRow(
                    systemImage:
                        "rectangle.bottomthird.inset.filled",
                    title: Text("Sheet-Auswahl"),
                    detail: Text(
                        "Aktivität, Ziel und Kontakt verwenden einen Custom Select."
                    ),
                    tone: .blue
                )

                BentoActivityRow(
                    systemImage: "arrow.triangle.branch",
                    title: Text("Conditional Content"),
                    detail: Text(
                        "Die Satzstruktur folgt dem ausgewählten Aktivitätstyp."
                    ),
                    tone: .pink
                )
            }
        }
    }

    private var pickerTitle: Text {
        switch activePicker {
        case .activity:
            Text("Aktivität auswählen")
        case .destination:
            Text("Reiseziel auswählen")
        case .contact:
            Text("Kontakt auswählen")
        case nil:
            Text("Auswählen")
        }
    }

    @ViewBuilder
    private var pickerContent: some View {
        switch activePicker {
        case .activity:
            BentoSentenceSelectionSheet(
                items: DemoActivity.allCases,
                selection: $activity,
                allowsClearing: true,
                clearTitle: Text("Keine Aktivität"),
                onSelection: { _ in
                    showsValidation = false
                }
            ) { item, _ in
                BentoSentenceSelectionLabel(
                    title: Text(
                        verbatim: item.displayName
                    ),
                    subtitle: Text(
                        verbatim: item.detail
                    )
                ) {
                    Image(
                        systemName: item.systemImage
                    )
                    .font(.headline)
                    .foregroundStyle(
                        theme.colors.foreground(
                            for: item.tone
                        )
                    )
                    .frame(
                        width:
                            theme.sizing
                            .minimumTouchTarget,
                        height:
                            theme.sizing
                            .minimumTouchTarget
                    )
                    .background(
                        theme.colors.fill(
                            for: item.tone
                        ),
                        in: RoundedRectangle(
                            cornerRadius:
                                theme.radii.small,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)
                }
            }

        case .destination:
            BentoSentenceSelectionSheet(
                items: destinations,
                selection: $destinationID,
                showsSearch: true,
                searchPrompt: Text("Ziel suchen"),
                allowsClearing: true,
                clearTitle: Text("Kein Ziel"),
                filter: { destination, query in
                    destination.displayName
                        .localizedCaseInsensitiveContains(
                            query
                        )
                    || destination.detail
                        .localizedCaseInsensitiveContains(
                            query
                        )
                },
                onSelection: { _ in
                    showsValidation = false
                }
            ) { destination, _ in
                BentoSentenceSelectionLabel(
                    title: Text(
                        verbatim:
                            destination.displayName
                    ),
                    subtitle: Text(
                        verbatim: destination.detail
                    )
                ) {
                    Image(
                        systemName:
                            destination.systemImage
                    )
                    .font(.headline)
                    .foregroundStyle(
                        theme.colors.foreground(
                            for: .green
                        )
                    )
                    .frame(
                        width:
                            theme.sizing
                            .minimumTouchTarget,
                        height:
                            theme.sizing
                            .minimumTouchTarget
                    )
                    .background(
                        theme.colors.fill(
                            for: .green
                        ),
                        in: RoundedRectangle(
                            cornerRadius:
                                theme.radii.small,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)
                }
            }

        case .contact:
            BentoSentenceSelectionSheet(
                items: contacts,
                selection: $contactID,
                showsSearch: true,
                searchPrompt: Text("Kontakt suchen"),
                allowsClearing: true,
                clearTitle: Text("Niemand"),
                filter: { contact, query in
                    contact.displayName
                        .localizedCaseInsensitiveContains(
                            query
                        )
                    || contact.detail
                        .localizedCaseInsensitiveContains(
                            query
                        )
                },
                onSelection: { _ in
                    showsValidation = false
                }
            ) { contact, _ in
                BentoSentenceSelectionLabel(
                    title: Text(
                        verbatim: contact.displayName
                    ),
                    subtitle: Text(
                        verbatim: contact.detail
                    )
                ) {
                    BentoAvatar(
                        source: .initials(
                            contact.initials
                        ),
                        size: theme.sizing
                            .minimumTouchTarget,
                        tone: contact.tone,
                        accessibilityLabel: Text(
                            verbatim: contact.displayName
                        )
                    )
                    .accessibilityHidden(true)
                }
            }

        case nil:
            EmptyView()
        }
    }

    private var validDuration: Bool {
        guard let value = Int(duration) else {
            return false
        }

        return value > 0
    }

    private var completion:
        (completed: Int, total: Int) {
        switch activity {
        case .ride:
            return (
                1
                    + (selectedDestination == nil ? 0 : 1)
                    + (selectedContact == nil ? 0 : 1),
                3
            )

        case .meeting:
            let hasTopic = !meetingTopic
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty

            return (
                1
                    + (selectedContact == nil ? 0 : 1)
                    + (hasTopic ? 1 : 0),
                3
            )

        case .workout:
            return (
                1 + (validDuration ? 1 : 0),
                2
            )

        case nil:
            return (0, 1)
        }
    }

    private var completionProgress: Double {
        guard completion.total > 0 else {
            return 0
        }

        return Double(completion.completed)
            / Double(completion.total)
    }

    private var isComplete: Bool {
        completion.completed == completion.total
    }

    private func requiredStatus(
        _ hasValue: Bool
    ) -> BentoSentenceGapStatus {
        if hasValue {
            return .filled
        }

        return showsValidation ? .error : .empty
    }

    private func save() {
        guard isComplete else {
            showsValidation = true

            snackbar = BentoSnackbarData(
                title: Text(
                    "Satz noch unvollständig"
                ),
                message: Text(
                    "Bitte fülle alle erforderlichen Lücken aus."
                ),
                tone: .warning,
                systemImage:
                    "exclamationmark.triangle.fill"
            )

            return
        }

        showsValidation = false

        snackbar = BentoSnackbarData(
            title: Text("Aktivität gespeichert"),
            message: Text(
                "Die strukturierten Werte wurden übernommen."
            ),
            tone: .success,
            systemImage: "checkmark.circle.fill"
        )
    }

    private func reset() {
        activity = nil
        destinationID = nil
        contactID = nil
        meetingTopic = ""
        duration = "45"
        activePicker = nil
        showsValidation = false
    }
}

// MARK: - Demo domain

private enum DemoActivity:
    String,
    CaseIterable,
    Identifiable {
    case ride = "activity.ride"
    case meeting = "activity.meeting"
    case workout = "activity.workout"

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .ride:
            "eine Fahrt"
        case .meeting:
            "ein Meeting"
        case .workout:
            "ein Workout"
        }
    }

    var detail: String {
        switch self {
        case .ride:
            "Mit Ziel und Begleitperson"
        case .meeting:
            "Mit Kontakt und Thema"
        case .workout:
            "Mit frei eingebbarer Dauer"
        }
    }

    var systemImage: String {
        switch self {
        case .ride:
            "car.fill"
        case .meeting:
            "person.2.fill"
        case .workout:
            "figure.run"
        }
    }

    var tone: BentoTone {
        switch self {
        case .ride:
            .yellow
        case .meeting:
            .pink
        case .workout:
            .green
        }
    }
}

private struct DemoDestination: Identifiable {
    let id: String
    let displayName: String
    let detail: String
    let systemImage: String
}

private struct DemoContact: Identifiable {
    let id: String
    let displayName: String
    let detail: String
    let initials: String
    let tone: BentoTone
}

#Preview("Dynamic Sentence Form") {
    BentoSentenceFormDemo()
}