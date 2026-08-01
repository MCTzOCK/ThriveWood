# FEATURES.md — Ideen für neue Features

> Dieses Dokument ergänzt die `ROADMAP.md` und `BODY_PROGRESS_PLAN.md`.  
> Hier stehen nur Ideen, die **noch nicht** in der Roadmap oder im Body-Progress-Plan beschrieben sind.  
> Fokus: **Sport-Bereich** (Priorität), danach alle anderen Domains.

---

## 🏋️ Sport & Workout (Priorität 1)

### 1. 1RM-Rechner & Kraftstandards 🟢🆕
**Was:** Berechne das geschätzte One-Rep-Max aus jedem Satz (Epley-Formel) und vergleiche es mit Kraftstandards (Anfänger, Fortgeschritten, Elite) nach Körpergewicht.
- Formel: `1RM = Gewicht × (1 + Wiederholungen / 30)`
- Kraftlevel-Datenbank pro Übung (Bankdrücken, Kniebeuge, Kreuzheben, Schulterdrücken)
- Anzeige: „Geschätztes 1RM: 92,5 kg — Fortgeschritten (Top 30%)“
- Progression: 1RM-Verlauf als Chart

### 2. Plattenrechner 🟢🆕
**Was:** Bei Langhantel-Übungen automatisch berechnen, welche Gewichtsscheiben aufgelegt werden müssen.
- Eingabe: Zielgewicht (z. B. 87,5 kg), Stangen-Gewicht (20 kg)
- Ausgabe: „2× 20 kg + 2× 10 kg + 2× 2,5 kg + 2× 1,25 kg pro Seite“
- Konfigurierbare verfügbare Scheiben (Standard: 25, 20, 15, 10, 5, 2,5, 1,25 kg)
- Ein-Knopf-Zugriff aus dem `SetRow` während der aktiven Session

### 3. Aufwärmsatz-Rechner 🟢🆕
**Was:** Vor dem ersten Arbeitssatz automatisch Aufwärmsätze vorschlagen.
- Basierend auf dem Arbeitsgewicht des ersten Satzes:
  - 50% × 8–10 (allgemeines Aufwärmen)
  - 60% × 5
  - 70% × 3
  - 80% × 2
  - 90% × 1 (optional)
- Diese Sätze werden als „Aufwärmsatz“ markiert und in der Session-Übersicht gruppiert
- `targetWeight`-Feld nutzen, das bereits im `WorkoutExercise`-Modell existiert

### 4. Workout-Timer-Modi 🟡🆕
**Was:** Verschiedene Trainings-Timer neben dem bestehenden Pausen-Timer.
- **EMOM** (Every Minute on the Minute): 60-Sekunden-Zyklus mit akustischem Signal
- **AMRAP** (As Many Rounds As Possible): Countdown-Timer (z. B. 20 Minuten) mit Rundenzähler
- **Tabata**: 20 Sekunden Arbeit / 10 Sekunden Pause, 8 Runden
- **Intervall-Timer**: Frei konfigurierbare Arbeits-/Pausen-Intervalle
- Integration in `ActiveSessionViewV2` als alternative Timer-Overlay

### 5. Workout-Streaks & Kalender-Heatmap 🟢🆕
**Was:** Visuelle Darstellung der Trainingstage als Heatmap (wie die bestehende Habit-Heatmap).
- Streak-Zähler: „5 Tage Training in Folge“
- Kalender-Ansicht: Farbcodierte Tage nach Trainingsvolumen
- Bestehende `AnalyticsService`-Infrastruktur nutzen
- Widget: „Workout-Streak“ Widget

### 6. Bodyweight-Progressionen 🟡🆕
**Was:** Automatische Erkennung, wann eine Körpergewichts-Übung zu einfach wird, und Vorschlag der nächsten Progression.
- Datenbank mit Progressions-Ketten:
  - Liegestütze → Diamant-Liegestütze → Einarmige Liegestütze
  - Kniebeugen → Pistol Squats
  - Klimmzüge → Muscle-Ups
