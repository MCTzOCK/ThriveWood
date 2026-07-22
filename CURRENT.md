# ThriveWood – Aktueller Feature-Stand

> **Letzte Aktualisierung:** 22.07.2026  
> **Basis:** Code-Analyse aller Swift-Dateien in `ThriveWood/`, `ThriveWoodWidgets/` und `GymPlanBuilder/`  
> **ModelContainer:** SwiftData mit CloudKit-Sync (app group `group.com.bensiebert.thrivewood`)

---

## 1. Architektur & Datenmodell

### 1.1 Datenbank-Schema (SwiftData + CloudKit)
24 `@Model`-Klassen in `SharedModelContainer.swift:16-44`:

| Modell | Beschreibung |
|---|---|
| `Habit` | Gewohnheiten mit Titel, Icon, Farbe, Punkten, Frequenz, Erinnerungszeit, Tracking-Modus (simple/messbar) |
| `HabitCompletion` | Erledigungen mit Datum, Punktzahl, Fortschritt (currentValue), Notiz |
| `HabitGroup` | Gruppierung von Habits (enthält UUID-Liste) |
| `Forest` | Der „Wald“ des Nutzers (Name, ausgegebene Punkte) |
| `TreeEntity` | Einzelner Baum (Species, Grid-Position, Wachstumspunkte, Nickname) |
| `UserProfile` | Nutzerprofil (Name, Einheiten, Theme, Wochenstart, Punktziel, Nutrition-Goals, Quiet Hours, iCloud-Sync) |
| `Exercise` | Übungen (Name, Kategorie, Tracking-Typ, Muskelgruppen, Bilder, Anleitungen) |
| `Workout` | Workout-Vorlagen (Name, Farbe, Dauer, Sortierung, Archivierung) |
| `WorkoutExercise` | Plan-Slot: Übung im Workout mit Ziel-Sets, Reps, Gewicht, Pause, Superset-Gruppe |
| `WorkoutSession` | Durchgeführte Trainingseinheit (Start/Ende, RPE, Notizen, Gewichtseinheit) |
| `SetEntry` | Einzelner Satz (Reps, Gewicht, Dauer, Distanz, Warmup, Assisted Reps, Volumen-Berechnung) |
| `Food` | Lebensmittel (Nährwerte pro 100g, Barcode, Kategorie, Favoriten) |
| `FoodEntry` | Gegessenes (Tag, Mahlzeit-Typ, Portion, Notiz) |
| `Supplement` | Supplement (Name, Dosierung, Frequenz, Erinnerungszeiten) |
| `SupplementEntry` | Eingenommenes Supplement |
| `MealTemplate` | Mahlzeiten-Vorlage (Name, Icon, Farbe) |
| `MealTemplateItem` | Einzelposten in Template |
| `TrainingsPlan` | Trainingsplan (Name, aktiv/inaktiv, Farbe) |
| `TrainingsPlanDay` | Tag im Trainingsplan (Wochentag → Workout) |
| `AchievementRecord` | Erreichte Achievements |
| `BodyProgressEntry` | Körpermaße & Fotos (Gewicht, KFA, Umfänge, Energielevel, Tags, Fotos) |
| `Gym` | Fitnessstudio (Name, Adresse, Icon, Farbe) |
| `GymExercise` | Übung im Gym (Zone) |
| `GymEquipment` | Gerät im Gym (Position X/Y, Typ, Etage, Zone, Icon) |
| `EquipmentExercise` | Übungszuweisung zu Gerät |
| `FloorPlan` | Etagen-Grundriss (Zeichnungsdaten, logische Größe) |
| `FloorZone` | Zone im Grundriss |
| `WallSegment` | Wandsegment im Grundriss |
| `WellnessEntry` | Wellness-Check-in (Stimmung, Energie, Schlaf, Stress 1–5, Tags) |

