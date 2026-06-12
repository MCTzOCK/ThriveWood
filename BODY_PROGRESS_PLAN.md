# Body Progress — Feature Plan

## Überblick

Ein neues Feature, das Nutzerinnen erlaubt, ihren körperlichen Fortschritt über Zeit zu verfolgen — mit Fotos, Körpermaßen und Gewicht. Der gesamte Bereich ist Face-ID / Touch-ID geschützt und wird als eigener Tab oder eigener Bereich im bestehenden Analytics-Tab integriert.

---

## Datenmodell

### `BodyProgressEntry` (SwiftData `@Model`)

```swift
@Model final class BodyProgressEntry {
    @Attribute(.unique) var id: UUID
    var date: Date                    // Tag der Aufnahme
    var weightKg: Double?             // Körpergewicht
    var bodyFatPercent: Double?        // Körperfettanteil (optional)

    // Körpermaße (alle optional — Nutzer entscheidet, was er trackt)
    var chestCm: Double?              // Brustumfang
    var waistCm: Double?              // Taillenumfang
    var hipCm: Double?                // Hüftumfang
    var bicepCm: Double?              // Oberarmumfang
    var thighCm: Double?              // Oberschenkelumfang
    var calfCm: Double?               // Wadenumfang
    var neckCm: Double?               // Nackenumfang
    var forearmCm: Double?            // Unterarmumfang
    var shoulderCm: Double?           // Schulterumfang

    // Fotos (relative Pfade im App-Sandbox-Documents-Verzeichnis)
    var frontPhotoPath: String?
    var sidePhotoPath: String?
    var backPhotoPath: String?

    var notes: String                 // Freitextnotizen
    var createdAt: Date               // Erstellungszeitpunkt

    var weightUnitRaw: String         // "kg" oder "lb"
}
```

**Überlegungen:**
- Alle Maße sind `Double?` — der Nutzer muss nicht jeden Wert ausfüllen
- Fotos werden als Dateien im Documents-Verzeichnis gespeichert (nicht in SwiftData direkt, da Bilddaten nicht in die Datenbank gehören)
- Dateipfade sind relativ zum App-Documents-Verzeichnis, für CloudKit-Kompatibilität
- `weightUnitRaw` wie im restlichen App-Pattern (bestehendes `WeightUnit`-Enum wiederverwenden)

### Foto-Speicherstrategie

```
Documents/
  BodyProgress/
    {entryId}/
      front.jpg
      side.jpg
      back.jpg
```

- Fotos werden als JPEG mit mäßiger Kompression gespeichert (Quality 0.7, ca. 200-400 KB pro Foto)
- Bei Anzeige werden Thumbnails asynchron geladen
- Beim Löschen eines Eintrags wird das gesamte Verzeichnis gelöscht
- CloudKit synchronisiert **keine** Fotos — nur die Pfade. Fotos sind lokal.

---

## Face-ID / Biometrische Absicherung

### `PrivacyService` (`@MainActor @Observable`)

```swift
@MainActor @Observable
final class PrivacyService {
    var isBodyProgressLocked: Bool     // Gespeichert in UserDefaults
    var isBiometricsAvailable: Bool    // LAContext.canEvaluatePolicy
    var isUnlocked: Bool               // Aktueller Freischaltzustand

    func requestUnlock() async throws  // Face-ID / Touch-ID Prompt
    func lock()                         // Bereich wieder sperren
    func toggleLockSetting()            // Sperre ein-/ausschalten
}
```

**Ablauf:**
1. Nutzer öffnet Body-Progress-Tab → wenn `isBodyProgressLocked && !isUnlocked`, erscheint Face-ID-Prompt
2. Nach erfolgreicher Authentifizierung → `isUnlocked = true`, Inhalt wird angezeigt
3. `isUnlocked` wird zurückgesetzt, wenn: App in den Hintergrund geht, Bildschirm gesperrt wird, oder Nutzer manuell sperrt
4. Setting in `UserProfile` oder `UserDefaults`: `bodyProgressLocked: Bool`

**Info.plist Ergänzung:**
```xml
<key>NSFaceIDUsageDescription</key>
<string>ThriveWood benötigt Face ID, um deine Körper-Fortschrittsdaten zu schützen.</string>
```

