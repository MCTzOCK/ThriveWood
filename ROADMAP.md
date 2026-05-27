# ROADMAP.md — ThriveWood Feature Roadmap (Community Edition)

## So funktioniert diese Roadmap

Diese Roadmap ist eine **Ideensammlung** — keine verbindliche Planung. Wenn du einen Vorschlag umsetzen möchtest, erstelle ein Issue und verlinke auf diese Zeile.

### Legende
- 🟢 **Kurzer Aufwand** (Stunden–Tage)
- 🟡 **Mittlerer Aufwand** (Tage–Wochen)
- 🔴 **Großer Aufwand** (Wochen–Monate)
- 🧱 **Fundament** — bestehender Code liegt bereit, muss nur aktiviert/vervollständigt werden
- 🆕 **Neuland** — vollständig neue Implementierung nötig

---

## 1. Ernährungstagebuch aktivieren 🟡🧱

**Status:** Der gesamte Backend-Code (`NutritionService`, `FoodDiaryView`, `FoodSearchView`, `BarcodeScannerView`, `MealTemplateEditorView`, `NutritionGoalEditor`) ist **fertig geschrieben**, aber in `NutritionTab.swift` durch ein `ContentUnavailableView` („In Kürze verfügbar“) blockiert.

**Zu tun:**
- `FoodDiaryView` im `NutritionTab` entkommentieren und testen
- `FoodSearchView` (lokal + OpenFoodFacts online) einbinden
- `BarcodeScannerView` funktional prüfen
- `MealTemplateEditorView` / Templatesheet verlinken
- `NutritionGoalEditor` aus Settings/Ernährung erreichbar machen
- Ggf. SwiftData-Migration für `Food`-Modell prüfen (Backup DTO v2)

---

## 2. Social & Challenges 🟡🆕

Es gibt keinerlei soziale oder Challenge-Features.

**Ideen:**
- **30-Tage-Challenges** — z. B. „30 Tage 2L Wasser“, „30 Tage tägliches Training“, mit vordefinierten Templates und Fortschrittsanzeige
- **Freundesliste** — andere ThriveWood-Nutzer:innen hinzufügen, gegenseitig Fortschritt sehen (opt-in)
- **Wettbewerbe** — z. B. „Wer sammelt diese Woche die meisten Punkte?“
- **Share-Modul** — Forest-Screenshot, PR-Karte, Wochenstatistik als Bild teilen (Instagram Story Format)

---

## 3. Apple Watch Companion 🔴🆕

**Motivation:** Stage-2-Workout-Tracking direkt am Handgelenk, ohne iPhone.

**Umfang:**
- `watchOS` Target (SwiftUI)
- `RestTimer` als Komplikation
- `ActiveSessionView`-ähnliches Live-Workout mit Haptik-Feedback pro Satz
- `HealthKit`-Workout-Sessions direkt von der Watch schreiben
- `WidgetKit`-Komplikationen für Habits, Forest, Punkte
- Kommunikation über `WatchConnectivity` oder geteilte SwiftData-Container

---

## 4. HealthKit ↔ Messbare Habits synchronisieren 🟢🆕

Derzeit zeigt die Analyse nur HealthKit-Schritte **neben** den Habits an, aber Habits werden nie automatisch aus HealthKit befüllt.

**Idee:**
- Neuer `healthKitSourced: Bool`-Flag an `Habit`
- `HealthKitService` ruft periodisch Schritte/Energie/Distanz ab und schreibt sie in messbare Habits
- Ermöglicht: „Schritte“-Habit, das sich **automatisch** füllt — kein manuelles Tracken mehr

---

## 5. Trainingsplan-Verbesserungen 🟡🆕

**Aktueller Stand:** `TrainingsPlanService` existiert mit PPL- und Upper/Lower-Templates, aber die Pläne sind statisch.

**Ideen:**
- **Progressive Overload** — Automatische Gewichtssteigerung basierend auf PR-Logik. Nach X erfolgreichen Sätzen schlägt die App vor: „Nächste Woche +2.5kg“
- **Deload-Erinnerung** — Nach 4–6 Wochen ohne Deload-Woche Push-Nachricht
- **Periodisierungs-Makrozyklen** — Hypertrophie → Strength → Peak als aufeinanderfolgende Blöcke
- **Trainingsplan-Teilen** — Export/Import von Plänen als JSON (baut auf existierendem Backup-System auf)

