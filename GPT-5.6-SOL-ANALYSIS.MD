# ThriveWood – umfassende zukünftige Feature-Roadmap

ThriveWood ist vom Umfang her bereits deutlich mehr als ein klassischer Habit-Tracker. Die App vereint inzwischen Gewohnheiten, Krafttraining, Trainingsplanung, Ernährung, Supplements, Körperfortschritt, Wellness, Gamification und HealthKit.

Die größte Chance liegt deshalb meiner Meinung nach **nicht darin, einfach immer mehr isolierte Funktionen hinzuzufügen**, sondern die vorhandenen Bereiche zu einem geschlossenen System zu verbinden:

> **Planen → Ausführen → Auswerten → Anpassen → Erholen → Fortschritt sichtbar machen**

Gerade der Sport-Tab kann zum stärksten täglichen Bindungsfaktor der App werden. Er sollte langfristig vier zentrale Fragen beantworten:

* Was soll ich heute trainieren?
* Wie kann ich das Training mit möglichst wenig Reibung erfassen?
* Habe ich mich verbessert?
* Was sollte ich beim nächsten Training anders machen?

## Prioritätslegende

* **P0 – Vertrauensbasis:** Muss zuverlässig funktionieren, bevor komplexere Funktionen folgen.
* **P1 – Hoher Nutzwert:** Erhöht Retention und verbessert das tägliche Training deutlich.
* **P2 – Differenzierung:** Macht ThriveWood gegenüber gewöhnlichen Workout-Trackern besonders.
* **P3 – Expansion:** Sinnvoll, aber erst nach einem sehr stabilen Kern.
* **S/M/L/XL:** Grobe relative Einschätzung des Implementierungsaufwands.

## Meine 20 wichtigsten nächsten Features

| Rang | Feature | Begründung | Priorität/Aufwand |
|---:|---|---|---|
| 1 | Crash-sichere aktive Trainingseinheit | Kein Nutzer darf ein laufendes Training durch App-Neustart, Speicherbereinigung oder Absturz verlieren | P0/M |
| 2 | Trainingskalender mit flexibler Planung | Verbindet Trainingspläne mit dem tatsächlichen Alltag | P0/L |
| 3 | Nachträgliches vollständiges Bearbeiten von Sessions | Falsche Sets, Übungen oder Zeiten müssen korrigierbar sein | P0/M |
| 4 | Historische Werte direkt neben jedem Set | Der wichtigste Kontext während des Trainings: „Was habe ich letztes Mal gemacht?“ | P0/S |
| 5 | Satztypen, RIR und Satz-RPE | Grundlage für sinnvolle Progressions- und Erholungsberechnungen | P1/M |
| 6 | Übungsalternativen und Substitutionen | Löst das reale Problem besetzter Geräte, Schmerzen oder fehlender Ausstattung | P1/M |
| 7 | Aufwärmsatz-Generator und Scheibenrechner | Sehr konkreter Alltagsnutzen mit überschaubarem Aufwand | P1/M |
| 8 | Regelbasierte Progression | ThriveWood sagt zuverlässig, was beim nächsten Training gesteigert werden sollte | P1/L |
| 9 | Robustes PR- und e1RM-System | Macht Fortschritt sichtbar, ohne nur auf das Trainingsvolumen zu schauen | P1/M |
| 10 | Effektive Sätze pro Muskel und Woche | Sinnvollere Muskelanalyse als reine Gesamttonnage | P1/L |
| 11 | Readiness- und Muskelkater-Check-in | Verbindet Wellness, HealthKit, Erholung und Trainingsplanung | P1/M |
| 12 | Adaptiver Trainingsplan | Passt Volumen, Intensität und Übungsauswahl an Fortschritt und Erholung an | P2/XL |
| 13 | Apple-Watch-Begleit-App | Reduziert die Smartphone-Nutzung während des Trainings massiv | P2/XL |
| 14 | Maschinenprofile mit persönlichen Einstellungen | Sitzposition, Griff, Stack und PRs unterscheiden sich je Gerät und Gym | P2/M |
| 15 | Gym-Routen und Gerätealternativen | Nutzt den vorhandenen Gym Plan Builder als echtes Alleinstellungsmerkmal | P2/L |
| 16 | Einheitlicher Wochenbericht | Verbindet Sport, Habits, Wellness, Ernährung und Körperfortschritt | P1/M |
| 17 | Food Diary fertigstellen | Der vorhandene Nutrition-Bereich wirkt sonst dauerhaft unvollständig | P0/M |
| 18 | Supplement-Tagesliste fertigstellen | Das Datenmodell und die Reminder existieren bereits; die Kernoberfläche fehlt | P0/S–M |
| 19 | Interaktive Widgets und Live-Activity-Aktionen | Häufige Aktionen ohne vollständiges Öffnen der App | P1/M |
| 20 | Sync- und Datenschutz-Center | Nutzer müssen sehen können, ob ihre sensiblen Daten sicher synchronisiert wurden | P0/M |

# Besonderer Fokus: Sport-Tab

## Empfohlenes Zielbild für den Sport-Tab

Der Sport-Tab sollte nicht hauptsächlich eine Sammlung von Workouts, Plänen, Sessions und Analyse-Links sein. Er sollte sich wie ein **persönlicher Trainingsassistent** anfühlen.

Ich würde ihn konzeptionell in vier Ebenen gliedern:

* **Heute:** Nächste Trainingseinheit, Readiness, Muskel-Erholung und Schnellstart.
* **Trainieren:** Aktive Session, Workout-Vorlagen, freies Training und Übungsbibliothek.
* **Plan:** Kalender, aktiver Trainingsplan, Trainingsblöcke und Anpassungen.
* **Fortschritt:** PRs, Muskelbelastung, Übungsentwicklung und Berichte.

Diese Ebenen müssen nicht als vier weitere permanente Tabs umgesetzt werden. Eine starke Sport-Startseite mit klaren Navigationseinträgen dürfte übersichtlicher sein.

## Sport-Startseite und tägliche Trainingsentscheidung

* **Heutiges Workout als primäre Karte – P0:** Die Startseite zeigt das laut aktivem Plan vorgesehene Workout, die geschätzte Dauer, den vorgesehenen Trainingsort und einen großen Start-Button.

* **Globale „Training fortsetzen“-Leiste – P0:** Eine aktive Session sollte ähnlich wie ein Mini-Player appweit sichtbar bleiben. Der Nutzer kann während des Trainings in die Übungsbibliothek, Einstellungen oder Analyse wechseln und jederzeit zurückspringen.

* **Wochenstreifen für geplante Sessions – P1:** Eine kompakte Kalenderansicht zeigt absolvierte, geplante, verschobene und ausgelassene Trainingstage.

* **15-Sekunden-Readiness-Check-in – P1:** Vor dem Training werden Energie, Motivation, Muskelkater, Schlaf und eventuell Schmerzen abgefragt. Die Eingabe sollte überspringbar und extrem schnell sein.

* **Pre-Workout-Briefing – P1:** Vor dem Start erhält der Nutzer eine Zusammenfassung:
    * Welche Muskeln werden trainiert?
    * Welche Übungen stehen an?
    * Was wurde beim letzten Mal erreicht?
    * Bei welchen Übungen ist eine Steigerung vorgesehen?
    * Gibt es Erholungs- oder Belastungshinweise?

* **Geschätzte Trainingsdauer – P1:** Berechnung aus Ziel-Sätzen, durchschnittlicher Satzdauer, Pausen und historischen Session-Daten.

* **Rest-Day-Modus – P1:** An trainingsfreien Tagen zeigt der Sport-Tab keine leere Oberfläche, sondern Erholung, Mobilität, Spaziergang, Schlafziel oder eine kurze Recovery-Routine.

* **Umgang mit verpassten Trainingstagen – P1:** Statt einen Montag-Plan einfach zu verlieren, sollte ThriveWood anbieten:
    * Workout auf den nächsten Tag verschieben
    * Restliche Woche neu verteilen
    * Einheit überspringen
    * Plan als fortlaufende A/B/C-Sequenz weiterführen

* **Flexible Plansequenz statt nur Wochentage – P1:** Viele Nutzer trainieren nicht zuverlässig an festen Tagen. Zusätzlich zum Wochenplan sollte ein Modus „immer mit der nächsten Einheit fortfahren“ existieren.

* **Schnellstarts – P1:** Beispiele wären „Freies Krafttraining“, „Letztes Workout wiederholen“, „30-Minuten-Training“, „Cardio“, „Mobilität“ oder ein favorisiertes Workout.

* **Wochenziel und Planerfüllung – P1:** Nicht nur die Anzahl der Sessions, sondern auch absolvierte Soll-Sätze, Trainingsminuten und Plan-Adherence anzeigen.

* **Kontextabhängiges Gym – P2:** Das zuletzt verwendete oder manuell ausgewählte Gym bestimmt verfügbare Geräte, Übungsalternativen und Maschinenprofile.

* **Persönliches Trainingsziel – P2:** Auf der Startseite kann ein aktuelles Ziel stehen, beispielsweise „100 kg Bankdrücken“, „10 Klimmzüge“ oder „dreimal pro Woche trainieren“.

* **Trainingsempfehlung bei wenig Zeit – P2:** Wenn nur 20 oder 30 Minuten verfügbar sind, kürzt ThriveWood das geplante Workout intelligent, ohne zufällig wichtige Übungen zu entfernen.