### 1.2 App-Architektur
- **`ThriveWoodApp.swift`**: `@main` Einstieg, erzeugt `AppEnvironment` und setzt `NotificationRouter` sowie UserDefaults
- **`AppEnvironment.swift`**: Zentraler DI-Container – hält alle Repositories und Services als `@Observable`
- **`SharedModelContainer.swift`**: Singleton `ModelContainer` mit CloudKit, App Group, Migrationsplan
- **MVVM-Muster**: Views nutzen `@Environment(AppEnvironment.self)`, ViewModels laden Daten aus Services

### 1.3 Repositories
Alle SwiftData-basiert, über Protokolle abstrahiert (`Data/Repositories.swift`):
- `HabitRepository`, `HabitCompletionRepository`, `HabitGroupRepository`
- `ForestRepository`, `TreeRepository`
- `ExerciseRepository`, `WorkoutRepository`, `WorkoutSessionRepository`
- `UserProfileRepository`
- `FoodRepository`, `FoodEntryRepository`, `SupplementRepository`, `SupplementEntryRepository`, `MealTemplateRepository`
- `TrainingsPlanRepository`
- `AchievementRepository`
- `BodyProgressRepository`
- `GymRepository`
- `WellnessRepository`

---

## 2. Haupt-Tabs (RootTabView)

4 Tabs definiert in `RootTabView.swift`:

| Tab | Label | Icon | View |
|---|---|---|---|
| `home` | Habits | `checklist` | `HomeView` |
| `analytics` | Analyse | `chart.bar.xaxis` | `AnalyticsView` |
| `sport` | Sport | `dumbbell.fill` | `SportView` |
| `settings` | Profil | `person.crop.circle` | `SettingsView` |

---

## 3. Habits (Home-Tab)

**Dateien:** `Views/Home/HomeView.swift`, `HomeViewModel.swift`, `HabitRowView.swift`, `HabitGroupHeaderView.swift`, `HabitReorderView.swift`, `WeekStripView.swift`, `ProgressRing.swift`, `DailySummaryCard.swift`, `EmptyHabitsView.swift`, `ForestPreviewCard.swift`

### 3.1 Features
- **Tab-Umschalter**: Habits / Supplements (`selectedTab`)
- **Tagesauswahl**: Über `WeekStripView` zwischen Tagen wechseln
- **Habit-Tracking**:
  - **Simple**: Einmal antippen = erledigt (1 Punkt)
  - **Messbar**: Fortschrittsbasiert (`trackingMode = .measurable`) mit `targetValue`, `incrementValue`, `unitLabel` (z.B. 2000ml Wasser in 200ml-Schritten)
- **Habit-Gruppen**: `HabitGroup` als Container für mehrere Habits, einklappbar, Drag & Drop per `HabitReorderView`
- **Habit-Editor**: `HabitEditorView` mit Icon-Picker, Farbraster, Wochentag-Auswahl, Erinnerungszeit, Punkte, Tracking-Modus
- **Gruppen-Editor**: `HabitGroupEditorView`
- **Archivierung**: Habits archivieren (`archivedAt`) statt löschen
- **Punktesystem**: `ScoringService` – verdiente Punkte minus ausgegebene = verfügbares Budget für Wald

### 3.2 Freemium-Limits
- Free: max. 3 Habits, Pro: unbegrenzt (`EntitlementService.freeHabitLimit = 3`)

---

## 4. Sport (Sport-Tab)

**Dateien:** `Views/Sport/SportView.swift`, `SportViewModel.swift`, `ActiveSessionViewV2.swift`, diverse Support- und Sheet-Views

### 4.1 Workout-Management
- **Workout-Vorlagen**: Erstellen, Bearbeiten, Löschen, Archivieren von `Workout`-Objekten (`WorkoutEditorView`)
- **Übungs-Slots**: `WorkoutExercise` mit:
  - Ziel-Sets, -Reps, -Gewicht, -Dauer, -Distanz
  - Pausenzeit (`restSeconds`)
  - Superset-Gruppen (`supersetGroup`)
  - Drag & Drop Reordering
- **Freemium**: Free max. 2 Workouts, Pro unbegrenzt

