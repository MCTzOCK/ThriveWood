# UnioKit Integration

UnioKit ermöglicht einer eigenständigen App, ihren vollständigen logischen Datenbestand für die Unio-App bereitzustellen.

Unio kann anschließend alle vorhandenen Exporte laden, miteinander vergleichen und appübergreifende Zusammenhänge erkennen.

## Grundprinzip

Jede App bleibt vollständig eigenständig.

Eine App:

* besitzt ihre eigene Datenbank,
* funktioniert ohne Unio,
* kennt keine anderen Tracker-Apps,
* exportiert ihren vollständigen logischen Datenbestand,
* beschreibt die Bedeutung ihrer Felder in einem Schema.

Unio:

* erkennt automatisch alle vorhandenen Exporte,
* importiert nur Daten installierter und eingebundener Apps,
* normalisiert Zeiten, Orte, Personen und Messwerte,
* sucht nach appübergreifenden Zusammenhängen,
* verändert niemals die ursprünglichen Tracker-Daten.

## App Group aktivieren

Das App-Target in Xcode auswählen und unter **Signing & Capabilities** die Capability **App Groups** hinzufügen.

Folgende App Group aktivieren:

```text
group.com.bensiebert.apps
```

Dieser Schritt ist sowohl in der Tracker-App als auch in Unio erforderlich.

Alle beteiligten Apps müssen vom selben Apple Developer Team signiert sein.

## UnioKit hinzufügen

`UnioKit.swift` in das Projekt kopieren und dem App-Target zuordnen.

Langfristig sollte die Datei als lokales Swift Package eingebunden werden:

```text
UnioKit/
    Package.swift
    Sources/
        UnioKit/
            UnioKit.swift
```

## Source definieren

Jede App benötigt eine dauerhaft eindeutige Source-ID.

```swift
enum DrivoUnio {
    static let source = UnioSource(
        id: "drive-tracker",
        displayName: "Drivo"
    )
}
```

Empfohlene IDs:

| App | Source-ID |
|---|---|
| Drivo | `drive-tracker` |
| Socio | `social-tracker` |
| Workout Tracker | `workout-tracker` |
| Habit Tracker | `habit-tracker` |
| iVisited | `ivisited` |

Eine veröffentlichte Source-ID darf nicht mehr geändert werden.

## Export-DTOs erstellen

Die internen SwiftData-, Core-Data- oder Datenbankmodelle sollten nicht direkt exportiert werden.

Stattdessen definiert die App stabile Exportmodelle:

```swift
struct DrivoTripExport: Codable, Sendable {
    let id: String
    let startedAt: Date
    let endedAt: Date?
    let updatedAt: Date
    let origin: DrivoPlaceExport?
    let destination: DrivoPlaceExport?
    let distanceKilometers: Double
    let durationMinutes: Int
    let averageSpeedKmh: Int?
    let fuelCostEUR: Double?
    let vehicleID: String?
}

struct DrivoPlaceExport: Codable, Sendable {
    let id: String?
    let name: String
    let latitude: Double?
    let longitude: Double?
}
```

Das Exportmodell sollte alle analytisch relevanten Daten enthalten.

Dazu gehören insbesondere:

* stabile IDs,
* Zeitpunkte,
* Zeiträume,
* Messwerte,
* Beziehungen,
* Orte,
* Koordinaten,
* Kategorien,
* Statuswerte,
* historische Daten.

Nicht exportiert werden sollten technische Daten, die für Unio keine Bedeutung haben:

* SwiftData-interne IDs,
* UI-Zustände,
* Cache-Daten,
* temporäre Dateien,
* Zugangsdaten,
* Authentifizierungs-Tokens.

## Dataset-Schema definieren

Ein Schema erklärt Unio die Bedeutung der exportierten Felder.