## Live-Training und Set-Erfassung

### Zuverlässigkeit und Session-Lebenszyklus

* **Autosave nach jeder Aktion – P0:** Jeder hinzugefügte, bearbeitete oder gelöschte Satz sollte unmittelbar gespeichert werden.

* **Wiederherstellung nach App-Neustart – P0:** Startzeit, aktuelle Übung, laufender Timer, Rest-Timer, nicht abgeschlossene Eingaben und Session-Reihenfolge müssen wiederhergestellt werden.

* **Session-Snapshot – P0:** Eine gestartete Session sollte einen unveränderlichen Snapshot der damaligen Workout-Struktur erhalten. Spätere Änderungen an der Vorlage dürfen historische Einheiten nicht verändern.

* **Entwurf statt sofortiger Abschluss – P0:** Eine Session sollte als Entwurf gespeichert werden können, wenn der Nutzer sie nicht sofort fertigstellen möchte.

* **Unterbrechungsmodus – P1:** Training pausieren, beispielsweise bei einem längeren Telefonat oder einer Geräteunterbrechung. Pausenzeit und echte Trainingsdauer können getrennt dargestellt werden.

* **Duplikat-Erkennung – P1:** Falls dieselbe Session durch Sync-Probleme oder wiederholtes Abschließen doppelt angelegt wurde, sollte ThriveWood davor warnen.

* **Nachträgliche Session-Korrektur – P0:** Übungen hinzufügen oder entfernen, Satzwerte ändern, Zeit korrigieren, RPE ergänzen und das verwendete Gym wechseln.

* **Änderungsnachweis – P2:** Optional kann markiert werden, dass eine abgeschlossene Session nachträglich bearbeitet wurde. Das hilft bei PRs und Analysen.

### Schnellere Eingabe

* **Vorherige Leistung direkt in der Satzzeile – P0:** Zum Beispiel `80 kg × 8` vom letzten vergleichbaren Training, ohne ein weiteres Sheet zu öffnen.

* **Ziel, letzter Wert und aktueller Wert gleichzeitig – P1:** Der Nutzer sieht sofort:
    * Ziel aus dem Plan
    * Leistung der letzten Session
    * aktuellen Eintrag

* **Ein-Tap-Wiederholung des letzten Satzes – P1:** Gewicht und Wiederholungen des vorherigen Satzes übernehmen.

* **Automatisches Vorausfüllen – P1:** Der nächste Satz übernimmt sinnvolle Werte des vorherigen Satzes, bleibt aber zunächst unbestätigt.

* **Optimierter Nummernblock – P1:** Gewicht, Wiederholungen, RIR und Dauer müssen mit möglichst wenigen Fokuswechseln erfasst werden.

* **Automatischer Feldwechsel – P1:** Nach Eingabe der Wiederholungen springt der Fokus zum Gewicht oder direkt zum Abschluss-Button.

* **Undo für Set-Aktionen – P1:** Gelöschte oder versehentlich abgeschlossene Sätze sollten kurz rückgängig gemacht werden können.

* **Plausibilitätswarnungen – P1:** Bei einem ungewöhnlichen Sprung von beispielsweise 80 auf 800 kg sollte ThriveWood nachfragen, statt sofort einen falschen PR zu erzeugen.

* **Session-weite Gewichtsänderung – P2:** Alle noch offenen Arbeitssätze einer Übung gleichzeitig um einen bestimmten Wert erhöhen oder reduzieren.

* **Gestensteuerung – P2:** Wischen zum Abschließen, Duplizieren oder Löschen eines Satzes, sofern die Aktionen weiterhin zugänglich und fehlertolerant bleiben.

* **Spracheingabe – P2:** Kurze Eingaben wie „acht Wiederholungen mit achtzig Kilo, zwei RIR“ könnten während des Trainings hilfreich sein.

### Erweiterte Satzdaten

* **Satztypen – P1:** Zusätzlich zu Warm-up:
    * Arbeitssatz
    * Top Set
    * Back-off Set
    * Drop Set
    * AMRAP
    * Failure Set
    * Rest-Pause
    * Myo-Reps
    * Cluster Set
    * Technik- oder Vorbereitungssatz

* **RIR pro Satz – P1:** „Reps in Reserve“ ist für Progression und Belastungssteuerung meist wertvoller als nur ein Session-RPE.

* **Satz-RPE – P1:** Alternativ oder ergänzend zu RIR, konfigurierbar je Nutzer.

* **Tempo – P2:** Eingabe oder Zielvorgabe wie exzentrische Dauer, Pause und konzentrische Phase.

* **Teilwiederholungen – P2:** Separate Erfassung von vollständigen und partiellen Wiederholungen.

* **Unilaterale Übungen – P1:** Linke und rechte Seite getrennt erfassen oder einen Satz für beide Seiten bestätigen.

* **Körpergewichtsübungen – P1:** Körpergewicht, Zusatzgewicht und Assistenz sollten sauber unterschieden werden. Ein Klimmzug mit 20 kg Zusatzgewicht darf nicht wie eine gewöhnliche 20-kg-Übung behandelt werden.

* **Assistance statt nur Assisted Reps – P2:** Bei unterstützten Klimmzügen oder Dips sollte die tatsächliche Assistenzlast erfasst werden können.

* **Distanz-, Pace- und Intervall-Sätze – P2:** Für Cardio-Übungen sollten einzelne Intervalle mit Dauer, Distanz, Pace und optionaler Herzfrequenz erfasst werden.

* **Bewegungsumfang – P3:** Optionaler Hinweis auf reduzierte oder vollständige Range of Motion, vor allem für persönliche Vergleichbarkeit.

### Aufwärmen und Gewichtsaufbau

* **Aufwärmsatz-Generator – P1:** Basierend auf Arbeitsgewicht, Übung, Trainingsstand und vorhandener Historie werden Ramp-up-Sätze vorgeschlagen.

* **Individuelle Aufwärmprofile – P2:** Nutzer können beispielsweise festlegen, dass sie beim Kniebeugen mehr Aufwärmsätze benötigen als bei Bizepscurls.

* **Scheibenrechner – P1:** Anzeige der benötigten Scheiben pro Seite anhand von:
    * Stangengewicht
    * Verschlüssen
    * verfügbaren Scheiben
    * Zielgewicht
    * kg- oder lb-System

* **Scheibenbestand pro Gym – P2:** Kleine Gewichtsschritte sind nur dann empfehlbar, wenn passende Scheiben im ausgewählten Studio vorhanden sind.

* **Barbell-Profile – P2:** Unterschiedliche Stangen mit 10, 15, 20 oder anderen Gewichten speichern.

* **Warm-up nicht in Arbeitsvolumen einrechnen – P0:** Warm-up-Sätze sollten klar von effektiven Sätzen, PRs und Muskelbelastung getrennt werden.

### Rest-Timer

* **Pausenziel pro Satztyp – P1:** Warm-up, Arbeitssatz, Superset und schweres Top Set dürfen unterschiedliche Standardpausen besitzen.

* **Intelligenter Rest-Timer – P2:** Die vorgeschlagene Pause kann anhand von RIR, Übungstyp und Belastung angepasst werden.

* **Automatischer Start nach Satzabschluss – P1:** Bereits vorhanden, sollte aber individuell deaktivierbar sein.

* **Timer-Steuerung aus der Live Activity – P1:** Verlängern, überspringen oder beenden, ohne die App vollständig zu öffnen.

* **Timer-Steuerung auf der Apple Watch – P2:** Haptische Benachrichtigung direkt am Handgelenk.

* **Mehrere Alarmprofile – P2:** Haptik, Ton, Sprache oder ausschließlich visuelle Rückmeldung.

* **Pausen-Adherence – P2:** Spätere Analyse, wie stark die tatsächlichen Pausen von den geplanten Pausen abweichen.

### Übungsänderungen während des Trainings

* **Übung spontan ersetzen – P1:** Besetztes Gerät, Schmerzen oder fehlendes Equipment sind normale Trainingssituationen.

* **Stimulusbasierte Alternativen – P2:** Ersatzübungen nach Zielmuskel, Bewegungsmuster, Equipment und Schwierigkeit sortieren.

* **Historie beim Ersatz erhalten – P1:** Der Austausch muss dokumentiert werden, ohne die ursprüngliche Workout-Vorlage automatisch zu überschreiben.

* **Änderung nur heute oder dauerhaft – P1:** Nach dem Austausch sollte ThriveWood fragen, ob die Änderung nur für diese Session oder für zukünftige Plantermine gilt.

* **Übungen spontan hinzufügen – P0:** Freie Zusatzübung während einer geplanten Session.

* **Übungen überspringen – P0:** Mit optionalem Grund wie „Gerät belegt“, „Zeitmangel“, „Schmerzen“ oder „bewusst gestrichen“.

* **Reihenfolge flexibel ändern – P1:** Planreihenfolge und tatsächliche Ausführungsreihenfolge separat speichern.

* **Superset auflösen oder erstellen – P1:** Superset-Strukturen während einer Session bearbeiten, ohne in den Workout-Editor zurückkehren zu müssen.

* **Circuit-Modus – P2:** Mehrere Übungen als Runde behandeln und Fortschritt nach Runden darstellen.

### Notizen, Technik und Wohlbefinden