### 4.2 Live-Training (`ActiveSessionViewV2`)
- **Session starten**: Quick-Start (freies Training) oder aus Workout-Vorlage
- **Live-Statistiken**: Abgeschlossene Sets, Gesamtvolumen, Dauer, Übungsanzahl
- **Set-Erfassung**: Pro Übung Sets mit Reps, Gewicht, Dauer, Distanz, Warmup-Flag, Assisted Reps
- **Rest-Timer**: `RestTimer` mit Countdown, Verlängerung, Haptik-Benachrichtigung
- **Set-Empfehlungen**: `SetRecommendationService` (Pro-Feature) – KI-basierte Gewichts-/Reps-Vorschläge basierend auf Historie
- **Superset-Erkennung**: Farbliche Gruppierung im Training
- **Training beenden**: `FinishSessionSheet` mit RPE (1-10), Notizen, HealthKit-Sync
- **Workout-Foto**: `WorkoutSummaryImage` / `WorkoutPhotoShareSheet` – Zusammenfassung als Bild teilen
- **Session abbrechen**: Mit Bestätigungsdialog

### 4.3 Exercise-Tracking
4 Tracking-Typen (`ExerciseTrackingType`):
- `repsWeight` – Krafttraining (Reps × Gewicht)
- `reps` – Körpergewicht-Übungen
- `duration` – Zeitbasiert (Plank, Dehnen)
- `distanceDuration` – Cardio (Distanz + Zeit)

7 Übungskategorien: `strength`, `cardio`, `mobility`, `stretching`, `plyometrics`, `balance`, `other`

### 4.4 Übungs-Bibliothek (`ExerciseLibraryView`)
- Anzeige aller Übungen (Built-in + selbst erstellt)
- Detailsheet pro Übung (`ExerciseDetailsSheet`)
- Übungs-Editor (`ExerciseEditorView`) – eigene Übungen erstellen/bearbeiten
- Progression-Sheet (`ExerciseProgressionSheet`) – Gewichtsentwicklung über Zeit
- Über 80 Built-in-Übungen mit Bildern in `Assets.xcassets/Exercises/` und in `BuiltInExercises.swift` / `BuiltInExercises0.swift`

### 4.5 Trainingspläne (`TrainingsPlan`)
- **Erstellen/Bearbeiten**: `CreateTrainingsPlanSheet`, `EditTrainingsPlanSheet`
- **Tages-Zuweisung**: Pro Wochentag ein Workout
- **Aktiv/Inaktiv**: Nur ein Plan gleichzeitig aktiv (`isActive`)
- **Tages-Edit**: `EditDaySheet`, `EditSessionSheet`
- **Detail-Ansicht**: `TrainingsPlanDetailView`
- **KI-Plan-Generator**: `AIPlanGeneratorView` nutzt `FoundationModels` (`@Generable`) mit on-device `SystemLanguageModel` zur automatischen Planerstellung

### 4.6 Sessions & Workout-Verlauf
- `AllSessionsView` – Alle abgeschlossenen Sessions
- `WorkoutSessionDetailView` – Detaillierte Session-Ansicht
- `WorkoutAnalysisView` – Analyse einer einzelnen Session
- `PRListView` – Personal Records (Bestleistungen pro Übung)
- `EditNotesSheet` – Nachträgliche Notizen

### 4.7 Muskel-Analyse
- **Muskel-Ranking**: `MuscleRankingScreen` / `MuscleRankingService`
  - Visualisierung auf anatomischer Karte (`AnatomicMuscleMapView`, `MuscleMapView`)
  - Bronze/Silber/Gold/Platin/Diamant/Champion/Legend Ränge
  - Oberkörper/Unterkörper/Core/Rücken Kategorien
  - Rang-Legende (`RankLegendSheet`)
- **Muskel-Erholung**: `MuscleRecoveryService` / `RecoveryMuscleCard`
  - Berechnet Erholungsstatus aller Muskelgruppen
  - Recovery-Legende (`RecoveryLegendSheet`)
  - Konfigurierbar: untrainierte Muskeln zählen (UserDefaults)
- **Session-Muskel-Map**: `SessionMuscleMapView`

### 4.8 Sport-Analytics
- `SportInsightsView` – Übergreifende Trainingsanalysen
- `WorkoutStatsCard` – Statistiken im Analyse-Tab