```swift
extension DrivoTripExport {
    static let unioSchema = UnioDatasetSchema(
        datasetID: "trips",
        entityType: "trip",
        title: "Fahrten",
        description: "Alle von Drivo aufgezeichneten Fahrten",
        primaryKeyPath: ["id"],
        updatedAtPath: ["updatedAt"],
        fields: [
            UnioFieldDefinition(
                path: ["id"],
                title: "ID",
                valueType: .identifier,
                semanticType: UnioSemanticType.identifier
            ),
            UnioFieldDefinition(
                path: ["startedAt"],
                title: "Start",
                valueType: .date,
                semanticType: UnioSemanticType.startTime
            ),
            UnioFieldDefinition(
                path: ["endedAt"],
                title: "Ende",
                valueType: .date,
                semanticType: UnioSemanticType.endTime
            ),
            UnioFieldDefinition(
                path: ["origin", "name"],
                title: "Startort",
                valueType: .string,
                semanticType: UnioSemanticType.locationName
            ),
            UnioFieldDefinition(
                path: ["origin", "latitude"],
                title: "Breitengrad des Startorts",
                valueType: .latitude,
                semanticType: UnioSemanticType.latitude
            ),
            UnioFieldDefinition(
                path: ["origin", "longitude"],
                title: "Längengrad des Startorts",
                valueType: .longitude,
                semanticType: UnioSemanticType.longitude
            ),
            UnioFieldDefinition(
                path: ["destination", "name"],
                title: "Ziel",
                valueType: .string,
                semanticType: UnioSemanticType.locationName
            ),
            UnioFieldDefinition(
                path: ["distanceKilometers"],
                title: "Distanz",
                valueType: .number,
                semanticType: UnioSemanticType.distance,
                unit: "kilometer"
            ),
            UnioFieldDefinition(
                path: ["durationMinutes"],
                title: "Dauer",
                valueType: .integer,
                semanticType: UnioSemanticType.duration,
                unit: "minute"
            ),
            UnioFieldDefinition(
                path: ["fuelCostEUR"],
                title: "Kraftstoffkosten",
                valueType: .number,
                semanticType: UnioSemanticType.money,
                currency: "EUR"
            )
        ],
        relations: [
            UnioRelationDefinition(
                path: ["vehicleID"],
                relationType: "usedVehicle",
                targetEntityType: "vehicle",
                targetDatasetID: "vehicles"
            )
        ]
    )
}
```

## Semantic Types

Semantic Types sollten appübergreifend konsistent verwendet werden.

Verfügbare Standardwerte:

```swift
UnioSemanticType.identifier
UnioSemanticType.title
UnioSemanticType.name

UnioSemanticType.startTime
UnioSemanticType.endTime
UnioSemanticType.timestamp
UnioSemanticType.createdAt
UnioSemanticType.updatedAt

UnioSemanticType.duration
UnioSemanticType.distance
UnioSemanticType.money
UnioSemanticType.count

UnioSemanticType.latitude
UnioSemanticType.longitude
UnioSemanticType.locationName

UnioSemanticType.personName
UnioSemanticType.personIdentifier
UnioSemanticType.placeIdentifier
```

Eigene Semantic Types sind erlaubt:

```swift
semanticType: "workoutIntensity"
```

Unio kann unbekannte Semantic Types speichern und später durch einen speziellen Analyseadapter interpretieren.

## Dataset erstellen

Die aktuellen App-Daten werden in Export-DTOs umgewandelt:

```swift
func buildTripDataset() async throws -> UnioDatasetExport {
    let trips = try await tripRepository.fetchAll()

    let exportRecords = trips.map { trip in
        DrivoTripExport(
            id: trip.id.uuidString,
            startedAt: trip.startedAt,
            endedAt: trip.endedAt,
            updatedAt: trip.updatedAt,
            origin: trip.origin.map {
                DrivoPlaceExport(
                    id: $0.id?.uuidString,
                    name: $0.name,
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            },
            destination: trip.destination.map {
                DrivoPlaceExport(
                    id: $0.id?.uuidString,
                    name: $0.name,
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            },
            distanceKilometers: trip.distanceKilometers,
            durationMinutes: trip.durationMinutes,
            averageSpeedKmh: trip.averageSpeedKmh,
            fuelCostEUR: trip.fuelCost,
            vehicleID: trip.vehicle?.id.uuidString
        )
    }

    return try UnioDatasetExport(
        id: "trips",
        entityType: "trip",
        title: "Fahrten",
        schema: DrivoTripExport.unioSchema,
        records: exportRecords
    )
}
```