* **Fixierte Übungsnotiz – P1:** Hinweise wie „Sitzposition 4“ oder „Griff eine Markierung breiter“ direkt bei jeder Ausführung anzeigen.

* **Session-spezifische Übungsnotiz – P1:** Beobachtungen nur für dieses Training erfassen.

* **Notiz pro Satz – P2:** Sinnvoll bei Technikproblemen, Griffänderungen oder ungewöhnlichen Bedingungen.

* **Schmerz- oder Beschwerden-Flag – P1:** Körperregion und Intensität dokumentieren, ohne daraus eine medizinische Diagnose abzuleiten.

* **Technik-Cues – P2:** Kurze, vom Nutzer auswählbare Hinweise vor dem ersten Satz.

* **Form-Video verknüpfen – P3:** Eigene kurze Videos mit einer Übung oder Session verbinden, vorzugsweise lokal und datenschutzfreundlich.

* **Maschineneinstellungen – P1:** Sitz, Rückenlehne, Griff, Sicherheitsstopps, Pin und individuelle Notizen pro Gerät speichern.

* **Trainingsgefühl nach Übung – P2:** Optionaler Stimulus-, Stabilitäts- oder Gelenkkomfort-Score, um langfristig bessere Übungsalternativen zu finden.

### Session-Abschluss

* **Abschlussprüfung – P0:** Fehlende oder unbestätigte Sätze, ungewöhnliche Werte und versehentlich offene Übungen vor dem Speichern anzeigen.

* **Ausführliche Zusammenfassung – P1:** Dauer, Volumen, Arbeitssätze, PRs, Muskelbelastung, durchschnittliche RIR, Pausenzeiten und Planerfüllung.

* **Persönlicher Session-Score – P2:** Kein pauschaler „gut/schlecht“-Score, sondern getrennte Dimensionen wie Planerfüllung, Leistungsfortschritt, Belastung und subjektives Gefühl.

* **Post-Workout-Check-in – P1:** Session-RPE, Energie danach, Schmerzen und allgemeine Qualität.

* **Automatische PR-Erklärung – P1:** Nicht nur „neuer PR“, sondern beispielsweise „zwei Wiederholungen mehr bei gleichem Gewicht“.

* **Planänderungsvorschau – P2:** Vor dem Übernehmen vorgeschlagener Gewichts- oder Rep-Anpassungen zeigen, was sich beim nächsten Training ändern würde.

* **Nächste Einheit anzeigen – P2:** Nach Abschluss direkt darstellen, wann und was als Nächstes geplant ist.

* **Datenschutz beim Teilen – P1:** Name, Körpergewicht, Notizen, Gym und andere persönliche Angaben vor dem Erstellen eines Share-Bildes ein- oder ausblenden.

## Trainingspläne und Programmierung

* **Echter Trainingskalender – P0:** Geplante und absolvierte Sessions sollten klar getrennt sein. Ein Workout-Template ist nicht automatisch ein konkreter Kalendereintrag.

* **Fortlaufende A/B/C-Pläne – P1:** Ideal für Nutzer, die keine festen Wochentage garantieren können.

* **Mehrwöchige Trainingsblöcke – P1:** Programme mit Wochen, Belastungsphasen, Deload und Testwoche.

* **Mesocycle-Unterstützung – P2:** Ein Plan kann aus mehreren aufeinanderfolgenden Blöcken mit unterschiedlichen Zielen bestehen.

* **Progressionsregel pro Übung – P1:** Beispiele:
    * Lineare Gewichtssteigerung
    * Double Progression
    * Rep-Range-Progression
    * Top Set mit Back-off-Sätzen
    * RIR-basierte Progression
    * Dauer- oder Distanzsteigerung
    * Manuelle Progression

* **Soll-RIR pro Woche oder Satz – P1:** Besonders relevant für geplante Intensitätssteigerungen innerhalb eines Blocks.

* **Automatische Deload-Regeln – P2:** Deload vorschlagen, wenn Leistung, Readiness und Planerfüllung über mehrere Sessions einbrechen. Der Nutzer entscheidet letztlich selbst.

* **Optionale Übungen – P1:** Ein Workout kann einen Pflichtteil und einen optionalen Teil enthalten.

* **Alternativgruppen – P1:** Beispielsweise „eine Übung aus dieser horizontalen Zug-Gruppe auswählen“.

* **Zeitbudget pro Workout – P1:** Planerstellung für 30, 45, 60 oder 90 Minuten.

* **Equipment-Anforderungen – P1:** Ein Workout zeigt vorab, welche Geräte benötigt werden.

* **Gym-Kompatibilitätsprüfung – P2:** ThriveWood erkennt, ob ein Plan im gewählten Gym vollständig durchführbar ist.

* **Planversionen – P1:** Änderungen erzeugen eine neue Version, anstatt historische Sessions rückwirkend umzudeuten.

* **Änderungen nur für zukünftige Sessions – P0:** Bereits absolvierte Einheiten bleiben unverändert.

* **Plan duplizieren und variieren – P1:** Beispielsweise aus „Push A“ schnell „Push B“ erstellen.

* **Planvorlagen – P2:** Eigene Vorlagen für Ganzkörper, Upper/Lower, Push/Pull/Legs oder andere Strukturen.

* **Trainingsphase und Ziel – P2:** Aufbau, Kraftphase, Technik, Erhaltung, Diät, Wiedereinstieg oder allgemeine Fitness.

* **Wiedereinstiegsmodus – P2:** Nach Krankheit, Urlaub oder längerer Pause Volumen und Intensität kontrolliert reduzieren.

* **Reiseplan – P2:** Bestehenden Plan temporär auf Hotelgym, Kurzhanteln oder Bodyweight umstellen.

* **Trainingstage intelligent verschieben – P1:** Muskelüberschneidungen und erforderliche Erholung beim Neuplanen berücksichtigen.

* **Plan-Adherence – P1:** Soll- und Ist-Sätze, absolvierte Einheiten, ausgelassene Übungen und Zeitabweichungen auswerten.

* **Plan-Review nach einem Block – P2:** Zusammenfassung, welche Übungen Fortschritt brachten, wo Plateaus entstanden und was geändert werden könnte.

* **Plan teilen – P2:** Als Datei, Link, QR-Code oder strukturiertes PDF.

* **Plan importieren – P2:** Strukturierter Import mit Zuordnung zu vorhandenen Übungen und kontrollierter Behandlung unbekannter Übungen.

* **Coach-Freigabe – P3:** Ein Coach kann einen Plan aktualisieren; der Nutzer sieht vor der Übernahme eine Änderungsliste.

## Progression, PRs und Sport-Analytics

### Personal Records

* **Mehrere PR-Arten – P1:** Schwerstes Gewicht, höchste Wiederholungszahl, bestes geschätztes 1RM, größtes Satzvolumen, längste Dauer, größte Distanz und beste Pace.

* **Rep-PRs nach Wiederholungsbereich – P1:** Ein 5-Rep-PR ist etwas anderes als ein 12-Rep-PR.

* **e1RM-Verlauf – P1:** Entwicklung der geschätzten Maximalkraft, ohne dass echte 1RM-Versuche erforderlich sind.

* **Wählbare Berechnungsmethode – P2:** Nutzer können eine bevorzugte e1RM-Methode wählen oder einen robusten Durchschnitt nutzen.

* **PR-Gültigkeitsregeln – P1:** Warm-up-Sätze, fehlerhafte Werte oder manuell als ungültig markierte Sätze dürfen keine PRs auslösen.

* **PR pro Equipment-Profil – P2:** Maschinen verschiedener Hersteller sind nicht direkt vergleichbar.

* **Körpergewichtsnormalisierte PRs – P2:** Relative Kraft zusätzlich zu absoluten Werten darstellen.

* **PR-Zeitleiste – P2:** Alle wichtigen Meilensteine chronologisch anzeigen.

* **PR-Feier mit Kontext – P1:** Statt nur Konfetti sollte die App erklären, wie groß die Verbesserung gegenüber dem bisherigen Wert war.

### Belastung und Muskelanalyse

* **Effektive Arbeitssätze pro Muskel – P1:** Warm-ups und sehr leichte Vorbereitungssätze ausschließen.

* **Primäre und sekundäre Muskelbeteiligung – P1:** Ein Satz kann beispielsweise den Zielmuskel voll und einen unterstützenden Muskel anteilig belasten.

* **Nutzeranpassbare Muskelzuordnung – P2:** Menschen führen Übungen unterschiedlich aus. Die subjektive Zielmuskelverteilung sollte optional justierbar sein.

* **Wochenvolumen pro Muskel – P1:** Sätze, Wiederholungen und Belastung getrennt darstellen, nicht in einen undurchsichtigen Gesamtscore pressen.

* **Trainingsfrequenz pro Muskel – P1:** Wie häufig eine Muskelgruppe tatsächlich belastet wurde.

* **Intensitätsverteilung – P2:** Verteilung nach RIR, Wiederholungsbereich oder relativer Belastung.

* **Push/Pull- und Bewegungsmuster-Balance – P2:** Horizontales Drücken/Ziehen, vertikales Drücken/Ziehen, Squat, Hinge und Carry vergleichen.

* **Links-rechts-Symmetrie – P2:** Bei unilateral erfassten Übungen Leistungsunterschiede anzeigen.

* **Aktuelle Form und Lifetime-Rang trennen – P2:** Ein dauerhaft erreichter Rang sollte nicht verschwinden. Zusätzlich kann ein kurzfristiger Aktivitäts- oder Formstatus existieren.