### 4.9 HealthKit-Integration
- `HealthKitService`:
  - Liest: Schritte, aktive Kalorien, Distanz (Laufen/Radfahren), Workouts
  - Schreibt: Workouts nach Session-Abschluss in Apple Health (inkl. Distanz, geschätzte Kalorien)
  - Activity-Typ-Mapping: Kraft → `traditionalStrengthTraining`, Cardio → `mixedCardio`, Laufen → `running`, Rad → `cycling` usw.

---

## 5. Wald (Forest)

**Dateien:** `Views/Forest/ForestView.swift`, `ForestViewModel.swift`, `ForestService.swift`, `Sheets/SpeciesPickerSheet.swift`, `Sheets/TreeDetailSheet.swift`, Support-Views

### 5.1 Features
- **Wald-Grid**: `ForestGridView` – Bäume in Grid-Zellen (logische X/Y-Koordinaten)
- **Baum pflanzen**: Aus `ScoringService.availablePoints()` bezahlen, `SpeciesPickerSheet` mit unlockten Spezies
- **8 Baumarten**: `TreeSpecies` – Oak (0 Pkt), Pine (25), Birch (60), Maple (120), Willow (220), Cherry (400), Sequoia (750), Bonsai (1200)
- **6 Wachstumsstufen**: Seed (0-4), Sprout (5-14), Sapling (15-34), Young (35-69), Mature (70-149), Ancient (150+)
- **Baum-Details**: `TreeDetailSheet` – Spezies, Wachstumsstufe, Nickname, Pflanzdatum
- **Visualisierung**: `TreeShapeView` + `CanopyShapes` + `TreeStyle` – prozedurales Baum-Rendering je nach Spezies und Stufe
- **Statistik-Header**: Verfügbare Punkte, Gesamt verdient, Grid-Abdeckung, Anzahl Bäume
- **Freemium**: Free nur Oak, Pro alle Spezies

---

## 6. Analyse-Tab (Analytics)

**Dateien:** `Views/Analytics/AnalyticsView.swift`, `AnalyticsViewModel.swift`, Support-Views

### 6.1 Features
- **Zeitraum-Auswahl**: Woche / Monat / Quartal / Jahr (`AnalyticsRange`)
  - Free: nur Woche, Pro: alle Zeiträume
- **Summary Grid**: Übersichtskacheln (Punkte, Completions, Streaks usw.)
- **Punkte-Trend**: `PointsTrendCard` – Diagramm mit täglichen Punkten vs. Ziel
- **Wochentag-Verteilung**: `WeekdayDistributionCard`
- **Habit-Leaderboard**: `HabitLeaderboardCard` – Ranking der Habits nach Performance
- **Heatmap**: `HeatmapCard` – Kalender-Heatmap pro Habit
- **Workout-Statistiken**: `WorkoutStatsCard`, `WorkoutVolumeCard` – Sessions, Volumen, Dauer
- **Schritte**: `StepsCard` – HealthKit-Schrittdaten

---

## 7. Profil & Einstellungen (Settings-Tab)

**Dateien:** `Views/Settings/SettingsView.swift` und Subviews

### 7.1 Features
- **Profil**: Display-Name, Profil-Hero-Card mit Punkten (verdient/ausgegeben)
- **Erscheinungsbild**:
  - **Akzentfarbe**: `AccentThemePicker` – Forest, Ocean, Sunset, Lavender, Mono, Neon (Pro: Custom Icons & Themes)
  - **App-Icon**: `AppIconPickerView` – 5 Icons (Standard, Forest, Night, Mono, Cartoon)
  - **Modus**: System / Hell / Dunkel
- **Habits & Ziele**: Tagesziel (Punkte), Wochenbeginn (Mo/So/Sa)
- **Sport-Einstellungen**: Gewichtseinheit (kg/lb), Standard-Pause (0–600s), Aktivitätsprofil, untrainierte Muskeln zählen
- **Benachrichtigungen**: `NotificationsCard` – Auth-Status, Quiet Hours (Pro-Feature), Test-Notification
- **Apple Health**: Verbindung autorisieren, Berechtigungsstatus
- **Daten**: Export (`ExportSheet`), Import (`ImportSheet`) – Pro-Feature, JSON-Backup aller Daten
- **Abonnement**: `SubscriptionStatusCard` – Pro-Status, Kaufoptionen, Restore
- **Sonstiges**: Onboarding erneut starten, Debug-Menü (nur `#if DEBUG`), App-Bewertung, Lizenzen

