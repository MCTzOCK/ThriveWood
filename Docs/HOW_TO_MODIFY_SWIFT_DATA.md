# How to Modify SwiftData Models (Without Migration Plan)

**Stand: Juli 2026 — iOS 26+ / SwiftData**

---

## Prinzip

Kein `SchemaMigrationPlan`, kein `VersionedSchema`. Nur ein reines `Schema` mit allen `@Model`-Klassen. CoreData macht additive Änderungen (neue Entities, neue Attribute mit Defaults) automatisch per Lightweight Migration.

---

## SharedModelContainer

```swift
import SwiftData

enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            ModelA.self,
            ModelB.self,
            // Alle @Model-Klassen hier auflisten
        ])

        let config = ModelConfiguration(
            "AppName",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.example.app"),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
```

**Wichtig:** Kein `migrationPlan:`-Parameter.

---

## Neue `@Model`-Klasse hinzufügen

1. Neue Klasse definieren
2. In `Schema([...])` im `SharedModelContainer` aufnehmen
3. Fertig — CoreData legt die Tabelle automatisch an

---

## Neue Properties zu bestehender `@Model`-Klasse hinzufügen

**Regel:** Jede nicht-optionale Property braucht einen **Inline-Default**.

```swift
@Model
final class MyModel {
    var existingProperty: String

    // ✅ NEU: Inline-Default
    var newString: String = ""
    var newInt: Int = 0
    var newBool: Bool = false
    var newDouble: Double = 0.0
    var newDate: Date = .now
    var newUUID: UUID = UUID()

    // ✅ NEU: Optional — kein Default nötig
    var newOptional: String?
}
```

**Falsch (crasht bei Migration):**
```swift
var newString: String  // ❌ Kein Default → "Validation error missing attribute values"
```

Nur Defaults im `init()` reichen **nicht** — sie müssen direkt an der Property-Deklaration stehen.

---

## Häufige Fehler

| Fehler | Ursache | Lösung |
|---|---|---|
| `Validation error missing attribute values on mandatory destination attribute` | Neue nicht-optionale Property ohne Inline-Default | Inline-Default hinzufügen |
| `Duplicate version checksums detected` | MigrationPlan mit identischen Versionen | MigrationPlan entfernen (wird nicht gebraucht) |
| `Cannot migrate store in-place` | s.o. (fehlende Defaults) | Inline-Defaults setzen |

---

## Zusammenfassung

- **Kein** `VersionedSchema`, **kein** `SchemaMigrationPlan`
- Nur `Schema([...])` → `ModelContainer(for: schema, configurations: [...])`
- Neue Properties: **immer Inline-Default** bei nicht-optionalen Typen
- Neue Entities: einfach zur `Schema`-Liste hinzufügen