* **Schutz vor „Junk Volume“ – P1:** Muskelränge und Punkte sollten nicht unbegrenzt durch extrem viele bedeutungslose Sätze manipulierbar sein.

### Fortschrittsanalyse

* **Übungs-Dashboard – P1:** Pro Übung Gewicht, Reps, e1RM, Volumen, RIR, PRs, Frequenz und letzte Sessions.

* **Session-Vergleich – P1:** Zwei Ausführungen desselben Workouts direkt vergleichen.

* **Zeitraumvergleich – P1:** Aktuelle vier Wochen gegen vorherige vier Wochen.

* **Plateau-Erkennung – P2:** Erkennen, wenn e1RM, Wiederholungen oder Belastbarkeit über mehrere Einheiten stagnieren.

* **Regressionserkennung – P2:** Leistungseinbruch sichtbar machen und mit Schlaf, Krankheit, Readiness oder Planänderungen kontextualisieren.

* **Zielprognose – P3:** Vorsichtige Schätzung, wann ein Kraftziel erreichbar sein könnte, inklusive klarer Unsicherheit.

* **Trainingsdichte – P2:** Effektive Sätze oder Volumen pro Trainingsminute.

* **Pausenanalyse – P2:** Zusammenhang zwischen Pausenlänge und Satzleistung.

* **RIR-Kalibrierung – P3:** Vergleichen, wie zuverlässig subjektive RIR-Werte über die Zeit zur tatsächlichen Leistung passen.

* **Workout-Effizienz – P2:** Zielerreichung, Zeitaufwand und unnötige Wartezeit getrennt darstellen.

* **Konsistenzkalender – P1:** Geplante versus absolvierte Sessions in einer kalenderartigen Ansicht.

* **Monatlicher Sportbericht – P1:** Fortschritt, wichtigste PRs, Muskelverteilung, Trainingszeit und Planerfüllung.

* **Erklärbare Analyse – P1:** Jede Kennzahl erhält eine kurze verständliche Erklärung und zeigt, welche Daten eingeflossen sind.

* **Datenqualitätsanzeige – P2:** Analyse kennzeichnet, wenn Aussagen aufgrund fehlender RIR-, Schlaf- oder Session-Daten unsicher sind.

## Recovery, Readiness und Belastungssteuerung

* **Täglicher Readiness-Score – P1:** Zusammensetzung aus subjektiven Angaben, Wellness, Schlaf und optionalen HealthKit-Daten.

* **Keine künstliche Präzision – P1:** Lieber „niedrig“, „normal“ und „hoch“ mit Konfidenz als eine scheinbar wissenschaftlich exakte Zahl wie 83,7.

* **Muskelkater-Körperkarte – P1:** Muskeln antippen und Muskelkater oder Beschwerden bewerten.

* **Individueller Erholungsverlauf – P2:** ThriveWood lernt, wie lange bestimmte Muskelgruppen beim jeweiligen Nutzer typischerweise Erholung benötigen.

* **Belastungsabhängige Erholung – P1:** Schwere Sätze nahe am Versagen sollten anders zählen als leichte Technik-Sätze.

* **Schlafintegration – P2:** Schlafdauer und Schlafqualität als optionaler Kontext, nicht als alleinige Entscheidungsgrundlage.

* **Ruhepuls und HRV – P2:** Optional einbeziehen, sofern verfügbar und vom Nutzer gewünscht.

* **Recovery-Confidence – P2:** Anzeigen, ob eine Empfehlung auf vielen oder wenigen Datenpunkten basiert.

* **Erholungsorientierte Workout-Anpassung – P2:** Übungen, Sätze oder Ziel-RIR reduzieren, statt direkt eine komplette Einheit zu streichen.

* **Aktiver Erholungsvorschlag – P2:** Mobilität, leichtes Cardio oder Spaziergang als Alternative.

* **Illness Mode – P2:** Training pausieren, Erinnerungen reduzieren und einen späteren Wiedereinstieg vorbereiten.

* **Deload-Vorschlag – P2:** Aus Leistungsabfall, hoher Belastung, schlechter Readiness und subjektiver Ermüdung ableiten.

* **Beschwerden-Verlauf – P2:** Körperregionen und betroffene Übungen im Zeitverlauf darstellen.

* **Optionale zyklusbezogene Insights – P3:** Nur mit ausdrücklicher Zustimmung und ohne pauschale Leistungsannahmen.

* **Klare Gesundheitsgrenzen – P0:** ThriveWood darf Schmerzen, Verletzungen oder auffällige Gesundheitsdaten nicht diagnostizieren. Es sollte im Zweifel zur professionellen Abklärung raten.

## Progressions- und Empfehlungslogik

Für Zahlen wie Gewicht, Wiederholungen und Volumen würde ich **keine freie KI-Entscheidung als primäre Logik** verwenden. Sinnvoller wäre:

* Ein deterministischer Progressionsalgorithmus berechnet den Vorschlag.
* Die KI erklärt den Vorschlag in natürlicher Sprache.
* Der Nutzer sieht, welche Daten und Regeln verwendet wurden.
* Jede Empfehlung kann abgelehnt oder angepasst werden.
* Die Entscheidung wird gespeichert, damit zukünftige Empfehlungen verbessert werden können.

Sinnvolle Funktionen wären:

* **Double-Progression-Engine – P1:** Erst Wiederholungen innerhalb einer Range steigern, danach das Gewicht erhöhen.

* **RIR-basierte Anpassung – P1:** Ziel erreicht und mehr Reserve als vorgesehen bedeutet potenzielle Steigerung.

* **Fehlversuchslogik – P1:** Nach einem schwachen Satz nicht sofort aggressiv reduzieren, sondern Verlauf und Tagesform berücksichtigen.

* **Mikrosteigerungen – P2:** Verfügbare kleinste Gewichtsschritte des gewählten Gyms beachten.

* **Top-Set- und Back-off-Logik – P2:** Folgesätze anhand des Top Sets berechnen.

* **Cardio-Progression – P2:** Dauer, Distanz, Intervallzahl oder Pace kontrolliert steigern.

* **Übungsabhängige Regeln – P1:** Kleine Isolationsübungen brauchen andere Schritte als Kniebeugen oder Kreuzheben.

* **Plateau-Reaktion – P2:** Gewicht halten, Wiederholungsziel ändern, Satzanzahl anpassen oder eine Alternative vorschlagen.

* **Empfehlungsbegründung – P1:** Beispielsweise: „Du hast in den letzten beiden Sessions alle Zielwiederholungen mit mindestens zwei RIR erreicht.“

* **Vorschau vor Übernahme – P1:** Nutzer sieht alle Änderungen des kommenden Workouts auf einen Blick.

## KI-Coach und adaptive Planung

* **Strukturierte Planerstellung – P1:** Ziel, Erfahrung, Trainingstage, Zeitbudget, Equipment, bevorzugte Übungen, ausgeschlossene Übungen und körperliche Einschränkungen abfragen.

* **Planvalidierung – P1:** Generierte Pläne auf fehlende Muskelgruppen, unrealistische Dauer, zu viele Sätze und inkompatibles Equipment prüfen.

* **Nur vorhandene Exercise-IDs verwenden – P0:** Die KI sollte keine frei erfundenen oder uneindeutigen Übungsnamen erzeugen.

* **Natürlichsprachliche Planänderung – P2:** „Ersetze Langhantelrudern durch eine Maschine und kürze Freitag auf 45 Minuten.“

* **Adaptiver Wochenreview – P2:** Am Ende der Woche konkrete Änderungsvorschläge mit Begründung.

* **Zeitmangel-Modus – P2:** Das heutige Workout auf eine vorgegebene Dauer komprimieren.

* **Travel-Modus – P2:** Plan auf verfügbares Equipment umstellen.

* **Wiedereinstieg nach Pause – P2:** Volumen und Intensität für die ersten Sessions reduzieren.

* **Übungsersatz bei Beschwerden – P2:** Nur als Trainingsalternative, nicht als medizinische Behandlungsempfehlung.

* **Fragen an die eigenen Daten – P2:** Beispiele:
    * „Warum stagniert mein Bankdrücken?“
    * „Welche Muskeln habe ich diesen Monat vernachlässigt?“
    * „Bei welchen Übungen mache ich die besten Fortschritte?“
    * „Wie hat mein Schlaf mit meiner Trainingsleistung zusammengehangen?“

* **Automatische Session-Zusammenfassung – P1:** Kurzer Bericht mit PRs, Abweichungen und auffälligen Entwicklungen.

* **Feedback auf Empfehlungen – P1:** Hilfreich, nicht hilfreich oder unpassend, damit Regeln personalisiert werden können.

* **Änderungsprotokoll – P2:** Jede KI-Anpassung zeigt alte und neue Werte.

* **Fallback ohne On-Device-Modell – P0:** Planen und Progression müssen weiterhin über deterministische Regeln funktionieren.

* **Keine medizinischen oder leistungssteigernden Risikoempfehlungen – P0:** Keine Diagnosen, Medikamentenanweisungen oder gefährlichen Belastungsempfehlungen.

## Übungsbibliothek

* **Umfassende Filter – P1:** Muskelgruppe, Equipment, Bewegungsmuster, Kategorie, Tracking-Typ, Schwierigkeitsgrad, Gym und Favoriten.