### 7.2 Aktivitätsprofil
`ActivityProfile` enum (in SettingsView verwendet): moderat, aktiv, sehr aktiv – beeinflusst Kalorienberechnungen

---

## 8. Ernährung (Nutrition)

**Dateien:** `Views/Food/NutritionTab.swift`, `Nutrition/` und `Supplements/` Ordner

### 8.1 Features
- **Tab-Umschalter**: Ernährung / Supplements
- **Ernährung**:
  - `FoodSearchView` – Lebensmittel suchen & hinzufügen
  - `FoodDiaryView` – Tagebuch (derzeit als „In Kürze verfügbar“ ausgegraut)
  - `FoodEditorView` – Lebensmittel erstellen/bearbeiten (Nährwerte pro 100g)
  - `FoodLogSheet` – Portion loggen (`FoodAmountSheet`)
  - `BarcodeScannerView` – Barcode scannen (OpenFoodFacts-Integration via `OpenFoodFacts.swift`)
  - `MealTemplateEditorView` / `MealTemplatesSection` – Mahlzeiten-Vorlagen
  - `NutritionGoalEditor` – Makro-Ziele (Kalorien, Protein, Carbs, Fett) als JSON in `UserProfile.nutritionGoals`
  - `AllMealTemplatesView` – Alle Templates anzeigen
- **Supplements**:
  - `SupplementEditorView` – Supplement anlegen (Name, Dosierung, Frequenz, Erinnerungen)
  - `SupplementListView` – Tägliche Supplement-Einnahme tracken (derzeit als „In Kürze verfügbar“ ausgegraut)
  - `SupplementAnalysisView` – KI-Analyse (nutzt on-device AI)
  - `SupplementCard` – Übersichtskarte im Home-Tab
  - **Freemium**: Free max. 2 Supplements

### 8.2 Datenmodell
- `Food` – Nährwerte pro 100g (Kalorien, Protein, Carbs, Fett, Ballaststoffe, Zucker, Natrium), Barcode, Kategorie, Favorit
- `FoodEntry` – Tag, Mahlzeit-Typ (Frühstück/Mittag/Abend/Snack), Portion in g
- `Supplement` – Name, Dosierung, Frequenz (daily/weekly/custom), reminderTimes, activeWeekdays
- `SupplementEntry` – Einnahme-Datum
- `MealTemplate` / `MealTemplateItem` – Zusammengesetzte Mahlzeiten
- `NutritionGoals` – Codable-Struct für Makro-Ziele
- `NutritionValues` – Helper-Struct für Nährwertberechnung
- `FoodCategory` enum – verschiedene Lebensmittelkategorien

---

## 9. Körper & Wellness

**Dateien:** `Views/BodyProgress/`, `Views/Wellness/`

### 9.1 Body Progress
- **Messwerte**: Gewicht, KFA, Muskelmasse, Wasseranteil, Größe, Brust/Taille/Hüfte/Schultern/Nacken, Bizeps/Unterarm/Oberschenkel/Wade (je links/rechts) – in kg/lbs und cm/in
- **Metadaten**: Energielevel (1-5), Tags (z.B. „Diät“, „Massephase“), Pump-Status
- **Fotos**: Bildpfade für Fortschrittsbilder (`photoPaths`)
- **Charts**: `BodyProgressView` mit `ChartMetric` enum – Liniendiagramme für alle Metriken
- **Galerie**: `BodyProgressGalleryView` – Fotos im Zeitverlauf
- **Editor**: `BodyProgressEntryEditor` – Neue Messung anlegen
- **Body Map**: `BodyMeasurementMapView` – Anatomische Visualisierung
- **Detail**: `BodyProgressDetailView` – Einzelansicht einer Messung

