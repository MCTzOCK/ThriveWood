# HANDOFF.md — ThriveWood Project State

> **Last updated:** 2026-05-27  
> **Purpose:** Complete context for an AI agent to continue work on ThriveWood without prior session knowledge.

---

## 1. Project Overview

**ThriveWood** is a German-language iOS fitness & habit tracking app built with SwiftUI + SwiftData. The core metaphor: completing habits earns points, points plant trees in a virtual forest. The app also includes a full workout tracker with muscle ranking gamification, supplement tracking, and analytics.

- **Platform:** iOS 17+ (SwiftUI, SwiftData, Swift 6 concurrency)
- **Language:** UI strings are in German
- **Bundle ID:** com.bensiebert.ThriveWood
- **Architecture:** MVVM-like with `@Observable` services + protocol-based repositories

---

## 2. Project Structure

```
ThriveWood/
├── AppEnvironment.swift          # DI container — all repos & services
├── ThriveWoodApp.swift           # App entry point
├── SharedModelContainer.swift    # SwiftData ModelContainer setup
├── Data/
│   ├── Models/                   # SwiftData @Model classes
│   │   ├── SportDomain.swift     # Exercise, Workout, WorkoutSession, SetEntry, TrainingsPlan
│   │   ├── HabitDomain.swift     # Habit, HabitCompletion
│   │   ├── ForestDomain.swift    # Forest, Tree
│   │   ├── FoodDomain.swift      # Food, FoodEntry, Meal, MealTemplate
│   │   ├── MealDomain.swift
│   │   └── UserProfile.swift     # UserProfile (settings, preferences)
│   ├── SharedEnums.swift         # ALL enums: MuscleGroup, MuscleRank, ExerciseCategory, etc.
│   ├── Repositories.swift        # All SwiftData repository implementations
│   ├── Default/
│   │   └── BuiltInExercises.swift # Seed data for exercises
│   └── ThriveWoodBackup.swift    # JSON export/import
├── Services/                     # Business logic (all @MainActor @Observable)
│   ├── WorkoutService.swift      # ⭐ Workout/PR logic — most recently modified
│   ├── MuscleRankingService.swift
│   ├── HabitService.swift
│   ├── ForestService.swift
│   ├── AnalyticsService.swift
│   ├── NutritionService.swift
│   ├── SupplementService.swift
│   ├── AIService.swift           # OpenAI-based supplement analysis
│   ├── HealthKitService.swift
│   ├── StoreService.swift        # StoreKit 2
│   ├── EntitlementService.swift  # Pro/free feature gating
│   ├── NotificationService.swift
│   ├── RestTimer.swift
│   ├── WorkoutLiveActivityManager.swift
│   └── ... (see full list in README)
├── Views/
│   ├── RootTabView.swift         # 5-tab navigation: Habits, Forest, Analytics, Nutrition, Sport
│   ├── Home/                     # Habits tab
│   ├── Forest/                   # Virtual forest gamification
│   ├── Analytics/                # Dashboard + charts
│   ├── Food/                     # Nutrition & supplements
│   ├── Sport/                    # ⭐ Workout tracker, muscle rankings, PRs
│   │   ├── ActiveSessionView.swift  # Live workout (performance-optimized)
│   │   ├── WorkoutSessionDetailView.swift  # Post-workout summary + PRs
│   │   ├── PRListView.swift           # PR list → taps open ExerciseProgressionSheet
│   │   ├── Sheets/
│   │   │   └── ExerciseProgressionSheet.swift  # ⭐ NEW — PR progression chart
│   │   ├── Support/
│   │   │   ├── SetRow.swift           # ⭐ FlexibleNumberField for decimal input
│   │   │   ├── ElapsedTimer.swift     # Extracted timer subview (perf fix)
│   │   │   └── ...
│   │   └── MuscleRankings/
│   │       ├── MuscleRankingScreen.swift
│   │       └── Support/
│   │           ├── AnatomicMuscleMapView.swift   # ⭐ SVG body map (V2, renamed)
│   │           └── AnatomicMuscleHelpers.swift   # SVG path data
│   ├── HabitEditor/
│   ├── Onboarding/
│   ├── Settings/
│   ├── Paywall/
│   └── Helpers/
├── Helpers/
│   ├── DesignSystem.swift        # Theme.Spacing, Theme.Radius, Haptics
│   ├── Protocols.swift           # Repository protocols
│   ├── Extensions.swift
│   ├── DomainErrors.swift
│   └── WorkoutActivityAttributes.swift  # Live Activity attributes
└── ThriveWoodWidgets/            # WidgetKit widgets
```