* **Primäre und sekundäre Muskeln – P1:** Mit unterschiedlicher Gewichtung für Analysen.

* **Bewegungsmuster – P1:** Squat, Hinge, Push, Pull, Carry, Rotation, Anti-Rotation und weitere Muster.

* **Compound- und Isolation-Kennzeichnung – P1:** Relevant für Plananalyse und Pausenvorschläge.

* **Übungsvarianten – P1:** Übungen als verwandte Varianten gruppieren, ohne ihre Historien vollständig zu vermischen.

* **Alternative Übungen – P1:** Manuell gepflegte Beziehungen zwischen ähnlichen Übungen.

* **Aliasnamen – P1:** Deutsche und englische Namen sowie geläufige Gym-Bezeichnungen.

* **Eigene Favoriten und zuletzt verwendet – P1:** Schneller Zugriff beim Hinzufügen während einer Session.

* **Kurze Technikvideos – P2:** Idealerweise kompakt, offline verfügbar und ohne unnötige Ablenkung.

* **Setup-Schritte – P2:** Sitzposition, Startposition, Griff und Sicherheitsinformationen.

* **Häufige Fehler – P2:** Kurze Hinweise statt langer Fließtexte.

* **Eigene Bilder und Videos – P2:** Für selbst erstellte Übungen.

* **Persönliche Übungsnotizen – P1:** Dauerhaft von allgemeinen Anleitungen getrennt.

* **Exercise Merge – P2:** Doppelt angelegte Übungen zusammenführen und historische Daten migrieren.

* **Exercise Archive – P1:** Eigene Übungen ausblenden, ohne Sessions zu beschädigen.

* **Übungsspezifische PR-Regeln – P2:** Bei Planks zählt Dauer, beim Laufen Pace oder Distanz, beim Krafttraining Gewicht und Wiederholungen.

* **Maschinenvariante pro Gym – P2:** Eine Chest-Press-Maschine in Gym A ist nicht zwingend mit der Maschine in Gym B vergleichbar.

* **Subjektives Übungsrating – P2:** Zielmuskelgefühl, Gelenkkomfort, Stabilität und allgemeine Präferenz.

## Cardio, Mobilität und hybride Trainingsformen

Der Cardio-Bereich sollte nur dann stark erweitert werden, wenn ThriveWood auch Hybrid- und Ausdauerathleten aktiv bedienen soll. Ansonsten würde ich zunächst Krafttraining perfektionieren.

* **Intervall-Builder – P2:** Warm-up, Belastungsintervall, Pause, Wiederholungen und Cool-down.

* **Herzfrequenzzonen – P2:** Zielzone und tatsächliche Zeit pro Zone.

* **GPS-Aufzeichnung – P3:** Strecke, Distanz, Pace, Höhenmeter und Splits.

* **Kilometer- oder Meilensplits – P2:** Automatische Zwischenzeiten.

* **Auto-Pause – P3:** Für Laufen und Radfahren.

* **Audio- und Haptik-Cues – P2:** Hinweise bei Intervallwechseln oder Verlassen der Zielzone.

* **Indoor-Cardio – P2:** Laufband, Ergometer, Rudergerät, Stairmaster und Crosstrainer.

* **Laufbandkalibrierung – P3:** Manuelle Anpassung bei Abweichungen zwischen Gerät und Uhr.

* **Cardio-PRs – P2:** Schnellste Strecke, längste Distanz, beste Pace und höchste Intervallleistung.

* **Zone-2-Ziele – P2:** Wochenziel nach Zeit statt nur Distanz.

* **Gemischte Sessions – P2:** Krafttraining plus Cardio innerhalb einer Session.

* **HIIT- und EMOM-Modus – P2:** Zeitbasierte Runden mit klarer Timer-Darstellung.

* **Mobilitätsroutinen – P2:** Sequenzen mit Haltezeiten, Seitenwechseln und Videoanleitung.

* **Mobility Check-in – P3:** Subjektive Beweglichkeit oder Einschränkungen vor und nach einer Routine.

* **Cardio-Import – P2:** Externe HealthKit-Workouts in die ThriveWood-Historie einbinden, ohne doppelte Einträge zu erzeugen.

## Apple Watch, Live Activities und Systemintegration

* **Eigenständige Watch-App – P2:** Workout auswählen, starten und beenden.

* **Set-Logging auf der Watch – P2:** Gewicht und Wiederholungen über Digital Crown oder Schnellwerte eingeben.

* **Rest-Timer am Handgelenk – P2:** Haptik, verlängern und überspringen.

* **Aktuelle Übung und Zielwerte – P2:** Letzte Leistung, heutiges Ziel und laufender Satz.

* **Offline-Watch-Session – P3:** Training ohne erreichbares iPhone durchführen und später synchronisieren.

* **Herzfrequenz während der Session – P2:** Optional als zusätzlicher Kontext anzeigen.

* **Watch-Komplikation – P3:** Heutiges Workout, Wochenziel oder Recovery-Status.

* **Interaktive Live Activity – P1:** Satz abschließen, Timer verlängern und nächste Übung öffnen.

* **App Intents und Kurzbefehle – P1:** „Starte Push Day“, „Logge meinen Supplement-Stack“ oder „Zeige das heutige Workout“.

* **Siri-Eingabe – P2:** Kurze Set- oder Habit-Aktionen per Sprache.

* **Interaktive Sport-Widgets – P1:** Heutiges Workout starten, Wochenfortschritt sehen oder Rest-Timer öffnen.

* **Erweiterte HealthKit-Daten – P2:** Optional Schlaf, Gewicht, Körperfett, Ruhepuls und weitere relevante Werte importieren.

* **Saubere HealthKit-Deduplizierung – P0:** Jede exportierte Session benötigt eine stabile Referenz, damit sie nicht mehrfach geschrieben wird.

* **Datenquellen-Auswahl – P2:** Nutzer entscheidet, welcher Quelle bei konkurrierenden Werten vertraut wird.

## Gym Plan Builder und Gym-Integration

Der Gym Plan Builder ist eines der ungewöhnlichsten vorhandenen Features und könnte ein echtes Alleinstellungsmerkmal werden. Dafür muss die Karte aber ein konkretes Problem lösen.

* **Aktives Gym pro Session – P1:** Das verwendete Gym wird an der Session gespeichert.

* **Equipment-Inventar – P1:** Welche Hanteln, Maschinen, Kabelzüge und Cardio-Geräte sind vorhanden?

* **Workout-Kompatibilität – P2:** Prozentual anzeigen, wie vollständig ein Workout im Gym durchgeführt werden kann.

* **Persönliche Maschineneinstellungen – P1:** Sitz, Lehne, Griff, Pin, Startposition und Notizen.

* **PRs pro konkretem Gerät – P2:** Gewichtsangaben verschiedener Maschinen nicht automatisch vergleichen.

* **Route zur nächsten Übung – P2:** Sinnvolle Wegführung über Etagen und Zonen.

* **Routenoptimierung – P3:** Reihenfolge optional anpassen, um unnötige Wege zu vermeiden.

* **Nächstgelegene Alternative – P2:** Wenn ein Gerät belegt ist, passende Übungen in der Nähe anzeigen.

* **QR- oder NFC-Zuordnung – P3:** Gerät scannen und direkt Übung, Einstellungen und letzte Werte öffnen.

* **Manueller Belegt-Status – P3:** Nutzer kann Geräte temporär als belegt markieren.

* **Crowd-basierte Auslastung – P3:** Erst sinnvoll mit ausreichender Nutzerzahl, Datenschutzkonzept und Server-Infrastruktur.

* **Etagenwechsel und barrierearme Routen – P3:** Aufzüge oder zugängliche Wege berücksichtigen.

* **Map-Kalibrierung – P2:** Kartenmaßstab und Gerätepositionen präzise anpassen.

* **Offline-Karten – P1:** Grundriss muss im Gym ohne Netz verfügbar sein.

* **Gym-Pakete teilen – P3:** Andere Nutzer können einen Grundriss importieren, prüfen und lokal anpassen.

* **Versionierung zwischen macOS Builder und App – P1:** Änderungen mit Vorschau und Konflikterkennung synchronisieren.

* **Gym-Statistik – P2:** Häufigkeit, durchschnittliche Trainingsdauer und persönliche Leistungsunterschiede nach Standort.

## Private Sharing, Training Partner und Coaching

* **Trainingsplan privat teilen – P2:** Der sinnvollste Einstieg in soziale Funktionen.

* **Session-Zusammenfassung teilen – P1:** Mit detaillierter Kontrolle über sichtbare Daten.

* **Training-Partner-Modus – P3:** Gemeinsames Workout mit getrennten Gewichten, Wiederholungen und Pausen.

* **Synchronisierte Partner-Session – P3:** Übungsreihenfolge und Fortschritt gemeinsam sehen.

* **Coach-Ansicht – P3:** Coach erstellt Pläne, kommentiert Sessions und sieht freigegebene Daten.

* **Freigabeberechtigungen – P2:** Nur Plan, nur Sessions, nur Fortschritt oder vollständiger Zugriff.

* **Private Herausforderungen – P2:** Wochenziele mit Freunden, ohne öffentliches Netzwerk.

* **Opt-in-Leaderboards – P3:** Eher nach Konsistenz und Planerfüllung als nach absolutem Gewicht.