### 9.2 Wellness
- **Täglicher Check-in**: `WellnessView` – Stimmung (1-5), Energie (1-5), Schlafqualität (1-5), Stress (1-5), Notizen, Tags
- **Wellness-Score**: Automatisch berechnet aus den 4 Metriken (0-5)
- **Emoji-Darstellung**: Jede Stufe hat eigenes Emoji
- **Wellness-Summary**: `WellnessService.WellnessSummary` – Durchschnittswerte über Zeitraum
- **Korrelationen**: `WellnessService.CorrelationInsight` – Zusammenhänge zwischen Metriken und Habits/Workouts
- **Verlauf**: Liste aller Check-ins

---

## 10. Achievements (Erfolge)

**Dateien:** `Views/Achievements/AchievementsView.swift`, `Data/AchievementDefinitions.swift`, `Services/AchievementService.swift`

### 10.1 Umfang
103 Achievements in 4 Kategorien:

| Kategorie | Anzahl | Beispiele |
|---|---|---|
| **Habit** | 27 | firstHabit, streaks (3/7/14/30/60/100/180/365 Tage), Punkte (10–5000), measurable goals (100/500/1000), single-day points (10/20/30) |
| **Workout** | 21 | firstWorkout, 5–200 Workouts, Dauer (30/60/90min), PRs (1/5/15/30), Volumen (1k–250k kg), Streak (3/7 Tage), erste Cardio/Kraft, Sets (100/500/1000) |
| **Forest** | 24 | Bäume (1–40), eine von jeder Species, Wachstumsstufen (sapling–ancient), 2/5 Ancient-Bäume, Coverage (25/50/75%), Punkte ausgegeben (50/200/500) |
| **Muscle** | 18 | Rang-Achievements (Bronze–Legend), Oberkörper/Unterkörper/Core/Back, erste Set, Sets total (100/500) |

- **Progress-Tracking**: Jedes Achievement hat Fortschrittsberechnung (`AchievementService.progress(for:)`)
- **HUD**: `AchievementHUD` – Overlay beim Freischalten, auch in `RootTabView` per `.achievementHUD()` Modifier
- **Kategorie-Filter**: In AchievementsView nach Kategorie filtern

---

## 11. Onboarding

**Dateien:** `Views/Onboarding/OnboardingView.swift` + Steps

### 11.1 Ablauf (6 Schritte)
1. **Welcome** – Willkommensbildschirm
2. **Concept** – Erklärung des Konzepts (Habits → Punkte → Wald)
3. **Profile** – Name, Tagesziel, Akzentfarbe
4. **FirstHabit** – Ersten Habit anlegen
5. **Notifications** – Benachrichtigungen aktivieren
6. **Ready** – Abschluss

- **Erneutes Ausführen**: Aus Settings möglich (`isRerun`-Flag)
- **Animation**: Slide-Transition zwischen Schritten
- **Wird erzwungen**: Bei `profile.onboardingCompletedAt == nil` in `RootTabView`

---

## 12. Monetarisierung (StoreKit)

**Dateien:** `Services/StoreService.swift`, `Services/EntitlementService.swift`, `Views/Paywall/`

### 12.1 Produkte
- `com.bensiebert.thrivewood.pro.monthly`
- `com.bensiebert.thrivewood.pro.yearly`
- `com.bensiebert.thrivewood.pro.lifetime`

### 12.2 Pro-Features
| Feature | Free Limit | Pro |
|---|---|---|
| Habits | 3 | ∞ |
| Workouts | 2 | ∞ |
| Supplements | 2 | ∞ |
| Gyms | 1 | ∞ |
| Baumarten | Nur Oak | Alle 8 |
| Analytics-Zeiträume | Nur Woche | Alle |
| Export/Import | ❌ | ✅ |
| Themes & Custom Icons | ❌ | ✅ |
| Quiet Hours | ❌ | ✅ |
| Set-Empfehlungen | ❌ | ✅ |
| Geräte auf Map platzieren | ❌ | ✅ |
| Map in Workout nutzen | ❌ | ✅ |