---

## 6. Körpermaße & Fortschrittsfotos 🟡🆕

Kein Tracking von Körpergewicht, Körperfett, Umfängen oder Progress-Fotos.

**Idee:**
- Neues `BodyMeasurement` SwiftData-Modell (`weight`, `bodyFat`, `chest`, `waist`, `hip`, `arm`, `thigh` etc.)
- Neue `ProgressPhoto` Entität mit Datum, optionaler Notiz, Kategorie (Front/Back/Side)
- Chart-Visualisierung im Analytics-Tab
- Side-by-Side-Fotovergleich

---

## 7. Forest-Gamification erweitern 🟢🆕

Aktuell: Bäume pflanzen + gießen; 8×8-Grid; `ForestService` ist solide.

**Ideen:**
- **Täglicher Forest-Streak-Bonus** — z. B. jeden Tag 1 Gratis-Wasser bei 7-Tage-Streak
- **Saisonale/Besondere Bäume** — limitierte Spezies zu bestimmten Jahreszeiten oder Events
- **Forest-Wetter** — visuelle Wettereffekte basierend auf tatsächlichem Wetter oder Punktestand (Sonnenschein bei guter Woche, Regen bei schwacher)
- **Forest-Besucher** — Tiere erscheinen bei bestimmten Meilensteinen (Vogel bei 10 Bäumen, Reh bei 50, etc.)
- **Achievement-System** — Badges für Meilensteine („Erster Baum“, „100 Tage Streak“, „Wald voll“)

---

## 8. Erweitertes Achievement/Badge-System 🟡🆕

Derzeit kein Achievement-System. Ergänzt die Forest-Gamification.

**Badge-Kategorien:**
- **Habits:** 7-Tage-Streak, 30-Tage-Streak, 100-Tage-Streak, 365-Tage-Streak, Alle Habits an einem Tag
- **Workouts:** 10/50/100 Workouts, 1000/5000/10000 Sätze, Erster PR, 10 PRs
- **Forest:** 5/10/20/40/64 Bäume, Erster uralter Baum, Alle Spezies freigeschaltet
- **Ernährung:** 7-Tage-Streak getrackt, Alle Mahlzeiten an einem Tag geloggt

---

## 9. Übungsdatenbank anreichern 🟢🧱

`Exercise.images` und `Exercise.instructions` sind als Arrays am Modell vorhanden, werden aber nirgends prominent genutzt.

**Idee:**
- `ExerciseDetailsSheet` um Bild-Galerie und Schritt-für-Schritt-Anleitungen erweitern
- Animationen/GIFs für Übungsausführung (lokal gebundelt oder remote)
- Tipps zur Form („Häufige Fehler“)
- YouTube-Integration für Übungsvideos

---

## 10. Recovery & Readiness 🟡🆕

Keine Erholungsmetriken. Keine Belastungsanalyse.

**Idee:**
- **Muscle Recovery Timer** — Basierend auf letztem Training einer Muskelgruppe: „Bizeps: bereit“ / „Brust: 24h Pause empfohlen“
- **Weekly Strain Score** — 0–100 basierend auf Volumen, Frequenz, Intensität
- **Ruhetag-Empfehlung** — Wenn Strain > Schwelle, schlägt App Ruhetag vor
- `HKWorkoutEffortScore` aus HealthKit lesen (iOS 18+)

---

## 11. Widgets ausbauen 🟡🆕

Derzeit 4 Widget-Typen vorhanden.

**Ideen:**
- **Lock Screen Widgets** — Punkte-Stand, heutiges Top-Habit, nächster Trainingsplan-Tag
- **Control Center Widget** — Schnellzugriff: „Workout starten“
- **Interactive Widgets** — Habit direkt aus Widget abhaken (iOS 18 App Intents)
- **Stack-Widget** — Rotierend: Habits → Forest → Workout → Punkte

---

## 12. KI-Features ausbauen 🟡🆕