* **Clubs oder Trainingsgruppen – P3:** Erst sinnvoll, wenn Moderation und Datenschutz tragfähig sind.

* **Kein öffentlicher Feed als frühes Feature:** Hoher Backend-, Moderations- und Datenschutzaufwand bei zunächst geringem Nutzen.

## Verbindung von Sport und Wald

Die Gamification sollte Training fördern, aber niemals Übertraining belohnen.

* **Punkte für Planerfüllung statt reine Tonnage – P1:** Ein sauber absolviertes geplantes Training zählt mehr als beliebiges Zusatzvolumen.

* **Tägliches Punktelimit für Sport – P1:** Verhindert, dass unnötig viele Sätze nur für Waldpunkte absolviert werden.

* **PR-Wachstumsringe – P2:** Bedeutende PRs werden als besondere Ringe oder Merkmale eines Baums dargestellt.

* **Workout-Bäume – P2:** Ein Baum kann ein langfristiges Programm oder Ziel repräsentieren.

* **Muskel-Haine – P2:** Unterschiedliche Waldgebiete repräsentieren Trainingsbereiche wie Oberkörper, Unterkörper, Cardio oder Mobilität.

* **Recovery-Belohnungen – P2:** Auch Schlaf, Wellness-Check-ins, Mobilität und geplante Ruhetage können positiv einfließen.

* **Trainingsblock als Saison – P2:** Ein abgeschlossener Block verändert einen bestimmten Bereich des Waldes.

* **Plan-Adherence schaltet Dekoration frei – P2:** Kosmetische Belohnungen statt immer höherer Punktwerte.

* **Keine Bestrafung durch sterbende Bäume – P0:** Pausen, Krankheit oder stressige Phasen dürfen keinen emotionalen Verlust erzeugen.

* **Persönliche Meilenstein-Bäume – P2:** Erster Klimmzug, 100 Workouts oder ein bestimmtes Kraftziel können einzigartige Bäume freischalten.

# App-weite zukünftige Features

## Einheitliche Tagesübersicht

Langfristig würde ich neben den einzelnen Tabs eine stärker integrierte „Heute“-Erfahrung aufbauen.

* **Tages-Dashboard:** Habits, heutiges Workout, Supplements, Ernährung, Wellness und verfügbare Waldpunkte auf einer Seite.

* **Personalisierbare Module:** Nutzer können irrelevante Bereiche ausblenden oder neu anordnen.

* **Universeller Kalender:** Habits, Training, Körpermessungen, Wellness und geplante Erinnerungen gemeinsam anzeigen.

* **Globale Suche:** Übungen, Workouts, Lebensmittel, Sessions, Habits und Einstellungen durchsuchen.

* **Globale Schnellaktion:** Über einen zentralen Button Habit abschließen, Workout starten, Lebensmittel loggen oder Wellness-Check-in erstellen.

* **Cross-Domain-Ziele:** Beispielsweise „dreimal trainieren, Protein an fünf Tagen erreichen und sieben Stunden schlafen“.

* **Automatische Habit-Verknüpfung:** Eine abgeschlossene Session kann ein verknüpftes Trainings-Habit bestätigen.

* **Schutz vor doppelten Punkten:** Automatische und manuelle Bestätigung desselben Ereignisses darf nicht doppelt belohnt werden.

* **Wochenreview:** Gemeinsamer Bericht über Gewohnheiten, Training, Ernährung, Wellness und Körperentwicklung.

* **Kontextabhängige Benachrichtigungen:** Während eines aktiven Workouts weniger irrelevante Reminder senden.

## Habits

* **Wochenziele statt nur feste Wochentage:** Beispielsweise „dreimal pro Woche“, unabhängig von konkreten Tagen.

* **Mehrfachziele pro Tag:** „Dreimal zehn Minuten lernen“ oder „vier Portionen Wasser“.

* **Flexible Zielbereiche:** Minimum, Ziel und Stretch Goal.

* **Habit pausieren:** Urlaub, Krankheit oder Prüfungsphase, ohne Streak-Verlust.

* **Bewusstes Überspringen:** Mit Grund und ohne dieselbe Wirkung wie schlichtes Vergessen.

* **Streak Freeze:** Sparsam nutzbar oder als Wald-Belohnung.

* **Habit Stacking:** „Nach dem Frühstück Supplements nehmen“.

* **Routinen:** Morgen-, Abend-, Gym- oder Lernroutine mit mehreren Schritten.

* **Negative Habits:** Verhalten reduzieren, beispielsweise Bildschirmzeit oder Rauchen. Hier sollte das Punktesystem besonders vorsichtig gestaltet werden.

* **Zeitfenster:** Habit morgens, nachmittags oder abends abschließen.

* **Ortsabhängige Reminder – optional:** Nur mit ausdrücklicher Zustimmung.

* **Automatische HealthKit-Erfüllung:** Schritte, Workout oder Distanz können verknüpfte Habits abschließen.

* **Habit-Vorlagen:** Vorgefertigte, anpassbare Routinen.

* **Notizen und kurze Reflexion:** Warum wurde ein Habit erreicht oder verpasst?

* **Adaptive Ziele:** Zielanpassung vorschlagen, wenn ein Habit dauerhaft zu leicht oder unrealistisch ist.

* **Abhängigkeiten:** Ein Habit wird erst relevant, nachdem ein anderes abgeschlossen wurde.

* **Monatskalender pro Habit:** Neben der bestehenden Heatmap eine direkte Detailhistorie.

## Ernährung

Die Fertigstellung des Food Diary sollte appweit eine der höchsten Prioritäten haben.

* **Vollständiges Ernährungstagebuch – P0:** Mahlzeiten nach Frühstück, Mittagessen, Abendessen und Snacks gruppieren.

* **Makro-Ringe und Tagesfortschritt – P0:** Kalorien, Protein, Kohlenhydrate und Fett.

* **Schnelles Kopieren – P1:** Mahlzeit, Tag oder einzelne Lebensmittel auf einen anderen Tag kopieren.

* **Zuletzt verwendet und häufig gegessen – P1:** Reduziert den Eingabeaufwand deutlich.

* **Portionseinheiten – P1:** Gramm, Milliliter, Stück, Portion, Scheibe, Esslöffel oder benutzerdefinierte Einheit.

* **Rezepte – P1:** Mehrere Lebensmittel zu einem Rezept kombinieren und Portionen berechnen.

* **Meal Prep – P2:** Rezeptmenge auf mehrere Portionen oder Tage verteilen.

* **Quick Add – P1:** Nur Kalorien oder Makros eingeben, wenn das genaue Lebensmittel unbekannt ist.

* **Wassertracking – P1:** Kann mit messbaren Habits verbunden werden.

* **Trainingstag- und Ruhetag-Ziele – P2:** Unterschiedliche Makroziele abhängig vom Tagesplan.

* **Proteinverteilung – P2:** Proteinaufnahme pro Mahlzeit statt nur Tagesgesamtwert.

* **Pre- und Post-Workout-Ernährung – P2:** Mahlzeiten zeitlich einer Session zuordnen.

* **Ballaststoff-, Zucker- und Natriumziele – P2:** Bereits vorhandene Nährwerte sinnvoll nutzen.

* **Mikronährstoffe – P3:** Nur, wenn die zugrunde liegenden Lebensmitteldaten ausreichend vollständig sind.

* **Nährwertetikett scannen – P2:** OCR mit manueller Bestätigung.

* **Foto-basierte Mahlzeitenschätzung – P3:** Nur als grobe Schätzung mit sichtbarer Unsicherheit, nicht als präzise Wahrheit.

* **Lebensmittel-Datenqualität – P1:** Quelle, Vollständigkeit und Verifizierungsstatus anzeigen.

* **Fehlerhafte Produkte melden – P2:** Lokale Korrektur und optionales Feedback an die Datenquelle.

* **Adaptive Kalorienziele – P3:** Auf Basis geglätteter Körpergewichtsentwicklung, aber immer transparent und vom Nutzer kontrolliert.

* **Ernährungsbericht – P2:** Zielerreichung, Regelmäßigkeit, Proteinverteilung und häufigste Lebensmittel.

* **Nutrition-Widget – P2:** Tagesfortschritt und Schnell-Logging.

## Supplements

* **Tägliche Supplement-Liste fertigstellen – P0:** Offene, eingenommene und übersprungene Einnahmen.

* **Zeitfenster statt exakter Uhrzeit – P1:** Beispielsweise morgens oder zwischen 18:00 und 21:00 Uhr.

* **Bestand und Nachkauf-Erinnerung – P1:** Anzahl Portionen oder Kapseln verwalten.

* **Packungsgröße – P1:** Automatisch abschätzen, wann das Produkt leer ist.

* **Einnahmehistorie – P1:** Adherence nach Woche und Monat.

* **Geplante Pausen und Zyklen – P2:** Für Nutzer, die Supplements nicht dauerhaft nehmen.

* **Batch und Ablaufdatum – P2:** Optional für umfangreiche Stacks.

* **Notizen zu Verträglichkeit – P2:** Subjektive Beobachtungen festhalten.

* **Doppelte Inhaltsstoffe erkennen – P3:** Nur bei zuverlässigen Inhaltsstoffdaten und mit klarer medizinischer Vorsicht.

* **Korrelationen mit Wellness – P3:** Ausschließlich als zeitlicher Zusammenhang, niemals als bewiesene Wirkung darstellen.