---

## 3. Key Decisions & Conventions

### UI Language
- All user-facing strings are **German**. Enum labels, placeholder text, navigation titles, etc.
- Code comments can be in English or German

### Design System (`Helpers/DesignSystem.swift`)
- Spacing: `xs=4, s=8, m=12, l=16, xl=24, xxl=32`
- Corner radius: `s=10, m=16, l=22`
- Card style: `.cardStyle()` modifier (rounded rect, shadow)
- Haptics: `Haptics.selection()`, `Haptics.success()`, `Haptics.impact(.light/.medium/.heavy)`

### Dependency Injection
- `AppEnvironment` is `@MainActor @Observable` — injected everywhere via `@Environment(AppEnvironment.self)`
- All repositories are protocol-based (defined in `Protocols.swift`) with SwiftData concrete implementations
- Services are created in `AppEnvironment.init()` and injected into each other

### SwiftData Models
- All `@Model` classes use `@Attribute(.unique) var id: UUID`
- Relationships use `@Relationship(deleteRule: .cascade/.nullify, inverse: \...)`
- `SetEntry` has `exercise: Exercise?`, `session: WorkoutSession?` relationships

### Pro Feature Gating
- `EntitlementService` checks StoreKit 2 subscriptions
- Pro features: extended analytics (30/90/365 day ranges), accent themes, app icons, muscle ranking map
- Free tier: 7-day analytics, green accent, default icon

---

## 4. Recent Changes (This Session)

### 4.1 AnatomicMuscleMapView (SVG Body Map) — Complete Rewrite
- **Before:** Hand-drawn bezier curves (V1) with symmetry issues
- **After:** SVG-path-based renderer (V2, renamed to `AnatomicMuscleMapView`)
- **Key fix:** Back view was empty because SVG paths use viewBox offset x=37. The parser now subtracts `vbOriginX` in the coordinate transform
- **Key fix:** Label positions were top-left because `approximateCenter()` was broken — replaced with `Path.boundingRect`
- **Key fix:** Unranked muscles invisible — changed from `systemGray5.opacity(0.3)` to `systemGray3.opacity(0.55)`
- **File:** `Views/Sport/MuscleRankings/Support/AnatomicMuscleMapView.swift`
- **Helper:** `AnatomicMuscleHelpers.swift` contains SVG path data for front (viewBox "0 0 35 93") and back (viewBox "37 0 35 93") views
- **Mapping:** `svgIdToMuscleGroup()` maps SVG path IDs to `MuscleGroup` enum cases. Non-tappable IDs (head, hands, feet, etc.) return `nil`
- **Old V1 file deleted** — only `AnatomicMuscleMapView.swift` (V2) remains

### 4.2 ActiveSessionView Performance Fix
- **Problem:** Production builds ran hot and drained battery; debug builds were fine
- **Root cause:** Timer fired every second → entire view body re-evaluated → `groupedSets` recomputed → all ExerciseBlocks re-rendered
- **Fix 1:** Extracted `ElapsedTimer` into isolated subview with its own `@State` + `onReceive(timer)` — only this tiny view re-renders per second
- **Fix 2:** Cached `groupedSets`, `cachedCompletedCount`, `cachedTotalVolume`, `cachedExerciseCount` as `@State` — updated only via `onChange(of: session.sets.count)` and `onChange(of: completedSignature)`
- **File:** `Views/Sport/ActiveSessionView.swift`
- **Extracted:** `Views/Sport/Support/ElapsedTimer.swift`