### 12.3 Paywall
`PaywallView` mit `ProBadge`, Kauf/Restore-Buttons, Debug-Reset (nur `#if DEBUG`)

---

## 13. Benachrichtigungen & Live Activities

**Dateien:** `Services/NotificationService.swift`, `Services/NotificationRouter.swift`, `Services/WorkoutLiveActivityManager.swift`

### 13.1 Push Notifications
- **Habit-Reminder**: Pro Habit mit `reminderTime` → `UNCalendarNotificationTrigger`
  - Täglich oder wochentag-spezifisch
  - Actions: „Erledigt ✓“ (mit Auth) und „In 15 Min erinnern“ (Snooze)
  - Category: `HABIT_REMINDER`
- **Supplement-Reminder**: Via `SupplementService` mit `reminderTimes`
- **NotificationRouter**: Deep-Link zum entsprechenden Habit-Sheet bei Tap
- **Reschedule**: Alle Habits auf einmal neu planen

### 13.2 Live Activities (Dynamic Island)
- **Workout Live Activity**: `WorkoutLiveActivityManager` + `WorkoutLiveActivity` Widget
  - Zeigt: Workout-Name, aktuelle Übung, Übung X/Y, Sets completed/total, Timer, Rest-Timer
  - Dynamic Island: Expanded (Leading/Trailing/Center/Bottom), Compact, Minimal
  - Lock Screen: Ausführliche Workout-Ansicht
  - Updates: Übungswechsel, Set-Abschluss, Rest-Timer

---

## 14. Widgets (ThriveWoodWidgets Extension)

**Dateien:** `ThriveWoodWidgets/ThriveWoodWidgets.swift`, `WidgetTypes/`, `Providers/`

### 14.1 Widget-Typen
| Widget | Konfiguration | Familien |
|---|---|---|
| **DailyHabitsWidget** | Static, `DailyHabitsProvider` | small, medium, large |
| **HabitStreakWidget** | Configurable (`SelectHabitIntent`), `HabitStreakProvider` | small, medium |
| **ForestWidget** | Static, `ForestProvider` | small, medium, large |
| **WorkoutWidget** | Static, `WorkoutProvider` | small, medium |

### 14.2 Datenzugriff
Widgets nutzen App Group (`group.com.bensiebert.thrivewood`) zum Lesen aus SwiftData

---

## 15. KI / On-Device AI

**Dateien:** `Services/AIService.swift`, `Views/Sport/Sheets/AIPlanGeneratorView.swift`

### 15.1 Foundation Models
- `AIService` wrapped `SystemLanguageModel.default` (iOS 26+)
- Prüft `model.availability == .available`
- Bietet Streaming-Response

### 15.2 Anwendungen
- **KI-Plan-Generator**: `AIPlanGeneratorView` – Generiert Trainingspläne via `@Generable` structs
  - Strukturierter Output: `AIGeneratedPlan` → `AIGeneratedWorkout` → `AIGeneratedExercise`
  - Nutzt vorhandene Übungsnamen aus der Bibliothek
- **Supplement-Analyse**: `SupplementAnalysisView` (AI-gestützt)
- **Set-Empfehlungen**: `SetRecommendationService` nutzt `aiService` für Gewichts-/Reps-Empfehlungen

---

## 16. Daten-Export / Import & Backup

**Dateien:** `Services/BackupService.swift`, `Data/ThriveWoodBackup.swift`

### 16.1 Backup-Format
`ThriveWoodBackup` – JSON-Struktur mit DTOs für alle Entitäten:
- Profil, Habits, Completions, Forest, Trees, Exercises (nur user-created), Workouts, WorkoutExercises, Sessions, Sets, Supplements, SupplementEntries
- Versionierung (`currentVersion`)
- App-Version, Export-Zeitstempel

### 16.2 Export
- `ExportSheet` – JSON-Datei teilen (Share Sheet)
- Pro-Feature

### 16.3 Import
- `ImportSheet` – JSON auswählen und importieren
- ID-Mapping für referenzierte Objekte (Übungen, Habits, Workouts)
- Merge-Strategie für Profil (überschreibt nicht alles)
- Pro-Feature