* **Reminder-Aktionen – P1:** „Eingenommen“, „überspringen“ und „später erinnern“.

* **Reise-Packliste – P3:** Benötigte Mengen für einen Zeitraum berechnen.

## Wald

* **Wald vergrößern – P1:** Neue Gebiete oder Parzellen freischalten.

* **Bäume verschieben – P1:** Mit sicherem Bearbeitungsmodus.

* **Undo beim Pflanzen oder Verschieben – P1:** Verhindert ärgerliche Fehlaktionen.

* **Biomes – P2:** Wald, Gebirge, Küste, Herbstlandschaft oder Zen-Garten.

* **Dekorationen – P2:** Wege, Bänke, Steine, Wasser, Laternen oder kleine Gebäude.

* **Jahreszeiten – P2:** Visuelle Veränderung anhand der realen Jahreszeit oder eines eigenen Zyklus.

* **Tageszeit und Wettereffekte – P3:** Rein kosmetisch und deaktivierbar.

* **Tiere – P2:** Werden durch Biodiversität oder langfristige Konsistenz freigeschaltet.

* **Wachstums-Timeline – P1:** Entwicklung eines Baums vom Samen bis zum aktuellen Zustand ansehen.

* **Foto-Modus – P2:** UI ausblenden und den Wald als Bild exportieren.

* **Baumgeschichten – P2:** Anzeigen, welche Gewohnheiten, Workouts oder Meilensteine zu seinem Wachstum beigetragen haben.

* **Sammlungsbuch – P2:** Arten, Wachstumsstufen, Dekorationen und besondere Varianten.

* **Zeitlich begrenzte Herausforderungen – P3:** Belohnung bevorzugt kosmetisch, nicht über aggressive Streak-Mechaniken.

* **Waldziele – P2:** Ein bestimmtes Gebiet durch eine langfristige persönliche Herausforderung aufbauen.

* **Barrierefreie Listenansicht – P0:** Alle Waldinformationen müssen auch ohne visuelle Grid-Interpretation zugänglich sein.

## Körperfortschritt und Wellness

* **Mess-Erinnerungen – P1:** Flexible wöchentliche oder monatliche Intervalle.

* **Geglätteter Gewichtstrend – P1:** Tagesgewicht und langfristiger Trend getrennt darstellen.

* **Phasen – P1:** Aufbau, Diät, Erhaltung, Recomp oder freie benutzerdefinierte Phase.

* **Zielbereiche – P2:** Kein starres Einzelziel, sondern optionaler Bereich.

* **HealthKit-Import für Gewicht und Körperfett – P1:** Mit sauberer Quellenbehandlung.

* **Foto-Ausrichtungshilfe – P1:** Kamera-Overlay, Abstand, Pose und Beleuchtung konsistent halten.

* **Vorher-Nachher-Vergleich – P1:** Zwei Fotos mit Slider, Überblendung oder Seitenansicht.

* **Automatische Gesichtsverdeckung – P2:** Für private Vergleiche oder Teilen.

* **Private Foto-Sperre – P1:** Face ID oder Geräteauthentifizierung.

* **Foto-Export mit Redaction – P2:** Metadaten und persönliche Werte kontrolliert ausblenden.

* **Schlafprotokoll – P1:** Manuell oder über HealthKit.

* **Stress- und Energieverlauf – P1:** Direkt mit Trainingsphasen vergleichen.

* **Kurzes Tagebuch – P2:** Freitext neben dem Wellness-Check-in.

* **Beschwerden- und Schmerzjournal – P1:** Mit Körperkarte und Übungsverknüpfung.

* **Wellness-Trigger – P2:** Bei mehreren schlechten Tagen Erinnerungen reduzieren und Erholung vorschlagen.

* **Erklärbare Korrelationen – P1:** „An Tagen mit besserem Schlaf war deine Trainingsleistung im Durchschnitt höher“ statt kausaler Behauptungen.

## Analyse und Berichte

* **Einheitlicher Wochenbericht – P1:** Die wichtigste Cross-Domain-Erweiterung.

* **Monats- und Jahresrückblick – P2:** Vergleich mit vorherigem Zeitraum.

* **Persönliche Highlights – P1:** PRs, längste Streak, stärkster Habit, bester Wellness-Tag und Waldwachstum.

* **Zielerreichung – P1:** Konkrete Ziele über alle Bereiche hinweg.

* **Benutzerdefinierte Dashboards – P2:** Karten auswählen, anordnen und ausblenden.

* **Anmerkungen im Zeitverlauf – P2:** Urlaub, Krankheit, Diätbeginn oder neuer Plan als Marker in Charts.

* **Datenüberlagerungen – P2:** Beispielsweise Körpergewicht und e1RM gemeinsam betrachten.

* **Korrelationen mit Mindestdatenmenge – P1:** Keine Aussagen aus zwei oder drei zufälligen Datenpunkten.

* **Konfidenzanzeige – P2:** Stärke und Datenbasis eines Insights offenlegen.

* **PDF-Bericht – P2:** Für Coach, Arzt oder persönliche Dokumentation, mit auswählbaren Bereichen.

* **CSV-Export – P1:** Für Nutzer, die eigene Analysen durchführen möchten.

* **Share Cards – P1:** Datenschutzfreundliche Zusammenfassungen für PRs, Wochenberichte und Waldmeilensteine.

## Achievements und Challenges

* **Dynamische Challenges – P2:** Wöchentlich oder monatlich, auf den Nutzer zugeschnitten.

* **Achievement-Stufen – P1:** Bronze bis Legend als sichtbarer Progress innerhalb eines Erfolgs.

* **Geheime Achievements – P2:** Sparsam einsetzen, damit Fortschritt nicht unverständlich wird.

* **Achievement Showcase – P2:** Nutzer wählt favorisierte Erfolge fürs Profil.

* **Kosmetische Belohnungen – P2:** Walddekorationen, Baumvarianten, App-Icons oder Share-Designs.

* **Cross-Domain-Erfolge – P2:** Beispielsweise Training, Schlaf und Ernährung in einer Woche konsistent erfüllen.

* **Recovery-Achievements – P1:** Geplante Pausen und gesunde Trainingssteuerung ebenfalls belohnen.

* **Keine Belohnung für riskante Extreme – P0:** Keine Achievements für gefährlich lange Trainingszeiten, extremes Volumen oder zu wenig Erholung.

* **Fortschrittsbenachrichtigung – P1:** „Noch zwei Sessions bis zum nächsten Meilenstein.“

## Onboarding und Personalisierung

* **Fokus-Auswahl – P1:** Habits, Sport, Ernährung, Wellness oder Kombination.

* **Progressives Onboarding – P1:** Nicht alle Funktionen und Berechtigungen direkt beim ersten Start erklären.

* **Sport-Onboarding – P1:** Trainingsstand, Ziel, Equipment, verfügbare Tage und bevorzugte Dauer.

* **Bestehende Daten importieren – P2:** Nutzer kann mit Workout-Historie oder Körpergewichtsdaten starten.

* **Beispieldaten optional – P1:** Demodaten klar als solche kennzeichnen und leicht entfernen.

* **Just-in-time-Berechtigungen – P0:** HealthKit, Notifications, Fotos und Standort erst erklären, wenn die Funktion verwendet wird.

* **Erster Erfolg vor Paywall – P1:** Nutzer sollte mindestens ein Habit abschließen oder ein Workout planen können, bevor Pro prominent angeboten wird.

* **Personalisierte Startseite – P1:** Module nach dem gewählten Fokus gewichten.

* **Feature Discovery – P1:** Neue oder bisher ungenutzte Funktionen dezent im passenden Kontext erklären.

## Notifications und Widgets

* **Täglicher Digest – P1:** Optional eine einzige Übersicht statt vieler einzelner Reminder.

* **Intelligente Reminder – P2:** Keine Erinnerung senden, wenn die Aufgabe bereits erledigt wurde.

* **Workout-Reminder – P1:** Geplante Session mit direktem Start-Button.

* **Pre-Workout-Reminder – P2:** Optional mit Dauer, Übungen und Readiness-Check-in.

* **Post-Workout-Reminder – P2:** Nur wenn RPE oder Notizen fehlen.

* **Wochenreview-Notification – P1:** Zusammenfassung zum selbst gewählten Wochenabschluss.

* **Kontextabhängige Quiet Hours – P2:** Während Training, Schlaf oder Fokusmodus.

* **Interaktives Habit-Widget – P1:** Completion ohne App-Start.

* **Supplement-Widget – P1:** Einnahme direkt bestätigen.

* **Sport-Widget – P1:** Heutiges Workout, Wochenfortschritt und Schnellstart.

* **Recovery-Widget – P2:** Readiness und wichtigste Muskelgruppen.

* **Nutrition-Widget – P2:** Makrofortschritt und Quick Add.

## Datenschutz, Sync und Zuverlässigkeit

* **Sync-Status-Center – P0:** Letzte erfolgreiche Synchronisation, ausstehende Änderungen und mögliche Fehler.

* **Manuelle Sync-Wiederholung – P1:** Nutzer kann problematische Synchronisation erneut anstoßen.

* **Konfliktanzeige – P1:** Besonders bei parallel bearbeiteten Plänen und Sessions.

* **Lokaler Modus – P2:** App ohne iCloud-Sync verwenden.

* **Automatische Backups – P1:** Regelmäßige versionierte Sicherungen, soweit technisch und datenschutzrechtlich sinnvoll.