## Vollständigen Export veröffentlichen

Jede App sollte genau eine zentrale Exportfunktion besitzen.

```swift
enum DrivoUnioExporter {
    static let exporter: UnioExporter = {
        do {
            return try UnioExporter()
        } catch {
            fatalError(
                "Unio exporter could not be created: \(error)"
            )
        }
    }()

    static func publishFullExport() async {
        do {
            async let trips = buildTripDataset()
            async let vehicles = buildVehicleDataset()
            async let fuelEntries = buildFuelEntryDataset()
            async let destinations = buildDestinationDataset()

            let datasets = try await [
                trips,
                vehicles,
                fuelEntries,
                destinations
            ]

            try await exporter.export(
                source: DrivoUnio.source,
                datasets: datasets
            )
        } catch {
            print("Unio export failed:", error)
        }
    }
}
```

Alle Datasets werden als ein gemeinsamer Snapshot veröffentlicht.

Unio sieht entweder den vorherigen vollständigen Export oder den neuen vollständigen Export. Ein teilweise geschriebener Export wird nie aktiviert.

## Empfohlene Datasets

### Drivo

* `trips`
* `vehicles`
* `destinations`
* `fuel-entries`
* `maintenance-entries`

### Socio

* `people`
* `interactions`
* `groups`
* `events`
* `places`

### Workout Tracker

* `workouts`
* `exercises`
* `workout-exercises`
* `personal-records`
* `body-measurements`

### Habit Tracker

* `habits`
* `habit-completions`
* `habit-skips`
* `habit-goals`

### iVisited

* `places`
* `visits`
* `exploration-sessions`
* `discovered-regions`

Sehr große Standort-Rohdaten sollten nicht zwingend vollständig exportiert werden. Für Unio reichen häufig Visits, Aufenthalte, relevante Orte und verdichtete Bewegungspfade.

## Exportzeitpunkte

Ein vollständiger Export sollte erstellt werden:

* nach dem Erstellen eines Datensatzes,
* nach dem Bearbeiten eines Datensatzes,
* nach dem Löschen eines Datensatzes,
* nach einem Import,
* nach einer Datenmigration,
* beim Wechsel in den Hintergrund,
* beim ersten Start nach einem App-Update.

Eine einfache Debounce-Logik verhindert zu viele Exporte:

```swift
actor UnioExportScheduler {
    private var pendingTask: Task<Void, Never>?

    func schedule() {
        pendingTask?.cancel()

        pendingTask = Task {
            try? await Task.sleep(
                for: .seconds(2)
            )

            guard !Task.isCancelled else {
                return
            }

            await DrivoUnioExporter.publishFullExport()
        }
    }

    func exportImmediately() async {
        pendingTask?.cancel()
        pendingTask = nil

        await DrivoUnioExporter.publishFullExport()
    }
}
```

Zentrale Instanz:

```swift
enum AppServices {
    static let unioExportScheduler = UnioExportScheduler()
}
```

Nach einer Änderung:

```swift
try await tripRepository.save(trip)
await AppServices.unioExportScheduler.schedule()
```

## Primäre App-Funktion nicht blockieren

Ein Fehler beim Unio-Export darf das Speichern in der Tracker-App nicht verhindern.

Falsch:

```swift
try await publishFullExport()
try await tripRepository.save(trip)
```

Richtig:

```swift
try await tripRepository.save(trip)

Task {
    await DrivoUnioExporter.publishFullExport()
}
```

Die Tracker-Datenbank bleibt immer die Source of Truth.

## Löschen von Daten

Da jede Veröffentlichung einen vollständigen Snapshot erzeugt, müssen gelöschte Datensätze im nächsten Export einfach fehlen.

Beispiel:

1. Export enthält 100 Fahrten.
2. Eine Fahrt wird gelöscht.
3. Neuer Export enthält 99 Fahrten.
4. Unio ersetzt beim Import die alte Drivo-Version durch die neue.

Separate Tombstones sind bei vollständigen Snapshots nicht erforderlich.