- Trigger: 3×12+ Wiederholungen über 3 aufeinanderfolgende Sessions
- Vorschlag erscheint nach Session-Ende als Card

### 7. Split-Erkennung & Visualisierung 🟡🆕
**Was:** Automatische Analyse der vergangenen Workouts, um das Trainings-Split zu erkennen.
- Erkennt: PPL, Upper/Lower, Bro-Split, Ganzkörper, Push/Pull
- Visualisierung: Kalender-Ansicht mit farbcodierten Tagen
- Body-Map-Ansicht: Welche Muskeln an welchem Tag trainiert werden
- Warnung: Wenn ein Muskel zu oft oder zu selten trainiert wird

### 8. Volumen-Meilensteine & Live-Feedback 🟢🆕
**Was:** Während der Session Meilenstein-Benachrichtigungen anzeigen.
- „1.000 kg Gesamtvolumen heute!“ als Toast/HUD
- „10.000 kg Gesamtvolumen diesen Monat!“
- „100. Trainingseinheit abgeschlossen!“
- Integration mit bestehendem `AchievementHUD`-System

### 9. Drop-Set, Myo-Rep & Rest-Pause Tracking 🟡🆕
**Was:** Erweiterte Satz-Typen jenseits von normalen Sätzen.
- **Drop-Set**: Satz mit automatisch reduziertem Gewicht (z. B. 3 Drops)
- **Myo-Reps**: Aktivierungssatz + 3–5 Mini-Sätze mit 3–5 Atemzügen Pause
- **Rest-Pause**: Ein Satz, kurze Pause (15–20 sek), weiter bis zum Muskelversagen
- UI: Satz-Gruppierung mit visueller Kennzeichnung des Satztyps
- `SetEntry`-Modell um `setType`-Enum erweitern

### 10. Workout-Notizen-Vorlagen 🟢🆕
**Was:** Vordefinierte Textbausteine für Session-Notizen, schnell auswählbar.
- „Heute wenig Energie“
- „Top-Form heute“
- „Gelenkschmerzen in …“
- „Neue Übung ausprobiert“
- „Gewicht erhöht“
- Eigene Vorlagen erstellbar und als Favoriten markierbar

### 11. Übungs-Vergleich & Alternativen 🟡🆕
**Was:** Zwei Übungen nebeneinander vergleichen und intelligente Alternativen vorschlagen.
- Side-by-Side-Vergleich: Muskelgruppen, Volumen-Trend, PR-Chart
- Alternativ-Vorschläge basierend auf:
  - Gleiche primäre Muskelgruppe
  - Verfügbares Equipment (konfigurierbar)
  - Muskel-Erholungsstatus (erschöpfte Muskeln vermeiden)
- „Langhantel-Bankdrücken → Kurzhantel-Bankdrücken (Bizeps noch in Erholung)“

### 12. Cardio-Zonen & Herzfrequenz-Tracking 🟡🆕
**Was:** Herzfrequenz-Zonen aus HealthKit/Apple Watch in Echtzeit während Cardio-Übungen anzeigen.
- 5 Zonen farbcodiert (Regeneration, Fettverbrennung, Aerob, Anaerob, Maximal)
- Live-Anzeige im `ExerciseTrackerView`-Overlay
- Nach dem Workout: Zeit-in-Zone-Analyse
- HealthKit `HKWorkout`-Daten nutzen

### 13. Trainingsplan-Assistent 🟡🆕
**Was:** Geführter Wizard zum Erstellen eines Trainingsplans.
- Schritt 1: Ziel wählen (Kraftaufbau, Hypertrophie, Ausdauer, Fettabbau)
- Schritt 2: Verfügbare Tage pro Woche (2–6)
- Schritt 3: Equipment (Langhantel, Kurzhanteln, Kabelzug, Maschinen, Bodyweight)
- Schritt 4: Split-Vorschlag mit Übungsauswahl
- Baut auf bestehendem `TrainingsPlanService` und `AIPlanGeneratorView` auf