### 4.3 SetRow Decimal Input Fix
- **Problem:** Comma in decimal fields disappeared immediately because `TextField(value:format:)` parsed "12," as `12.0` and wrote it back
- **Fix:** Created `FlexibleNumberField` that uses `@State var text: String` internally, only commits to the `Double` binding on focus loss
- **Only applies when `decimal: true`** — integer fields still use the native `TextField(value:format:)`
- **File:** `Views/Sport/Support/SetRow.swift`

### 4.4 PR System — New Features
- **`WorkoutService.getTopSetBefore(exercise:date:)`** — Finds the best set for an exercise from all sessions that ended *before* the given date
- **`WorkoutService.getNewPRs(in:)`** — For a completed session, compares each exercise's best set against the previous all-time best. Returns exercises where a new PR was set
- **`WorkoutService.getProgression(for:)`** — Returns chronological list of PR breakthroughs for an exercise (date, value, optional reps). Uses `setIsLess` for comparison so e.g. same weight + more reps = new PR
- **`WorkoutService.setIsLess(_:_:for:)`** — Extracted shared comparison logic used by `getTopSet`, `getAllPRs`, `getNewPRs`, and `getProgression`
- **`ExerciseProgressionSheet`** — New sheet showing:
  - Current PR header with value + date
  - Chart (SwiftUI Charts) with line + area marks, catmull-rom interpolation, axis labels
  - For `repsWeight`: reps shown as annotations above each data point
  - PR history list with trophy on latest entry
- **`PRListView`** — Now opens `ExerciseProgressionSheet` instead of `ExerciseDetailsSheet`. Uses `PRSelection` struct (Identifiable) to fix the "first tap shows empty sheet" bug

### 4.5 WorkoutSessionDetailView — New PR Banner
- Shows "Neue persönliche Rekorde" section when the session achieved new PRs
- Each PR card shows exercise icon, name, old PR → new PR with arrow, flame icon
- PRs loaded via `env.workoutService.getNewPRs(in: session)` on `.onAppear`

### 4.6 MuscleRank Thresholds (Adjusted)
- Bronze: 3,000 kg → discussed but **not changed** (user decided to keep current values)
- See `SharedEnums.swift` `MuscleRank.minVolume` for current thresholds

### 4.7 App Store Screenshots
- Scaffolded Next.js + ShadCN screenshot editor in project root
- Custom "Warm Forest" theme (`warm-forest`) added to match ThriveWood's brand
- German locale (`de`) seeded with 6 iPhone slides, 3 iPad slides
- **File:** `src/lib/defaults.ts` — app name "ThriveWood", locales ["de", "en"]
- **File:** `src/lib/constants.ts` — added `warm-forest` theme to `THEMES`
- **File:** `src/lib/types.ts` — added `warm-forest` to `ThemeId` union
- **Run:** `pnpm dev` from project root → http://localhost:3000

### 4.8 APPSTORE.md & README.md
- Created `APPSTORE.md` with German Werbetext, Beschreibung, Schlüsselwörter
- Created `README.md` with English project documentation

---

## 5. Known Issues & Open Tasks

### Bugs / Incomplete
- **Nutrition tab** (`Food/NutritionTab.swift`) — "Ernahrung" segment shows "Coming soon" placeholder; supplement tracking is functional
- **MuscleMapView.swift** (`Views/Sport/MuscleRankings/Support/MuscleMapView.swift`) — Old V1 map view still exists as a file but is no longer referenced. Can be deleted.
- **App Store Screenshots** — Scaffolded but no actual device screenshots captured yet. User needs to run the app in simulator and screenshot, then drop images into the editor.