## Assets exportieren

Analytisch relevante Dateien können optional exportiert werden:

```swift
let asset = UnioAssetExport(
    relativePath: "vehicles/golf-thumbnail.jpg",
    contentType: "image/jpeg",
    data: imageData
)

try await exporter.export(
    source: DrivoUnio.source,
    datasets: datasets,
    assets: [asset]
)
```

Im Datensatz wird nur der relative Pfad gespeichert:

```swift
struct VehicleExport: Codable, Sendable {
    let id: String
    let name: String
    let thumbnailAssetPath: String?
}
```

Beispielwert:

```text
assets/vehicles/golf-thumbnail.jpg
```

Keine absoluten Dateipfade exportieren.

## Export entfernen

Wenn ein Nutzer die Unio-Integration deaktiviert:

```swift
try await DrivoUnioExporter.exporter.removeExport(
    for: "drive-tracker"
)
```

Die App sollte dafür eine Einstellung anbieten:

```text
Unio-Integration
    [x] Daten für Unio bereitstellen

    Letzter Export: Heute, 17:42
    Exportierte Datensätze: 2.481

    [Export jetzt aktualisieren]
    [Unio-Daten löschen]
```

## Daten in Unio laden

Unio erstellt einen zentralen Reader:

```swift
let reader = try UnioReader(
    appGroupIdentifier: "group.com.bensiebert.apps"
)
```

Alle vorhandenen Quellen erkennen:

```swift
let discovery = await reader.discover()

for source in discovery.sources {
    print(source.manifest.source.displayName)

    for dataset in source.manifest.datasets {
        print(dataset.id, dataset.recordCount)
    }
}
```

Sind nur Drivo und iVisited vorhanden, liefert `discover()` auch nur Drivo und iVisited.

Unio benötigt keine installierte Socio-App, um Drivo auszuwerten.

## Gesamten Katalog laden

```swift
let catalog = await reader.loadCatalog()
```

Der Katalog enthält:

* alle verfügbaren Sources,
* alle Datasets,
* alle Schemas,
* alle Records,
* Discovery-Fehler,
* fehlerhafte JSONL-Zeilen.

Alle Fahrten:

```swift
let trips = catalog.records(
    entityType: "trip"
)
```

Alle Drivo-Datensätze:

```swift
let drivoRecords = catalog.records(
    fromSource: "drive-tracker"
)
```

Ein bestimmtes Dataset:

```swift
let interactions = catalog.records(
    datasetID: "interactions",
    sourceID: "social-tracker"
)
```

## Typisierte Daten lesen

Wenn Unio den App-Typ kennt:

```swift
let tripRecords = catalog.records(
    datasetID: "trips",
    sourceID: "drive-tracker"
)

let trips = tripRecords.compactMap {
    try? catalog.decode(
        DrivoTripExport.self,
        record: $0
    )
}
```

## Unbekannte Daten generisch lesen

Unio kann Datensätze ohne app-spezifisches Swift-Modell lesen:

```swift
for record in catalog.records {
    print(record.source.displayName)
    print(record.dataset.entityType)

    let title = record.firstValue(
        withSemanticType: UnioSemanticType.title
    )?.stringValue

    let start = record.firstValue(
        withSemanticType: UnioSemanticType.startTime
    )?.dateValue

    print(title ?? "Ohne Titel")
    print(start as Any)
}
```

## Zeitliche Zusammenhänge finden

Fahrten und soziale Interaktionen innerhalb von 30 Minuten:

```swift
let trips = catalog.records(
    entityType: "trip"
)

let interactions = catalog.records(
    entityType: "socialInteraction"
)

let candidates = UnioCorrelation.temporalCandidates(
    left: trips,
    right: interactions,
    maximumGap: 30 * 60
)

for candidate in candidates {
    print(
        candidate.left.id,
        candidate.right.id,
        candidate.gap
    )
}
```

Ein kleiner Zeitabstand ist ein Signal, aber noch kein Beweis für einen Zusammenhang.

Unio sollte zusätzlich prüfen:

* Koordinaten,
* Ortsnamen,
* Personennamen,
* Ereignisreihenfolge,
* wiederkehrende Muster.

