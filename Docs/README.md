# ThriveWood

**Grow your habits. Grow your forest.**

ThriveWood is a German-language iOS app that turns habit tracking into a living, growing virtual forest. Every completed habit earns points, every point plants a tree — making consistency visually rewarding.

## Features

### 🌲 Forest Gamification
Earn points for every habit you complete, then invest them in your personal forest. Eight tree species across six growth stages, each drawn with procedural SwiftUI geometry. Your forest is a living reflection of your consistency.

### ✅ Habit Tracking
Simple check-offs or measurable goals (water intake, steps, meditation minutes). Configure weekdays, reminders, and point difficulty. Streaks keep you coming back.

### 💪 Workout Tracker
Full session management with set-by-set logging, rest timers, and RPE rating. Build custom workouts, schedule training plans by weekday, and track personal records for every exercise.

**Exercise Tracking Modes:**
- **Reps × Weight** — Classic strength training (e.g. bench press)
- **Reps Only** — Bodyweight exercises (e.g. push-ups)
- **Duration** — Time-based exercises with a built-in fullscreen stopwatch timer (e.g. plank, stretching)
- **Distance & Time** — Cardio exercises with GPS distance tracking and live pace display (e.g. running, cycling, rowing)

**Smart Tracker (Duration & Cardio):**
- One-tap fullscreen tracker overlay for duration and distance exercises
- Automatic timer that counts up from start
- GPS-based distance tracking for cardio exercises with real-time pace (/km)
- Start / Pause / Resume controls
- Persists tracking state across app restarts — if the app closes or crashes mid-exercise, the tracker resumes exactly where it left off when reopened
- Completed sets show tracked values directly in the set row

### 🏋️ Muscle Rankings
An anatomical body map (SVG-based, both front and back) shows which muscles are trained and which need attention. Ranks from Untrained through Bronze, Silver, Gold, Platinum, Diamond, Champion, and Legend — based on volume and sets.

### 💊 Supplements & AI Analysis
Track daily supplements and get AI-powered feedback on whether your stack makes sense together.

### 📊 Analytics
Points trend, weekday distribution, habit leaderboard, completion heatmap, workout volume charts, and Apple Health step data — all in one dashboard.

### 🩺 Apple Health
Steps and health metrics pulled directly from HealthKit, displayed alongside your habits and workouts.

### 📱 Widgets & Live Activity
Home screen widgets for habits and forest preview. Live Activity on the lock screen during active workouts.

### 🎨 Pro Features
Additional accent themes (Ocean, Sunset, Lavender, Rosé), alternate app icons, extended analytics, and more — available via weekly, monthly, or lifetime subscription.

## Architecture

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI, iOS 17+ |
| Data | SwiftData with `ModelContainer` |
| Location | CoreLocation (GPS distance tracking) |
| Health | HealthKit |
| Payments | StoreKit 2 |
| AI | OpenAI API (supplement analysis) |
| Widgets | WidgetKit |
| Live Activity | ActivityKit |

## Project Structure

```
ThriveWood/
├── AppEnvironment.swift          # Dependency container
├── ThriveWoodApp.swift           # App entry point
├── Data/
│   ├── Models/                   # SwiftData models
│   └── SharedEnums.swift         # Enums, rankings, units
├── Services/                     # Business logic
│   ├── HabitService.swift
│   ├── WorkoutService.swift
│   ├── ExerciseTrackerService.swift  # Timer & GPS distance tracking
│   ├── RestTimer.swift
│   ├── MuscleRankingService.swift
│   ├── ForestService.swift
│   ├── SupplementService.swift
│   ├── AIService.swift
│   └── ...
├── Views/
│   ├── RootTabView.swift         # 5-tab navigation
│   ├── Home/                     # Habits tab
│   ├── Forest/                   # Virtual forest
│   ├── Analytics/                # Stats dashboard
│   ├── Food/                     # Nutrition & supplements
│   ├── Sport/                    # Workouts & muscle rankings
│   │   ├── MuscleRankings/
│   │   │   └── Support/
│   │   │       ├── AnatomicMuscleMapView.swift   # SVG body map
│   │   │       └── AnatomicMuscleHelpers.swift   # Path data
│   │   └── Sheets/              # Exercise & workout editors
│   │   └── ExerciseTracker/    # Fullscreen timer & GPS tracker
│   │       └── ExerciseTrackerView.swift
│   ├── HabitEditor/
│   ├── Onboarding/
│   ├── Settings/
│   ├── Paywall/
│   └── Helpers/
├── ThriveWoodWidgets/           # Home screen widgets
└── Assets.xcassets/             # Icons, colors, images
```

## Muscle Ranking System

Muscles are ranked by cumulative volume (kg) or total sets, whichever is higher:

| Rank | Min Volume (kg) | Min Sets |
|------|-----------------|----------|
| Untrained | 0 | 0 |
| Bronze | 3,000 | 30 |
| Silver | 10,000 | 100 |
| Gold | 25,000 | 250 |
| Platinum | 50,000 | 500 |
| Diamond | 100,000 | 1,000 |
| Champion | 200,000 | 2,000 |
| Legend | 400,000 | 4,000 |

The anatomical muscle map renders SVG paths for 25+ muscle zones on both front and back views, with interactive tap-to-select and color-coded rankings.

## Setup

1. Open `ThriveWood.xcodeproj` in Xcode 16+
2. Select the ThriveWood scheme
3. Build & run on simulator or device (iOS 17+)

### Requirements
- Xcode 16+
- iOS 17.0+
- Swift 6 compatible

## Localization

The app UI is in German. All user-facing strings are defined in `SharedEnums.swift` and the relevant view files.

## License

Private project. All rights reserved.