### 14. Übungs-Bibliothek: Video-Integration 🟡🆕
**Was:** YouTube-Videos oder gebundelte Animationen für Übungen einbinden.
- `Exercise.images`-Array wird bereits im Modell unterstützt
- YouTube-Integration: Einbettung oder Deep-Link zu Übungsvideos
- Lokale Animationen (Lottie/JSON) für die Top-20-Übungen
- `ExerciseDetailsSheet` um Video-Tab erweitern

### 15. Mobility-Screening 🟡🆕
**Was:** Eingebaute Beweglichkeitstests mit Bewertung.
- Shoulder Flexion Test
- Sit-and-Reach
- Deep Squat Assessment
- Thoracic Rotation Test
- Ergebnisse als Score (0–100) mit Verbesserungsvorschlägen
- Mobilitäts-Verlauf als Chart

### 16. Verletzungs-Log 🟢🆕
**Was:** Verletzungen dokumentieren und Trainingsanpassungen vorschlagen.
- Eintrag: Körperregion, Schweregrad (1–5), Datum, Notizen
- Automatische Markierung betroffener Muskelgruppen
- Warnung vor Übungen, die die verletzte Region belasten
- Recovery-Status: „Schulter: 3 von 4 Wochen Erholung“
- Neues `Injury` SwiftData-Modell

### 17. Workout-Wetter-Integration 🟢🆕
**Was:** Für Outdoor-Cardio: Wettervorhersage einblenden.
- Anzeige auf der Sport-Startseite: „Heute 18°C, sonnig — perfekt für einen Lauf“
- Vorschlag: Outdoor-Übungen bei gutem Wetter priorisieren
- WeatherKit von Apple nutzen (keine API-Keys nötig)

### 18. Stretching-Routinen 🟡🆕
**Was:** Geführte Pre- und Post-Workout-Stretching-Routinen.
- Vorlagen: Oberkörper, Unterkörper, Ganzkörper, Rücken
- Dauer: 5, 10, 15 Minuten
- Schritt-für-Schritt mit Timer pro Dehnung
- Integration in Trainingsplan: „Stretching“ als Übungstyp

### 19. Apple Watch: Herzfrequenzzonen & Haptik 🟡🆕
**Was:** (Ergänzung zur Watch-App in der Roadmap) Spezifische HR-Features.
- Haptisches Feedback bei Zonenwechsel
- Vibration bei Satz-Ende (Rest-Timer abgelaufen)
- Komplikation: Aktuelle Herzfrequenz-Zone
- `HKWorkoutSession` direkt von der Watch starten

### 20. Trainings-Musik-Playlist 🟡🆕
**Was:** Apple Music Integration für Workout-Playlists.
- Playlist-Vorschläge basierend auf Trainingsart (Krafttraining → Metal/Hip-Hop, Cardio → Electronic)
- BPM-Analyse für Cardio (Lauf-Kadenz)
- Mini-Player in der ActiveSessionView
- `MusicKit` / `MPMusicPlayerController` nutzen

---

## 🍎 Ernährung (Priorität 2)

### 21. Rezept-Vorschläge 🟡🆕
**Was:** Basierend auf verbleibenden Makros des Tages Rezepte vorschlagen.
- „Dir fehlen noch 30g Protein — wie wär's mit einem Proteinshake?“
- Rezept-Datenbank mit Nährwerten
- Integration mit `NutritionGoalEditor`-Zielen

### 22. Barcode-Scan: Verlauf & Favoriten 🟢🆕
**Was:** Häufig gescannte Produkte als Favoriten speichern.
- „Zuletzt gescannt“-Sektion im `FoodSearchView`
- Favoriten mit einem Tap loggen
- Barcode-Scan-Historie

### 23. Mahlzeiten-Fotos 🟢🆕
**Was:** Foto zu jeder Mahlzeit hinzufügen (visuelles Ernährungstagebuch).
- Kamera-Integration im `FoodLogSheet`
- Galerie-Ansicht: „Meine Mahlzeiten dieser Woche“
- `Meal`-Modell um `imageData` erweitern

