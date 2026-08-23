# ThriveWood Unio-Export – Datenreferenz

Dieses Dokument beschreibt exakt, welche Daten maximal in einem ThriveWood-Export für Unio vorkommen können.

Maßgeblich sind die Implementierungen in:

* `ThriveWood/Unio/ThriveWoodUnio.swift` (Quelle, Datasets, Export)
* `ThriveWood/Unio/UnioExportModels.swift` (Export-DTOs und Schemas)
* `ThriveWood/Unio/UnioKit.swift` (Export- und Speicherformat)

## Rahmendaten

| Eigenschaft | Wert |
|---|---|
| Source-ID | `thrivewood` (dauerhaft, nicht änderbar) |
| Anzeigename | `ThriveWood` |
| App Group | `group.com.bensiebert.apps` |
| Protokoll-Version | `1` |
| Export-Modus | `full` (vollständiger Snapshot, atomar aktiviert) |
| Schema-Version | `1` (alle Datasets) |
| Behaltene Export-Versionen | `2` (ältere werden automatisch gelöscht) |
| Assets | **keine** (es werden keine Dateien/Bilder exportiert) |

## Maximale Datenmenge

Ein Export enthält **jeden Datensatz** der unten gelisteten Entitäten – unabhängig vom Alter (vollständige Historie), inklusive archivierter Einträge. Es gibt keine Zeit- oder Mengenbegrenzung.

* Gelöschte Datensätze fehlen im nächsten Snapshot (keine Tombstones nötig).
* Archivierte Datensätze enthalten einen `archivedAt`-Zeitstempel.
* Abgeleitete Kennzahlen (Volumen, Punktestände, Nährwertsummen, Dauern) werden **nicht** exportiert – Unio berechnet sie aus Rohdaten und Schemas.

## Ablagestruktur in der App Group

```text
group.com.bensiebert.apps/
└── Unio/v1/sources/thrivewood/
    ├── current.json                  # Pointer auf aktiven Export (exportID, updatedAt)
    └── exports/<UUID>/
        ├── manifest.json             # Quelle, Export-Deskriptor, Dataset-Liste, SHA-256-Prüfsummen
        ├── datasets/<datasetID>.jsonl
        └── schemas/<datasetID>.json
```

Codierung: JSON Lines, ISO-8601-Datumsangaben mit Millisekunden, sortierte Schlüssel. Dateien sind mit `completeFileProtectionUnlessOpen` geschützt.

---

## Exportierte Datasets (23)

### 1. `forests` – Wälder (Entity `forest`)

Alle angelegten Wälder (in der Praxis genau einer).

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `name` | String | `name` | | |
| `spentPoints` | Int | `count` | `point` | Manuell ausgegebene Punkte |
| `createdAt` | Date | `createdAt` | | |

### 2. `trees` – Bäume (Entity `tree`)

Alle gepflanzten Bäume inklusive Wachstumsstand.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `forestID` | String? | – | | Relation → `forests` |
| `species` | String | `name` | | z.B. `oak`, `sequoia` |
| `growthPoints` | Int | `count` | `point` | |
| `plantedAt` | Date | `timestamp` | | |
| `nickname` | String? | `name` | | **sensibel** |

Nicht exportiert: `gridX`/`gridY` (UI-Grid-Koordinaten).

### 3. `habits` – Habits (Entity `habit`)

Alle Gewohnheiten, auch archivierte.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `title` | String | `title` | | |
| `details` | String | – | | **sensibel** |
| `points` | Int | `count` | `point` | Punkte pro Erledigung (1–3) |
| `frequency` | String | – | | `daily` \| `weekly` \| `custom` |
| `activeWeekdays` | [Int] | – | | ISO-8601-Wochentag (1 = So … 7 = Sa) |
| `trackingMode` | String | – | | `simple` \| `measurable` |
| `targetValue` | Double | `habitTargetValue` | | Tagesziel bei messbaren Habits |
| `incrementValue` | Double | – | | Schrittgröße pro Bedienung |
| `unitLabel` | String | – | | Einheit des Zielwerts (`ml`, `Seiten`, `min`, …) |
| `createdAt` | Date | `createdAt` | | |
| `archivedAt` | Date? | `timestamp` | | |