* **Papierkorb – P1:** Gelöschte Workouts, Sessions, Habits und Messungen für einen Zeitraum wiederherstellen.

* **Vollständige Datenlöschung – P0:** Klarer und transparenter Prozess.

* **App-Sperre – P1:** Geräteauthentifizierung für Körperfotos, Wellness und Gesundheitsdaten.

* **Export-Auswahl – P1:** Nutzer entscheidet, ob Fotos, Notizen, Wellness oder Standorte enthalten sind.

* **Grundlegender Datenexport für alle Nutzer:** Persönliche Datenportabilität würde ich nicht vollständig hinter Pro verstecken. Premium-Berichte und komfortable Imports können weiterhin Pro sein.

* **Diagnose-Export – P1:** Technische Sync- und Datenbankinformationen ohne persönliche Inhalte für Supportfälle.

* **Offline-Funktionalität – P0:** Habits und Training müssen ohne Netz vollständig nutzbar bleiben.

* **Datenquellen-Provenienz – P1:** Manuell, HealthKit, Widget, Import oder KI-generiert kennzeichnen.

* **Feature Flags – P1:** Komplexe neue Funktionen kontrolliert und schrittweise ausrollen.

## Accessibility und Bedienkomfort

* **Vollständige Dynamic-Type-Unterstützung – P0**
* **VoiceOver-Beschreibungen für Muskelkarten und Wald – P0**
* **Alternative Listenansichten für visuelle Karten – P0**
* **Farben nie als einziges Statusmerkmal – P0**
* **Höhere Kontraste und farbenblind-freundliche Paletten – P1**
* **Reduce Motion respektieren – P0**
* **Große Touch-Flächen im Live-Training – P0**
* **Einhandbedienung – P1**
* **Konfigurierbare Haptik und Sounds – P1**
* **iPad-Layout – P2:** Besonders attraktiv für Planung, Analyse und Gym-Karten.
* **macOS-Erweiterung – P2:** Trainingspläne und Gym-Grundrisse bearbeiten, Analysen ansehen.
* **Lokalisierung – P1:** Mindestens Deutsch und Englisch einschließlich Übungsaliasen.

# Sinnvolle technische Erweiterungen des Datenmodells

Damit die genannten Sport-Features später nicht zu Architekturproblemen führen, würde ich frühzeitig folgende fachliche Trennungen einplanen:

* **Geplante Session getrennt von Workout-Template:** Ein Template beschreibt die Vorlage, ein geplanter Termin die konkrete Durchführung.

* **Session-Snapshot:** Name, Reihenfolge, Ziele, Pausen und Übungsinformationen beim Start einfrieren.

* **Trainingsblöcke und Planwochen:** Nicht alles direkt an `TrainingsPlanDay` hängen.

* **Set-Ziele getrennt von tatsächlichen Set-Einträgen:** Geplante und absolvierte Werte müssen vergleichbar bleiben.

* **Erweiterte Set-Metadaten:** Satztyp, RIR, RPE, Tempo, Seite, Range of Motion und Gültigkeitsstatus.

* **Exercise-Varianten und Alternativen:** Stabile Beziehungen statt einfacher Namensvergleiche.

* **Stabile IDs für Built-in-Übungen:** Namen dürfen lokalisiert oder geändert werden, ohne Historien zu zerstören.

* **Equipment-Profile:** Konkrete Maschine, Gym, Einstellungen, Gewichtseinheit und verfügbare Schritte.

* **Readiness- und Soreness-Einträge:** Von allgemeinen Wellness-Einträgen fachlich trennen, falls die Daten detaillierter werden.

* **Recommendation Record:** Vorschlag, verwendete Daten, Begründung, angenommene Änderung und Nutzerfeedback speichern.

* **PR mit Quellreferenz:** Jeder gespeicherte oder gecachte PR verweist auf den verursachenden Satz.

* **Einheiten intern normalisieren:** Anzeige kann kg, lb, km oder mi verwenden; Berechnungen sollten konsistent auf normalisierten Werten basieren.

* **Abgeleitete Analysen neu berechenbar halten:** Sessions und Sets sind die Wahrheit. Muskelvolumen, PRs und Trends sollten bei Algorithmusänderungen neu berechnet werden können.

* **HealthKit-Referenzen speichern:** Verhindert doppelte Exporte und erleichtert spätere Korrekturen.

* **Soft Delete und Wiederherstellung:** Besonders wichtig bei CloudKit-Sync und mehreren Geräten.

* **Datenmigrationen mit realistischen Testbeständen:** Nicht nur leere Datenbanken, sondern große historische Session-, Foto- und Planbestände testen.

# Empfohlene Umsetzungsreihenfolge

## Phase 1: Vertrauen und Vollständigkeit

* Crash-sichere aktive Session
* Session-Snapshots
* Vollständige nachträgliche Bearbeitung
* Papierkorb und Undo
* Sync-Status und HealthKit-Deduplizierung
* Food Diary fertigstellen
* Supplement-Tagesliste fertigstellen

**Ziel:** Kein Nutzer verliert Daten oder stößt auf sichtbar unfertige Kernbereiche.

## Phase 2: Der bestmögliche Krafttraining-Logger

* Historische Set-Werte in der Live-Ansicht
* Satztypen, RIR und unilateral tracking
* Warm-up-Generator
* Scheibenrechner
* Übungssubstitution
* Maschinenprofile
* Besseres PR- und e1RM-System
* Übungs-Dashboards

**Ziel:** ThriveWood ist während einer Trainingseinheit schneller und hilfreicher als eine Notiz-App oder Tabelle.

## Phase 3: Planung und Progression

* Trainingskalender
* Fortlaufende A/B/C-Sequenzen
* Mehrwöchige Trainingsblöcke
* Progressionsregeln
* Plan-Adherence
* Effektive Sätze pro Muskel
* Monats- und Blockberichte

**Ziel:** ThriveWood speichert nicht nur Training, sondern steuert nachvollziehbar den Fortschritt.

## Phase 4: Recovery und adaptives Coaching

* Readiness-Check-in
* Muskelkater-Körperkarte
* HealthKit-Kontext
* Personalisierte Erholungsmodelle
* Deload- und Anpassungsvorschläge
* Adaptive Trainingspläne
* Fragen an die eigenen Daten

**Ziel:** Die App schließt den Kreis zwischen Training, Erholung und nächster Entscheidung.

## Phase 5: Apple-Ökosystem und Gym-Differenzierung

* Apple-Watch-App
* Interaktive Live Activities
* Erweiterte Widgets und App Intents
* Gym-Kompatibilität
* Geräteeinstellungen
* Gym-Routen und Alternativen
* Synchronisation mit dem macOS Gym Plan Builder

**Ziel:** ThriveWood erhält Funktionen, die nicht leicht von einem gewöhnlichen Workout-Tracker kopiert werden können.

## Phase 6: Sharing und Wachstum

* Private Planfreigabe
* Trainingspartner
* Coach-Modus
* Private Challenges
* Erweiterte Waldwelten
* Kosmetische Belohnungen
* Erst wesentlich später öffentliche Community-Funktionen

# Features, die ich vorerst bewusst nicht priorisieren würde

* **Öffentlicher Social Feed:** Sehr hoher Moderations- und Backend-Aufwand.
* **Workout-Marktplatz:** Erst sinnvoll, wenn Planerstellung, Import und Qualitätsprüfung perfekt funktionieren.
* **Live-Auslastung ganzer Gyms:** Benötigt kritische Nutzermasse und belastbare Infrastruktur.
* **Freier KI-Chat ohne Datengrundlage:** Produziert schnell generische oder falsche Empfehlungen.
* **Foto-Kalorienschätzung als Kernfunktion:** Zu ungenau für eine vertrauenswürdige Ernährungserfassung.
* **Medizinische Verletzungsdiagnosen:** Fachlich und rechtlich ungeeignet.
* **Aggressive Streak-Bestrafung:** Krankheit und notwendige Erholung dürfen nicht negativ sanktioniert werden.
* **Gamification nach maximalem Volumen:** Kann ungesundes Trainingsverhalten fördern.
* **Großes Web-Dashboard:** Vor Apple Watch, Trainingskalender und Progression wahrscheinlich weniger relevant.
* **Zu viele neue Hauptbereiche:** Zuerst die vorhandenen Bereiche miteinander verbinden und vollständig ausarbeiten.

## Mein klares Produktfazit

Der größte mögliche Sprung für ThriveWood wäre nicht „noch eine Analysekarte“, sondern ein Sport-System, das den Nutzer zuverlässig durch den gesamten Trainingszyklus begleitet:

* **Vor dem Training:** Was steht an und wie bereit bin ich?
* **Während des Trainings:** Was habe ich letztes Mal gemacht und was soll ich jetzt tun?
* **Nach dem Training:** Was hat sich verbessert?
* **Zwischen den Sessions:** Bin ich erholt und wie wird mein Plan angepasst?
* **Langfristig:** Welche Ziele, Gewohnheiten und körperlichen Entwicklungen hängen miteinander zusammen?

Wenn diese Schleife hervorragend funktioniert, werden Apple Watch, KI, Gym-Karte und Wald nicht wie getrennte Extras wirken, sondern wie Teile eines zusammenhängenden Produkts. Genau darin sehe ich das größte Differenzierungspotenzial von ThriveWood.