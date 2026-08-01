import SwiftUI

public struct BentoCreativeComponentsDemo: View {
    public init() {}

    public var body: some View {
        BentoThemeHost(
            family: .paper,
            mode: .system
        ) {
            NavigationStack {
                BentoCreativeComponentsGallery()
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
        }
    }
}

public struct BentoCreativeComponentsGallery: View {
    @Environment(\.bentoTheme) private var theme

    @State private var focusDuration = 45.0

    @State private var spatialValue =
        BentoSpatialValue(
            x: 0.7,
            y: 0.65
        )

    @State private var selectedModes:
        Set<String> = [
            "deep-work"
        ]

    @State private var deckItems =
        BentoCreativeIdea.samples

    @State private var comparisonPosition =
        0.52

    @State private var showsCommandPalette =
        false

    @State private var snackbar:
        BentoSnackbarData?

    public init() {}

    public var body: some View {
        BentoScreen {
            VStack(spacing: theme.spacing.lg) {
                BentoPageHeader(
                    eyebrow: Text("Interaction Lab"),
                    title: Text("Neue Superkräfte"),
                    subtitle: Text(
                        "Interaktionen, die sich nicht wie gewöhnliche Formulare anfühlen."
                    )
                )

                dialSection
                spatialSection
                choiceSection
                swipeSection
                comparisonSection
                timelineSection
                commandSection
                confirmationSection
            }
        }
        .bentoCommandPalette(
            isPresented:
                $showsCommandPalette,
            title: Text("Schnellaktionen"),
            subtitle: Text(
                "Navigation, Aktionen und Suche in einer Oberfläche."
            ),
            commands: commands
        )
        .bentoSnackbar($snackbar)
    }