### Potential Improvements
- **MuscleRank thresholds** — Discussed raising Bronze from 3k→5k and Gold from 25k→20k, but user hasn't confirmed
- **ActiveSessionView** — Could further optimize by making `ExerciseBlock` Equatable to skip re-renders when data hasn't changed
- **SetRow decimal input** — The `FlexibleNumberField` currently doesn't handle locale-specific grouping separators (e.g. "1.000" in German). For now it works correctly for decimal comma input.

---

## 6. Architecture Patterns

### Service Layer
```
AppEnvironment (DI container)
  ├── Repositories (protocol-based, SwiftData-backed)
  │   └── All CRUD operations throw
  └── Services (@MainActor @Observable)
      ├── WorkoutService — session lifecycle, PR logic, set logging
      ├── MuscleRankingService — volume/sets calculation, ranking
      ├── HabitService — habit CRUD, completion toggle
      ├── ForestService — tree planting, growth stages
      └── ... (see full list in AppEnvironment.swift)
```

### View → Service Communication
- Views bind to `@Environment(AppEnvironment.self)` 
- Services are `@Observable` — views react to changes automatically
- `WorkoutService.activeSession` is the single source of truth during a workout
- `WorkoutSession` is `@Bindable` — view mutations to sets directly update SwiftData

### PR Logic (Critical — Must Match)
The `setIsLess` function in `WorkoutService` determines what counts as "better":
```swift
// repsWeight: higher weight wins; same weight → higher reps wins
// reps: higher reps wins
// duration: longer duration wins
// distanceDuration: longer distance wins; same distance → shorter time wins
```
This is used consistently by: `getTopSet`, `getAllPRs`, `getNewPRs`, `getProgression`

---

## 7. Build & Run

```bash
# Open in Xcode
open ThriveWood.xcodeproj

# Or build from CLI
xcodebuild -project ThriveWood.xcodeproj -scheme ThriveWood \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# For Release profiling (to test performance fixes):
# Xcode → Product → Scheme → Edit Scheme → Run → Build Configuration → Release

# App Store Screenshots editor (Next.js)
pnpm dev  # → http://localhost:3000
```

### Key Dependencies
- SwiftData (iOS 17+)
- Swift Concurrency (`@MainActor`, `async/await`)
- StoreKit 2
- HealthKit
- WidgetKit / ActivityKit (Live Activities)
- Charts framework (SwiftUI Charts)
- Foundation Models (Apple Intelligence, supplement analysis — iOS 26+)

---

## 8. File Index — Most Recently Modified Files

These are the files most likely to need context in the next session:

| File | What changed |
|------|-------------|
| `WorkoutService.swift` | Added `getTopSetBefore`, `getNewPRs`, `getProgression`, `setIsLess` |
| `WorkoutSessionDetailView.swift` | Added PR section + `onAppear { loadPRs() }` |
| `PRListView.swift` | Changed from `ExerciseDetailsSheet` → `ExerciseProgressionSheet`, added `PRSelection` struct |
| `ExerciseProgressionSheet.swift` | **NEW** — PR progression chart + history list |
| `ActiveSessionView.swift` | Performance fix: extracted `ElapsedTimer`, cached `groupedSets` |
| `ElapsedTimer.swift` | **NEW** — Isolated timer subview |
| `SetRow.swift` | Added `FlexibleNumberField` for decimal input |
| `AnatomicMuscleMapView.swift` | Complete rewrite (SVG-based), viewBox offset fix, label positioning via boundingRect |
| `AnatomicMuscleHelpers.swift` | SVG path data for front/back body views |
| `SharedEnums.swift` | MuscleRank thresholds (unchanged but discussed) |
| `defaults.ts` / `constants.ts` / `types.ts` | App Store screenshot editor configs |
| `APPSTORE.md` | German App Store copy |
| `README.md` | English project documentation |