### 24. Fasten-Tracker 🟡🆕
**Was:** Intermittent Fasting Tracking.
- Fasten-Fenster konfigurierbar (16:8, 18:6, 20:4, OMAD)
- Live-Timer: „Noch 3:45 bis zum Fastenbrechen“
- Widget: Fasten-Status
- Neues `FastingWindow` SwiftData-Modell

---

## 🌲 Forest & Gamification

### 25. Forest-Theme: Jahreszeiten 🟢🆕
**Was:** Der Forest-Hintergrund ändert sich mit der echten Jahreszeit.
- Frühling: Blühende Bäume, grüner Hintergrund
- Sommer: Sattes Grün, Sonnenschein
- Herbst: Orange/Rote Blätter
- Winter: Schneebedeckte Bäume
- Option: Manuelles Theme in den Einstellungen

### 26. Forest-Besucher: Tiere & Charaktere 🟡🆕
**Was:** Bei bestimmten Meilensteinen erscheinen Tiere im Wald.
- 10 Bäume → Vogel
- 25 Bäume → Eichhörnchen
- 40 Bäume → Reh
- 64 Bäume → Eule
- Tiere haben kleine Animationen (flattern, hüpfen)
- Jedes Tier vergibt einmalig Bonuspunkte

### 27. Forest-Pflege: Dünger & Boosts 🟢🆕
**Was:** Spezielle Items, die das Baumwachstum beschleunigen.
- „Dünger“: Baum wächst doppelt so schnell für 7 Tage (Pro-Feature)
- „Regenwolke“: Einmalig +2 Wachstumspunkte (kostet 10 Punkte)
- „Sonne“: +1 Wachstumspunkt für alle Bäume (kostet 50 Punkte)
- Items in der Forest-UI einlösbar

### 28. Forest-Export & Sharing 🟢🆕
**Was:** Den eigenen Wald als Bild exportieren und teilen.
- Screenshot ohne UI-Elemente rendern
- Teilen via ShareSheet (Instagram-Story-Format, 9:16)
- „Mein ThriveWood-Wald — 42 Bäume, 1.250 Punkte“

---

## 📊 Analytics & Insights

### 29. Wöchentlicher Report 🟡🆕
**Was:** Jeden Sonntag eine Zusammenfassung als Push-Nachricht.
- „Diese Woche: 85% Habits erfüllt, 3 Workouts, 2 neue PRs“
- Visuelle Zusammenfassung als Card in der Analytics-View
- PDF-Export des Reports (`PDFService` existiert bereits)

### 30. Korrelations-Analyse 🟡🆕
**Was:** Zusammenhänge zwischen verschiedenen Datenquellen erkennen.
- „An Tagen mit 7+ Stunden Schlaf erfüllst du 20% mehr Habits“
- „Nach Beintraining ist deine Schrittzahl am Folgetag 15% niedriger“
- HealthKit-Schlafdaten + Habit-Daten + Workout-Daten korrelieren

### 31. Jahresrückblick 🟡🆕
**Was:** „Dein ThriveWood-Jahr“ als interaktive Zusammenfassung.
- Meisttrainierte Muskelgruppe
- Meistgeloggte Übung
- Gesamtvolumen des Jahres
- Längster Streak
- Meistgewachsener Baum
- Teilbar als Story/Post

---

## 🧠 Wellness & Mindset

### 32. Täglicher Mood-Check 🟢🆕
**Was:** Einmal täglich Stimmung erfassen (1–5 Emoji-Skala).
- Widget: Mood-Check-in
- Korrelation: Mood vs. Workout-Performance, Habit-Completion
- `MoodEntry` SwiftData-Modell

### 33. Atemübungen 🟢🆕
**Was:** Geführte Atemübungen (Box Breathing, 4-7-8, etc.).
- Animation: Kreis, der sich ausdehnt/zusammenzieht
- Haptik bei jedem Atemzug
- HealthKit: „Mindful Minutes“ schreiben
- Dauer: 1, 3, 5 Minuten

