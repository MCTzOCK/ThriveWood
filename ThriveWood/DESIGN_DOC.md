# ThriveWood - Architecture Design Document

## Table of Contents
1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Overview](#architecture-overview)
4. [Data Model](#data-model)
5. [Domain Architecture](#domain-architecture)
6. [Service Layer](#service-layer)
7. [User Interface](#user-interface)
8. [Data Flow](#data-flow)
9. [Key Features Implementation](#key-features-implementation)
10. [State Management](#state-management)
11. [External Integrations](#external-integrations)
12. [Performance Considerations](#performance-considerations)
13. [Testing Strategy](#testing-strategy)
14. [Deployment](#deployment)

## Overview

ThriveWood is a German-language iOS fitness and habit tracking application that combines gamification elements with comprehensive health tracking. The app features a unique "virtual forest" metaphor where completing habits earns points that can be used to plant and grow trees in a virtual forest.

### Core Features
- **Habit Tracking**: Simple check-offs or measurable goals with configurable difficulty points
- **Workout Tracking**: Full session management with set-by-set logging, rest timers, and RPE rating
- **Forest Gamification**: Eight tree species across six growth stages with procedural SwiftUI rendering
- **Muscle Rankings**: Anatomical body map showing training focus and muscle development progress
- **Supplement Tracking**: Daily supplement logging with AI-powered stack analysis
- **Analytics Dashboard**: Comprehensive trend analysis, heatmaps, and progress charts
- **Apple Health Integration**: HealthKit integration for steps and health metrics
- **Widgets & Live Activities**: Home screen widgets and lock screen Live Activities during workouts

## Technology Stack

### Platforms & Frameworks
- **Platform**: iOS 17+ (SwiftUI, SwiftData, Swift 6 concurrency)
- **UI Framework**: SwiftUI with programmatic tree geometry generation
- **Data Persistence**: SwiftData with CloudKit synchronization
- **Dependency Management**: Built-in Swift Package Manager
- **Widget Framework**: WidgetKit for home screen widgets
- **Live Activities**: ActivityKit for lock screen workout tracking
- **Charts**: SwiftUI Charts framework for data visualization

### External Dependencies
- **HealthKit**: For reading health metrics and workout data
- **StoreKit 2**: For in-app purchases and subscription management
- **OpenAI API**: For supplement stack analysis
- **Textual**: Markdown parsing for UI content

### Build Configuration
- **IDE**: Xcode 16+
- **Deployment Target**: iOS 17.0+
- **Swift Version**: Swift 6 compatible
- **Architecture**: MVVM-like with dependency injection

## Architecture Overview

### Architectural Pattern
ThriveWood follows a **MVVM-like architecture** with:
- **Model**: SwiftData persistent models with business logic
- **View**: SwiftUI views with minimal logic
- **ViewModel**: Observable services containing business logic

### Key Architectural Decisions
1. **Dependency Injection**: Centralized in `AppEnvironment` for all services
2. **Repository Pattern**: Protocol-based repositories with SwiftData implementations
3. **Service Layer**: Business logic separated into focused, testable services
4. **Observable Pattern**: All services use `@Observable` for reactive UI updates

### Directory Structure
```
ThriveWood/
├── AppEnvironment.swift          # DI container - all repos & services
├── ThriveWoodApp.swift           # App entry point
├── SharedModelContainer.swift    # SwiftData ModelContainer setup
├── Data/
│   ├── Models/                   # SwiftData @Model classes
│   │   ├── SportDomain.swift     # Exercise, Workout, WorkoutSession, SetEntry
│   │   ├── HabitDomain.swift     # Habit, HabitCompletion
│   │   ├── ForestDomain.swift    # Forest, Tree
│   │   ├── FoodDomain.swift      # Food, FoodEntry, Meal
│   │   └── UserProfile.swift     # User settings and preferences
│   ├── SharedEnums.swift         # All enums: MuscleGroup, MuscleRank, etc.
│   └── Repositories.swift        # SwiftData repository implementations
├── Services/                     # Business logic (all @MainActor @Observable)
│   ├── WorkoutService.swift      # Session lifecycle, PR logic, set logging
│   ├── HabitService.swift        # Habit CRUD, completion tracking
│   ├── ForestService.swift       # Tree planting, growth management
│   ├── AnalyticsService.swift    # Data aggregation and chart preparation
│   ├── MuscleRankingService.swift# Muscle ranking calculations
│   ├── StoreService.swift        # Subscription management
│   └── ... (other services)
├── Views/
│   ├── RootTabView.swift         # 5-tab navigation
│   ├── Home/                     # Habits and habit tracking
│   ├── Forest/                   # Virtual forest gamification
│   ├── Analytics/                # Charts and statistics
│   ├── Sport/                    # Workout tracking and muscle rankings
│   └── Settings/                 # App configuration
└── ThriveWoodWidgets/            # WidgetKit extensions
```

## Data Model

### SwiftData Schema
The app uses SwiftData with CloudKit synchronization across 19 model types:

#### Core Domain Models

**Habit Tracking**
```swift
@Model final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var pointsRaw: Int                // 1-3 points based on difficulty
    var trackingModeRaw: String      // simple or measurable
    var activeWeekdays: [Int]        // Days habit is active
    var targetValue: Double          // Goal for measurable habits
    @Relationship var completions: [HabitCompletion] = []
}

@Model final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var day: Date                     // Calendar day for tracking
    var pointsAwarded: Int
    var currentValue: Double          // Progress for measurable habits
    var habit: Habit?
}
```

**Workout tracking**
```swift
@Model final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var estimatedDurationMinutes: Int
    @Relationship var exercises: [WorkoutExercise] = []
    @Relationship var sessions: [WorkoutSession] = []
}

@Model final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var perceivedExertion: Int?      // RPE 1-10
    @Relationship var sets: [SetEntry] = []
}

@Model final class SetEntry {
    @Attribute(.unique) var id: UUID
    var reps: Int?                   // Repetitions
    var weight: Double?              // Weight in kg/lb
    var durationSeconds: Int?        // For time-based exercises
    var distanceMeters: Double?      // For cardio exercises
    var isCompleted: Bool
    var session: WorkoutSession?
    var exercise: Exercise?
    
    // Volume calculation varies by exercise type
    var volumeValue: Double { /* implementation */ }
}
```

**Exercise Library**
```swift
@Model final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String           // strength, cardio, mobility, etc.
    var trackingTypeRaw: String      // repsWeight, reps, duration, distanceDuration
    var primaryMuscleGroupsRaw: [String]
    var secondaryMuscleGroupsRaw: [String]
    var isBuiltIn: Bool               // System vs custom exercises
}
```

**Forest Gamification**
```swift
@Model final class Forest {
    @Attribute(.unique) var id: UUID
    var totalPointsEarned: Int
    var spentPoints: Int
    @Relationship var trees: [TreeEntity] = []
}

@Model final class TreeEntity {
    @Attribute(.unique) var id: UUID
    var speciesRaw: String           // oak, pine, birch, etc.
    var gridX: Int                  // Position in forest grid
    var gridY: Int
    var growthPoints: Int           // 0-5 for growth stages
    var plantedAt: Date
    var forest: Forest?
}
```

### Enum-driven Design
The app heavily uses enums for type safety and UI consistency in `SharedEnums.swift`:

- **MuscleGroup**: 40+ muscle groups with anatomical positioning
- **MuscleRank**: 8 ranks from Untrained to Legend with volume thresholds
- **ExerciseCategory**: 7 exercise categories
- **ExerciseTrackingType**: 4 tracking types (repsWeight, reps, duration, distanceDuration)
- **TreeSpecies**: 8 tree species with unlock thresholds
- **TreeGrowthStage**: 6 growth stages based on accumulated points

### Data Relationships
The SwiftData models form a cohesive graph:
- Habits → Completions (1:N cascade delete)
- Forest → Trees (1:N cascade delete)
- Workouts → WorkoutExercise (1:N cascade delete)
- WorkoutExercise → Exercise (N:1)
- Workouts → Sessions (1:N nullify delete)
- Sessions → Sets (1:N cascade delete)
- Sets → Exercise (N:1)
- Sets → Session (N:1)

## Domain Architecture

### Domain Separation
The app is organized around 5 distinct domains, each with their models, services, and views:

1. **Habits Domain**: Daily habit tracking with points-based gamification
2. **Workout Domain**: Exercise tracking with comprehensive workout management
3. **Forest Domain**: Virtual forest gamification system
4. **Analytics Domain**: Data aggregation and visualization
5. **Settings Domain**: User preferences and app configuration

### Business Rules & Invariants
- **Points System**: Each habit completion awards 1-3 points based on difficulty
- **Muscle Ranking**: Combines volume (kg) and set count with specifically defined thresholds
- **Forest Ownership**: Each user has exactly one forest with a 10×10 tree grid
- **Exercise Catalog**: Built-in exercises are immutable, but users can create custom ones
- **Session State**: Only one active workout session can exist at a time

### Domain Interactions
- Habit completions generate points for forest gameplay
- Workout sessions contribute to muscle rankings
- All user activities feed into analytics
- Settings across domains affect user experience consistently

## Service Layer

### Service Architecture
All services are `@MainActor @Observable` classes that coordinate between views and repositories:

```swift
@MainActor
@Observable
final class ExampleService {
    private let repo: SomeRepository
    // Observable state properties
    var someState: StateProperty
    
    init(repo: SomeRepository) {
        self.repo = repo
        // Initialize state
    }
    
    // Business methods
    func performAction() async throws {
        // Business logic
        // State updates
        // Repository calls
    }
}
```

### Key Services Implementation

**WorkoutService**
- Manages active workout session state
- Handles PR (Personal Record) detection and tracking
- Provides set logging with performance optimization
- Integrates with HealthKit for workout data

**HabitService**  
- Manages habit lifecycle (create, update, delete, archive)
- Handles completion tracking with points calculation
- Coordinates with NotificationService for reminders

**ForestService**
- Manizes tree planting, growth, and forest state
- Implements points economy for gamification
- Handles grid positioning and species unlocking

**AnalyticsService**
- Aggregates data across all domains for charts
- Provides heatmapped habit completion visualization
- Prepares workout trend analysis data

**MuscleRankingService**
- Calculates muscle development rankings
- Primary vs secondary muscle credit distribution
- Provides weakest/strongest muscle identification

### Service-to-Service Dependencies
Services form a dependency graph through `AppEnvironment`:
- `WorkoutService` depends on `MuscleRankingService` for analytics
- `ForestService` depends on `ScoringService` for points calculations
- `AnalyticsService` aggregates data from multiple domain repositories

### Error Handling
Services use structured error handling:
```swift
enum ServiceError: LocalizedError {
    case noActiveSession
    case insufficientPoints(required: Int, available: Int)
    case speciesLocked(species: TreeSpecies, requires: Int)
    case sessionAlreadyActive
}
```

## User Interface

### SwiftUI Architecture
The UI follows SwiftUI declarative patterns with:
- **View Composition**: Small, reusable SwiftUI views
- **State-driven UI**: Views react to observable service state changes
- **Environment Objects**: Services injected via `@Environment(AppEnvironment.self)`

### Navigation Structure
The app uses a 5-tab navigation in `RootTabView.swift`:
1. **Habits** (`HomeView`) - Daily habit tracking and management
2. **Analytics** (`AnalyticsView`) - Charts and progress visualization  
3. **Sport** (`SportView`) - Workout tracking and muscle rankings
4. **Settings** (`SettingsView`) - App configuration and preferences

### Key UI Components

**Forest Visualization**
- Procedural tree rendering using SwiftUI Geometry paths
- 6 growth stages with progressively complex geometry
- Interactive grid placement with drag-and-drop
- Species-specific appearance with color and shape variations

**Muscle Ranking Map**
- SVG-based anatomical body map (front and back views)
- Interactive muscle selection with ranked color coding
- 40+ muscle groups positioned using normalized coordinates
- Color-coded ranking visualization from gray (untrained) to rainbow (legend)

**Active Workout Session**
- Real-time timer with rest countdown
- Set-by-set exercise logging with performance optimizations
- Live Activity integration for lock screen tracking
- RPE input and session completion workflow

**Habit Tracking**
- Simple toggle for completion-based habits
- Progress tracking for measurable habits with step increments
- Heatmap visualization for habit completion patterns
- Customizable reminders and weekday configurations

### Custom Design System
The app uses a centralized design system in `Helpers/DesignSystem.swift`:
- **Spacing**: Standardized spacing values (xs=4, s=8, m=12, l=16, xl=24, xxl=32)
- **Corner Radius**: Consistent border radius (s=10, m=16, l=22)
- **Card Styling**: `.cardStyle()` modifier for consistent appearance
- **Haptics**: `Haptics.selection()`, `Haptics.success()`, `Haptics.impact()` 

### Theme Customization
- **Accent Themes**: 5 color schemes (forest, ocean, sunset, lavender, rosé)
- **Appearance System**: Support for system/light/dark mode switching
- **Pro Feature Gating**: Premium themes available through subscription

### Accessibility
The UI follows accessibility best practices:
- Semantic navigation with proper VoiceOver labels
- Dynamic Type support for text scaling
- High contrast mode compatibility
- Motor accessibility with large tap targets

## Data Flow

### Application Data Flow
ThriveWood uses a unidirectional data flow pattern:

1. **User Interaction** → View
2. **View** → Action on Service
3. **Service** → Business Logic
4. **Service** → Repository (CRUD)
5. **Repository** → SwiftData
6. **SwiftData** → Model Updates
7. **Model Updates** → Service State Changes (via @Observable)
8. **State Changes** → View Updates

### Observable State Pattern
Services use `@Observable` for reactive state management:
```swift
@MainActor
@Observable
final class WorkoutService {
    private(set) var activeSession: WorkoutSession?
    
    func startSession(for workout: Workout) throws {
        // Business logic
        self.activeSession = newSession // Triggers UI update
    }
}
```

### Dependency Injection
All dependencies flow from `AppEnvironment`:
```swift
struct MyView: View {
    @Environment(AppEnvironment.self) private var env
    
    var body: some View {
        // Access services via env.workoutService, env.habitService, etc.
    }
}
```

### Data Persistence Flow
1. **Models** defined as `@Model` SwiftData classes
2. **Repositories** handle CRUD operations with error handling
3. **Services** orchestrate business logic across multiple models
4. **CloudKit** synchronization handled automatically by SwiftData
5. **Widgets** access data via App Group container
6. **Live Activities** receive state updates during active sessions

### Notification Flow
The app sends notifications for:
- **Habit Reminders** based on user-defined schedules
- **Workout Live Activities** during active training sessions
- **Widget Updates** when forest or habit data changes

## Key Features Implementation

### Points Economy System
The gamification system uses a dual-currency approach:

**Earning Points**
- Simple habits: Full points on completion
- Measurable habits: Partial points based on progress percentage
- Example: 2-point habit at 50% completion = 1 point earned

**Spending Points**
- Tree planting: 5-80 points depending on species
- Tree growth: 1 point per growth increment
- Species unlocking: Requires total lifetime points threshold

```swift
enum TreeSpecies: String, CaseIterable {
    case oak, pine, birch, maple, willow, cherry, sequoia, bonsai
    
    var unlockThreshold: Int { /* Species-specific thresholds */ }
}

static let plantingCost: [TreeSpecies: Int] = [
    .oak: 5, .pine: 8, .birch: 10, .maple: 15,
    .willow: 20, .cherry: 30, .sequoia: 50, .bonsai: 80
]
```

### Personal Record (PR) System
The PR system tracks progress across different exercise types:

```swift
func setIsLess(_ set1: SetEntry, _ set2: SetEntry, for exercise: Exercise) -> Bool {
    switch exercise.trackingType {
    case .repsWeight:
        // Higher weight wins; same weight → higher reps wins
    case .reps:
        // Higher reps wins
    case .duration:
        // Longer duration wins
    case .distanceDuration:
        // Longer distance wins; same distance → shorter time wins
    }
}
```

PR detection happens:
- **During Workouts**: Compare against all-time best
- **After Completion**: Identify new PRs reached in the session
- **Progress Visualization**: Show PR breakthrough timeline per exercise

### Muscle Ranking Calculation
Muscle rankings use a dual-value system:

```swift
enum MuscleRank: Int, CaseIterable {
    case untrained = 0
    case bronze = 1      // Min: 5,000 kg OR 30 sets
    case silver = 2      // Min: 10,000 kg OR 100 sets
    case gold = 3        // Min: 25,000 kg OR 250 sets
    case platinum = 4    // Min: 50,000 kg OR 500 sets
    case diamond = 5     // Min: 100,000 kg OR 1,000 sets
    case champion = 6    // Min: 200,000 kg OR 2,000 sets
    case legend = 7      // Min: 400,000 kg OR 4,000 sets
}
```

**Volume Calculation** varies by exercise type:
- **Strength**: weight × reps
- **Bodyweight**: reps count as volume
- **Duration**: seconds as volume
- **Cardio**: distance in meters as volume

**Muscle Credit Distribution**:
- **Primary Muscles**: 100% volume credit, full set credit
- **Secondary Muscles**: 50% volume credit, full set credit

### Forest Growth System
Tree growth follows a points-based progression:

```swift
enum TreeGrowthStage: Int, CaseIterable {
    case seed = 0
    case sprout = 1
    case sapling = 2
    case young = 3
    case mature = 4
    case ancient = 5
}

static func stage(forTreePoints points: Int) -> TreeGrowthStage {
    switch points {
    case ..<5: return .seed
    case ..<15: return .sprout
    case ..<35: return .sapling
    case ..<70: return .young
    case ..<150: return .mature
    default: return .ancient
    }
}
```

## State Management

### Observable Services
All services use the `@Observable` macro for reactive state changes:

```swift
@MainActor
@Observable
final class WorkoutService {
    private(set) var activeSession: WorkoutSession?
    // automatically publishes changes to views
}
```

### State Synchronization
- **Single Source of Truth**: Services hold canonical state
- **Computed State**: Views derive presentation state from services
- **Automatic Updates**: SwiftData changes automatically update models
- **UI Reactivity**: SwiftUI automatically updates when service state changes

### Session Management
The app manages session state through:
- **App Environment**: Centralized dependency injection
- **View State**: Local state for UI interactions
- **Persistent State**: SwiftData models for data persistence
- **Temporary State**: In-memory for ongoing operations

### Background Operations
- **CloudKit Sync**: Automatic when app is active
- **Widget Timelines**: Updated via `WidgetCenter.shared.reloadAllTimelines()`
- **Live Activities**: State updates during active workouts
- **Notifications**: Scheduled and delivered via `NotificationService`

## External Integrations

### HealthKit Integration
The app integrates with Apple Health through a dedicated `HealthKitService`:

```swift
@MainActor
final class HealthKitService {
    func requestAuthorization() async throws
    func save(session: WorkoutSession) async throws
    func fetchSteps(for date: Date) async throws -> Int
    // Other health metrics integration
}
```

**Integration Points**:
- **Workout Data**: Workout sessions are saved to HealthKit
- **Step Data**: Steps are imported for analytics
- **Health Metrics**: Available for future expansion

### StoreKit 2 Integration
In-app purchases are managed through `StoreService`:

```swift
enum ProProduct: String, CaseIterable {
    case monthly  = "com.bensiebert.thrivewood.pro.monthly"
    case yearly   = "com.bensiebert.thrivewood.pro.yearly"
    case lifetime = "com.bensiebert.thrivewood.pro.lifetime"
}
```

**Pro Features Gated by Subscription**:
- **Extended Analytics**: 30/90/365 day ranges vs 7-day free tier
- **Accent Themes**: Premium color schemes
- **App Icons**: Custom app icon selection
- **Advanced Features**: Additional muscle ranking features

### OpenAI Integration
Supplement analysis uses OpenAI API:

```swift
@MainActor
final class AIService {
    func analyzeStack(_ supplements: [Supplement]) async throws -> String
}
```

**Used For**: AI-powered feedback on supplement combinations and interactions.

### Widget Extensions
Home screen widgets are implemented through `ThriveWoodWidgets` target:

- **Habit Progress Widget**: Shows daily habit completion status
- **Forest Preview Widget**: Displays current forest state
- **Shared Data Access**: Uses App Group container for data sharing

## Performance Considerations

### Critical Performance Optimizations

**UI Performance in ActiveSessionView**
The workout tracking view implements several performance optimizations:
```swift
@State private var cachedGroups: [(Exercise, [SetEntry])] = []
@State private var cachedCompletedCount: Int = 0
@State private var cachedTotalVolume: Double = 0
@State private var cachedExerciseCount: Int = 0

// Only recompute when session data actually changes
.onChange(of: session.sets.count) { _, _ in recache() }
.onChange(of: completedSignature) { _, _ in recache() }
```

- **Timer Isolation**: Extracted `ElapsedTimer` to separate view
- **Data Caching**: Prevent expensive recalculations on every render
- **Conditional Updates**: Only recache when underlying data changes

**Memory Management**
- **Lazy Loading**: Large data sets loaded as needed
- **Efficient Fetching**: Use predicates and limits in SwiftData queries
- **View Recycling**: SwiftUI automatic view recycling optimization

**Database Performance**
- **Batch Operations**: Group related data modifications
- **Efficient Queries**: Optimized predicates and sort descriptors
- **CloudKit Sync**: Background synchronization doesn't block UI

### Async/Await Usage
The app uses Swift Concurrency throughout:
- **Service Methods**: Async operations for network and storage
- **Error Propagation**: Structured error throwing and handling
- **MainActor Isolation**: UI updates properly isolated to main thread

### Storage Optimization
- **App Groups**: Shared container for widgets and main app
- **CloudKit**: Efficient data synchronization
- **Image Caching**: On-device caching for exercise images
- **Data Compression**: Minimal data storage footprint

## Testing Strategy

### Architecture for Testability
The codebase is structured to enable comprehensive testing:

**Protocol-Based Repositories**
```swift
protocol HabitRepository {
    func fetchAll() throws -> [Habit]
    func create(_ habit: Habit) throws
    // ... other methods
}
```

**Mock Implementation**
- In-memory implementations for unit testing
- Protocols enable dependency injection for test doubles
- Service isolation for individual testing

### Testing Approach

**Unit Tests**
- Service-level business logic testing
- Repository CRUD operation testing
- Model validation and business rule testing
- Enum functionality testing

**Integration Tests**
- Service-to-service interaction testing
- SwiftData model relationship testing
- End-to-end workflow testing
- CloudKit synchronization testing

**UI Tests**
- Critical user journey testing
- Accessibility testing with contrast and VoiceOver
- Performance testing for complex views
- Widget functionality testing

### Test Data Strategy
- Built-in test data seeds for consistent test environment
- Isolated test configurations
- Mock service implementations for deterministic tests
- Test-specific model factories for complex test scenarios

## Deployment

### App Store Configuration
The app is configured for Apple App Store distribution:

**App Identifier**
- Bundle ID: `com.bensiebert.ThriveWood`
- App Group: `group.com.bensiebert.thrivewood`

**Entitlements**
- App Groups for widget data sharing
- HealthKit for health data integration
- In-App Purchases for subscription model
- Push Notifications for habit reminders

**Privacy Manifest**
- HealthKit usage descriptions
- In-app analytics transparency
- Minimal data collection practices
- GDPR compliance documentation

### Build Process
**Release Configuration**
- Optimized build settings for production
- Stripped debug symbols
- App Store Connect automated uploads
- Bitcode generation disabled (modern Swift)

**Version Strategy**
- Semantic versioning (major.minor.patch)
- Incremental build numbers
- Release notes in German and English
- App Store screenshots via Next.js editor

### Localization
**Current Language**
- German (primary) as requested in requirements
- All UI strings, notifications, and error messages in German

**Future Localization**
- String extraction for easy translation
- Placeholder strings in neutral language
- Localizable.strings structure ready for English expansion

### Analytics & Monitoring
**Production Monitoring**
- Crash reporting for stability
- Performance metrics for user experience
- StoreKit transaction monitoring
- HealthKit authorization tracking

**User Feedback**
- App Store ratings and reviews monitoring
- Support email integration
- In-app feedback collection
- Feature request tracking

---

## Conclusion

ThriveWood represents a comprehensive iOS application that demonstrates modern SwiftUI architecture patterns, combining sophisticated data modeling with engaging gamification elements. The architecture prioritizes:
- **Maintainability** through clear separation of concerns
- **Testability** via protocol-based dependency injection
- **Performance** with thoughtful optimizations
- **User Experience** through cohesive design systems
- **Data Integrity** with structured SwiftData models

The codebase serves as a reference implementation for complex iOS applications using SwiftUI, SwiftData, and modern Swift concurrency patterns, while maintaining a practical approach to real-world app development requirements.

This design document should enable new engineers to quickly understand the application architecture and contribute effectively to the codebase.