Nicht exportiert: `iconSystemName`, `colorRaw`, `sortOrder`, `reminderTime` (reine UI-/Erinnerungsdaten).

### 4. `habit-completions` – Habit-Erledigungen (Entity `habitCompletion`)

Die vollständige Historie aller Erledigungen und Messwerte.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `habitID` | String? | – | | Relation → `habits` |
| `day` | Date | `day` | | Kalendertag (Tagesbeginn) |
| `completedAt` | Date | `timestamp` | | Letzte Änderung des Fortschritts |
| `pointsAwarded` | Int | `count` | `point` | |
| `currentValue` | Double | `habitProgressValue` | | Messwert (bei `simple` = Zielwert) |
| `note` | String? | – | | **sensibel** |

### 5. `habit-groups` – Habit-Gruppen (Entity `habitGroup`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `title` | String | `title` | |
| `habitIDs` | [String] | – | Relation → `habits` (n:1, `containsHabit`) |
| `sortOrder` | Int | – | Im Datensatz, nicht schema-beschrieben |
| `createdAt` | Date | `createdAt` | |

Nicht exportiert: `iconSystemName`, `colorRaw`, `isCollapsed` (UI-Zustand).

### 6. `habit-routines` – Habit-Routinen (Entity `habitRoutine`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `title` | String | `title` | |
| `habitIDs` | [String] | – | Relation → `habits` (geordnete Liste, `containsHabit`) |
| `sortOrder` | Int | – | Im Datensatz, nicht schema-beschrieben |
| `createdAt` | Date | `createdAt` | |

Nicht exportiert: `iconSystemName`, `colorRaw`, `habitTargets` (Anzeige-Override pro Habit).

### 7. `exercises` – Übungen (Entity `exercise`)

Alle Übungen: vordefinierte und selbst angelegte.

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `name` | String | `name` | |
| `details` | String | – | **sensibel** |
| `category` | String | – | `strength` \| `cardio` \| `mobility` \| … |
| `trackingType` | String | – | `repsWeight` \| `reps` \| `duration` \| `distanceDuration` |
| `primaryMuscleGroups` | [String] | – | Muskelgruppen-IDs |
| `secondaryMuscleGroups` | [String] | – | Muskelgruppen-IDs |
| `isBuiltIn` | Bool | – | |
| `createdAt` | Date | `createdAt` | |

Nicht exportiert: `iconSystemName`, `images`, `instructions` (UI-Assets/-Texte).

### 8. `workouts` – Workouts (Entity `workout`)

Alle Workout-Vorlagen, auch archivierte.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `name` | String | `title` | | |
| `details` | String | – | | **sensibel** |
| `estimatedDurationMinutes` | Int | `duration` | `minute` | |
| `sortOrder` | Int | – | | Im Datensatz, nicht schema-beschrieben |
| `createdAt` | Date | `createdAt` | | |
| `archivedAt` | Date? | `timestamp` | | |

Nicht exportiert: `colorRaw`.

### 9. `workout-exercises` – Workout-Übungen (Entity `workoutExercise`)

Plan-Slots mit Soll-Vorgaben.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `workoutID` | String? | – | | Relation → `workouts` |
| `exerciseID` | String? | – | | Relation → `exercises` |
| `order` | Int | – | | |
| `targetSets` | Int | `count` | | |
| `targetReps` | Int? | `count` | | |
| `targetWeight` | Double? | `weight` | `kilogram` | |
| `targetDurationSeconds` | Int? | `duration` | `second` | |
| `targetDistanceMeters` | Double? | `distance` | `meter` | |
| `restSeconds` | Int | `duration` | `second` | |
| `notes` | String | – | | **sensibel** |
| `supersetGroup` | Int? | – | | Superset-Gruppierung |