`AIService` existiert für Supplement-Analyse (Apple Intelligence, iOS 26+).

**Ideen:**
- **Workout-Empfehlung** — Basierend auf Muscle Rankings: „Deine Waden sind untrainiert — wie wär's mit Wadenheben?“
- **Ernährungs-Feedback** — Basierend auf geloggten Mahlzeiten + Trainingsziel
- **Habit-Vorschläge** — Basierend auf ungenutzten Morgen-/Abend-Slots
- **Trainingsplan-Generator** — „Erstelle mir einen 4-Tage-Upper/Lower-Plan mit Fokus auf Brust“

---

## 13. Lokalisierung & Internationalisierung 🔴🆕

Derzeit ist die gesamte UI fest auf Deutsch.

**Umfang:**
- `LocalizedStringKey` aus allen UI-Strings extrahieren
- `String(localized:)` verwenden
- `en.lproj` erstellen
- Pro-Feature: Nutzer:in wählt Sprache unabhängig von Systemsprache

---

## 14. Datenschutz & Account-System 🟡🆕

Derzeit kein Login — alles lokal + iCloud Sync.

**Optionen:**
- **Anonymes Konto via Sign in with Apple** — Optional, für geräteübergreifende Sync-Garantie
- **Export-Verschlüsselung** — Backup mit optionalem Passwort
- **Daten-Dashboard** — „Welche Daten speichert ThriveWood über mich?“

---

## 15. Weitere Kleinigkeiten 🟢🆕

| Idee | Beschreibung |
|---|---|
| **Freier Modus Workout** | Workout ohne Template starten, Übungen spontan hinzufügen |
| **Warmup-Sätze zusammenfassen** | In Session-Detail-View Warmup-Sätze separat gruppieren oder ausblenden |
| **Timer pro Satz** | Nicht nur Rest-Timer zwischen Sätzen, sondern auch Countdown-Timer für die Übungsausführung (z. B. Planks) |
| **RPE-Visualisierung** | RPE-Wert in PR-Chart als Farbe oder Annotation anzeigen |
| **Workout-Notizen** | Freitext-Notizfeld pro Session (z. B. „Heute wenig Energie“) |
| **Habit-Notizen anzeigen** | `HabitCompletion.note` existiert, wird aber nirgends im UI angezeigt |
| **Mehr TreeSpecies** | Z. B. Palme, Bambus, Magnolie — weitere unlockbare Bäume |
| **Forest-Tageszeit-Visualisierung** | Forest-Hintergrund ändert sich je nach Tageszeit (Morgen/Abend/Nacht) |
| **Dark Mode Forest** | Spezielles Night-Forest-Theme |
| **Workout-Musik-Integration** | Apple Music/Spotify-Playlist-Vorschlag basierend auf Trainingsart |

---

## 16. Technische Schuld & Maintenance 🟢🆕

| Thema | Details |
|---|---|
| **Alte V1-MuscleMapView löschen** | `MuscleMapView.swift` existiert noch, wird nicht mehr referenziert (siehe HANDOFF.md) |
| **ExerciseBlock Equatable** | Weitere Performance-Optimierung für `ActiveSessionView` |
| **FlexibleNumberField Tausendertrennzeichen** | Deutsche Gruppierungsseparatoren („1.000“) werden noch nicht unterstützt |
| **Swift Testing Migration** | Von XCTest zu Swift Testing migrieren (Swift 6) |
| **Snapshot-Tests** | Visuelle Regression-Tests für kritische Views (Forest, MuscleMap, PR-Chart) |

---

## Priorisierungsvorschlag (Quick Wins zuerst)

1. **Ernährungstagebuch aktivieren** 🧱 — Code ist fertig, sofortiger Mehrwert
2. **HealthKit ↔ Habits sync** — Kleines Feature, großer Komfortgewinn
3. **Forest-Gamification (Streak-Bonus, Tiere, Wetter)** — Erweitert Kern-USP der App
4. **Achievement-System** — Querschnitts-Feature, motiviert in allen Bereichen
5. **Übungsdatenbank anreichern** — Daten existieren, nur UI fehlt

---

> **Letzte Aktualisierung:** 2026-05-27