**Fallback:**
- Falls Face ID / Touch ID nicht verfügbar → Passcode-Eingabe über LAContext `.deviceOwnerAuthentication`
- Falls Nutzer keine Biometrie hat → Option deaktiviert, Bereich immer zugänglich

---

## UI-Struktur

### Navigation

Neuer Tab oder Bereich innerhalb des Analytics-Tabs (konfigurierbar in Settings). Vorschlag: **Eigener Tab im RootTabView**.

```
RootTabView
  ├── Habits      (existing)
  ├── Analytics    (existing)
  ├── Sport       (existing)
  ├── Body        (NEU — Body Progress)
  └── Settings    (existing)
```

### View-Hierarchie

```
Views/Body/
├── BodyProgressView.swift           # Hauptansicht (Timeline oder Kalender)
├── BodyProgressDetailView.swift     # Detailansicht eines Eintrags
├── BodyProgressEntryView.swift       # Neuen Eintrag erstellen/bearbeiten
├── BodyProgressPhotoGrid.swift       # Foto-Vergleichsansicht (vor/nach)
├── BodyProgressChartsView.swift      # Charts für Maße & Gewicht
├── BodyProgressLockView.swift        # Face-ID Lock-Screen
└── Support/
    ├── MeasurementField.swift         # Wiederverwendbares Eingabefeld für Maße
    ├── PhotoCaptureButton.swift       # Foto aufnehmen/auswählen
    ├── ProgressPhotoView.swift        # Einzelfoto-Anzeige mit Zoom
    └── BodyMeasurementUnit.swift      # Einheiten-Konvertierung (cm/inch)
```

### BodyProgressView (Hauptansicht)

**Inhalt:**
- Oben: Aktuellster Eintrag als Card mit Foto-Previews und neuesten Maßen
- Mitte: Schnellzugriff auf "Neuen Eintrag erstellen"
- Unten: Timeline-Liste aller Einträge (neueste oben)
- Tab-Leiste zum Wechseln zwischen: Timeline | Charts | Foto-Vergleich

**Lock-Verhalten:**
- Wenn `isBodyProgressLocked && !isUnlocked`: Blurred Placeholder mit Schloss-Icon und "Zum Öffnen authentifizieren"-Button
- Nach Unlock: Vollständige Ansicht

### BodyProgressEntryView (Eintrag erstellen/bearbeiten)

**Sektionen:**
1. **Datum** — DatePicker
2. **Gewicht** — Decimal-Pad Eingabe mit Einheit (kg/lb aus Profil)
3. **Körperfett** — Optional, Decimal-Pad mit `%`-Suffix
4. **Körpermaße** — Gruppiert nach Körperregion
   - Oberkörper: Brust, Schultern, Nacken
   - Arme: Oberarm, Unterarm
   - Rumpf: Taille, Hüfte
   - Beine: Oberschenkel, Wade
   - Jedes Feld mit Einheit (cm/inch) und optionalem Toggle
5. **Fotos** — Bis zu 3 Fotos (Vorderseite, Seite, Rücken)
   - Jedes Foto: Aufnehmen mit Kamera oder aus Bibliothek wählen
   - Thumbnail-Vorschau mit Löschen-Option
6. **Notizen** — Multiline TextEditor

### BodyProgressPhotoGrid (Foto-Vergleichsansicht)

**Funktionalität:**
- Zwei Einträge nebeneinander (vorher / nachher)
- Slider-Overlay zum Vergleichen gleicher Perspektiven (front/side/back)
- Automatische Vorschläge: "Dein Fortschritt der letzten 30/60/90 Tage"
- Pinch-to-Zoom auf einzelnen Fotos

### BodyProgressChartsView (Charts)

**SwiftUI Charts:**
- Liniendiagramm für Gewicht über Zeit
- Liniendiagramm für ausgewählte Maße über Zeit (Multi-Select)
- Balkendiagramm für Änderungen zwischen zwei Zeitpunkten
- Y-Achse: cm oder inch (je nach Profil-Einstellung)

---

## Service Layer

### `BodyProgressService` (`@MainActor @Observable`)

