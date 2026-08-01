# Swift iOS App — Style Guide

## 1. Architecture Overview

The app follows an **MVVM-like architecture** with centralized dependency injection through a single `AppEnvironment` container. All data flows unidirectionally:

```
User → View → ViewModel/Service → Repository → Persistence
                      ↓
              @Observable state update
                      ↓
                    View
```

### Layer Responsibilities

| Layer | Role | Examples |
|---|---|---|
| **Model** | SwiftData `@Model` classes, enums, value types | `Habit`, `WorkoutSession`, `MuscleGroup` |
| **Repository** | Protocol-based CRUD wrappers around persistence | `HabitRepository`, `SwiftDataHabitRepository` |
| **Service** | Business logic, state management, `@MainActor @Observable` | `HabitService`, `WorkoutService` |
| **ViewModel** | Screen-scoped state coordinator, calls services | `HomeViewModel`, `ForestViewModel` |
| **View** | Declarative SwiftUI, zero business logic | `HomeView`, `ForestView` |

---

## 2. Directory Structure

```
AppName/
├── AppEnvironment.swift          # Central DI container
├── AppNameApp.swift              # @main entry point
├── SharedModelContainer.swift    # SwiftData ModelContainer
├── Data/
│   ├── Models/                   # One file per domain
│   │   ├── HabitDomain.swift
│   │   ├── SportDomain.swift
│   │   └── ...
│   ├── SharedEnums.swift         # All app-wide enums
│   ├── Repositories.swift        # Protocol defs + SwiftData impls
│   └── Default/                  # Seed / bootstrap data
├── Services/                     # Business logic (@MainActor @Observable)
├── Helpers/                      # DesignSystem, Extensions, Protocols
└── Views/
    ├── RootTabView.swift
    ├── FeatureA/
    │   ├── FeatureAView.swift      # Main screen
    │   ├── FeatureAViewModel.swift # Screen coordinator
    │   ├── Support/                # Inline sub-components
    │   └── Sheets/                 # Modal presentations
    ├── FeatureB/
    │   ├── FeatureBView.swift
    │   ├── FeatureBViewModel.swift
    │   ├── Support/
    │   ├── Sheets/
    │   └── SubFeature/             # Nested feature (with own Support/ & Sheets/)
    └── ...
```

### Rules