### 10. `workout-sessions` – Trainingseinheiten (Entity `workoutSession`)

Jede tatsächlich gestartete Trainingseinheit.

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `workoutID` | String? | – | Relation → `workouts`; `null` bei freiem Training |
| `startedAt` | Date | `startTime` | |
| `endedAt` | Date? | `endTime` | `null` = Laufzeit/abgebrochen gelöscht |
| `perceivedExertion` | Int? | `perceivedExertion` | RPE 1–10 |
| `notes` | String | – | **sensibel** |
| `weightUnit` | String | – | `kg` \| `lb` |

Nicht exportiert: berechnete `durationSeconds` (aus Start/Ende ableitbar).

### 11. `set-entries` – Sätze (Entity `setEntry`)

Jeder geloggte Satz.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `sessionID` | String? | – | | Relation → `workout-sessions` |
| `exerciseID` | String? | – | | Relation → `exercises` |
| `order` | Int | – | | |
| `reps` | Int? | `count` | | |
| `weight` | Double? | `weight` | `kilogram` | |
| `durationSeconds` | Int? | `duration` | `second` | |
| `distanceMeters` | Double? | `distance` | `meter` | |
| `isWarmup` | Bool | – | | |
| `isCompleted` | Bool | – | | |
| `completedAt` | Date? | `timestamp` | | |
| `assistedReps` | Int? | `count` | | |

Nicht exportiert: berechnete `volumeValue`/`summaryText`.

### 12. `trainings-plans` – Trainingspläne (Entity `trainingsPlan`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `name` | String | `title` | |
| `details` | String | – | **sensibel** |
| `isActive` | Bool | – | |
| `planType` | String | – | `weekday` \| `rotation` |
| `currentRotationIndex` | Int | – | |
| `completedRotations` | Int | `count` | |
| `createdAt` | Date | `createdAt` | |

Nicht exportiert: `color` (Hex-UI-Farbe).

### 13. `trainings-plan-days` – Trainingsplan-Tage (Entity `trainingsPlanDay`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `planID` | String? | – | Relation → `trainings-plans` |
| `workoutID` | String? | – | Relation → `workouts` |
| `weekday` | Int | – | 1 = Montag … 7 = Sonntag |
| `isRestDay` | Bool | – | |
| `notes` | String | – | **sensibel** |
| `rotationOrder` | Int | – | |
| `label` | String | – | Rotations-Label (A/B/C…) |

### 14. `foods` – Lebensmittel (Entity `food`)

Kompletter Lebensmittelkatalog (vordefiniert, aus OpenFoodFacts importiert, selbst erstellt). Alle Nährwerte **pro 100 g**.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `name` | String | `name` | | |
| `brand` | String? | – | | |
| `barcode` | String? | – | | |
| `caloriesPer100g` | Double | `energy` | `kilocalorie` | |
| `proteinPer100g` | Double | `protein` | `gram` | |
| `carbsPer100g` | Double | `carbohydrate` | `gram` | |
| `fatPer100g` | Double | `fat` | `gram` | |
| `fiberPer100g` | Double | `fiber` | `gram` | |
| `sugarPer100g` | Double | `sugar` | `gram` | |
| `sodiumPer100g` | Double | `sodium` | `milligram` | |
| `defaultServingSize` | Double | `servingSize` | `gram` | |
| `servingUnit` | String | – | | `g`, `ml`, `Stück`, … |
| `category` | String | – | | `fruits` \| `protein` \| … |
| `isUserCreated` | Bool | – | | |
| `usageCount` | Int | `count` | | Wie oft geloggt |
| `createdAt` | Date | `createdAt` | | |

Nicht exportiert: `isFavorite` (UI-Zustand).

### 15. `food-entries` – Ernährungseinträge (Entity `foodEntry`)