```swift
@MainActor @Observable
final class BodyProgressService {
    private let repo: BodyProgressRepository

    var entries: [BodyProgressEntry]
    var latestEntry: BodyProgressEntry?

    // CRUD
    func createEntry(...) throws -> BodyProgressEntry
    func updateEntry(_ entry: BodyProgressEntry) throws
    func deleteEntry(_ entry: BodyProgressEntry) throws

    // Foto-Management
    func savePhoto(_ image: UIImage, type: PhotoType, for entry: BodyProgressEntry) throws -> String
    func loadPhoto(path: String) async -> UIImage?
    func deletePhotos(for entry: BodyProgressEntry) throws

    // Berechnungen
    func progressBetween(_ from: BodyProgressEntry, _ to: BodyProgressEntry) -> MeasurementDiff
    func weightTrend(days: Int) -> [(date: Date, weight: Double)]
    func measurementTrend(measurement: MeasurementType, days: Int) -> [(date: Date, value: Double)]
}
```

### `MeasurementDiff` (Struct)

```swift
struct MeasurementDiff {
    var weightChange: Double?
    var bodyFatChange: Double?
    var chestChange: Double?
    var waistChange: Double?
    var hipChange: Double?
    var bicepChange: Double?
    var thighChange: Double?
    var calfChange: Double?
    var neckChange: Double?
    var forearmChange: Double?
    var shoulderChange: Double?

    var totalInchesLost: Double?   // Summe aller cm-Änderungen (negativ = verloren)
    var direction: ChangeDirection // .gained, .lost, .maintained
}
```

### Repository

```swift
protocol BodyProgressRepository {
    func fetchAll() throws -> [BodyProgressEntry]
    func create(_ entry: BodyProgressEntry) throws
    func update(_ entry: BodyProgressEntry) throws
    func delete(_ entry: BodyProgressEntry) throws
    func fetch(in range: DateInterval) throws -> [BodyProgressEntry]
}
```

---

## Maße & Einheiten

### Neues Enum: `BodyMeasurementUnit`

```swift
enum BodyMeasurementUnit: String, Codable, CaseIterable {
    case cm, inch
    var label: String { self == .cm ? "cm" : "in" }
    var conversionFactor: Double { self == .cm ? 1.0 : 0.393701 }
}
```

- `UserProfile` erhält neue Properties: `bodyMeasurementUnit: BodyMeasurementUnit`, `bodyProgressLocked: Bool`
- Eingaben werden immer in der Profileinheit gespeichert, Anzeige konvertiert bei Bedarf

### `MeasurementType` Enum (für Charts)

```swift
enum MeasurementType: String, CaseIterable {
    case weight, bodyFat, chest, waist, hip, bicep, thigh, calf, neck, forearm, shoulder

    var label: String {
        switch self {
        case .weight: "Gewicht"
        case .bodyFat: "Körperfett"
        case .chest: "Brustumfang"
        case .waist: "Taillenumfang"
        case .hip: "Hüftumfang"
        case .bicep: "Oberarm"
        case .thigh: "Oberschenkel"
        case .calf: "Wade"
        case .neck: "Nacken"
        case .forearm: "Unterarm"
        case .shoulder: "Schultern"
        }
    }

    var icon: String { /* SF Symbols */ }
    var unit: String { /* "kg", "%", "cm" etc. */ }
}
```

---

## Foto-Handling

### Aufnahme-Flow

1. Nutzer tippt auf Foto-Platzhalter (front/side/back)
2. ActionSheet: "Foto aufnehmen" / "Aus Bibliothek wählen"
3. `UIImagePickerController` via `UIViewControllerRepresentable` oder `PhotosPicker`
4. Nach Auswahl: Bild zuschneiden (Quadrat, optional mit Guides für Pose-Vergleich)
5. Bild skalieren auf max 1200×1200 px
6. Als JPEG (Quality 0.7) ins Documents-Verzeichnis speichern
7. Pfad im `BodyProgressEntry` hinterlegen

### Privacy bei Fotos

- Fotos werden **nicht** in die Photo Library geschrieben (nur App-Sandbox)
- Wenn Face-ID aktiv: Fotos werden nur angezeigt wenn entsperrt
- Fotos werden **nicht** mit CloudKit synchronisiert (nur Metadaten/Pfade)
- Beim Löschen eines Eintrags: Foto-Dateien sofort löschen