## Räumliche Nähe prüfen

```swift
guard
    let tripCoordinate = trip.semanticCoordinate,
    let interactionCoordinate = interaction.semanticCoordinate
else {
    return
}

let distance = UnioCorrelation.distanceMeters(
    from: tripCoordinate,
    to: interactionCoordinate
)

if distance < 250 {
    print("Wahrscheinlich gleicher Ort")
}
```

## Confidence Score bilden

Eine einfache erste Heuristik:

```swift
struct UnioCorrelationScore {
    static func score(
        timeGap: TimeInterval,
        distanceMeters: Double?,
        namesMatch: Bool
    ) -> Double {
        var score = 0.0

        if timeGap <= 15 * 60 {
            score += 0.45
        } else if timeGap <= 30 * 60 {
            score += 0.25
        }

        if let distanceMeters {
            if distanceMeters <= 100 {
                score += 0.4
            } else if distanceMeters <= 500 {
                score += 0.2
            }
        }

        if namesMatch {
            score += 0.15
        }

        return min(score, 1.0)
    }
}
```

Ergebnisse sollten sprachlich entsprechend dargestellt werden:

| Confidence | Darstellung |
|---|---|
| Unter `0,5` | Nicht anzeigen |
| `0,5–0,7` | „Könnte zusammenhängen“ |
| `0,7–0,9` | „Hängt wahrscheinlich zusammen“ |
| Über `0,9` | „Sehr wahrscheinlicher Zusammenhang“ |

Unio darf eine abgeleitete Verbindung nicht als gesicherte Tatsache darstellen.

## Mögliche Unio-Insights

Wenn nur Drivo installiert ist:

* gefahrene Strecke nach Woche und Monat,
* häufigste Ziele,
* Zeit- und Kostenaufwand,
* wiederkehrende Mobilitätsmuster,
* ungewöhnlich lange Fahrten.

Wenn Drivo und Socio installiert sind:

* Fahrten zu sozialen Treffen,
* Entfernung pro Kontakt,
* soziale Reisezeit,
* häufig besuchte Personen,
* Verhältnis zwischen Fahrzeit und gemeinsamer Zeit.

Wenn Drivo und Workout installiert sind:

* Fahrten zum Fitnessstudio,
* tatsächliche Trainingsquote nach Anfahrt,
* gesamte für Training aufgewendete Zeit,
* Fahrstrecke pro Workout.

Wenn iVisited und Socio installiert sind:

* gemeinsam entdeckte Orte,
* neue Orte durch soziale Treffen,
* Aufenthalte mit wahrscheinlichen Interaktionen,
* häufige soziale Orte.

Wenn Habit und Workout installiert sind:

* Habit Completion an Trainingstagen,
* zeitliche Reihenfolge von Gewohnheiten und Workouts,
* Trainingseinfluss auf andere Routinen.

## Datenschutz

Alle Apps in derselben App Group können technisch alle dort gespeicherten Exporte lesen.

Daher sollte jede App:

* die Unio-Integration sichtbar erklären,
* sie optional deaktivierbar machen,
* den letzten Exportzeitpunkt anzeigen,
* das Löschen des Exports ermöglichen,
* sensible Felder im Schema markieren,
* unnötige Geheimnisse nicht exportieren.

Sensible Felder können markiert werden:

```swift
UnioFieldDefinition(
    path: ["notes"],
    title: "Private Notiz",
    valueType: .string,
    description: "Private Notiz zur Interaktion",
    isSensitive: true
)
```

Unio kann sensible Felder standardmäßig von automatischen Analysen ausschließen.

## Performance

Die aktuelle Version erstellt vollständige Snapshots im Speicher.

Das eignet sich gut für:

* mehrere Tausend Fahrten,
* mehrere Tausend Interaktionen,
* Habit-Einträge,
* Workouts,
* relevante Aufenthalte.

Sehr große Rohdaten sollten vorher verdichtet werden:

* GPS-Punkte zu Bewegungspfaden zusammenfassen,
* identische Orte deduplizieren,
* große Bilder nur bei Bedarf exportieren,
* Audiodateien und Videos nicht automatisch exportieren.