    private var dialSection: some View {
        BentoSection(
            title: Text("Tactile Dial"),
            subtitle: Text(
                "Werte einstellen, ohne die Tastatur zu öffnen"
            )
        ) {
            BentoCard(tone: .yellow) {
                VStack(spacing: theme.spacing.lg) {
                    BentoRadialDial(
                        value: $focusDuration,
                        in: 5...120,
                        step: 5,
                        title: Text("Fokuszeit"),
                        tone: .warning,
                        diameter: 244
                    ) {
                        Text("\(Int($0)) min")
                    }

                    BentoProgressBar(
                        progress:
                            focusDuration / 120,
                        tone: .warning,
                        label: Text("Session")
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var spatialSection: some View {
        BentoSection(
            title: Text("Spatial Input"),
            subtitle: Text(
                "Zwei Werte in einer einzigen Geste"
            )
        ) {
            BentoCard {
                BentoSpatialPicker(
                    value: $spatialValue,
                    title: Text("Aktueller Zustand"),
                    xAxis: BentoSpatialAxis(
                        title: Text("Fokus"),
                        minimumLabel: Text("Zerstreut"),
                        maximumLabel: Text("Fokussiert"),
                        step: 0.05
                    ),
                    yAxis: BentoSpatialAxis(
                        title: Text("Energie"),
                        minimumLabel: Text("Ruhig"),
                        maximumLabel: Text("Energiegeladen"),
                        step: 0.05
                    ),
                    palette: .focusEnergy
                ) { value in
                    Text(
                        "Fokus \(Int(value.x * 100)) · "
                        + "Energie \(Int(value.y * 100))"
                    )
                }
            }
        }
    }

    private var choiceSection: some View {
        BentoSection(
            title: Text("Visual Choice Grid"),
            subtitle: Text(
                "Maximal drei Modi auswählen"
            )
        ) {
            BentoChoiceGrid(
                items: BentoCreativeMode.samples,
                selection: $selectedModes,
                behavior:
                    .multiple(maximum: 3),
                minimumItemWidth: 150,
                minimumItemHeight: 130,
                tone: \.tone,
                accessibilityLabel: {
                    Text(verbatim: $0.title)
                }
            ) { item, isSelected in
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.sm
                ) {
                    Image(
                        systemName:
                            item.systemImage
                    )
                    .font(
                        .system(
                            size: 28,
                            weight: .bold
                        )
                    )
                    .accessibilityHidden(true)

                    Spacer()

                    Text(verbatim: item.title)
                        .bentoTextStyle(.headline)

                    Text(
                        verbatim: item.subtitle
                    )
                    .bentoTextStyle(.caption)
                    .opacity(
                        isSelected ? 0.8 : 0.68
                    )
                }
            }
        }
    }

    private var swipeSection: some View {
        BentoSection(
            title: Text("Decision Deck"),
            subtitle: Text(
                "Ideen behalten, verwerfen oder später prüfen"
            )
        ) {
            BentoSwipeDeck(
                items: $deckItems,
                configuration:
                    BentoSwipeDeckConfiguration(
                        left: BentoSwipeDeckAction(
                            title: Text("Verwerfen"),
                            systemImage: "xmark",
                            tone: .danger
                        ),
                        right: BentoSwipeDeckAction(
                            title: Text("Behalten"),
                            systemImage: "heart.fill",
                            tone: .success
                        ),
                        up: BentoSwipeDeckAction(
                            title: Text("Später"),
                            systemImage: "clock.fill",
                            tone: .warning
                        )
                    ),
                cardHeight: 330
            ) { item, decision in
                snackbar = BentoSnackbarData(
                    title: decisionTitle(
                        decision
                    ),
                    message: Text(
                        verbatim: item.title
                    ),
                    tone: tone(
                        for: decision
                    )
                )
            } card: { item in
                BentoCard(
                    tone: item.tone,
                    style: .elevated,
                    padding: .lg,
                    radius: .extraLarge
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: theme.spacing.lg
                    ) {
                        HStack {
                            BentoBadge(
                                Text(
                                    verbatim:
                                        item.category
                                ),
                                tone: .neutral
                            )

                            Spacer()

                            Image(
                                systemName:
                                    item.systemImage
                            )
                            .font(.title2)
                        }

                        Spacer()

                        VStack(
                            alignment: .leading,
                            spacing: theme.spacing.sm
                        ) {
                            Text(
                                verbatim: item.title
                            )
                            .bentoTextStyle(.title1)

                            Text(
                                verbatim:
                                    item.description
                            )
                            .bentoTextStyle(.body)
                        }
                    }
                }
            }

            if deckItems.isEmpty {
                BentoButton(
                    Text("Deck zurücksetzen"),
                    systemImage:
                        "arrow.counterclockwise",
                    variant: .secondary,
                    expands: true
                ) {
                    deckItems =
                        BentoCreativeIdea.samples
                }
            }
        }
    }

    private var comparisonSection: some View {
        BentoSection(
            title: Text("Before / After"),
            subtitle: Text(
                "Fortschritt und visuelle Änderungen vergleichen"
            )
        ) {
            BentoBeforeAfterSlider(
                position:
                    $comparisonPosition,
                beforeLabel: Text("Vorher"),
                afterLabel: Text("Nachher"),
                accessibilityLabel:
                    Text("Fortschrittsvergleich")
            ) {
                ZStack {
                    LinearGradient(
                        colors: [
                            theme.colors.tileBlue,
                            theme.colors.surfaceSecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: theme.spacing.sm) {
                        Image(
                            systemName:
                                "cloud.rain.fill"
                        )
                        .font(
                            .system(
                                size: 58,
                                weight: .bold
                            )
                        )

                        Text("Unstrukturiert")
                            .bentoTextStyle(.title3)
                    }
                    .foregroundStyle(
                        theme.colors.onTile
                    )
                }
            } after: {
                ZStack {
                    LinearGradient(
                        colors: [
                            theme.colors.tileGreen,
                            theme.colors.accent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: theme.spacing.sm) {
                        Image(
                            systemName:
                                "sun.max.fill"
                        )
                        .font(
                            .system(
                                size: 58,
                                weight: .bold
                            )
                        )

                        Text("Im Flow")
                            .bentoTextStyle(.title3)
                    }
                    .foregroundStyle(
                        theme.colors.onTile
                    )
                }
            }
        }
    }

    private var timelineSection: some View {
        BentoSection(
            title: Text("Day Timeline"),
            subtitle: Text(
                "Überlappende Termine werden automatisch angeordnet"
            )
        ) {
            BentoCard {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    BentoSectionHeader(
                        title: Text("Heute"),
                        subtitle: Text(
                            "08:00 bis 18:00 Uhr"
                        )
                    ) {
                        BentoBadge(
                            Text(
                                "\(timelineEvents.count) Termine"
                            ),
                            tone: .info
                        )
                    }

                    BentoDayTimeline(
                        date: .now,
                        events: timelineEvents,
                        startHour: 8,
                        endHour: 18,
                        hourHeight: 64
                    ) { event in
                        snackbar =
                            BentoSnackbarData(
                                title:
                                    Text("Termin geöffnet"),
                                message: event.title,
                                tone: event.tone
                            )
                    }
                }
            }
        }
    }

    private var commandSection: some View {
        BentoSection(
            title: Text("Command Palette"),
            subtitle: Text(
                "Die globale Schaltzentrale der App"
            )
        ) {
            BentoCard(tone: .blue) {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    Image(
                        systemName:
                            "command.circle.fill"
                    )
                    .font(
                        .system(
                            size: 44,
                            weight: .bold
                        )
                    )

                    Text("Alles nur einen Tap entfernt")
                        .bentoTextStyle(.title2)

                    Text(
                        "Ideal für Power User, globale Navigation, Shortcuts und häufige Aktionen."
                    )
                    .bentoTextStyle(.body)

                    BentoButton(
                        Text("Palette öffnen"),
                        systemImage:
                            "magnifyingglass",
                        variant: .chrome,
                        expands: true
                    ) {
                        showsCommandPalette = true
                    }
                }
            }
        }
    }

    private var confirmationSection: some View {
        BentoSection(
            title: Text("Slide to Confirm"),
            subtitle: Text(
                "Kritische Aktionen ohne versehentliche Taps"
            )
        ) {
            BentoCard(tone: .pink) {
                VStack(
                    alignment: .leading,
                    spacing: theme.spacing.md
                ) {
                    BentoCallout(
                        kind: .warning,
                        title: Text(
                            "Sicherheitsinteraktion"
                        ),
                        message: Text(
                            "Die Aktion startet erst, wenn der Regler vollständig bewegt wurde."
                        )
                    )

                    BentoSlideToConfirm(
                        Text("Tag abschließen"),
                        successTitle:
                            Text("Tag abgeschlossen"),
                        failureTitle:
                            Text("Erneut versuchen"),
                        systemImage:
                            "chevron.right.2",
                        tone: .success
                    ) {
                        try await ContinuousClock()
                            .sleep(
                                for: .seconds(1.1)
                            )

                        snackbar =
                            BentoSnackbarData(
                                title:
                                    Text("Tag abgeschlossen"),
                                message:
                                    Text("Großartige Arbeit!"),
                                tone: .success,
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                    } onError: { _ in
                        snackbar =
                            BentoSnackbarData(
                                title:
                                    Text("Aktion fehlgeschlagen"),
                                tone: .danger
                            )
                    }
                }
            }
        }
    }

    private var commands:
        [BentoCommand] {
        [
            BentoCommand(
                id: "start-focus",
                title: "Fokus-Session starten",
                subtitle:
                    "\(Int(focusDuration)) Minuten",
                category: "Produktivität",
                keywords: [
                    "timer",
                    "konzentration",
                    "deep work"
                ],
                systemImage: "timer",
                tone: .yellow,
                isPinned: true
            ) {
                snackbar = BentoSnackbarData(
                    title:
                        Text("Fokus-Session gestartet"),
                    message: Text(
                        "\(Int(focusDuration)) Minuten"
                    ),
                    tone: .warning
                )
            },
            BentoCommand(
                id: "new-activity",
                title: "Aktivität erfassen",
                subtitle:
                    "Sentence Form öffnen",
                category: "Erstellen",
                keywords: [
                    "fahrt",
                    "meeting",
                    "workout"
                ],
                systemImage:
                    "rectangle.and.pencil.and.ellipsis",
                tone: .green,
                isPinned: true
            ) {
                snackbar = BentoSnackbarData(
                    title:
                        Text("Sentence Form"),
                    message: Text(
                        "Hier kann dein Sentence Form geöffnet werden."
                    ),
                    tone: .green
                )
            },
            BentoCommand(
                id: "reset-deck",
                title: "Decision Deck zurücksetzen",
                category: "Werkzeuge",
                keywords: [
                    "karten",
                    "ideen",
                    "reset"
                ],
                systemImage:
                    "arrow.counterclockwise",
                tone: .blue
            ) {
                deckItems =
                    BentoCreativeIdea.samples
            },
            BentoCommand(
                id: "set-focus",
                title: "60 Minuten Fokus",
                subtitle:
                    "Dial direkt aktualisieren",
                category: "Produktivität",
                keywords: [
                    "dauer",
                    "stunde"
                ],
                systemImage:
                    "60.circle.fill",
                tone: .accent
            ) {
                focusDuration = 60
            },
            BentoCommand(
                id: "clear-selection",
                title: "Modi zurücksetzen",
                category: "Werkzeuge",
                keywords: [
                    "auswahl",
                    "löschen"
                ],
                systemImage:
                    "square.dashed",
                tone: .neutral
            ) {
                selectedModes.removeAll()
            },
            BentoCommand(
                id: "delete-day",
                title: "Tag löschen",
                subtitle:
                    "Nur als Demo markiert",
                category: "Gefahrenzone",
                keywords: [
                    "entfernen",
                    "delete"
                ],
                systemImage: "trash.fill",
                tone: .danger,
                role: .destructive
            ) {
                snackbar = BentoSnackbarData(
                    title:
                        Text("Demo-Aktion"),
                    message: Text(
                        "Es wurden keine echten Daten gelöscht."
                    ),
                    tone: .danger
                )
            }
        ]
    }

    private var timelineEvents:
        [BentoTimelineEvent] {
        [
            BentoTimelineEvent(
                id: "planning",
                start: today(
                    hour: 8,
                    minute: 30
                ),
                end: today(
                    hour: 9,
                    minute: 15
                ),
                title:
                    Text("Tagesplanung"),
                subtitle:
                    Text("Prioritäten setzen"),
                systemImage:
                    "checklist",
                tone: .yellow
            ),
            BentoTimelineEvent(
                id: "deep-work",
                start: today(
                    hour: 9,
                    minute: 30
                ),
                end: today(
                    hour: 11,
                    minute: 30
                ),
                title:
                    Text("Deep Work"),
                subtitle:
                    Text("Design System"),
                systemImage:
                    "brain.head.profile",
                tone: .blue
            ),
            BentoTimelineEvent(
                id: "design-review",
                start: today(
                    hour: 10,
                    minute: 15
                ),
                end: today(
                    hour: 11,
                    minute: 0
                ),
                title:
                    Text("Design Review"),
                subtitle:
                    Text("Mobile Team"),
                systemImage:
                    "person.2.fill",
                tone: .pink
            ),
            BentoTimelineEvent(
                id: "lunch",
                start: today(
                    hour: 12,
                    minute: 15
                ),
                end: today(
                    hour: 13,
                    minute: 0
                ),
                title:
                    Text("Mittagspause"),
                systemImage:
                    "fork.knife",
                tone: .green
            ),
            BentoTimelineEvent(
                id: "prototype",
                start: today(
                    hour: 13,
                    minute: 30
                ),
                end: today(
                    hour: 15,
                    minute: 30
                ),
                title:
                    Text("Prototype"),
                subtitle:
                    Text("Interaction Lab"),
                systemImage:
                    "hammer.fill",
                tone: .accent
            ),
            BentoTimelineEvent(
                id: "call",
                start: today(
                    hour: 14,
                    minute: 15
                ),
                end: today(
                    hour: 15,
                    minute: 0
                ),
                title:
                    Text("Kunden-Call"),
                systemImage:
                    "phone.fill",
                tone: .warning
            ),
            BentoTimelineEvent(
                id: "workout",
                start: today(
                    hour: 16,
                    minute: 30
                ),
                end: today(
                    hour: 17,
                    minute: 30
                ),
                title:
                    Text("Workout"),
                subtitle:
                    Text("Running"),
                systemImage:
                    "figure.run",
                tone: .success
            )
        ]
    }

    private func today(
        hour: Int,
        minute: Int
    ) -> Date {
        Calendar.autoupdatingCurrent.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: .now
        ) ?? .now
    }

    private func decisionTitle(
        _ decision: BentoSwipeDecision
    ) -> Text {
        switch decision {
        case .left:
            Text("Idee verworfen")
        case .right:
            Text("Idee behalten")
        case .up:
            Text("Für später gespeichert")
        }
    }

    private func tone(
        for decision: BentoSwipeDecision
    ) -> BentoTone {
        switch decision {
        case .left:
            .danger
        case .right:
            .success
        case .up:
            .warning
        }
    }
}

// MARK: - Demo models

struct BentoCreativeMode:
    Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tone: BentoTone

    static let samples = [
        BentoCreativeMode(
            id: "deep-work",
            title: "Deep Work",
            subtitle:
                "Benachrichtigungen pausieren",
            systemImage:
                "brain.head.profile",
            tone: .blue
        ),
        BentoCreativeMode(
            id: "creative",
            title: "Creative",
            subtitle:
                "Freiraum für neue Ideen",
            systemImage:
                "paintbrush.fill",
            tone: .pink
        ),
        BentoCreativeMode(
            id: "movement",
            title: "Bewegung",
            subtitle:
                "Aktiv und energiegeladen",
            systemImage:
                "figure.run",
            tone: .green
        ),
        BentoCreativeMode(
            id: "recovery",
            title: "Recovery",
            subtitle:
                "Entschleunigen und erholen",
            systemImage:
                "leaf.fill",
            tone: .yellow
        )
    ]
}

struct BentoCreativeIdea:
    Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let systemImage: String
    let tone: BentoTone

    static let samples = [
        BentoCreativeIdea(
            id: "sentence-form",
            title: "Sentence Forms",
            description:
                "Formulare werden zu dynamischen, natürlichen Sätzen.",
            category: "Interaction",
            systemImage:
                "text.badge.plus",
            tone: .blue
        ),
        BentoCreativeIdea(
            id: "spatial-input",
            title: "Spatial Input",
            description:
                "Zwei zusammenhängende Werte werden in einer Geste erfasst.",
            category: "Input",
            systemImage:
                "scope",
            tone: .green
        ),
        BentoCreativeIdea(
            id: "command-palette",
            title: "Command Palette",
            description:
                "Globale Aktionen und Navigation werden sofort auffindbar.",
            category: "Navigation",
            systemImage:
                "command.circle.fill",
            tone: .pink
        ),
        BentoCreativeIdea(
            id: "timeline",
            title: "Visual Timeline",
            description:
                "Termine und Überschneidungen werden auf einen Blick verständlich.",
            category: "Planning",
            systemImage:
                "calendar.day.timeline.leading",
            tone: .yellow
        )
    ]
}

#Preview("Creative Interaction Lab") {
    BentoCreativeComponentsDemo()
}