### Foto-Vergleich

- Slide-Over: Zwei Bilder übereinander, Slider von links nach rechts blendet zwischen "vorher" und "nachher"
- Gleiche Perspektive (front↔front, side↔side, back↔back) wird automatisch vorgeschlagen
- Pinch-to-Zoom auf einzelnen Fotos

---

## AppEnvironment Integration

```swift
// In AppEnvironment.swift ergänzen:
let bodyProgressRepo: BodyProgressRepository
let bodyProgressService: BodyProgressService
let privacyService: PrivacyService

// Im Init:
let bodyProgressRepo = SwiftDataBodyProgressRepository(context: context)
let privacyService = PrivacyService()
self.bodyProgressRepo = bodyProgressRepo
self.bodyProgressService = BodyProgressService(repo: bodyProgressRepo, privacy: privacyService)
self.privacyService = privacyService
```

---

## SharedModelContainer Erweiterung

`BodyProgressEntry` muss zum SwiftData `ModelContainer` hinzugefügt werden:

```swift
// In SharedModelContainer.swift:
Schema([..., BodyProgressEntry.self])
```

---

## Info.plist Ergänzungen

```xml
<!-- Bereits vorhanden -->
<key>NSFaceIDUsageDescription</key>
<string>ThriveWood benötigt Face ID, um deine Körper-Fortschrittsdaten zu schützen.</string>

<!-- Falls Fotobibliothek-Zugriff benötigt wird -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ThriveWood benötigt Zugriff auf deine Fotobibliothek, um Fortschrittsfotos auszuwählen.</key>

<!-- Bereits vorhanden für Location -->
<key>NSCameraUsageDescription</key>
<string>ThriveWood benötigt Zugriff auf die Kamera, um Fortschrittsfotos aufzunehmen.</string>
```

**Hinweis:** `NSCameraUsageDescription` muss ggf. ergänzt werden, falls noch nicht vorhanden.

---

## Settings Integration

Neue Section im Settings-Tab:

```
🔒 Körper-Fortschritt
   [Face-ID Schutz]  Toggle: ein/aus
   [Maßeinheit]       cm / inch
   [Gewichtseinheit]  kg / lb  (bestehend, ggf. verknüpfen)
```

---

## Punkte-Integration (Optional)

- Jeder Body-Progress-Eintrag könnte Habit-Punkte vergeben (z.B. 1 Punkt pro Eintrag als "Gewicht tracken"-Habit)
- Oder als separates Feature: "Körper tracken" als messbares Habit mit Ziel "1 Eintrag pro Woche"

---

## Pro Feature Gating

- **Free**: Timeline, Gewicht & Maße eintragen, einfache Charts
- **Pro**: Foto-Vergleich (Slide-Over), erweiterte Charts (90/365 Tage), Foto-Aufnahme, Face-ID Schutz

---

## Offene Fragen

1. **Tab vs. Section**: Eigener Tab im RootTabView oder Unterbereich im Analytics-Tab? Empfehlung: Eigener Tab, da das Feature umfangreich genug ist und Face-ID Protection einfacher pro-Tab zu realisieren ist.

2. **CloudKit Sync für Fotos**: Aktuell keine Sync geplant. Falls gewünscht, müsste auf CloudKit Asset-Fields oder einen Cloud-Speicher-Provider umgestellt werden.

3. **Foto-Zuschnitt**: Soll ein Crop-View mit Overlay-Guides (Körper-Silhouetten) angeboten werden, um konsistente Fotos zu ermöglichen? Empfehlung: Ja, als Pro-Feature.

4. **Integration mit HealthKit**: Gewicht und Körperfett könnten aus Apple Health importiert werden (`HKQuantityTypeIdentifier.bodyMass`, `HKQuantityTypeIdentifier.bodyFatPercentage`). Empfehlung: Ja, als Option in den Settings.

5. **Standard-Maße**: Welche Maße sollen standardmäßig angezeigt werden? Empfehlung: Alle optional, aber Gewicht + Taille + Brust + Hüfte als "Highlights" in der Hauptansicht.