- **One SwiftUI View per file.** Never put two `View` structs in the same file.
- **One ViewModel per main screen.** The ViewModel is a `@MainActor @Observable final class` that coordinates state for exactly one screen.
- **Support/** holds inline sub-components used only within that feature (cards, rows, cells, headers).
- **Sheets/** holds views presented via `.sheet()` or `.fullScreenCover()` — modal presentations, not inline content.
- Sub-features that are complex enough to warrant their own Support/Sheets/ get their own subdirectory (e.g. `Sport/MuscleRankings/`).

---

## 3. AppEnvironment — Single Source of Truth

`AppEnvironment` is the **only** place where services and repositories are instantiated. It is injected into the SwiftUI environment and accessed everywhere.

### Structure

```swift
@MainActor
@Observable
final class AppEnvironment {
    // Repositories (protocol-typed for testability)
    let habitRepo: any HabitRepository
    let forestRepo: any ForestRepository
    // ...

    // Services
    let habitService: HabitService
    let forestService: ForestService
    let workoutService: WorkoutService!
    // ...

    init(context: ModelContext) {
        // 1. Create repos (SwiftData-backed)
        self.habitRepo = SwiftDataHabitRepository(context: context)
        // 2. Create services (injecting repos)
        self.habitService = HabitService(habits: habitRepo, completions: completionRepo)
        // 3. Late-init services that need `self`
        self.workoutService = WorkoutService(env: self)
    }
}
```

### Access Pattern in Views

```swift
struct FeatureView: View {
    @Environment(AppEnvironment.self) private var env
    // ...
}
```

### Access Pattern in ViewModels

```swift
@MainActor
@Observable
final class FeatureViewModel {
    private let env: AppEnvironment
    init(env: AppEnvironment) { self.env = env }
}
```

**Never** create services or repos outside `AppEnvironment`. All cross-service communication goes through `env`.

---

## 4. View Pattern

Every screen follows this exact structure:

```swift
struct FeatureView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: FeatureViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Titel")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if vm == nil { vm = FeatureViewModel(env: env) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: FeatureViewModel) -> some View {
        // Main content, extracted into @ViewBuilder functions
    }
}
```

### Key Rules

- ViewModels are **lazily initialized** via `@State private var vm: XxxViewModel?` and `.task { }`.
- The `@Bindable var vm = vm` conversion happens inside `@ViewBuilder` functions, not at the struct level.
- Business logic **never** lives in a View. If a method does more than UI formatting, it belongs in the ViewModel or Service.
- Extract complex view hierarchies into **private `@ViewBuilder` functions** or **separate Support/ files** — never inline everything in `body`.
- Use `.errorAlert(vm.errors)` for error presentation via the shared `ErrorState`.

---

## 5. ViewModel Pattern

```swift
@MainActor
@Observable
final class FeatureViewModel {
    let env: AppEnvironment

    // State
    var items: [SomeModel] = []
    var selectedItem: SomeModel?

    // Error handling
    let errors = ErrorState()

    init(env: AppEnvironment) { self.env = env }

    // MARK: - Load

    func load() {
        do {
            items = try env.someService.fetchAll()
        } catch {
            errors.show(error)
        }
    }

    // MARK: - Actions

    func performAction() {
        do {
            try env.someService.doSomething()
            Haptics.success()
            withAnimation { load() }
        } catch {
            Haptics.warning()
            errors.show(error)
        }
    }
}
```

### Rules

- ViewModels are `@MainActor @Observable final class`.
- They hold a reference to `AppEnvironment` via `let env`.
- They contain **screen-scoped state** (items, selections, filter state).
- They **never** directly access repositories — always go through services.
- They use `ErrorState` for error presentation (not thrown to views).
- Haptic feedback (`Haptics.success()`, `.warning()`, `.selection()`) is triggered in ViewModels.
- State mutations that should animate are wrapped in `withAnimation { ... }`.
- Use `// MARK: -` sections to organize: Load, Actions, Helpers.

---

## 6. Service Pattern

```swift
@MainActor
@Observable
final class SomeService {
    private let repo: any SomeRepository

    // Observable state (read-mostly, services can publish)
    private(set) var activeSession: WorkoutSession?

    init(repo: any SomeRepository) {
        self.repo = repo
    }

    func performAction() throws -> Int {
        let result = try repo.doSomething()
        return result
    }
}
```

### Rules

- Services are `@MainActor @Observable final class`.
- They receive **repositories via protocol** in their `init` (dependency injection).
- Services that need other services receive `env: AppEnvironment` (late-init pattern for circular dependencies).
- State published to views uses `private(set)` — views read, services write.
- Synchronous methods `throw` errors. Async methods `async throws`.
- Services **never** import SwiftUI (except for `WidgetKit` or specific UI types).
- One service file per domain concept. Keep them focused.

---

## 7. Repository Pattern

### Protocol Definition (in `Helpers/Protocols.swift`)

```swift
protocol HabitRepository {
    func fetchAll(includeArchived: Bool) throws -> [Habit]
    func fetch(id: UUID) throws -> Habit?
    func create(_ habit: Habit) throws
    func update(_ habit: Habit) throws
    func archive(_ habit: Habit) throws
    func delete(_ habit: Habit) throws
}
```

### SwiftData Implementation (in `Data/Repositories.swift`)

```swift
@MainActor
final class SwiftDataHabitRepository: SwiftDataRepository, HabitRepository {
    func fetchAll(includeArchived: Bool = false) throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(...)
        return try context.fetch(descriptor)
    }
    // ...
}
```

### Base Class

All SwiftData repos inherit from `SwiftDataRepository`, which provides `context: ModelContext` and `save() throws`.

### Rules

- Protocols are defined in `Helpers/Protocols.swift`.
- Implementations live in `Data/Repositories.swift`.
- Repos are **thin wrappers** around SwiftData — no business logic.
- Error handling wraps SwiftData errors into `RepositoryError`.
- All repos are `@MainActor`.

---

## 8. Data Model Pattern

### Domain-Based Files

Models are organized **one file per domain**, not one file per model:

```
Data/Models/
├── HabitDomain.swift      # Habit, HabitCompletion
├── SportDomain.swift      # Exercise, Workout, WorkoutSession, SetEntry, ...
├── ForestDomain.swift     # Forest, TreeEntity
├── FoodDomain.swift       # Food, FoodEntry
├── MealDomain.swift       # MealTemplate, MealTemplateItem
└── UserProfile.swift      # UserProfile
```

### Model Structure

```swift
@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var trackingModeRaw: String    // Raw value for enum
    var pointsRaw: Int

    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion] = []

    // Typed computed accessors
    var trackingMode: HabitTrackingMode {
        get { HabitTrackingMode(rawValue: trackingModeRaw) ?? .simple }
        set { trackingModeRaw = newValue.rawValue }
    }
}
```

### Rules

- SwiftData models use `@Model final class`.
- `@Attribute(.unique)` on `id: UUID` fields.
- Enums are stored as raw values (`String` or `Int`) with typed computed properties.
- Relationships use explicit `deleteRule` (`.cascade` or `.nullify`).
- All enums live in `Data/SharedEnums.swift`.

---

## 9. Naming Conventions

| Category | Pattern | Example |
|---|---|---|
| Main screen View | `XxxView.swift` | `HomeView.swift`, `SportView.swift` |
| ViewModel | `XxxViewModel.swift` | `HomeViewModel.swift` |
| Support component | `XxxRow.swift`, `XxxCard.swift`, `XxxCell.swift` | `HabitRowView.swift`, `ForestCell.swift` |
| Sheet / Modal | `XxxSheet.swift` | `TreeDetailSheet.swift`, `FinishSessionSheet.swift` |
| Editor modal | `XxxEditorView.swift` | `FoodEditorView.swift` |
| Service | `XxxService.swift` | `HabitService.swift` |
| Repository protocol | `XxxRepository` | `HabitRepository` |
| Repository impl | `SwiftDataXxxRepository` | `SwiftDataHabitRepository` |
| Domain models file | `XxxDomain.swift` | `HabitDomain.swift` |
| Enum file | `SharedEnums.swift` (single file) | All enums together |
| Design tokens | `Theme.Spacing.l`, `Theme.Radius.m` | Static constants |

---

## 10. Design System

### Spacing & Layout

```swift
Theme.Spacing.xs   // 4
Theme.Spacing.s    // 8
Theme.Spacing.m    // 12
Theme.Spacing.l    // 16
Theme.Spacing.xl   // 24
Theme.Spacing.xxl  // 32
```

### Corner Radius

```swift
Theme.Radius.s     // 10
Theme.Radius.m     // 16
Theme.Radius.l     // 22
```

### Haptics

```swift
Haptics.selection()   // UI selection feedback
Haptics.success()     // Action succeeded
Haptics.warning()     // Action failed / error
Haptics.impact(.soft) // Light feedback
Haptics.impact(.medium) // Default
```

### Error Handling in Views

```swift
// In ViewModel:
let errors = ErrorState()

// In View:
.errorAlert(vm.errors)

// In ViewModel actions:
do { ... } catch { errors.show(error) }
```

### Card Style

Views use `.cardStyle()` modifier for consistent card appearance.

---

## 11. SwiftUI Conventions

- **Never** use `@StateObject` or `@ObservedObject`. Use `@Observable` + `@State` (Swift 6 pattern).
- **Never** use `@EnvironmentObject`. Use `@Environment(AppEnvironment.self)`.
- Use `@Bindable` only inside `@ViewBuilder` functions where binding is needed.
- Prefer `NavigationStack` over `NavigationView`.
- Use `.task { }` for initialization, not `.onAppear { }`.
- Extract complex view builders into `@ViewBuilder private func` methods or separate Support/ files.
- Use `fileprivate enum` for local state enums (e.g. `fileprivate enum HomeTab { case habits, supplements }`).
- Animations are applied at the call site in ViewModels: `withAnimation { load() }`.

---

## 12. File Organization Within a Feature

A well-structured feature directory:

```
Feature/
├── FeatureView.swift           # Main screen (NavigationStack + routing)
├── FeatureViewModel.swift      # Screen state coordinator
├── Support/                    # Inline sub-components
│   ├── FeatureStatsHeader.swift
│   ├── FeatureRow.swift
│   └── FeatureCard.swift
└── Sheets/                     # Modal presentations
    ├── DetailSheet.swift
    └── EditorView.swift
```

### What goes in Support/

- Reusable row/cell/card components used only in this feature.
- Header sections, progress indicators, summary tiles.
- Helper views that are composed into the main screen's `body`.

### What goes in Sheets/

- Views presented via `.sheet()` or `.fullScreenCover()`.
- Editor flows that modally present.
- Detail views that overlay the current screen.

### What gets its own ViewModel

- Only the **main screen** of a feature gets a ViewModel.
- Sheets and Support components receive data via **initializer parameters** — they do not get their own ViewModel.
- If a sheet becomes complex enough, it **may** get its own ViewModel, but this is the exception, not the rule.

---

## 13. Error Handling

```swift
// Domain errors — in DomainErrors.swift
enum ServiceError: LocalizedError {
    case noActiveSession
    case insufficientPoints(required: Int, available: Int)
    case speciesLocked(species: TreeSpecies, requires: Int)

    var errorDescription: String? { ... }
}

enum RepositoryError: LocalizedError {
    case notFound
    case persistenceFailed(underlying: Error)
    case invalidInput(String)

    var errorDescription: String? { ... }
}
```

- Services `throw` typed errors.
- ViewModels catch errors and forward to `ErrorState`.
- Views present errors via `.errorAlert(vm.errors)`.
- Never show raw error messages to users — always use `LocalizedError`.

---

## 14. Checklist for New Features

When adding a new feature, follow this order:

1. **Define models** in `Data/Models/XxxDomain.swift` (SwiftData `@Model` classes).
2. **Add enums** to `Data/SharedEnums.swift` if needed.
3. **Define repository protocol** in `Helpers/Protocols.swift`.
4. **Implement repository** in `Data/Repositories.swift` (`SwiftDataXxxRepository`).
5. **Create service** in `Services/XxxService.swift` (`@MainActor @Observable final class`).
6. **Register in AppEnvironment** — add repo and service to `init(context:)`.
7. **Create feature directory** under `Views/Xxx/` with View + ViewModel.
8. **Add Support/** and **Sheets/** subdirectories as needed.
9. **Wire into RootTabView** if it's a new tab.
10. **Update SharedModelContainer** if new SwiftData models were added.