Die vollständige Ernährungshistorie.

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `foodID` | String? | – | | Relation → `foods` |
| `day` | Date | `day` | | Kalendertag (Tagesbeginn) |
| `mealType` | String | – | | `breakfast` \| `lunch` \| `dinner` \| `snacks` |
| `servingAmount` | Double | `servingSize` | `gram` | |
| `loggedAt` | Date | `timestamp` | | |
| `note` | String? | – | | **sensibel**; kann Vorlagen-Herkunft enthalten („aus <Name>") |

Nicht exportiert: berechnete Nährwerte pro Eintrag (Food × Menge).

### 16. `meal-templates` – Mahlzeit-Vorlagen (Entity `mealTemplate`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `name` | String | `title` | |
| `usageCount` | Int | `count` | |
| `createdAt` | Date | `createdAt` | |

Nicht exportiert: `iconSystemName`, `colorRaw`.

### 17. `meal-template-items` – Mahlzeit-Vorlagen-Positionen (Entity `mealTemplateItem`)

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `templateID` | String? | – | | Relation → `meal-templates` |
| `foodID` | String? | – | | Relation → `foods` |
| `servingAmount` | Double | `servingSize` | `gram` | |
| `sortOrder` | Int | – | | |

### 18. `supplements` – Supplemente (Entity `supplement`)

Alle Supplemente, auch archivierte.

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `name` | String | `name` | |
| `dosage` | String | – | Freitext („500mg", „1 Kapsel") |
| `details` | String | – | **sensibel** |
| `frequency` | String | – | `daily` \| `weekly` \| `custom` |
| `activeWeekdays` | [Int] | – | ISO-8601-Wochentag |
| `timesPerDay` | Int | `count` | |
| `sortOrder` | Int | – | Im Datensatz, nicht schema-beschrieben |
| `createdAt` | Date | `createdAt` | |
| `archivedAt` | Date? | `timestamp` | |

Nicht exportiert: `iconSystemName`, `colorRaw`, `reminderTimes` (Erinnerungszeiten).

### 19. `supplement-entries` – Supplement-Einnahmen (Entity `supplementEntry`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `supplementID` | String? | – | Relation → `supplements` |
| `day` | Date | `day` | Kalendertag (Tagesbeginn) |
| `doseNumber` | Int | `count` | n-te Einnahme des Tages |
| `takenAt` | Date | `timestamp` | Zeitpunkt des Loggens |
| `skipped` | Bool | – | `true` = bewusst übersprungen |

### 20. `body-measurements` – Körpermessungen (Entity `bodyMeasurement`)

| Feld | Typ | Semantic Type | Einheit | Bemerkung |
|---|---|---|---|---|
| `id` | String | `identifier` | | UUID |
| `date` | Date | `timestamp` | | |
| `weightKg` | Double? | `bodyWeight` | `kilogram` | |
| `bodyFatPercentage` | Double? | `bodyFatPercentage` | `percent` | |
| `muscleMassKg` | Double? | `muscleMass` | `kilogram` | |
| `waterPercentage` | Double? | – | `percent` | |
| `heightCm` | Double? | `bodyHeight` | `centimeter` | |
| `chestCm` | Double? | `bodyCircumference` | `centimeter` | |
| `waistCm` | Double? | `bodyCircumference` | `centimeter` | |
| `hipCm` | Double? | `bodyCircumference` | `centimeter` | |
| `shoulderCm` | Double? | `bodyCircumference` | `centimeter` | |
| `neckCm` | Double? | `bodyCircumference` | `centimeter` | |
| `leftBicepCm` | Double? | `bodyCircumference` | `centimeter` | |
| `rightBicepCm` | Double? | `bodyCircumference` | `centimeter` | |
| `leftForearmCm` | Double? | `bodyCircumference` | `centimeter` | |
| `rightForearmCm` | Double? | `bodyCircumference` | `centimeter` | |
| `leftThighCm` | Double? | `bodyCircumference` | `centimeter` | |
| `rightThighCm` | Double? | `bodyCircumference` | `centimeter` | |
| `leftCalfCm` | Double? | `bodyCircumference` | `centimeter` | |
| `rightCalfCm` | Double? | `bodyCircumference` | `centimeter` | |
| `notes` | String | – | | **sensibel** |
| `tags` | [String]? | – | | z.B. „Diät", „Nüchtern" |
| `energyLevel` | Int? | `energyLevel` | | |
| `onPump` | Bool | – | | Messung direkt nach Training |
| `weightUnit` | String | – | | `kg` \| `lbs` |
| `measurementUnit` | String | – | | `cm` \| `in` |

Nicht exportiert: `photoPaths` (lokale Fortschrittsfotos; Fotos werden insgesamt nicht als Assets exportiert).

### 21. `wellness-entries` – Wellness-Tagebücher (Entity `wellnessEntry`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `date` | Date | `timestamp` | |
| `mood` | Int | `mood` | Skala 1–5 (höher = besser) |
| `energy` | Int | `energyLevel` | Skala 1–5 (höher = besser) |
| `sleepQuality` | Int | `sleepQuality` | Skala 1–5 (höher = besser) |
| `stress` | Int | `stressLevel` | Skala 1–5 (höher = mehr Stress) |
| `note` | String | – | **sensibel** |
| `tags` | [String] | – | |
| `createdAt` | Date | `createdAt` | |

### 22. `gyms` – Studios (Entity `gym`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `name` | String | `name` | |
| `details` | String | – | **sensibel** |
| `address` | String | `locationName` | Freitext-Adresse |
| `createdAt` | Date | `createdAt` | |
| `archivedAt` | Date? | `timestamp` | |

Nicht exportiert: `iconSystemName`, `colorRaw`, sämtliche Studio-Layout-Daten (siehe unten).

### 23. `achievements` – Erfolge (Entity `achievement`)

| Feld | Typ | Semantic Type | Bemerkung |
|---|---|---|---|
| `id` | String | `identifier` | UUID |
| `definition` | String | `identifier` | Interne Erfolgs-ID (z.B. `firstHabit`) |
| `unlockedAt` | Date | `timestamp` | |

---

## Beziehungen zwischen Datasets

| Dataset | Feld | Relation | Ziel |
|---|---|---|---|
| `trees` | `forestID` | `plantedInForest` | `forests` |
| `habit-completions` | `habitID` | `completesHabit` | `habits` |
| `habit-groups` | `habitIDs` | `containsHabit` (many) | `habits` |
| `habit-routines` | `habitIDs` | `containsHabit` (many) | `habits` |
| `workout-exercises` | `workoutID` | `partOfWorkout` | `workouts` |
| `workout-exercises` | `exerciseID` | `plannedExercise` | `exercises` |
| `workout-sessions` | `workoutID` | `performedWorkout` | `workouts` |
| `set-entries` | `sessionID` | `partOfSession` | `workout-sessions` |
| `set-entries` | `exerciseID` | `performedExercise` | `exercises` |
| `trainings-plan-days` | `planID` | `partOfPlan` | `trainings-plans` |
| `trainings-plan-days` | `workoutID` | `plannedWorkout` | `workouts` |
| `food-entries` | `foodID` | `consumedFood` | `foods` |
| `meal-template-items` | `templateID` | `partOfTemplate` | `meal-templates` |
| `meal-template-items` | `foodID` | `containsFood` | `foods` |
| `supplement-entries` | `supplementID` | `takenSupplement` | `supplements` |

## Sensible Felder (`isSensitive: true`)

Unio kann diese Felder standardmäßig von automatischen Analysen ausschließen:

`trees.nickname`, `habits.details`, `habit-completions.note`, `exercises.details`, `workouts.details`, `workout-exercises.notes`, `workout-sessions.notes`, `trainings-plans.details`, `trainings-plan-days.notes`, `food-entries.note`, `supplements.details`, `body-measurements.notes`, `wellness-entries.note`, `gyms.details`

## Verwendete Semantic Types

Standard: `identifier`, `title`, `name`, `startTime`, `endTime`, `timestamp`, `createdAt`, `duration`, `distance`, `count`, `locationName`

Eigene (app-spezifisch): `day`, `habitTargetValue`, `habitProgressValue`, `weight`, `perceivedExertion`, `energy`, `protein`, `carbohydrate`, `fat`, `fiber`, `sugar`, `sodium`, `servingSize`, `bodyWeight`, `bodyFatPercentage`, `muscleMass`, `bodyHeight`, `bodyCircumference`, `energyLevel`, `mood`, `sleepQuality`, `stressLevel`

---

## Bewusst nicht exportierte Daten

### Ganze Entitäten

| Modell | Grund |
|---|---|
| `UserProfile` | Reine App-Einstellungen (Name, Erscheinungsbild, Ziele, Ruhezeiten, Kaufzustand). Enthält `nutritionGoalsData` (Zielwerte) und keine Historie. |
| `Companion`, `AccessoryOwnership` | Gamification-Zustand (XP, Münzen, Accessoires) – abgeleiteter Spielstand ohne Analytewert. |
| `GymExercise` | Verfügbare Übungen pro Studio – reine Studio-Konfiguration. |
| `GymEquipment`, `EquipmentExercise` | Geräte-Layout und Geräte-Zuordnungen im Studio. |
| `FloorPlan`, `FloorZone`, `WallSegment` | Technische Zeichnungsdaten des Studio-Grundrisses. |

### Kategorien von Daten

* **Fotos/Fortschrittsbilder:** keine Assets, keine Pfade (`BodyProgressEntry.photoPaths`).
* **UI-Zustände:** Farben, Icons, `sortOrder`-Prioritäten (teilweise trotzdem im Datensatz enthalten, aber ohne Schema-Beschreibung), Favoriten-Markierungen, Einklapp-Zustände.
* **Erinnerungszeiten:** `Habit.reminderTime`, `Supplement.reminderTimes` (nur für lokale Benachrichtigungen relevant).
* **Zugangsdaten/Käufe:** StoreKit-, Entitlement- und Abo-Daten werden nie exportiert.
* **HealthKit-Daten:** in Apple Health gespiegelte Daten liegen dort vor und werden nicht über Unio bereitgestellt.
* **Abgeleitete Kennzahlen:** Volumen, Punktestände, Streaks, Nährwertsummen, Wohlfühl-Score etc. – Unio bildet sie aus Rohdaten.

## Export-Zeitpunkte

Ein vollständiger Export wird erstellt bzw. eingeplant (Debounce: 2 Sekunden):

* nach dem Erstellen, Bearbeiten oder Löschen von Daten in den Services (Habits, Gruppen, Routinen, Workouts, Sessions, Sätzen, Plänen, Ernährung, Supplementen, Körpermessungen, Wellness, Studios, Wald/Bäume),
* nach einem Backup-Import,
* beim App-Start,
* beim Wechsel der App in den Hintergrund (sofort),
* manuell über **Einstellungen → Unio → Export jetzt aktualisieren**.

## Steuerung durch den Nutzer

Einstellungen → Unio:

* **Daten für Unio bereitstellen** – Toggle, standardmäßig aktiv (`UserDefaults`-Schlüssel `unioExportEnabled`).
* Anzeige von letztem Export-Zeitpunkt und Anzahl exportierter Datensätze (aus dem Manifest gelesen).
* **Export jetzt aktualisieren** – schreibt einen neuen vollständigen Snapshot.
* **Unio-Integration deaktivieren & Daten löschen** – entfernt `Unio/v1/sources/thrivewood/` vollständig; ThriveWood-Daten bleiben unberührt.

Fehler beim Export blockieren niemals die primäre App-Funktion; die ThriveWood-Datenbank bleibt immer die Source of Truth.