### 16.4 PDF-Export
- `PDFService` – Workout als DIN A4 PDF rendern
- Enthält: Header, Workout-Summary, Übungskarten mit Target-Werten, Notizbereich
- Per `ShareLink` aus `WorkoutEditorView` teilbar

---

## 17. Gym Plan Builder (Separates Target)

**Dateien:** `GymPlanBuilder/` – Eigenständige App/Extension

### 17.1 Gym-Modell
- `Gym` – Fitnessstudio mit Name, Adresse, Icon, Farbe
- `GymEquipment` – Geräte mit Position (X/Y), Stockwerk, Typ, Icon
- `EquipmentExercise` – Übungen pro Gerät
- `FloorPlan` – Grundriss pro Stockwerk (Zeichnungsdaten als `Data`, Breite/Höhe)
- `FloorZone` – Zonen im Grundriss (Name, Farbe, Rechteck-Positionen)
- `WallSegment` – Wandsegmente (Start/Ende X/Y, Dicke)

### 17.2 Gym-Integration
- `GymService` – CRUD für Gyms
- `EntitlementService`: Free max. 1 Gym
- Pro-Features: `canPlaceEquipmentOnMap`, `canUseMapInWorkout`

---

## 18. Design System & UI

**Dateien:** `Helpers/DesignSystem.swift`, `Helpers/Extensions.swift`, `Helpers/Protocols.swift`

### 18.1 Theme-System
- `Theme` enum mit `Spacing`, `Typography`, `Radius`
- `AccentTheme` – 6 Themes (Forest, Ocean, Sunset, Lavender, Mono, Neon) mit `Color`-Ableitung
- `AppAppearance` – System/Light/Dark
- `HabitColor` – 12 Farben mit Gradient-Unterstützung

### 18.2 UI Components
- `cardStyle()` Modifier
- `AchievementHUD` – Erfolgs-Overlay
- `SuccessHUD` – Erfolgsmeldung
- `ErrorState` / `.errorAlert()` – Fehlerbehandlung
- `Haptics` – Haptisches Feedback (`selection`, `success`, `impact`)
- `BounceButtonStyle`, `PressScaleStyle` – Button-Animationen
- `FlexibleNumberField` – Zahlenfeld mit Formatierung
- `AIResponseView` – Streaming AI-Output anzeigen
- `LicenseViewer` – Lizenztexte
- `UnauthenticatedView` – Platzhalter bei fehlender Auth
- `PremiumSegmentedPicker` – Segment-Picker
- `SettingsGroup`, `SettingsRow`, `StepperRow`, `MenuPickerRow`, `ToggleRow` – Settings-Komponenten

---

## 19. GymPlanBuilder (macOS)

**Dateien:** `GymPlanBuilder/` und `GymPlanBuilderMac/` – macOS-Version der Gym-Verwaltung mit `SwiftUI`-App

---

## 20. Sonstiges

- **iCloud Sync**: ModelContainer konfiguriert mit `cloudKitDatabase: .automatic`
- **App Group**: `group.com.bensiebert.thrivewood` für Widget-Datenzugriff
- **Debug-Menü**: `DebugMenuView` / `DebugService` – Reset Purchases, Seed-Daten, Daten löschen
- **Calendar.app**: Benutzerdefinierte `Calendar.app` Extension für wochenstart-bewusste Datumsberechnungen
- **HabitTrackingMode**: Simple (an/aus) und Measurable (fortschrittsbasiert) mit `currentValue`
- **Volume-Berechnung**: `SetEntry.volumeValue` – kg × reps (assisted reps × 0.6)
- **Workout Summary Image**: `WorkoutSummaryImage` erstellt Screenshot-artige Zusammenfassung als Bild zum Teilen

---

## 21. Was ist NICHT implementiert (nur als Platzhalter/Coming Soon)

- `FoodDiaryView` – ausgegraut („In Kürze verfügbar“)
- `SupplementListView` – ausgegraut („In Kürze verfügbar“)
- Ernährung ist datenmodellseitig vollständig, aber die UI für Tagebuch-Ansicht und Supplement-Tracking fehlt