### 34. Dankbarkeitstagebuch 🟢🆕
**Was:** Tägliche Eingabe von 1–3 Dingen, für die man dankbar ist.
- Optionaler Reminder (z. B. 20:00 Uhr)
- Streak-Tracking
- Rückblick: „Deine Dankbarkeitseinträge diesen Monat“

---

## 👥 Social (Ergänzungen zu SOCIAL.MD)

### 35. QR-Code-Profil 🟢🆕
**Was:** (In SOCIAL.MD beschrieben) — konkretes Feature.
- QR-Code mit öffentlichem Profil (Name, Forest-Level, Punkte, Lieblingsübung)
- Im Profil-Tab erreichbar
- Scannen über die ThriveWood-Kamera oder Code-Scanner

### 36. Community-Challenges 🟡🆕
**Was:** Monatlich wechselnde Challenges für alle Nutzer.
- „Februar: 20 Workouts in 28 Tagen“
- „März: 100.000 Schritte“
- Fortschritt wird lokal getrackt, keine Server nötig
- Badge bei Abschluss

---

## ⚙️ App-Infrastruktur

### 37. Siri-Sprachbefehle 🟡🆕
**Was:** App Intents für schnelle Aktionen per Sprachbefehl.
- „Hey Siri, starte mein Oberkörper-Workout“
- „Hey Siri, logge mein Wasser-Habit“
- „Hey Siri, wie ist mein aktueller Streak?“
- `AppIntents`-Framework (iOS 17+)

### 38. Dynamic Island 🟢🆕
**Was:** Live Activity in der Dynamic Island während des Workouts.
- Kompakte Anzeige: Timer + aktuelle Übung
- Erweitert: Letzter Satz + Pausen-Timer
- Ergänzt die bestehende Lock-Screen Live Activity

### 39. Kurzbefehle (Shortcuts) 🟡🆕
**Was:** Shortcuts-Integration für Power-User.
- „Workout beenden & Protein-Shake loggen“
- „Morgenroutine: Meditation habit + Wasser habit + Mood check-in“
- Verkettung mehrerer App-Aktionen in einem Shortcut

### 40. Spotlight-Integration 🟢🆕
**Was:** Übungen und Workouts in Spotlight durchsuchbar machen.
- `CSSearchableItem` / `CoreSpotlight`
- „Bankdrücken“ in Spotlight → direkt zur PR-Ansicht
- Indexierung: Übungen, Workouts, Trainingspläne

---

## 📝 Quick Wins (Aufwand < 1 Tag)

| Nr. | Feature | Begründung |
|-----|---------|------------|
| Q1 | **1RM-Anzeige im SetRow** | `SetRow` zeigt bereits Gewicht × Wiederholungen — geschätztes 1RM daneben ist ein Einzeiler |
| Q2 | **Plattenrechner** | Reine Logik, keine neuen Modelle nötig. Sheet mit `availablePlates`-Array |
| Q3 | **Workout-Streak in Analytics** | `AnalyticsService` hat bereits Workout-Daten, nur Streak-Logik fehlt |
| Q4 | **Warmup-Sätze markieren** | Checkbox „Aufwärmsatz“ im `SetRow`, Gruppierung in `SessionDetailView` |
| Q5 | **Mood-Check-in** | Ein `MoodEntry`-Model + Slider-View + Analytics-Kachel |
| Q6 | **Forest-Jahreszeiten** | `ForestBackground`-View mit saisonaler Farbpalette |
| Q7 | **Spotlight-Indexierung** | `CSSearchableIndex` im `AppDelegate`/`SceneDelegate` |
| Q8 | **Dynamic Island Live Activity** | Bestehende `WorkoutLiveActivityManager`-Infrastruktur um Dynamic Island ergänzen |

---

> **Letzte Aktualisierung:** 2026-07-22