Der Export sollte nach Möglichkeit nicht auf dem Main Actor erzeugt werden.

## Schemaänderungen

Bestehende Feldnamen nicht ohne Grund ändern.

Bei kompatiblen Erweiterungen:

* neues optionales Feld ergänzen,
* neue `UnioFieldDefinition` hinzufügen,
* `schemaVersion` erhöhen.

Bei inkompatiblen Änderungen:

* neues Dataset veröffentlichen oder
* eine neue Major-Version des Schemas definieren.

Unio sollte unbekannte Felder ignorieren und bekannte Felder weiter importieren.

## Debugging

Unio kann alle Quellen ausgeben:

```swift
let result = await reader.discover()

for source in result.sources {
    print(
        source.manifest.source.id,
        source.manifest.export.id,
        source.manifest.datasets.count
    )
}

for issue in result.issues {
    print(
        issue.sourceDirectory,
        issue.message
    )
}
```

Alle Records ausgeben:

```swift
let catalog = await reader.loadCatalog()

for record in catalog.records {
    let data = try? UnioCoding.makeEncoder(
        prettyPrinted: true
    ).encode(record.value)

    let json = data.flatMap {
        String(data: $0, encoding: .utf8)
    }

    print(json ?? "Invalid JSON")
}
```

## Integrations-Checkliste

* [ ] App Group aktiviert
* [ ] `UnioKit.swift` eingebunden
* [ ] Eindeutige Source-ID definiert
* [ ] Export-DTOs erstellt
* [ ] Alle analytisch relevanten Daten berücksichtigt
* [ ] Pro Entität ein Dataset definiert
* [ ] Schema für jedes Dataset erstellt
* [ ] Zeitfelder semantisch beschrieben
* [ ] Einheiten für Messwerte angegeben
* [ ] Beziehungen zwischen Datensätzen beschrieben
* [ ] Vollständiger Export implementiert
* [ ] Export nach Änderungen eingeplant
* [ ] Fehler blockieren nicht die Tracker-App
* [ ] Unio-Integration deaktivierbar
* [ ] Export kann gelöscht werden
* [ ] Export in Unio getestet

## Vorgabe für AI-Agenten

Folgender Prompt kann einem AI-Agenten in einer Tracker-App gegeben werden:

```text
Integriere UnioKit in diese App.

Ziel:
Die App soll ihren vollständigen analytisch relevanten Datenbestand über
UnioKit exportieren. Sie darf keine fertigen Dashboard-Kennzahlen exportieren,
sondern vollständige logische Datensätze.

Aufgaben:

1. Identifiziere alle persistenten fachlichen Modelle.
2. Erstelle stabile Codable- und Sendable-Export-DTOs.
3. Erstelle für jeden Entitätstyp ein UnioDatasetSchema.
4. Markiere Zeitpunkte, Zeiträume, Orte, Koordinaten, Personen, Geldbeträge,
   Distanzen und Dauern mit passenden Semantic Types.
5. Erhalte Beziehungen über IDs zwischen den Datasets.
6. Implementiere eine zentrale publishFullExport()-Funktion.
7. Exportiere alle historischen Datensätze.
8. Aktualisiere den Export nach Erstellen, Bearbeiten und Löschen.
9. Ein Fehler beim Export darf die primäre App-Funktion nicht blockieren.
10. Verwende die Source-ID: REPLACE_SOURCE_ID.
11. Verwende die App Group: group.com.bensiebert.apps.
12. Füge eine Einstellung zum Aktivieren, Aktualisieren und Löschen des
    Unio-Exports hinzu.
13. Verändere nicht die bestehende Persistenzarchitektur.
14. Gib abschließend eine Liste aller exportierten Datasets und ausgelassenen
    Daten aus.
```

## Zentrale Regel

Tracker-Apps liefern Daten und Bedeutung.

Unio liefert:

* Kombination,
* Normalisierung,
* Korrelation,
* Visualisierung,
* Erkenntnisse.

Keine Tracker-App muss wissen, welche anderen Apps installiert sind oder wie Unio ihre Daten später verwendet.
