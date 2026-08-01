# BentoUI — Vollständige Dokumentation

BentoUI ist ein **theming-getriebenes SwiftUI-Komponenten-Framework** für iOS 17+.
Es liefert ein konsistentes Design-Token-System (Farben, Typografie, Abstände, Radien,
Border, Bewegung), eine handverlesene Palette an Komponenten für Layout, Steuerelemente,
Eingaben, Datenanzeige, Navigation und Feedback sowie fertige Bildschirm-Templates und
ein System für natürlichsprachliche „Sentence Forms".

Alle Komponenten greifen über die Environment-Variablen `\.bentoTheme` auf das aktive
Theme zu und verhalten sich automatisch dark-mode-, high-contrast- und
dynamic-type- sowie reduce-motion-aware.

---

## Inhaltsverzeichnis

1. [Installation & Erste Schritte](#1-installation--erste-schritte)
2. [Design-Foundation (Themes & Tokens)](#2-design-foundation-themes--tokens)
3. [Layout](#3-layout)
4. [Steuerelemente (Controls)](#4-steuerelemente-controls)
5. [Eingaben (Inputs)](#5-eingaben-inputs)
6. [Datenanzeige (Data Display)](#6-datenanzeige-data-display)
7. [Navigation](#7-navigation)
8. [Feedback & Status](#8-feedback--status)
9. [Overlays (Dialoge, Sheets, Tooltips, Snackbar)](#9-overlays-dialoge-sheets-tooltips-snackbar)
10. [Command Palette](#10-command-palette)
11. [Sentence Forms (natürlichsprachliche Formulare)](#11-sentence-forms-natürlichsprachliche-formulare)
12. [Creative Components](#12-creative-components)
13. [Templates (Bildschirm-Vorlagen)](#13-templates-bildschirm-vorlagen)
14. [Beispiele für gute UIs](#14-beispiele-für-gute-uis)

---

## 1. Installation & Erste Schritte

### Anforderungen

- iOS 17.0+
- Swift 5.10+
- Xcode 15+

### Einbindung

BentoUI ist als Swift Package ausgeführt (`Package.swift`). Bindest du das Paket in ein
App-Projekt ein, fügst du unter *File ▸ Add Package Dependencies…* den lokalen oder
Remote-Pfad hinzu. Anschließend `import BentoUI` in jeder Datei, die Komponenten nutzt.

### Der Theme-Host

Jeder Bildschirm sollte von einem `BentoThemeHost` umschlossen sein. Er löst das zur
`ColorScheme` passende Theme auf, injiziert es über `\.bentoTheme` und setzt den
System-Tint auf die Akzentfarbe.

```swift
import SwiftUI
import BentoUI

@main
struct MeineApp: App {
    var body: some Scene {
        WindowGroup {
            BentoThemeHost(family: .paper, mode: .system, contrastMode: .system) {
                ContentView()
            }
        }
    }
}
```

### Theme manuell überschreiben

Falls du keinen `BentoThemeHost` nutzt oder ein bestimmtes Theme erzwingen willst,
verwendest du den View-Modifier `.bentoTheme(_:)`:

```swift
ContentView()
    .bentoTheme(.berryDark)
```

---

## 2. Design-Foundation (Themes & Tokens)

Die Foundation definiert die semantischen Tokens, mit denen alle Komponenten arbeiten.

### 2.1 `BentoTone` — Tönung

Steuert die Farbgebung vieler Komponenten (Tiles, Badges, Buttons, Charts usw.).

| Wert | Bedeutung |
|------|-----------|
| `.neutral` | Neutral / Oberfläche |
| `.accent` | Akzentfarbe |
| `.success` | Erfolg |
| `.warning` | Warnung |
| `.danger` | Fehler / destruktiv |
| `.info` | Information |
| `.yellow` / `.green` / `.blue` / `.pink` | Tile-Tönungen (z. B. für Dashboards) |

`BentoTone` ist `CaseIterable` und `Identifiable`.

### 2.2 `BentoSpace` — Abstandstoken

`none`, `xxs` (4), `xs` (8), `sm` (12), `md` (16), `lg` (20), `xl` (28), `xxl` (40).

Aufgelöst via `theme.spacing.value(_:)`.

### 2.3 `BentoRadius` — Eckradien

`small` (10), `medium` (15), `large` (21), `extraLarge` (28), `pill` (999).

### 2.4 `BentoTextStyle` — Textstile

| Stil | Größe | Gewicht | Verwendung |
|------|-------|---------|------------|
| `.display` | 40 | black | Große Helden-Überschriften |
| `.title1` | 32 | bold | Seiten-Titel |
| `.title2` | 24 | bold | Abschnitts-Titel |
| `.title3` | 20 | bold | Karten-Köpfe |
| `.metric` | 36 | black | Kennzahlen |
| `.headline` | 17 | bold | Hervorgehobene Zeilen |
| `.body` | 16 | regular | Fließtext |
| `.bodyStrong` | 16 | bold | Fett-Kontrast |
| `.callout` | 14 | medium | Sekundärtext |
| `.caption` | 12 | medium | Beschriftungen |
| `.overline` | 11 | bold | Eyebrows / Labels |

Anwenden mit `BentoText` oder dem Modifier `.bentoTextStyle(_:)`.

### 2.5 Text-Komponenten & Modifier

#### `BentoText`

```swift
BentoText("Willkommen", style: .title1, color: nil)
BentoText(verbatim: "42%", style: .metric)
BentoText(Text("Hallo **Welt**"), style: .headline)
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| Inhalt | `LocalizedStringKey` / `String` / `Text` | — | Der Text |
| `style` | `BentoTextStyle` | `.body` | Typografie-Stil |
| `color` | `Color?` | `nil` | Optionale Vordergrundfarbe |

#### `.bentoTextStyle(_:color:)` (View-Modifier)

Wendet Stil + optionale Farbe auf eine beliebige View (insb. `Text`) an.

```swift
Text("€ 1.299").bentoTextStyle(.metric)
```

### 2.6 `BentoTheme` & Themenfamilien

Ein `BentoTheme` bündelt `colors`, `typography`, `spacing`, `radii`, `borders`,
`sizing` und `motion`. Mitgeführte statische Themen:

- `BentoTheme.paperLight` / `.paperDark`
- `BentoTheme.paperHighContrastLight` / `.paperHighContrastDark`
- `BentoTheme.berryLight` / `.berryDark`
- `BentoTheme.berryHighContrastLight` / `.berryHighContrastDark`

Eine **`BentoThemeFamily`** fasst light/dark + je eine high-contrast-Variante zusammen
und wählt automatisch das richtige Theme:

- `BentoThemeFamily.paper`
- `BentoThemeFamily.berry`

```swift
family.theme(for: colorScheme, increasedContrast: Bool) -> BentoTheme
```

#### `BentoThemeHost`

```swift
BentoThemeHost(
    family: BentoThemeFamily = .paper,
    mode: BentoThemeMode = .system,        // .system | .light | .dark
    contrastMode: BentoContrastMode = .system // .system | .standard | .increased
) { content }
```

### 2.7 Farbtokens (`BentoColors`)

Die zentrale Farbpalette eines Themes. Komponenten nutzen überwiegend diese
semantischen Farben:

| Token | Bedeutung |
|-------|-----------|
| `background` / `onBackground` | Bildschirm-Hintergrund & Text darauf |
| `surface` / `surfaceSecondary` | Karten-/Zeilenflächen |
| `onSurface` / `onSurfaceMuted` | Text auf Flächen (primär/sekundär) |
| `outline` / `outlineSubtle` | Border / Trennlinien |
| `accent` / `onAccent` | Akzent & Text auf Akzent |
| `success` / `onSuccess`, `warning` / `onWarning`, `danger` / `onDanger`, `info` / `onInfo` | Statusfarben |
| `tileYellow/Green/Blue/Pink` / `onTile` | Tile-Tönungen |
| `chrome` / `onChrome` | Tab-Bar / Action-Bar-Chrome |
| `focus` | Fokus-Ring |
| `disabled` | Deaktiviert |

Hilfsfunktionen:

```swift
colors.fill(for: tone)      // Ton → Füllfarbe
colors.foreground(for: tone) // Ton → Vordergrundfarbe
colors.replacing(accent: ..., danger: ...) // Selektives Überschreiben
```

### 2.8 Übrige Token-Strukturen

| Struktur | Wichtige Felder / Standardwerte |
|----------|--------------------------------|
| `BentoSpacing` | `xxs=4, xs=8, sm=12, md=16, lg=20, xl=28, xxl=40`; `.standard` |
| `BentoRadii` | `small=10, medium=15, large=21, extraLarge=28, pill=999`; `.standard` |
| `BentoBorders` | `thin=1, regular=2, strong=3`; `.standard`, `.highContrast` |
| `BentoSizing` | `controlSmall=38, controlMedium=48, controlLarge=56, minimumTouchTarget=44, tabBarHeight=76, contentMaxWidth=760` |
| `BentoMotion` | `fast/regular/slow` (Dauer), `snappy` Spring; `.fast`, `.regular`, `.snappy` Animationen |
| `BentoTypography` | `displayFontName`, `bodyFontName`, `displayDesign`, `bodyDesign` (`BentoFontDesign`), `usesMonospacedDigits`; `.typewriter` |

`Color(bentoHex: 0xRRGGBB, opacity:)` ist ein Convenience-Initializer für sRGB-Farben.

---

## 3. Layout

### 3.1 `BentoScreen`

Top-Level-Bildschirm-Container. Malt den Theme-Hintergrund, zentriert/begrenzt die
Inhaltsbreite (`contentMaxWidth`), wendet Padding an und kann scrollen.

```swift
BentoScreen(scrolls: true, showsIndicators: false,
            horizontalPadding: .sm, verticalPadding: .sm) {
    // Inhalt
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `scrolls` | `Bool` | `true` |
| `showsIndicators` | `Bool` | `false` |
| `horizontalPadding` | `BentoSpace` | `.sm` |
| `verticalPadding` | `BentoSpace` | `.sm` |
| `content` | `@ViewBuilder` | — |

### 3.2 `BentoCard`

Thematische Container-Karte mit abgerundeten Ecken, optionalem Border und Schatten.

```swift
BentoCard(tone: .blue, style: .outlined, padding: .md, radius: .large) {
    Text("Inhalt")
}
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `tone` | `BentoTone?` | `nil` | Tönung (Füllung aus Token) |
| `background` | `Color?` | `nil` | Explizite Hintergrundfarbe |
| `foreground` | `Color?` | `nil` | Explizite Vordergrundfarbe |
| `style` | `BentoCardStyle` | `.outlined` | `.flat` / `.outlined` / `.elevated` |
| `padding` | `BentoSpace` | `.md` | Innenabstand |
| `radius` | `BentoRadius` | `.large` | Eckradius |
| `content` | `@ViewBuilder` | — | Inhalt |

Auflösung der Farbe: explizit > `tone` > `theme.colors.surface`.

**`BentoCardStyle`**

| Wert | Verhalten |
|------|-----------|
| `.flat` | Kein Border, kein Schatten |
| `.outlined` | Border `regular`, kein Schatten |
| `.elevated` | Dünner Border + Schatten |

### 3.3 `BentoTile`

Ton-getönte Karte mit **Mindesthöhe** und ausrichtbarem Inhalt — der Namensgeber des
Frameworks („Bento Box").

```swift
BentoTile(tone: .green, minimumHeight: 160, alignment: .topLeading) {
    Text("Kennzahl")
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `tone` | `BentoTone` | — |
| `minimumHeight` | `CGFloat` | `160` |
| `style` | `BentoCardStyle` | `.outlined` |
| `alignment` | `Alignment` | `.topLeading` |
| `content` | `@ViewBuilder` | — |

### 3.4 `BentoSection` & `BentoSectionHeader`

Ein titelierter Abschnitt mit optionalem Untertitel und Trailing-Slot.

```swift
BentoSection(title: Text("Allgemein"), subtitle: Text("Konto & Profil")) {
    // Abschnittsinhalt
}
```

`BentoSectionHeader` (einzeln nutzbar) bietet einen `trailing`-Slot:

```swift
BentoSectionHeader(title: Text("Heute"), subtitle: Text("5 Termine")) {
    BentoButton(Text("Filter"), systemImage: "line.3.horizontal.decrease",
                variant: .secondary, size: .small) { }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `trailing` | `@ViewBuilder` | `EmptyView` |

### 3.5 `BentoDivider`

Dünne Trennlinie.

```swift
BentoDivider()                              // horizontal
BentoDivider(orientation: .vertical, color: .red)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `orientation` | `BentoDividerOrientation` (`.horizontal` / `.vertical`) | `.horizontal` |
| `color` | `Color?` | `nil` (→ `outlineSubtle`) |

### 3.6 `BentoAdaptiveGrid`

`LazyVGrid` mit adaptiven Spalten, das so viele Spalten wie möglich platziert.

```swift
BentoAdaptiveGrid(minimumItemWidth: 160) {
    ForEach(items) { item in
        BentoTile(tone: .blue) { Text(item.name) }
    }
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `minimumItemWidth` | `CGFloat` | `160` | Mindestens 80 |
| `content` | `@ViewBuilder` | — | — |

### 3.7 `BentoFlowLayout`

Eigener `Layout`-Typ, der Elemente links-rechts, oben-unten umbricht (Wrapping).

```swift
BentoFlowLayout(spacing: 8) {
    ForEach(tags) { BentoBadge(Text($0)) }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `spacing` | `CGFloat` | `8` (min. 0) |

### 3.8 `BentoResponsiveStack`

Stack, der je nach Size Class und Dynamic Type horizontal oder vertikal anordnet.

```swift
BentoResponsiveStack(compactAxis: .vertical, regularAxis: .horizontal,
                     horizontalAlignment: .top) {
    LinkeRegion(); RechteRegion()
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `compactAxis` | `BentoResponsiveAxis` | `.vertical` |
| `regularAxis` | `BentoResponsiveAxis` | `.horizontal` |
| `spacing` | `CGFloat?` | `nil` (→ `theme.spacing.sm`) |
| `horizontalAlignment` | `VerticalAlignment` | `.center` |
| `verticalAlignment` | `HorizontalAlignment` | `.leading` |

> Nutzt `regularAxis` nur bei `horizontalSizeClass == .regular` **und** wenn Dynamic Type
> keine Accessibility-Größe ist.

### 3.9 `BentoMasonryLayout` & `BentoMasonryGrid`

Spalten-Masonry-Layout, das Elemente Höhe-balanciert über Spalten verteilt.

```swift
BentoMasonryGrid(items: posts, columns: 2, spacing: 8) { post in
    BentoCard { Text(post.title) }
}
```

`BentoMasonryGrid`-Parameter: `items`, `columns` (Standard 2), `spacing` (Standard 8),
`content`.

`BentoMasonryLayout` (das nackte Layout): `columns: Int = 2`, `spacing: CGFloat = 8`.

### 3.10 `BentoCarousel`

Horizontales Paging-Karussell mit fixbreiten Elementen und optionaler Auswahlbindung.

```swift
BentoCarousel(items: featured, selection: $selectedID, itemWidth: 292) { item in
    BentoCard { Text(item.title) }
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `items` | `[Item]` (`Identifiable`) | — | — |
| `selection` | `Binding<Item.ID?>?` | `nil` | Scroll-Position |
| `itemWidth` | `CGFloat` | `292` | Mindestens 120 |
| `spacing` | `CGFloat?` | `nil` (→ `xs`) | — |
| `content` | `(Item) -> Content` | — | — |

Verwendet `.scrollTargetBehavior(.viewAligned)`.

### 3.11 `BentoStickySection`

`LazyVStack` mit **angepinntem** (sticky) Abschnitts-Header.

```swift
BentoStickySection {
    BentoSectionHeader(title: Text("A")) { EmptyView() }
} content: {
    ForEach(rows) { BentoListRow(title: $0.name) }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `header` | `@ViewBuilder` | — |
| `content` | `@ViewBuilder` | — |

### 3.12 `BentoSplitCard`

Zwei-Regionen-Karte: vertikal in kompakt, horizontal in regular Size Class.

```swift
BentoSplitCard(tone: .blue) {
    Text("Linke Region")
} trailing: {
    Text("Rechte Region")
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `tone` | `BentoTone?` | `nil` |
| `leading` / `trailing` | `@ViewBuilder` | — |

### 3.13 `BentoOverlayTile`

Tile mit ganzflächigem Hintergrund und abgedunkeltem (Scrim) Content-Overlay — ideal
für Bild-Tiles.

```swift
BentoOverlayTile(minimumHeight: 220, alignment: .bottomLeading) {
    Image("cover").resizable().scaledToFill()
} content: {
    BentoText("Titel", style: .title2, color: .white)
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `minimumHeight` | `CGFloat` | `220` | Mindestens 100 |
| `alignment` | `Alignment` | `.bottomLeading` | — |
| `background` | `@ViewBuilder` | — | Vollflächiger Hintergrund |
| `content` | `@ViewBuilder` | — | Liegt auf Gradient-Scrim |

### 3.14 `BentoActionBar` & `.bentoActionBar(content:)`

Chrome-farbige Aktionsleiste am unteren Bildschirmrand mit Haarlinie oben.

```swift
ContentView()
    .bentoActionBar {
        BentoButton(Text("Speichern"), variant: .primary, expands: true) { save() }
    }
```

`BentoActionBar` (direkt): nur `content: @ViewBuilder`.

---

## 4. Steuerelemente (Controls)

### 4.1 Steuerungs-Größen & Button-Varianten

**`BentoControlSize`**: `.small` (38), `.medium` (48), `.large` (56) — jeweils Höhe.

**`BentoButtonVariant`**:

| Variante | Aussehen |
|----------|----------|
| `.primary` | Akzent-Füllung |
| `.secondary` | Oberflächen-Füllung |
| `.tonal(BentoTone)` | Ton-basierte Füllung |
| `.ghost` | Transparent |
| `.destructive` | Danger-Füllung |
| `.chrome` | Chrome-Füllung |

**`BentoIconPlacement`**: `.leading` / `.trailing`.

### 4.2 `BentoButton`

Thematischer Button mit optionalem Icon, Loading-Spinner und Rollen.

```swift
BentoButton(Text("Speichern"), systemImage: "tray.and.arrow.down",
            variant: .primary, size: .medium, expands: false, isLoading: false) {
    save()
}
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `title` | `Text` | — | Beschriftung |
| `systemImage` | `String?` | `nil` | SF Symbol |
| `iconPlacement` | `BentoIconPlacement` | `.leading` | Position des Icons |
| `variant` | `BentoButtonVariant` | `.primary` | Stil |
| `size` | `BentoControlSize` | `.medium` | Höhe |
| `expands` | `Bool` | `false` | Volle Breite |
| `isLoading` | `Bool` | `false` | Spinner, deaktiviert |
| `role` | `ButtonRole?` | `nil` | `.destructive` / `.cancel` |
| `action` | `() -> Void` | — | Aktion |

### 4.3 `BentoIconButton`

Quadratischer Icon-Button.

```swift
BentoIconButton(systemImage: "plus", accessibilityLabel: Text("Hinzufügen"),
                variant: .secondary, size: .medium) { addItem() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `systemImage` | `String` | — |
| `accessibilityLabel` | `Text` | — |
| `variant` | `BentoButtonVariant` | `.secondary` |
| `size` | `BentoControlSize` | `.medium` |
| `action` | `() -> Void` | — |

### 4.4 `BentoFloatingActionButton`

Großer primärer schwebender Action-Button (mit Schatten).

```swift
BentoFloatingActionButton(systemImage: "plus", accessibilityLabel: Text("Neu")) { }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `systemImage` | `String` | — |
| `accessibilityLabel` | `Text` | — |
| `action` | `() -> Void` | — |

### 4.5 `BentoBadge`

Kleines pill-förmiges Status-Badge.

```swift
BentoBadge(Text("Neu"), tone: .accent, systemImage: "sparkles")
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `text` | `Text` | — |
| `tone` | `BentoTone` | `.neutral` |
| `systemImage` | `String?` | `nil` |

### 4.6 `BentoChip`

Auswählbare (oder statische) Capsule-Chips.

```swift
BentoChip(Text("Workout"), systemImage: "figure.run", tone: .green,
          isSelected: true) { toggle() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `systemImage` | `String?` | `nil` |
| `tone` | `BentoTone` | `.accent` |
| `isSelected` | `Bool` | `false` |
| `action` | `(() -> Void)?` | `nil` (statisch, wenn `nil`) |

### 4.7 `BentoAsyncButton`

Button, der eine **async throwing**-Aktion ausführt, mit Lade- und Erfolg-Zustand.

```swift
BentoAsyncButton(Text("Kaufen"), successTitle: Text("Erledigt"),
                 variant: .primary, expands: true,
                 action: { try await checkout() },
                 onError: { err in showError(err) })
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `title` | `Text` | — | — |
| `successTitle` | `Text?` | `nil` | Titel im Erfolg |
| `systemImage` | `String?` | `nil` | — |
| `variant` | `BentoButtonVariant` | `.primary` | — |
| `size` | `BentoControlSize` | `.medium` | — |
| `expands` | `Bool` | `false` | — |
| `minimumLoadingDuration` | `Double` | `0.35` | Min. sichtbare Ladezeit |
| `successDisplayDuration` | `Double` | `0.8` | Erfolg-Anzeige |
| `action` | `@MainActor () async throws -> Void` | — | — |
| `onError` | `@MainActor (Error) -> Void` | `{ _ in }` | — |

### 4.8 `BentoDisclosureCard`

Aufklappbare Karte mit tappbarem Header.

```swift
@State private var expanded = false

BentoDisclosureCard(isExpanded: $expanded, tone: .blue) {
    Text("Details")            // Header
} content: {
    Text("Versteckter Inhalt") // wird eingeblendet
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `isExpanded` | `Binding<Bool>` | — |
| `tone` | `BentoTone?` | `nil` |
| `header` | `@ViewBuilder` | — |
| `content` | `@ViewBuilder` | — |

Zeigt rotierendes Chevron; Einblenden mit Opacity+Move-Transition.

### 4.9 `BentoRatingPicker`

Stern-Bewertungspicker.

```swift
@State private var rating = 3

BentoRatingPicker(value: $rating, maximum: 5, allowsZero: true)
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `value` | `Binding<Int>` | — | Wert |
| `maximum` | `Int` | `5` | 1…10 |
| `allowsZero` | `Bool` | `true` | Erneutes Tappen löscht |
| `selectedSystemImage` | `String` | `"star.fill"` | — |
| `unselectedSystemImage` | `String` | `"star"` | — |
| `accessibilityLabel` | `Text` | `Text("Rating")` | — |

### 4.10 `BentoPageIndicator`

Punkt-/Capsule-Seitenanzeige.

```swift
@State private var page = 0

BentoPageIndicator(count: 5, current: $page, allowsDirectSelection: true)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `count` | `Int` | — (max. 100) |
| `current` | `Binding<Int>` | — |
| `allowsDirectSelection` | `Bool` | `true` |

### 4.11 `BentoTonePicker`

Farb-/Ton-Swatch-Auswahl.

```swift
@State private var tone: BentoTone = .accent

BentoTonePicker(selection: $tone, tones: [.accent, .pink, .blue, .green])
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `selection` | `Binding<BentoTone>` | — |
| `tones` | `[BentoTone]` | `BentoTone.allCases` |

### 4.12 `BentoSelectionChips`

Multi-/Single-Select-Chip-Gruppe.

```swift
@State private var selected: Set<String> = []

BentoSelectionChips(options: ["A", "B", "C"], selection: $selected,
                     behavior: .multiple(maximum: 2), tone: .accent,
                     label: { Text($0) })
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `options` | `[Option]` (`Hashable`) | — |
| `selection` | `Binding<Set<Option>>` | — |
| `behavior` | `BentoChipSelectionBehavior` | `.multiple(maximum: nil)` |
| `tone` | `BentoTone` | `.accent` |
| `label` | `(Option) -> Text` | — |
| `systemImage` | `(Option) -> String?` | `{ _ in nil }` |

**`BentoChipSelectionBehavior`**: `.single(allowsEmpty: Bool)` / `.multiple(maximum: Int?)`.

### 4.13 `BentoExpandableText`

Text, der bei Überlauf „Mehr anzeigen/weniger" anbietet.

```swift
BentoExpandableText(Text(langerText), lineLimit: 3, style: .body)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `text` | `Text` | — |
| `lineLimit` | `Int` | `3` |
| `style` | `BentoTextStyle` | `.body` |
| `moreTitle` | `Text` | `Text("Show more")` |
| `lessTitle` | `Text` | `Text("Show less")` |

### 4.14 `BentoCopyField`

Schreibgeschütztes Wert-Feld mit „In Zwischenablage kopieren"-Button.

```swift
BentoCopyField(value: "DE89 3704 …", label: Text("IBAN"))
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `value` | `String` | — |
| `label` | `Text?` | `nil` |
| `copiedTitle` | `Text` | `Text("Copied")` |

> Setzt `UIPasteboard` ein (iOS). Zeigt temporär „Kopiert" an.

---

## 5. Eingaben (Inputs)

### 5.1 `BentoFieldStatus`

Beschreibt Validierungs-/Status-Zustand eines Feldes.

```swift
let s1 = BentoFieldStatus.normal
let s2 = BentoFieldStatus.success(Text("Verfügbar"))
let s3 = BentoFieldStatus.warning(Text("Schwaches Passwort"))
let s4 = BentoFieldStatus.error(Text("Pflichtfeld"))
```

`Kind`: `.normal` / `.success` / `.warning` / `.error`. Jede Factory-Methode nimmt
optional eine `Text`-Nachricht. Bestimmt Rahmenfarbe + SF Symbol.

### 5.2 `BentoTextField`

Einzeiliges Textfeld mit Label, Sicherheit, Clear-Button, Status und Zähler.

```swift
@State private var email = ""

BentoTextField(
    label: Text("E-Mail"),
    text: $email,
    prompt: Text("name@beispiel.de"),
    leadingSystemImage: "envelope",
    isSecure: false,
    required: true,
    showsClearButton: true,
    status: .normal,
    maximumLength: 120,
    keyboardType: .emailAddress,
    contentType: .emailAddress,
    capitalization: .never,
    submitLabel: .done,
    isFocused: nil,
    onSubmit: { }
)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `label` | `Text?` | `nil` |
| `text` | `Binding<String>` | — |
| `prompt` | `Text?` | `nil` |
| `accessibilityLabel` | `Text?` | `nil` |
| `leadingSystemImage` | `String?` | `nil` |
| `isSecure` | `Bool` | `false` |
| `required` | `Bool` | `false` |
| `showsClearButton` | `Bool` | `true` |
| `status` | `BentoFieldStatus` | `.normal` |
| `maximumLength` | `Int?` | `nil` |
| `keyboardType` | `UIKeyboardType` | `.default` |
| `contentType` | `UITextContentType?` | `nil` |
| `capitalization` | `TextInputAutocapitalization` | `.sentences` |
| `autocorrectionDisabled` | `Bool` | `false` |
| `submitLabel` | `SubmitLabel` | `.done` |
| `isFocused` | `Binding<Bool>?` | `nil` |
| `onSubmit` | `() -> Void` | `{}` |

> Bei `isSecure` gibt es zusätzlich einen Eye-Toggle zum Ein-/Ausblenden.

### 5.3 `BentoTextArea`

Mehrzeiliger Text-Editor.

```swift
@State private var bio = ""

BentoTextArea(label: Text("Bio"), text: $bio, prompt: Text("Erzähl von dir"),
              maximumLength: 280, minimumHeight: 130)
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `label` | `Text?` | `nil` | — |
| `text` | `Binding<String>` | — | — |
| `prompt` | `Text` | — | Pflicht |
| `required` | `Bool` | `false` | — |
| `status` | `BentoFieldStatus` | `.normal` | — |
| `maximumLength` | `Int?` | `nil` | — |
| `minimumHeight` | `CGFloat` | `130` | Mindestens 90 |

### 5.4 `BentoSearchField`

Vorkonfiguriertes Suchfeld (baut auf `BentoTextField`).

```swift
@State private var query = ""

BentoSearchField(text: $query, prompt: Text("Suchen")) { runSearch() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `text` | `Binding<String>` | — |
| `prompt` | `Text` | `Text("Search")` |
| `onSubmit` | `() -> Void` | `{}` |

### 5.5 `BentoToggleRow`

Zeile mit Titel/Subtitel und Schalter.

```swift
@State private var notifications = true

BentoToggleRow(Text("Benachrichtigungen"), subtitle: Text("Push & E-Mail"),
               systemImage: "bell", isOn: $notifications)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `systemImage` | `String?` | `nil` |
| `isOn` | `Binding<Bool>` | — |

### 5.6 `BentoCheckbox`

Tappbare Checkbox-Zeile.

```swift
@State private var accepted = false

BentoCheckbox(Text("AGB akzeptieren"), subtitle: nil, isOn: $accepted)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `isOn` | `Binding<Bool>` | — |

### 5.7 `BentoRadioGroup`

Single-Select-Radiogruppe.

```swift
@State private var plan: String? = "pro"

BentoRadioGroup(options: ["free", "pro", "team"], selection: $plan) { opt in
    Text(opt.capitalized)
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `options` | `[Option]` (`Hashable`) | — |
| `selection` | `Binding<Option?>` | — |
| `label` | `(Option) -> Label` | — |

### 5.8 `BentoSegmentedPicker`

Segmentierte Kontrolle mit `matchedGeometry`-Kapsel.

```swift
@State private var tab = "Tag"

BentoSegmentedPicker(options: ["Tag", "Woche", "Monat"], selection: $tab) { Text($0) }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `options` | `[Option]` (`Hashable`) | — |
| `selection` | `Binding<Option>` | — |
| `label` | `(Option) -> Label` | — |

### 5.9 `BentoStepper`

Integer-Stepper.

```swift
@State private var count = 1

BentoStepper(Text("Personen"), value: $count, in: 1...20, step: 1) { Text("\($0)") }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `value` | `Binding<Int>` | — |
| `in range` | `ClosedRange<Int>` | — |
| `step` | `Int` | `1` |
| `valueLabel` | `(Int) -> Text` | `Text(String($0))` |

### 5.10 `BentoSlider`

Thematischer Schieberegler für `Double`.

```swift
@State private var volume = 50.0

BentoSlider(Text("Lautstärke"), value: $volume, in: 0...100, step: 1)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `value` | `Binding<Double>` | — |
| `in range` | `ClosedRange<Double>` | — |
| `step` | `Double` | `1` |
| `valueLabel` | `(Double) -> Text` | gerundete Zahl |

### 5.11 `BentoMenuPicker`

Titelzeile mit anhängendem Menü-Picker.

```swift
@State private var currency = "EUR"

BentoMenuPicker(Text("Währung"), options: ["EUR", "USD", "GBP"], selection: $currency) {
    Text($0)
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `options` | `[Option]` (`Hashable`) | — |
| `selection` | `Binding<Option>` | — |
| `optionLabel` | `(Option) -> Text` | — |

### 5.12 `BentoOTPField`

OTP-/Verifizierungscode-Feld als Reihe von Zeichenboxen.

```swift
@State private var code = ""

BentoOTPField(code: $code, length: 6, alphabet: .digits,
              onComplete: { verify($0) })
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `code` | `Binding<String>` | — | — |
| `length` | `Int` | `6` | 1…12 |
| `alphabet` | `BentoOTPAlphabet` | `.digits` | `.digits` / `.alphanumeric` |
| `isSecure` | `Bool` | `false` | Punkte statt Zeichen |
| `uppercasesInput` | `Bool` | `true` | — |
| `accessibilityLabel` | `Text` | `Text("Verification code")` | — |
| `onComplete` | `(String) -> Void` | `{ _ in }` | Einmalig bei Fertig |

Setzt `textContentType(.oneTimeCode)` für SMS-AutoFill.

### 5.13 `BentoTagInput`

Tag-Editor im Flusslayout mit Inline-Textfeld.

```swift
@State private var tags = ["Swift", "iOS"]

BentoTagInput(tags: $tags, label: Text("Skills"),
              placeholder: Text("Tag hinzufügen"), maximumCount: 10, tone: .accent)
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `tags` | `Binding<[String]>` | — | — |
| `label` | `Text?` | `nil` | — |
| `placeholder` | `Text` | `Text("Add tag")` | — |
| `maximumCount` | `Int` | `20` | — |
| `tone` | `BentoTone` | `.accent` | — |
| `normalize` | `(String) -> String` | trim | Vor dem Validieren |
| `validate` | `(String) -> Bool` | nicht leer | Gültigkeit |
| `onRejected` | `(String, BentoTagRejectionReason) -> Void` | `{ _ in }` | — |

`BentoTagRejectionReason`: `.empty` / `.duplicate` / `.invalid` / `.limitReached`.
Commit per Return oder `,`/`;`. Duplikaterkennung ist case-/diakritik-insensitiv.

### 5.14 `BentoRangeSlider`

Zwei-Daumen-Schieber für einen `ClosedRange<Double>`.

```swift
@State private var range: ClosedRange<Double> = 20...80

BentoRangeSlider(Text("Preis"), selection: $range, in: 0...100, step: 5)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `selection` | `Binding<ClosedRange<Double>>` | — |
| `in bounds` | `ClosedRange<Double>` | — |
| `step` | `Double` | `1` |
| `formatValue` | `(Double) -> String` | Zahl mit 0…2 Nachkommastellen |

### 5.15 `BentoDatePickerField`

Thematischer DatePicker.

```swift
@State private var date = Date()

BentoDatePickerField(Text("Geburtstag"), selection: $date,
                     displayedComponents: [.date], presentation: .graphical)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `label` | `Text` | — |
| `selection` | `Binding<Date>` | — |
| `in allowedRange` | `ClosedRange<Date>?` | `nil` |
| `displayedComponents` | `DatePickerComponents` | `[.date]` |
| `presentation` | `BentoDatePickerPresentation` | `.compact` |

`BentoDatePickerPresentation`: `.compact` / `.graphical` / `.wheel`.

### 5.16 `BentoDropZone`

Drag-&-Drop-Zielbereich.

```swift
BentoDropZone(for: Image.self, title: Text("Bild hierher ziehen"),
              message: Text("PNG oder JPEG"), supportsMultipleItems: false,
              onTap: { pickPhoto() }) { images in true }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `for type` | `Item.Type` (`Transferable`) | `Item.self` |
| `title` | `Text` | — |
| `message` | `Text` | — |
| `systemImage` | `String` | `"square.and.arrow.down"` |
| `supportsMultipleItems` | `Bool` | `true` |
| `onTap` | `(() -> Void)?` | `nil` |
| `onDrop` | `([Item]) -> Bool` | — |

---

## 6. Datenanzeige (Data Display)

### 6.1 Avatare

**`BentoAvatarSource`** (Enum):

| Fall | Inhalt |
|------|--------|
| `.initials(String)` | Bis zu 2 Initialen |
| `.systemImage(String)` | SF Symbol |
| `.image(Image)` | SwiftUI Image (scaled to fill) |
| `.remote(URL)` | `AsyncImage` mit Spinner/Fallback |

**`BentoAvatar`**

```swift
BentoAvatar(source: .initials("Max Mustermann"), size: 48, tone: .blue)
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `source` | `BentoAvatarSource` | — | — |
| `size` | `CGFloat` | `48` | Mindestens 28 |
| `tone` | `BentoTone` | `.blue` | — |
| `accessibilityLabel` | `Text` | `Text("Avatar")` | — |

**`BentoAvatarStack`** — überlappende Avatare mit „+N"-Badge.

```swift
BentoAvatarStack(sources: [...], size: 42, maximumVisible: 4)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `sources` | `[BentoAvatarSource]` | — |
| `size` | `CGFloat` | `42` (min. 28) |
| `maximumVisible` | `Int` | `4` (min. 1) |

### 6.2 Listen-Zeilen

**`BentoListRow`**

```swift
BentoListRow(title: Text("Einstellungen"), subtitle: Text("Konto"),
             systemImage: "gearshape", tone: .neutral) {
    BentoBadge(Text("Neu"), tone: .accent)
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `systemImage` | `String?` | `nil` |
| `tone` | `BentoTone` | `.neutral` |
| `trailing` | `@ViewBuilder` | `EmptyView` |

**`BentoActionRow`** — tappbare `BentoListRow` mit Chevron.

```swift
BentoActionRow(title: Text("Profil"), systemImage: "person.crop.circle",
               tone: .blue) { goProfile() }
```

### 6.3 `BentoSparkline`

Pure-SwiftUI-Liniensparkline aus `[Double]`.

```swift
BentoSparkline(values: [3, 5, 4, 8, 7, 9], color: nil,
               lineWidth: 3, fillsArea: true)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `values` | `[Double]` | — |
| `color` | `Color?` | `nil` (→ Akzent) |
| `lineWidth` | `CGFloat` | `3` (min. 1) |
| `fillsArea` | `Bool` | `true` |

### 6.4 `BentoMetricTile`

Kennzahlen-Tile mit optionalem Sparkline-Trend.

```swift
BentoMetricTile(title: Text("Umsatz"), value: Text("€ 12,4k"),
                unit: Text("/Monat"), delta: Text("+8 %"), deltaTone: .success,
                systemImage: "eurosign.circle", tone: .green,
                trendValues: [8, 9, 11, 10, 12])
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `value` | `Text` | — |
| `unit` | `Text?` | `nil` |
| `delta` | `Text?` | `nil` |
| `deltaTone` | `BentoTone` | `.success` |
| `systemImage` | `String?` | `nil` |
| `tone` | `BentoTone` | — |
| `trendValues` | `[Double]` | `[]` |

### 6.5 `BentoStatStrip` & `BentoStatValue`

Responsive Statistik-Leiste.

```swift
BentoStatStrip(values: [
    BentoStatValue(id: "v", title: Text("Aufrufe"), value: Text("1,2 Mio."),
                   detail: Text("+12 %")),
    // …
])
```

`BentoStatValue(id:title:value:detail:)`. Passt sich horizontal an (HStack) oder fällt
auf ein adaptives Grid zurück.

### 6.6 `BentoBarChart` & `BentoBarDatum`

Vertikales Balkendiagramm (ohne Charts-Framework).

```swift
BentoBarChart(data: [
    BentoBarDatum(id: "m", label: "Mo", value: 12),
    BentoBarDatum(id: "t", label: "Di", value: 18),
], tone: .accent, height: 150)
```

`BentoBarDatum(id:label:value:valueLabel:)`. Chart: `data`, `tone` (`.accent`),
`height` (`150`, min. 80).

### 6.7 `BentoActivityRow`

Aktivitätsfeed-Zeile.

```swift
BentoActivityRow(systemImage: "checkmark.circle", title: Text("Aufgabe erledigt"),
                 detail: Text("vor 5 Min."), trailing: Text("#42"), tone: .success)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `systemImage` | `String` | — |
| `title` | `Text` | — |
| `detail` | `Text` | — |
| `trailing` | `Text?` | `nil` |
| `tone` | `BentoTone` | `.success` |

### 6.8 `BentoTimelineRow`

Vertikaler Timeline-Eintrag mit Knotenpunkt und Verbindungslinie.

```swift
BentoTimelineRow(title: Text("Bestellt"), detail: Text("Bestätigt"),
                 time: Text("09:14"), tone: .accent, isLast: false)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `detail` | `Text` | — |
| `time` | `Text?` | `nil` |
| `tone` | `BentoTone` | `.accent` |
| `isLast` | `Bool` | `false` |

### 6.9 `BentoHeroCard`

Große Hero-Karte (responsive: nebeneinander / übereinander).

```swift
BentoHeroCard(eyebrow: Text("NEU"), title: Text("Premium"),
              message: Text("Mehr Funktionen"), tone: .pink) {
    Image("hero").resizable().scaledToFit()
} actions: {
    BentoButton(Text("Probieren"), variant: .primary) { }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `eyebrow` | `Text?` | `nil` |
| `title` | `Text` | — |
| `message` | `Text?` | `nil` |
| `tone` | `BentoTone` | `.blue` |
| `visual` | `@ViewBuilder` | — |
| `actions` | `@ViewBuilder` | — |

### 6.10 `BentoMediaCard`

Medienkarte: Medienbereich oben, Titel/Subtitel/Footer unten.

```swift
BentoMediaCard(title: Text("Rezept"), subtitle: Text("30 Min."),
               mediaHeight: 190) {
    Image("food").resizable().scaledToFill()
} footer: {
    HStack { BentoBadge(Text("Vegan"), tone: .green) }
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `title` | `Text` | — | — |
| `subtitle` | `Text?` | `nil` | — |
| `mediaHeight` | `CGFloat` | `190` | Mindestens 100 |
| `media` / `footer` | `@ViewBuilder` | — | — |

### 6.11 `BentoStatusIndicator`

Status-Punkt (optional pulsierend) mit Label.

```swift
BentoStatusIndicator(Text("Live"), tone: .success, pulses: true)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `tone` | `BentoTone` | — |
| `pulses` | `Bool` | `false` |

### 6.12 `BentoKeyValueRow`

Schlüssel-/Wert-Zeile (Wert optional als Badge).

```swift
BentoKeyValueRow(key: Text("Status"), value: Text("Offen"), valueTone: .warning)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `key` | `Text` | — |
| `value` | `Text` | — |
| `valueTone` | `BentoTone?` | `nil` |

### 6.13 Charts (Charts-Framework)

**`BentoLineChart`** — interaktives Liniendiagramm.

```swift
@State private var selected: String?

BentoLineChart(data: [
    BentoLineDatum(id: "a", category: "Mo", value: 12),
    BentoLineDatum(id: "b", category: "Di", value: 18),
], tone: .accent, height: 220, fillsArea: true, smoothsLine: true,
   selection: $selected)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `data` | `[BentoLineDatum]` | — |
| `tone` | `BentoTone` | `.accent` |
| `height` | `CGFloat` | `220` (min. 120) |
| `fillsArea` | `Bool` | `true` |
| `smoothsLine` | `Bool` | `true` |
| `label` | `Text?` | `nil` |
| `selection` | `Binding<String?>?` | `nil` |
| `formatValue` | `(Double) -> Text` | Zahl |

`BentoLineDatum(id:category:value:)`.

**`BentoDonutChart`** — Donut-/Tortendiagramm.

```swift
BentoDonutChart(data: [
    BentoDonutDatum(id: "a", label: Text("iOS"), value: 60, tone: .blue),
    BentoDonutDatum(id: "b", label: Text("Android"), value: 40, tone: .green),
], centerTitle: Text("Nutzer"), centerValue: Text("100 %"),
   innerRadius: 0.62, height: 220, showsLegend: true)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `data` | `[BentoDonutDatum]` | — |
| `centerTitle` | `Text?` | `nil` |
| `centerValue` | `Text?` | `nil` |
| `innerRadius` | `Double` | `0.62` (0.2…0.86) |
| `height` | `CGFloat` | `220` (min. 130) |
| `showsLegend` | `Bool` | `true` |

`BentoDonutDatum(id:label:value:tone:)`.

### 6.14 `BentoGauge`

Kreis-Gauge.

```swift
BentoGauge(value: 64, in: 0...100, title: Text("Speicher"),
           valueLabel: Text("64 %"), tone: .accent, size: 144)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `value` | `Double` | — |
| `in range` | `ClosedRange<Double>` | — |
| `title` | `Text` | — |
| `valueLabel` | `Text` | — |
| `tone` | `BentoTone` | `.accent` |
| `size` | `CGFloat` | `144` (min. 80) |

### 6.15 `BentoCalendarHeatmap`

GitHub-Stil Kalender-Heatmap.

```swift
BentoCalendarHeatmap(data: entries, numberOfWeeks: 16, endDate: .now,
                     tone: .green, cellSize: 15)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `data` | `[BentoHeatmapDatum]` | — |
| `numberOfWeeks` | `Int` | `16` (1…53) |
| `endDate` | `Date` | `.now` |
| `calendar` | `Calendar` | `.autoupdatingCurrent` |
| `tone` | `BentoTone` | `.green` |
| `cellSize` | `CGFloat` | `15` (min. 10) |

`BentoHeatmapDatum(id:date:intensity:)`. Horizontal scrollbar; „Weniger/Mehr"-Legende.

### 6.16 `BentoDataTable` & `BentoTableColumn`

Horizontal scrollbarbare Datentabelle.

```swift
BentoDataTable(rows: users,
    columns: [
        BentoTableColumn(id: "name", title: Text("Name"), width: 160) { Text($0.name) },
        BentoTableColumn(id: "role", title: Text("Rolle")) { Text($0.role) },
    ],
    onSelect: { user in show(user) }
)
```

| `BentoDataTable` | Typ | Standard |
|------------------|-----|----------|
| `rows` | `[Row]` (`Identifiable`) | — |
| `columns` | `[BentoTableColumn<Row>]` | — |
| `onSelect` | `((Row) -> Void)?` | `nil` |

| `BentoTableColumn` | Typ | Standard |
|--------------------|-----|----------|
| `id` | `String` | — |
| `title` | `Text` | — |
| `width` | `CGFloat` | `150` (min. 72) |
| `alignment` | `Alignment` | `.leading` |
| `cell` | `(Row) -> Content` | — |

Zeilen alternieren Hintergrund; Header überlistet.

### 6.17 `BentoCommentCard`

Kommentarkarte mit Avatar, Autor, Metadaten, Text und Aktionen.

```swift
BentoCommentCard(avatar: .initials("Anna Berg"), author: Text("Anna Berg"),
                 metadata: Text("vor 2 Std."), comment: Text("Top!"),
                 tone: .pink) {
    HStack { BentoButton(Text("Like"), variant: .ghost, size: .small) { } }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `avatar` | `BentoAvatarSource` | — |
| `author` | `Text` | — |
| `metadata` | `Text?` | `nil` |
| `comment` | `Text` | — |
| `tone` | `BentoTone` | `.blue` |
| `actions` | `@ViewBuilder` | — |

---

## 7. Navigation

### 7.1 `BentoPageHeader`

Seiten-Kopf mit Eyebrow, Titel, Subtitel und Trailing-Slot.

```swift
BentoPageHeader(eyebrow: Text("Dashboard"),
                title: Text("Übersicht"),
                subtitle: Text("Deine Kennzahlen auf einen Blick")) {
    BentoIconButton(systemImage: "bell", accessibilityLabel: Text("Mitteilungen")) { }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `eyebrow` | `Text?` | `nil` |
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `trailing` | `@ViewBuilder` | `EmptyView` |

### 7.2 `BentoTabItem`

Datenmodell für einen Tab.

```swift
BentoTabItem(id: 0, title: Text("Home"), systemImage: "house", badge: nil)
BentoTabItem(id: 1, title: Text("Chat"), systemImage: "message", badge: 9)
```

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `id` | `Selection` (`Hashable`) | — | — |
| `title` | `Text` | — | — |
| `systemImage` | `String` | — | SF Symbol |
| `badge` | `Int?` | `nil` | `> 99` → „99+" |

### 7.3 `BentoTabBar`

Horizontale Capsule-Tabbar mit animierter Auswahl (matchedGeometry).

```swift
@State private var tab = 0

BentoTabBar(selection: $tab, items: [...], showsLabels: false)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `selection` | `Binding<Selection>` | — |
| `items` | `[BentoTabItem<Selection>]` | — |
| `showsLabels` | `Bool` | `false` |

### 7.4 `BentoTabScaffold`

Vollbild-Scaffold: Inhalt + angeheftete `BentoTabBar`, mit richtungsbewusstem
Seitenübergang.

```swift
@State private var tab = 0

BentoTabScaffold(selection: $tab, items: tabs, showsLabels: false) {
    // aktueller Bildschirm je nach `tab`
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `selection` | `Binding<Selection>` | — |
| `items` | `[BentoTabItem<Selection>]` | — |
| `showsLabels` | `Bool` | `false` |
| `content` | `@ViewBuilder` | — |

Vorwärts-Taps gleiten von rechts ein, Rückwärts-Taps von links.

---

## 8. Feedback & Status

### 8.1 `BentoCallout` & `BentoCalloutKind`

Hinweis-/Warnbanner mit Icon, Titel, Nachricht, optionalem Schließen.

```swift
BentoCallout(kind: .warning, title: Text("Fast Speicher voll"),
             message: Text("Bitte Dateien aufräumen.")) { dismiss() }
```

`BentoCalloutKind`: `.info` / `.success` / `.warning` / `.error`.

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `kind` | `BentoCalloutKind` | — |
| `title` | `Text` | — |
| `message` | `Text?` | `nil` |
| `onDismiss` | `(() -> Void)?` | `nil` |

### 8.2 `BentoProgressBar`

Horizontale Fortschrittsleiste (bestimmt).

```swift
BentoProgressBar(progress: 0.65, tone: .accent, height: 12, label: Text("Upload"))
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `progress` | `Double` | — (0…1, Non-Finite → 0) |
| `tone` | `BentoTone` | `.accent` |
| `height` | `CGFloat` | `12` (min. 4) |
| `label` | `Text?` | `nil` |

### 8.3 `BentoProgressRing`

Kreisrunder Fortschrittsring.

```swift
BentoProgressRing(progress: 0.7, tone: .success, size: 104, lineWidth: 12)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `progress` | `Double` | — |
| `tone` | `BentoTone` | `.accent` |
| `size` | `CGFloat` | `104` (min. 44) |
| `lineWidth` | `CGFloat` | `12` (min. 3) |
| `label` | `Text?` | `nil` (→ Auto „X%") |

### 8.4 `BentoSpinner`

Unbestimmter Lade-Spinner.

```swift
BentoSpinner(size: 28, color: nil)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `size` | `CGFloat` | `28` (min. 16) |
| `color` | `Color?` | `nil` (→ Akzent) |

### 8.5 `BentoSkeleton`

Schimmerndes Skeleton-Platzhalter.

```swift
BentoSkeleton(height: 18, radius: .small)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `height` | `CGFloat` | `18` (min. 4) |
| `radius` | `BentoRadius` | `.small` |

### 8.6 `BentoEmptyState`

Zentrierter Leerzustand mit Icon, Titel, Nachricht, optionaler Aktion.

```swift
BentoEmptyState(systemImage: "tray", title: Text("Nichts hier"),
                message: Text("Noch keine Einträge.")) {
    BentoButton(Text("Hinzufügen"), variant: .primary) { addItem() }
} actionTitle: ... 
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `systemImage` | `String` | — |
| `title` | `Text` | — |
| `message` | `Text` | — |
| `actionTitle` | `Text?` | `nil` |
| `action` | `(() -> Void)?` | `nil` |

> `action` wird nur angezeigt, wenn auch `actionTitle` gesetzt ist.

### 8.7 Toast (`bentoToast`)

Transienter Hinweis oben. Nutzt das `BentoToastData`-Modell.

```swift
@State private var toast: BentoToastData?

ContentView()
    .bentoToast($toast)

// Auslösen:
toast = BentoToastData(kind: .success, title: Text("Gespeichert"),
                       message: nil, duration: 3)
```

**`BentoToastData`**:

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `UUID` | `UUID()` |
| `kind` | `Kind` (`.info/.success/.warning/.error`) | — |
| `title` | `Text` | — |
| `message` | `Text?` | `nil` |
| `duration` | `TimeInterval?` | `3` |

Blendet automatisch nach `duration` aus (> 0).

### 8.8 Loading-Overlay (`bentoLoading`)

Überlagert Inhalt mit Spinner + Label, solange geladen wird.

```swift
ContentView()
    .bentoLoading(isLoading, label: Text("Lädt …"))
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `isLoading` | `Bool` | — |
| `label` | `Text` | `Text("Loading")` |

---

## 9. Overlays (Dialoge, Sheets, Tooltips, Snackbar)

### 9.1 `bentoDialog`

Modaler Dialog mit Aktionen.

```swift
ContentView()
    .bentoDialog(isPresented: $showDialog,
                 systemImage: "exclamationmark.triangle",
                 title: Text("Wirklich löschen?"),
                 message: Text("Dies kann nicht rückgängig gemacht werden."),
                 actions: [
                    BentoDialogAction(title: Text("Abbrechen"), role: .cancel) { },
                    BentoDialogAction(title: Text("Löschen"), variant: .destructive,
                                      role: .destructive) { delete() }
                 ],
                 dismissesOnBackgroundTap: true)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `isPresented` | `Binding<Bool>` | — |
| `systemImage` | `String?` | `nil` |
| `title` | `Text` | — |
| `message` | `Text?` | `nil` |
| `actions` | `[BentoDialogAction]` | — |
| `dismissesOnBackgroundTap` | `Bool` | `true` |

**`BentoDialogAction`**: `id` (`UUID`), `title`, `systemImage` (`nil`),
`variant` (`.secondary`), `role` (`nil`), `action`.

### 9.2 `BentoBottomSheet` & `bentoSheet`

Bottom-Sheet-Inhalt bzw. Presenter über die System-Sheet-API.

```swift
ContentView()
    .bentoSheet(isPresented: $showSheet, title: Text("Filter"),
                subtitle: Text("Verfeinern"), showsCloseButton: true,
                detents: [.medium, .large], interactiveDismissDisabled: false) {
        BentoToggleRow(Text("Nur Favoriten"), isOn: $onlyFavs)
    }
```

| Parameter (`bentoSheet`) | Typ | Standard |
|--------------------------|-----|----------|
| `isPresented` | `Binding<Bool>` | — |
| `title` | `Text?` | `nil` |
| `subtitle` | `Text?` | `nil` |
| `showsCloseButton` | `Bool` | `true` |
| `detents` | `Set<PresentationDetent>` | `[.medium, .large]` |
| `interactiveDismissDisabled` | `Bool` | `false` |
| `content` | `@ViewBuilder` | — |

`BentoBottomSheet` (direkt nutzbar): `title`, `subtitle`, `showsCloseButton`,
`content`. Bietet Drag-Handle, scrollbaren Inhalt und Schließen-Button.

### 9.3 `bentoTooltip`

Popover-Tooltip.

```swift
Text("Premium")
    .bentoTooltip(isPresented: $showTip, arrowEdge: .top) {
        Text("Schaltet alle Funktionen frei.")
    }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `isPresented` | `Binding<Bool>` | — |
| `arrowEdge` | `Edge` | `.top` |
| `content` | `@ViewBuilder` | — |

### 9.4 Snackbar (`bentoSnackbar`)

Untere Benachrichtigung mit optionalem Action-Button.

```swift
@State private var snackbar: BentoSnackbarData?

ContentView()
    .bentoSnackbar($snackbar)

snackbar = BentoSnackbarData(title: Text("Gespeichert"), tone: .success,
                             actionTitle: Text("Rückgängig"),
                             duration: 4) { undo() }
```

**`BentoSnackbarData`**:

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `UUID` | `UUID()` |
| `title` | `Text` | — |
| `message` | `Text?` | `nil` |
| `tone` | `BentoTone` | `.neutral` |
| `systemImage` | `String?` | `nil` (→ ton-abhängiges Symbol) |
| `actionTitle` | `Text?` | `nil` |
| `duration` | `TimeInterval?` | `4` |
| `action` | `(() -> Void)?` | `nil` |

---

## 10. Command Palette

### `BentoCommand`

Modell für eine auswählbare Aktion.

```swift
BentoCommand(id: "new-task", title: "Neue Aufgabe",
             subtitle: "Aufgabe erstellen", category: "Aufgaben",
             keywords: ["add", "create"], systemImage: "plus.circle",
             tone: .accent, isPinned: true) { createTask() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `Hashable` | — |
| `title` | `String` | — |
| `subtitle` | `String?` | `nil` |
| `category` | `String?` | `nil` |
| `keywords` | `[String]` | `[]` |
| `systemImage` | `String` | — |
| `tone` | `BentoTone` | `.neutral` |
| `role` | `ButtonRole?` | `nil` |
| `isEnabled` | `Bool` | `true` |
| `isPinned` | `Bool` | `false` |
| `keepsPalettePresented` | `Bool` | `false` |
| `action` | `@MainActor () -> Void` | — |

### `BentoCommandPalette`

Die Palette selbst: Header + Suchfeld + gruppierte Liste.

```swift
BentoCommandPalette(title: Text("Quick actions"),
                    subtitle: Text("Tippe zum Suchen"),
                    commands: commands,
                    automaticallyFocusesSearch: true) { isPresented = false }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | `Text("Quick actions")` |
| `subtitle` | `Text?` | `Text("Search commands, …")` |
| `commands` | `[BentoCommand]` | — |
| `searchPrompt` | `Text` | `Text("Search commands")` |
| `pinnedTitle` | `String` | `"Pinned"` |
| `resultsTitle` | `String` | `"Results"` |
| `uncategorizedTitle` | `String` | `"Actions"` |
| `automaticallyFocusesSearch` | `Bool` | `true` |
| `onDismiss` | `() -> Void` | — |

Leere Suche: Pinned → nach Kategorie gruppiert. Suche: score-gewichtet
(case-/diakritik-insensitiv über Titel/Subtitel/Kategorie/Keywords; Pinned-Bonus +8).

### `.bentoCommandPalette(...)`

Presenter als Sheet.

```swift
ContentView()
    .bentoCommandPalette(isPresented: $showPalette, commands: commands,
                         detents: [.large], interactiveDismissDisabled: false)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `isPresented` | `Binding<Bool>` | — |
| `title` / `subtitle` | `Text` / `Text?` | (wie oben) |
| `commands` | `[BentoCommand]` | — |
| `detents` | `Set<PresentationDetent>` | `[.large]` |
| `interactiveDismissDisabled` | `Bool` | `false` |

---

## 11. Sentence Forms (natürlichsprachliche Formulare)

Das Herzstück von BentoUI sind **Sentence Forms**: interaktive Formulare, die als
fließende Sätze gerendert werden. Lücken (Gaps) sind klickbare, tönbare Elemente
innerhalb des Textflusses.

### 11.1 Kern-Enums

| Enum | Werte |
|------|-------|
| `BentoSentenceGapStatus` | `.empty` / `.filled` / `.warning` / `.error` / `.loading` / `.disabled` |
| `BentoSentenceSpacingBehavior` | `.separated` / `.joinedToPrevious` / `.joinedToNext` / `.joined` |
| `BentoSentenceHorizontalAlignment` | `.leading` / `.center` / `.trailing` |
| `BentoSentenceLineAlignment` | `.center` / `.firstTextBaseline` |
| `BentoSentenceDirection` | `.automatic` / `.leftToRight` / `.rightToLeft` |

### 11.2 `BentoSentenceGapSizing`

```swift
.standard   // 64 / 320 / 2
.compact    // 56 / 240 / 1
.wide       // 120 / 420 / 3
```

Felder: `minimumWidth`, `maximumWidth?`, `lineLimit?`.

### 11.3 Komponenten (Sentenzen-Bausteine)

Alle sind `BentoSentenceComponent` und lassen sich über den `@BentoSentenceBuilder`
inline verwenden. Strings werden automatisch zu `BentoSentenceText`.

**`BentoSentenceText`** — statischer Text.

```swift
BentoSentenceText("Ich möchte jeden", spacing: .separated)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `value` | `String` | — |
| `id` | `Hashable` | — (optional) |
| `spacing` | `BentoSentenceSpacingBehavior` | `.separated` |
| `accessibilityLabel` | `Text?` | `nil` |
| `announcesForAccessibility` | `Bool` | `true` |

**`BentoSentencePunctuation(_:)`** — Satzzeichen, ans vorherige Wort angefügt.

**`BentoSentenceLineBreak`** — erzwingt einen Zeilenumbruch (`id` optional).

**`BentoSentenceGap`** — generische Lücke mit eigenem Label.

```swift
BentoSentenceGap(id: "count", tone: .blue, status: .filled, required: true,
                 accessibilityLabel: Text("Wiederholungen")) {
    Text("3x").bentoTextStyle(.bodyStrong)
} action: { pickCount() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `Hashable` | — |
| `tone` | `BentoTone` | — |
| `status` | `BentoSentenceGapStatus` | `.filled` |
| `required` | `Bool` | `false` |
| `sizing` | `BentoSentenceGapSizing` | `.standard` |
| `spacing` | `BentoSentenceSpacingBehavior` | `.separated` |
| `revision` | `AnyHashable?` | `nil` |
| `accessibilityLabel` | `Text` | — |
| `accessibilityValue` / `accessibilityHint` | `Text?` | `nil` |
| `action` | `(() -> Void)?` | `nil` |
| `label` | `@ViewBuilder` | — |

**`BentoSentenceValueGap`** — Convenience-Textwert-Lücke.

```swift
BentoSentenceValueGap(id: "time", value: "30", placeholder: "Minuten",
                      systemImage: "clock", tone: .blue, required: true) { pick() }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `Hashable` | — |
| `value` | `String?` | — |
| `placeholder` | `String` | — |
| `systemImage` | `String?` | `nil` |
| `tone` | `BentoTone` | — |
| `status` | `BentoSentenceGapStatus?` | `nil` (auto) |
| `required` | `Bool` | `false` |
| `sizing` / `spacing` | … | `.standard` / `.separated` |
| `accessibilityLabel` / `accessibilityHint` | `Text?` | `nil` |
| `action` | `(() -> Void)?` | `nil` |

**`BentoSentenceInlineTextGap`** — editierbares Inline-Textfeld in der Lücke.

```swift
@State private var name = ""

BentoSentenceInlineTextGap(id: "name", text: $name, placeholder: "Name",
    tone: .accent, maximumLength: 40, keyboardType: .default,
    accessibilityLabel: Text("Name"), onSubmit: { })
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `id` | `Hashable` | — |
| `text` | `Binding<String>` | — |
| `placeholder` | `String` | — |
| `tone` | `BentoTone` | — |
| `status` | `BentoSentenceGapStatus?` | `nil` (auto) |
| `required` | `Bool` | `false` |
| `sizing` | `BentoSentenceGapSizing` | `.compact` |
| `spacing` | `BentoSentenceSpacingBehavior` | `.separated` |
| `maximumLength` | `Int?` | `nil` |
| `keyboardType` | `UIKeyboardType` | `.default` |
| `contentType` | `UITextContentType?` | `nil` |
| `capitalization` | `TextInputAutocapitalization` | `.sentences` |
| `autocorrectionDisabled` | `Bool` | `false` |
| `submitLabel` | `SubmitLabel` | `.done` |
| `isFocused` | `Binding<Bool>?` | `nil` |
| `accessibilityLabel` | `Text` | — |
| `animatesWidth` | `Bool` | `false` |
| `onSubmit` | `() -> Void` | `{}` |

**`BentoSentenceEntityLabel`** — Label (Visual + Titel + Subtitel) für Lücken.

```swift
BentoSentenceEntityLabel(title: Text("Laufen"), subtitle: Text("Cardio"),
                         visualSize: 30) {
    Image(systemName: "figure.run").resizable().scaledToFit()
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `visualSize` | `CGFloat` | `30` (min. 22) |
| `visual` | `@ViewBuilder` | — |

### 11.4 `BentoSentenceForm`

Der Container. Nutzt einen eigenen Flow-Layout, der Wörter bricht und Lücken ausrichtet.

```swift
BentoSentenceForm(textStyle: .title2,
                  horizontalAlignment: .leading,
                  lineAlignment: .center,
                  animatesChanges: true) {
    "Ich möchte jeden"
    BentoSentenceValueGap(id: "day", value: "Tag", placeholder: "Tag",
                          tone: .blue, required: true) { }
    "mindestens"
    BentoSentenceValueGap(id: "minutes", value: "30", placeholder: "–",
                          tone: .green, required: true) { }
    "Minuten"
    BentoSentencePunctuation(".")
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `textStyle` | `BentoTextStyle` | `.title2` |
| `wordSpacing` | `CGFloat?` | `nil` (→ `xs`) |
| `lineSpacing` | `CGFloat?` | `nil` (→ `sm`) |
| `gapHorizontalPadding` | `CGFloat?` | `nil` (→ `sm`) |
| `gapVerticalPadding` | `CGFloat?` | `nil` (→ `xs`) |
| `horizontalAlignment` | `BentoSentenceHorizontalAlignment` | `.leading` |
| `lineAlignment` | `BentoSentenceLineAlignment` | `.center` |
| `direction` | `BentoSentenceDirection` | `.automatic` |
| `animatesChanges` | `Bool` | `true` |
| `accessibilityLabel` | `Text?` | `nil` |
| `content` | `@BentoSentenceBuilder` | — |

### 11.5 `BentoSentencePromptCard`

Umhüllt eine Sentence Form mit Eyebrow/Prompt in einer tonigen Karte.

```swift
BentoSentencePromptCard(eyebrow: Text("ZIEL"),
                        prompt: Text("Wie sieht dein Plan aus?"),
                        tone: .blue) {
    BentoSentenceForm { /* … */ }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `eyebrow` | `Text?` | `nil` |
| `prompt` | `Text?` | `nil` |
| `tone` | `BentoTone` | `.blue` |
| `sentence` | `@ViewBuilder` | — |
| `supporting` | `@ViewBuilder` | `EmptyView` |

### 11.6 Auswahl-Sheet für Lücken

**`BentoSentenceSelectionSheet`** — Auswahl-Listen-Sheet für eine Lücke.

```swift
@State private var activity: String?

BentoSentenceSelectionSheet(items: activities, selection: $activity,
    showsSearch: true, allowsClearing: true,
    onSelection: { _ in }) { item, isSelected in
        BentoSentenceSelectionLabel(title: Text(item.name),
                                    subtitle: Text(item.category)) {
            BentoAvatar(source: .systemImage(item.icon), size: 36)
        }
    }
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `items` | `[Item]` (`Identifiable`) | — |
| `selection` | `Binding<Item.ID?>` | — |
| `showsSearch` | `Bool` | `false` |
| `searchPrompt` | `Text` | `Text("Search")` |
| `allowsClearing` | `Bool` | `false` |
| `clearTitle` | `Text` | `Text("No selection")` |
| `dismissesOnSelection` | `Bool` | `true` |
| `filter` | `(Item, String) -> Bool` | `{ _, _ in true }` |
| `onSelection` | `(Item?) -> Void` | `{ _ in }` |
| `row` | `(Item, Bool) -> RowContent` | — |

**`BentoSentenceSelectionLabel`** — Label für Auswahlzeilen.

```swift
BentoSentenceSelectionLabel(title: Text("Laufen"), subtitle: Text("Cardio"))
```

Parameter: `title`, `subtitle: Text? = nil`, optional `leading: @ViewBuilder`.

---

## 12. Creative Components

Interaktive Spezialkomponenten für besondere Eingabe- und Anzeigeerlebnisse.

### 12.1 `BentoRadialDial`

Drehbarer, ziehbarer Radial-Dial zur Wertauswahl.

```swift
@State private var duration = 45.0

BentoRadialDial(value: $duration, in: 5...120, step: 5,
                title: Text("Minuten"), tone: .warning,
                diameter: 240, trackWidth: 18, sweepDegrees: 280)
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `value` | `Binding<Double>` | — | — |
| `in bounds` | `ClosedRange<Double>` | — | — |
| `step` | `Double` | `1` | — |
| `title` | `Text` | — | — |
| `tone` | `BentoTone` | `.accent` | — |
| `diameter` | `CGFloat` | `240` | min. 150 |
| `trackWidth` | `CGFloat` | `18` | min. 8 |
| `sweepDegrees` | `Double` | `280` | 180…340 |
| `formatValue` | `(Double) -> Text` | Zahl | — |

### 12.2 `BentoSpatialPicker`

2D-Pad, das zwei normierte Werte (0…1) in einer Geste erfasst.

```swift
@State private var value = BentoSpatialValue(x: 0.7, y: 0.65)

BentoSpatialPicker(value: $value, title: Text("Fokus · Energie"),
    xAxis: BentoSpatialAxis(title: Text("Fokus"),
                            minimumLabel: Text("Zerstreut"),
                            maximumLabel: Text("Scharf")),
    yAxis: BentoSpatialAxis(title: Text("Energie"),
                            minimumLabel: Text("Müde"),
                            maximumLabel: Text("Wach")),
    palette: .focusEnergy, height: 250)
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `value` | `Binding<BentoSpatialValue>` | — |
| `title` | `Text` | — |
| `xAxis` / `yAxis` | `BentoSpatialAxis` | — |
| `palette` | `BentoSpatialPalette` | `.focusEnergy` |
| `height` | `CGFloat` | `250` (min. 180) |
| `formatValue` | `(BentoSpatialValue) -> Text` | `x · y in %` |

**`BentoSpatialValue`**: `x: Double`, `y: Double`.
**`BentoSpatialAxis`**: `title`, `minimumLabel`, `maximumLabel`, `step` (`.05`).
**`BentoSpatialPalette`**: vier Eck-Töne; Presets `.focusEnergy`, `.priority`.

### 12.3 `BentoSlideToConfirm`

„Zum Bestätigen wischen" mit async Aktion.

```swift
BentoSlideToConfirm(Text("Wischen zum Bezahlen"),
    successTitle: Text("Bezahlt"), failureTitle: Text("Fehlgeschlagen"),
    systemImage: "creditcard.fill", tone: .accent, height: 64,
    completionThreshold: 0.9, providesHaptics: true,
    action: { try await pay() },
    onError: { err in showError(err) })
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `title` | `Text` | — | — |
| `successTitle` | `Text` | `Text("Completed")` | — |
| `failureTitle` | `Text` | `Text("Try again")` | — |
| `systemImage` | `String` | `"chevron.right.2"` | — |
| `tone` | `BentoTone` | `.accent` | — |
| `height` | `CGFloat` | `64` | min. 56 |
| `completionThreshold` | `Double` | `0.9` | 0.6…1 |
| `successDisplayDuration` | `Double` | `1` | — |
| `providesHaptics` | `Bool` | `true` | UIKit-Haptik |
| `action` | `@MainActor () async throws -> Void` | — | — |
| `onError` | `@MainActor (Error) -> Void` | `{ _ in }` | — |

### 12.4 `BentoBeforeAfterSlider`

Vergleichs-Slider „Vorher/Nachher".

```swift
@State private var pos = 0.5

BentoBeforeAfterSlider(position: $pos, height: 280) {
    Color.gray.opacity(0.3)        // Before
} after: {
    Color.blue.opacity(0.3)        // After
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `position` | `Binding<Double>` | — | 0…1 |
| `beforeLabel` / `afterLabel` | `Text?` | `Text("Before/After")` | — |
| `accessibilityLabel` | `Text` | `Text("Before and after comparison")` | — |
| `height` | `CGFloat` | `280` | min. 160 |
| `before` / `after` | `@ViewBuilder` | — | — |

### 12.5 `BentoDayTimeline`

Vertikaler Tageskalender mit Überlappungs-Layout.

```swift
BentoDayTimeline(date: .now, events: [
    BentoTimelineEvent(id: "a", start: ..., end: ..., title: Text("Meeting"),
                       subtitle: Text("Raum 3"), systemImage: "person.3", tone: .blue)
], startHour: 8, endHour: 18, hourHeight: 72, showsCurrentTime: true,
   onSelect: { ev in show(ev) })
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `date` | `Date` | — |
| `events` | `[BentoTimelineEvent]` | — |
| `calendar` | `Calendar` | `.autoupdatingCurrent` |
| `startHour` | `Int` | `7` (0…23) |
| `endHour` | `Int` | `22` |
| `hourHeight` | `CGFloat` | `72` (min. 52) |
| `showsCurrentTime` | `Bool` | `true` |
| `onSelect` | `((BentoTimelineEvent) -> Void)?` | `nil` |

**`BentoTimelineEvent`**: `id`, `start`, `end`, `title`, `subtitle?`, `systemImage?`,
`tone` (`.blue`).

### 12.6 `BentoChoiceGrid`

Auswählbares Tile-Grid (single/multiple).

```swift
@State private var selected: Set<String> = ["deep-work"]

BentoChoiceGrid(items: modes, selection: $selected,
                behavior: .multiple(maximum: 3), minimumItemWidth: 150,
                minimumItemHeight: 140, tone: { $0.tone },
                accessibilityLabel: { Text($0.title) }) { mode, isSelected in
    VStack {
        Image(systemName: mode.systemImage)
        Text(mode.title)
    }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `items` | `[Item]` (`Identifiable`) | — |
| `selection` (Set) | `Binding<Set<Item.ID>>` | — |
| `behavior` | `BentoChoiceGridBehavior` | `.multiple(maximum: nil)` |
| `minimumItemWidth` | `CGFloat` | `150` (min. 110) |
| `minimumItemHeight` | `CGFloat` | `140` (min. 80) |
| `tone` | `(Item) -> BentoTone` | — |
| `accessibilityLabel` | `(Item) -> Text` | — |
| `content` | `(Item, Bool) -> Content` | — |

Alternative Init mit `selection: Binding<Item.ID?>` und `allowsEmpty: Bool`.

**`BentoChoiceGridBehavior`**: `.single(allowsEmpty: Bool)` / `.multiple(maximum: Int?)`.

### 12.7 `BentoSwipeDeck`

Wischbarer Kartenstapel (Tinder-Stil).

```swift
@State private var cards: [Idea] = Idea.samples

BentoSwipeDeck(items: $cards, configuration: .standard,
               cardHeight: 360, maximumVisibleCards: 3,
               onDecision: { idea, decision in handle(idea, decision) }) { idea in
    BentoCard { Text(idea.title) }
}
```

| Parameter | Typ | Standard | Hinweis |
|-----------|-----|----------|---------|
| `items` | `Binding<[Item]>` | — | Top wird entfernt |
| `configuration` | `BentoSwipeDeckConfiguration` | `.standard` | — |
| `cardHeight` | `CGFloat` | `360` | min. 220 |
| `maximumVisibleCards` | `Int` | `3` | 1…5 |
| `onDecision` | `(Item, BentoSwipeDecision) -> Void` | `{ _, _ in }` | — |
| `card` | `(Item) -> Card` | — | — |

**`BentoSwipeDecision`**: `.left` / `.right` / `.up`.

**`BentoSwipeDeckConfiguration`**:

```swift
BentoSwipeDeckConfiguration(
    left: BentoSwipeDeckAction(title: Text("Skip"), systemImage: "xmark", tone: .danger),
    right: BentoSwipeDeckAction(title: Text("Keep"), systemImage: "checkmark", tone: .success),
    up: BentoSwipeDeckAction(title: Text("Later"), systemImage: "clock.fill", tone: .warning),
    threshold: 100)        // min. 54
```

Preset: `.standard`. `BentoSwipeDeckAction(title:systemImage:tone:)`.

---

## 13. Templates (Bildschirm-Vorlagen)

Fertige, zusammengesetzte Bildschirm-Templates, die mehrere Komponenten verbinden.

### 13.1 Ladbarer Container

`BentoLoadableState<Value>`: `.idle` / `.loading` / `.loaded(Value)` / `.empty` /
`.failed(BentoErrorDescriptor)`. `BentoErrorDescriptor(title:message:systemImage:)`.

```swift
BentoLoadableContainer(state: state, retry: { reload() }) { value in
    BentoCard { Text(value.name) }
}
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `state` | `BentoLoadableState<Value>` | — |
| `emptyTitle` | `Text` | `Text("Nothing here yet")` |
| `emptyMessage` | `Text` | `Text("Content will appear…")` |
| `emptySystemImage` | `String` | `"tray.fill"` |
| `retry` | `(() -> Void)?` | `nil` |
| `content` | `(Value) -> LoadedContent` | — |

### 13.2 `BentoDashboardTemplate`

```swift
BentoDashboardTemplate {
    BentoPageHeader(title: Text("Dashboard")) { EmptyView() }
} hero: {
    BentoMetricTile(title: Text("Umsatz"), value: Text("€ 12,4k"), tone: .green)
} metrics: {
    BentoStatStrip(values: [...])
} content: {
    BentoBarChart(data: [...])
}
```

Slots: `header`, `hero`, `metrics`, `content`.

### 13.3 `BentoCollectionTemplate`

Durchsuchbare Sammlung mit Filtern.

```swift
BentoCollectionTemplate(title: Text("Rezepte"), searchText: $query, isEmpty: false,
    headerAction: { BentoButton(Text("Filter"), variant: .secondary) { } },
    filters: { BentoChip(Text("Vegan")) { } },
    content: { BentoAdaptiveGrid { ForEach(recipes) { RecipeCard($0) } } },
    empty: { BentoEmptyState(systemImage: "tray", title: Text("Leer"), message: Text("…")) })
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `searchText` | `Binding<String>` | — |
| `searchPrompt` | `Text` | `Text("Search")` |
| `isEmpty` | `Bool` | — |
| `headerAction` / `filters` / `content` / `empty` | `@ViewBuilder` | — |

### 13.4 `BentoDetailTemplate`

Detailseite mit optionaler Action-Bar.

```swift
BentoDetailTemplate(eyebrow: Text("PRODUKT"), title: Text("Kaffeemaschine"),
    subtitle: Text("Espresso"), showsActionBar: true,
    hero: { Image("machine").resizable().scaledToFit() },
    metadata: { BentoKeyValueRow(key: Text("Preis"), value: Text("€ 299")) },
    content: { Text("Beschreibung …") },
    actions: { BentoButton(Text("In den Warenkorb"), variant: .primary, expands: true) { } })
```

| Parameter | Typ | Standard |
|-----------|-----|----------|
| `eyebrow` | `Text?` | `nil` |
| `title` | `Text` | — |
| `subtitle` | `Text?` | `nil` |
| `showsActionBar` | `Bool` | `true` |
| `hero` / `metadata` / `content` / `actions` | `@ViewBuilder` | — |

### 13.5 `BentoFormPageTemplate`

Formularseite mit Action-Bar.

```swift
BentoFormPageTemplate(title: Text("Profil bearbeiten")) {
    BentoTextField(label: Text("Name"), text: $name)
    BentoToggleRow(Text("Newsletter"), isOn: $news)
} actions: {
    BentoButton(Text("Speichern"), variant: .primary, expands: true) { save() }
}
```

Slots: `title`, `subtitle?`, `content`, `actions`.

### 13.6 `BentoAuthTemplate`

Authentifizierungs-/Login-Bildschirm.

```swift
BentoAuthTemplate(title: Text("Willkommen zurück"), message: Text("Einloggen")) {
    Image("logo").resizable().scaledToFit().frame(height: 64)
} form: {
    BentoTextField(label: Text("E-Mail"), text: $email, isSecure: false)
    BentoButton(Text("Einloggen"), variant: .primary, expands: true) { login() }
} footer: {
    Text("Kein Konto? Registrieren")
}
```

Slots: `title`, `message?`, `brand`, `form`, `footer`.

### 13.7 `BentoSettingsTemplate` & `BentoSettingsGroup`

```swift
BentoSettingsTemplate {
    BentoCard { /* Profil */ }
} sections: {
    BentoSettingsGroup(title: Text("Allgemein")) {
        BentoActionRow(title: Text("Sprache")) { }
    }
}
```

`BentoSettingsGroup(title:subtitle:content:)`. Template-Slots: `title`, `profile`,
`sections`.

### 13.8 `BentoSplitNavigationTemplate`

Split-View-Navigation.

```swift
BentoSplitNavigationTemplate(columnVisibility: $visibility) {
    SidebarView()
} detail: {
    DetailView()
}
```

### 13.9 `BentoOnboardingTemplate` & `BentoOnboardingPage`

Gepagtes Onboarding.

```swift
@State private var page = 0

BentoOnboardingTemplate(
    pages: [
        BentoOnboardingPage(id: "1", eyebrow: Text("WILLKOMMEN"),
            title: Text("Plane deinen Tag"), message: Text("…"),
            systemImage: "calendar", tone: .blue),
        // …
    ],
    selection: $page,
    nextTitle: Text("Weiter"), finishTitle: Text("Loslegen"),
    skipTitle: Text("Überspringen"), onSkip: { finish() },
    onFinish: { finish() })
```

`BentoOnboardingPage(id:eyebrow?:title:message:systemImage:tone:)`.

### 13.10 `BentoWizardTemplate` & `BentoWizardStep`

Mehrschritt-Wizard.

```swift
@State private var step = 0

BentoWizardTemplate(steps: [
    BentoWizardStep(id: "1", title: Text("Konto"), subtitle: Text("Step 1")),
    BentoWizardStep(id: "2", title: Text("Profil")),
], currentStep: $step, canAdvance: { _ in true }, onFinish: { finish() }) { step in
    Text(step.title as? String ?? "")
}
```

`BentoWizardStep(id:title:subtitle:)`. Zeigt „Schritt N von M", Fortschrittsbalken,
Zurück/Weiter|Abschließen.

### 13.11 `BentoProfileTemplate`

Profilbildschirm.

```swift
BentoProfileTemplate(avatar: .initials("Max"), name: Text("Max Mustermann"),
    subtitle: Text("@max"), biography: Text("iOS Dev"), tone: .pink,
    stats: { BentoStatStrip(values: [...]) },
    content: { /* weitere Inhalte */ },
    actions: { BentoButton(Text("Folgen"), variant: .primary) { } })
```

Slots: `avatar`, `name`, `subtitle?`, `biography?`, `tone`, `stats`, `content`,
`actions`.

### 13.12 `BentoPaywallTemplate`

Abo-/Paywall-Bildschirm.

```swift
@State private var planID: String? = "yearly"

BentoPaywallTemplate(title: Text("Premium"), message: Text("Alle Funktionen"),
    plans: [
        BentoPaywallPlan(id: "monthly", title: Text("Monatlich"), price: Text("€ 9,99")),
        BentoPaywallPlan(id: "yearly", title: Text("Jährlich"), price: Text("€ 79"),
                         badge: Text("−33 %"), tone: .green)
    ],
    features: [
        BentoPaywallFeature(id: "f1", title: Text("Unbegrenzt"))
    ],
    selectedPlanID: $planID,
    purchase: { plan in try await purchase(plan) },
    restore: { try await restore() },
    onError: { err in showError(err) })
```

Modelle: `BentoPaywallPlan(id:title:subtitle?:price:badge?:tone:)`,
`BentoPaywallFeature(id:title:systemImage:tone:)`.

---

## 14. Beispiele für gute UIs

Die folgenden, vollständig funktionsfähigen Beispiele zeigen, wie sich die Komponenten
zu durchdachten, schönen Oberflächen kombinieren lassen.

### 14.1 Fitness-Dashboard (Bento Box)

```swift
import SwiftUI
import BentoUI

struct FitnessDashboard: View {
    @State private var steps = 8_421
    @State private var goal = 10_000

    var body: some View {
        BentoScreen {
            BentoPageHeader(eyebrow: Text("HEUTE"),
                            title: Text("Übersicht"),
                            subtitle: Text("Donnerstag, 8. Mai")) {
                BentoIconButton(systemImage: "calendar",
                                accessibilityLabel: Text("Kalender")) { }
            }

            // Kennzahlen-Bento
            BentoAdaptiveGrid(minimumItemWidth: 160) {
                BentoMetricTile(title: Text("Schritte"), value: Text("\(steps)"),
                                unit: Text("/ \(goal)"), delta: Text("84 %"),
                                deltaTone: .warning, systemImage: "figure.walk",
                                tone: .green, trendValues: [4, 5, 6, 7, 8])
                BentoMetricTile(title: Text("Kalorien"), value: Text("412"),
                                unit: Text("kcal"), delta: Text("+12 %"),
                                deltaTone: .success, systemImage: "flame.fill",
                                tone: .pink, trendValues: [3, 4, 4, 5, 6])
                BentoMetricTile(title: Text("Schlaf"), value: Text("7,4"),
                                unit: Text("Std."), systemImage: "moon.zzz.fill",
                                tone: .blue, trendValues: [6, 7, 7, 8, 7])
            }

            // Fortschritt
            BentoCard(tone: .blue) {
                VStack(alignment: .leading, spacing: 12) {
                    BentoSectionHeader(title: Text("Tagesziel")) {
                        BentoBadge(Text("84 %"), tone: .warning)
                    }
                    BentoProgressBar(progress: 0.84, tone: .warning, height: 14)
                }
            }

            // Wochen-Chart
            BentoCard {
                VStack(alignment: .leading, spacing: 12) {
                    BentoSectionHeader(title: Text("Diese Woche"))
                    BentoBarChart(data: [
                        BentoBarDatum(id: "m", label: "Mo", value: 9),
                        BentoBarDatum(id: "t", label: "Di", value: 11),
                        BentoBarDatum(id: "w", label: "Mi", value: 8),
                        BentoBarDatum(id: "t2", label: "Do", value: 12),
                        BentoBarDatum(id: "f", label: "Fr", value: 7),
                    ], tone: .accent, height: 150)
                }
            }
        }
    }
}
```

### 14.2 Natürlichsprachliches Ziel-Formular

```swift
struct GoalSentenceForm: View {
    @State private var day = "Tag"
    @State private var minutes = "30"
    @State private var activity: String?

    var body: some View {
        BentoScreen(scrolls: false) {
            BentoPageHeader(eyebrow: Text("ZIEL"),
                            title: Text("Neues Ziel")) { EmptyView() }

            BentoSentencePromptCard(eyebrow: Text("PLAN"),
                                    prompt: Text("Definiere deine Routine"),
                                    tone: .blue) {
                BentoSentenceForm {
                    "Ich möchte jeden"
                    BentoSentenceValueGap(id: "day", value: day,
                                          placeholder: "Tag", tone: .blue,
                                          required: true) { pickDay() }
                    "für"
                    BentoSentenceInlineTextGap(id: "minutes", text: $minutes,
                        placeholder: "30", tone: .green,
                        keyboardType: .numberPad,
                        accessibilityLabel: Text("Minuten")) { }
                    "Minuten"
                    BentoSentenceGap(id: "activity", tone: .pink,
                                     accessibilityLabel: Text("Aktivität")) {
                        BentoSentenceEntityLabel(title: Text("Laufen"),
                                                 subtitle: Text("Cardio")) {
                            Image(systemName: "figure.run")
                                .resizable().scaledToFit()
                        }
                    } action: { pickActivity() }
                    BentoSentencePunctuation("machen.")
                }
            }

            Spacer()
            BentoButton(Text("Ziel speichern"), systemImage: "checkmark.circle.fill",
                        variant: .primary, expands: true) { save() }
        }
        .bentoActionBar {
            BentoButton(Text("Speichern"), variant: .primary, expands: true) { save() }
        }
    }
}
```

### 14.3 Tab-Navigation mit Scaffold

```swift
struct MainApp: View {
    enum Tab: Hashable { case home, search, profile }
    @State private var tab: Tab = .home

    var body: some View {
        BentoTabScaffold(selection: $tab, items: [
            BentoTabItem(id: Tab.home, title: Text("Home"), systemImage: "house"),
            BentoTabItem(id: Tab.search, title: Text("Suche"), systemImage: "magnifyingglass"),
            BentoTabItem(id: Tab.profile, title: Text("Profil"),
                         systemImage: "person.crop.circle", badge: 3),
        ]) {
            switch tab {
            case .home:   HomeScreen()
            case .search: SearchScreen()
            case .profile: ProfileScreen()
            }
        }
    }
}
```

### 14.4 Aufladbare Sammlung mit leerem Zustand

```swift
struct RecipeCollection: View {
    @State private var query = ""
    @State private var state: BentoLoadableState<[Recipe]> = .idle

    var body: some View {
        BentoCollectionTemplate(title: Text("Rezepte"), searchText: $query,
            isEmpty: false,
            headerAction: { BentoIconButton(systemImage: "slider.horizontal.3",
                                            accessibilityLabel: Text("Filter")) { } },
            filters: {
                BentoSelectionChips(options: ["Alle","Vegan","Süß"],
                    selection: .constant([]), label: { Text($0) })
            },
            content: {
                BentoLoadableContainer(state: state, retry: { load() }) { recipes in
                    BentoMasonryGrid(items: recipes, columns: 2) { recipe in
                        BentoMediaCard(title: Text(recipe.title),
                                       subtitle: Text(recipe.time)) {
                            recipe.image.resizable().scaledToFill()
                        } footer: {
                            BentoBadge(Text(recipe.category), tone: .green)
                        }
                    }
                }
            },
            empty: {
                BentoEmptyState(systemImage: "fork.knife",
                                title: Text("Keine Rezepte"),
                                message: Text("Passe deine Suche an.")) { }
            })
        .onAppear { load() }
    }
}
```

### 14.5 Dialog + Snackbar Feedback

```swift
struct DeleteDemo: View {
    @State private var showDialog = false
    @State private var snackbar: BentoSnackbarData?

    var body: some View {
        BentoScreen {
            BentoButton(Text("Eintrag löschen"), systemImage: "trash",
                        variant: .destructive, expands: true) { showDialog = true }
        }
        .bentoDialog(isPresented: $showDialog,
                     systemImage: "exclamationmark.triangle.fill",
                     title: Text("Wirklich löschen?"),
                     message: Text("Der Eintrag wird unwiderruflich entfernt."),
                     actions: [
                        BentoDialogAction(title: Text("Abbrechen"), role: .cancel) { },
                        BentoDialogAction(title: Text("Löschen"),
                                          variant: .destructive, role: .destructive) {
                            delete()
                            snackbar = BentoSnackbarData(
                                title: Text("Gelöscht"), tone: .success,
                                actionTitle: Text("Rückgängig")) { undo() }
                        }
                     ])
        .bentoSnackbar($snackbar)
    }
}
```

### 14.6 Einstellungen

```swift
struct SettingsScreen: View {
    @State private var notifications = true
    @State private var haptics = true
    @State private var theme: BentoTone = .accent

    var body: some View {
        BentoSettingsTemplate {
            BentoProfileTemplate(avatar: .initials("Max Mustermann"),
                                 name: Text("Max Mustermann"),
                                 subtitle: Text("@max"), tone: .blue,
                                 stats: { BentoStatStrip(values: [
                                    BentoStatValue(id: "p", title: Text("Posts"),
                                                   value: Text("128"))
                                 ]) }, content: { EmptyView() },
                                 actions: { EmptyView() })
        } sections: {
            BentoSettingsGroup(title: Text("Allgemein")) {
                BentoToggleRow(Text("Benachrichtigungen"),
                               subtitle: Text("Push-Mitteilungen"),
                               systemImage: "bell", isOn: $notifications)
                BentoDivider()
                BentoToggleRow(Text("Haptik"), systemImage: "hand.tap", isOn: $haptics)
            }
            BentoSettingsGroup(title: Text("Darstellung"), subtitle: Text("Personalisierung")) {
                BentoActionRow(title: Text("Akzentfarbe"), systemImage: "paintpalette") { }
                BentoDivider()
                BentoTonePicker(selection: $theme, tones: [.accent, .pink, .blue, .green])
            }
        }
    }
}
```

### 14.7 Onboarding-Flow

```swift
struct OnboardingFlow: View {
    @State private var page = 0

    var body: some View {
        BentoOnboardingTemplate(
            pages: [
                BentoOnboardingPage(id: "1", eyebrow: Text("WILLKOMMEN"),
                    title: Text("Behalte den Überblick"),
                    message: Text("Plane deinen Tag in natürlichen Sätzen."),
                    systemImage: "list.clipboard", tone: .blue),
                BentoOnboardingPage(id: "2", eyebrow: Text("ZIELE"),
                    title: Text("Setze klare Ziele"),
                    message: Text("Definiere, was du erreichen willst."),
                    systemImage: "target", tone: .green),
                BentoOnboardingPage(id: "3", eyebrow: Text("STATISTIKEN"),
                    title: Text("Verfolge Fortschritt"),
                    message: Text("Sieh deine Entwicklung auf einen Blick."),
                    systemImage: "chart.bar.fill", tone: .pink),
            ],
            selection: $page,
            onSkip: { finish() },
            onFinish: { finish() })
    }
}
```

---

## Anhang: Schnellreferenz der Komponenten

| Kategorie | Komponenten |
|-----------|-------------|
| **Foundation** | `BentoTheme`, `BentoThemeFamily`, `BentoThemeHost`, `BentoColors`, `BentoTypography`, `BentoSpacing`, `BentoRadii`, `BentoBorders`, `BentoSizing`, `BentoMotion`, `BentoText`, `BentoTone`, `BentoSpace`, `BentoRadius`, `BentoTextStyle` |
| **Layout** | `BentoScreen`, `BentoCard`, `BentoTile`, `BentoSection`, `BentoSectionHeader`, `BentoDivider`, `BentoAdaptiveGrid`, `BentoFlowLayout`, `BentoResponsiveStack`, `BentoMasonryLayout`, `BentoMasonryGrid`, `BentoCarousel`, `BentoStickySection`, `BentoSplitCard`, `BentoOverlayTile`, `BentoActionBar` |
| **Controls** | `BentoButton`, `BentoIconButton`, `BentoFloatingActionButton`, `BentoBadge`, `BentoChip`, `BentoAsyncButton`, `BentoDisclosureCard`, `BentoRatingPicker`, `BentoPageIndicator`, `BentoTonePicker`, `BentoSelectionChips`, `BentoExpandableText`, `BentoCopyField` |
| **Inputs** | `BentoTextField`, `BentoTextArea`, `BentoSearchField`, `BentoToggleRow`, `BentoCheckbox`, `BentoRadioGroup`, `BentoSegmentedPicker`, `BentoStepper`, `BentoSlider`, `BentoMenuPicker`, `BentoOTPField`, `BentoTagInput`, `BentoRangeSlider`, `BentoDatePickerField`, `BentoDropZone` |
| **Data Display** | `BentoAvatar`, `BentoAvatarStack`, `BentoListRow`, `BentoActionRow`, `BentoSparkline`, `BentoMetricTile`, `BentoStatStrip`, `BentoBarChart`, `BentoActivityRow`, `BentoTimelineRow`, `BentoHeroCard`, `BentoMediaCard`, `BentoStatusIndicator`, `BentoKeyValueRow`, `BentoLineChart`, `BentoDonutChart`, `BentoGauge`, `BentoCalendarHeatmap`, `BentoDataTable`, `BentoCommentCard` |
| **Navigation** | `BentoPageHeader`, `BentoTabItem`, `BentoTabBar`, `BentoTabScaffold` |
| **Feedback** | `BentoCallout`, `BentoProgressBar`, `BentoProgressRing`, `BentoSpinner`, `BentoSkeleton`, `BentoEmptyState`, `bentoToast`, `bentoLoading` |
| **Overlays** | `bentoDialog`, `BentoBottomSheet`, `bentoSheet`, `bentoTooltip`, `bentoSnackbar` |
| **Command** | `BentoCommand`, `BentoCommandPalette`, `bentoCommandPalette` |
| **Sentence Forms** | `BentoSentenceForm`, `BentoSentencePromptCard`, `BentoSentenceText`, `BentoSentencePunctuation`, `BentoSentenceLineBreak`, `BentoSentenceGap`, `BentoSentenceValueGap`, `BentoSentenceInlineTextGap`, `BentoSentenceEntityLabel`, `BentoSentenceSelectionSheet`, `BentoSentenceSelectionLabel` |
| **Creative** | `BentoRadialDial`, `BentoSpatialPicker`, `BentoSlideToConfirm`, `BentoBeforeAfterSlider`, `BentoDayTimeline`, `BentoChoiceGrid`, `BentoSwipeDeck` |
| **Templates** | `BentoLoadableContainer`, `BentoDashboardTemplate`, `BentoCollectionTemplate`, `BentoDetailTemplate`, `BentoFormPageTemplate`, `BentoAuthTemplate`, `BentoSettingsTemplate`, `BentoSplitNavigationTemplate`, `BentoOnboardingTemplate`, `BentoWizardTemplate`, `BentoProfileTemplate`, `BentoPaywallTemplate` |
