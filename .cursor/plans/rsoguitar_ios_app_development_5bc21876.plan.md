---
name: rSoGuitar iOS App Development
overview: Build a native iOS app using SwiftUI that teaches the Rosetta Stone of Guitar method with a freemium model - free tier includes first 2-3 core concepts, premium unlocks all content plus advanced features. The app will feature interactive fretboard visualization, pattern learning (Spiral Mapping, Jumping, Family of Chords), and audio playback for notes/chords.
todos: []
---

# rSoGuitar iOS App Development Plan

## Project Overview

Build a native iOS app (SwiftUI, iOS 17+) that teaches the Rosetta Stone of Guitar method through interactive fretboard visualization, pattern recognition, and audio playback. Implement a freemium model where the first 2-3 core concepts are free, with premium unlocking all content and advanced features.

## Architecture

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Minimum iOS Version**: iOS 17.0
- **Audio Framework**: AVFoundation
- **In-App Purchases**: StoreKit 2
- **Persistence**: SwiftData (iOS 17 native) or Core Data
- **Dependency Management**: Swift Package Manager

### Project Structure

```javascript
rSoGuitar/
├── App/
│   ├── rSoGuitarApp.swift (main app entry)
│   └── AppDelegate.swift
├── Models/
│   ├── Lesson.swift
│   ├── Pattern.swift
│   ├── Chord.swift
│   ├── FretboardNote.swift
│   ├── UserProgress.swift
│   └── Subscription.swift
├── ViewModels/
│   ├── LessonViewModel.swift
│   ├── FretboardViewModel.swift
│   ├── PatternViewModel.swift
│   └── SubscriptionViewModel.swift
├── Views/
│   ├── Content/
│   │   ├── LessonListView.swift
│   │   ├── LessonDetailView.swift
│   │   ├── ConceptView.swift
│   │   └── PatternView.swift
│   ├── Fretboard/
│   │   ├── FretboardView.swift
│   │   ├── FretboardNoteView.swift
│   │   └── PatternOverlayView.swift
│   ├── Audio/
│   │   └── AudioPlayerView.swift
│   ├── Premium/
│   │   ├── PremiumGateView.swift
│   │   └── SubscriptionView.swift
│   └── Common/
│       ├── NavigationBar.swift
│       └── LoadingView.swift
├── Services/
│   ├── AudioService.swift
│   ├── SubscriptionService.swift
│   ├── ProgressService.swift
│   └── ContentService.swift
├── Utilities/
│   ├── FretboardCalculator.swift
│   ├── PatternGenerator.swift
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    ├── Audio/ (note samples, chord samples)
    └── Content/ (lesson data, pattern definitions)
```



## Core Features

### 1. Fretboard Visualization

**File**: `Views/Fretboard/FretboardView.swift`

- Interactive 6-string guitar fretboard (standard tuning: E-A-D-G-B-E)
- Visual representation of frets (0-12+), strings, and note positions
- Touch interaction to highlight notes and play audio
- Pattern overlay system to show rSoGuitar patterns
- Support for different keys and modes
- Visual indicators for:
- Root notes
- Pattern boundaries
- Available chord positions
- Spiral mapping paths

**Implementation Details**:

- Use `Canvas` or custom `Shape` for fretboard rendering
- Calculate note positions using `FretboardCalculator`
- Support portrait and landscape orientations
- Zoom and pan capabilities for detailed viewing

### 2. Pattern Learning System

**Files**:

- `Models/Pattern.swift`
- `ViewModels/PatternViewModel.swift`
- `Views/Content/PatternView.swift`

Implement the four core rSoGuitar concepts:

#### a. Spiral Mapping

- Visual representation of the vertical pattern that spirals across the fretboard
- Interactive navigation showing how the pattern connects from one end to the other
- Highlight pattern positions for any given key

#### b. Jumping

- Demonstrate horizontal movement rules
- Show valid "jump" paths that avoid bad notes
- Interactive exercises to practice jumping

#### c. Family of Chords

- Display chord relationships horizontally across the fretboard
- Show all available chord positions for the current key
- Visual connections between related chords

#### d. Familial Hierarchy

- Show relative positions of chords vertically
- Display the natural chord progression hierarchy
- Interactive exploration of chord relationships

### 3. Lesson Structure

**Files**:

- `Models/Lesson.swift`
- `ViewModels/LessonViewModel.swift`
- `Views/Content/LessonDetailView.swift`
- Hierarchical lesson structure:
- **Introduction** (Free)
- **Spiral Mapping** (Free)
- **Jumping** (Free)
- **Family of Chords** (Premium)
- **Familial Hierarchy** (Premium)
- **Advanced Patterns** (Premium)
- **Key Changes & Modes** (Premium)
- **Exotic Scales** (Premium - harmonic minor, diminished, blues, etc.)
- Each lesson includes:
- Text explanations
- Interactive fretboard demonstrations
- Audio examples
- Practice exercises
- Visual pattern overlays

### 4. Audio Playback

**Files**:

- `Services/AudioService.swift`
- `Views/Audio/AudioPlayerView.swift`
- Play individual notes when tapped on fretboard
- Play chord samples
- Audio examples for pattern demonstrations
- Support for:
- Note names (C, C#, D, etc.)
- Chord voicings
- Scale patterns
- Use AVFoundation's `AVAudioPlayer` or `AVAudioEngine`

### 5. Freemium Model

**Files**:

- `Services/SubscriptionService.swift`
- `ViewModels/SubscriptionViewModel.swift`
- `Views/Premium/PremiumGateView.swift`
- `Views/Premium/SubscriptionView.swift`

**Free Tier** (First 2-3 concepts):

- Introduction to rSoGuitar method
- Spiral Mapping concept
- Jumping concept
- Basic fretboard interaction
- Limited audio examples

**Premium Tier** (Unlocks):

- All remaining concepts (Family of Chords, Familial Hierarchy, etc.)
- Advanced patterns and exotic scales
- Key changes and modes
- Full audio library
- Progress tracking and bookmarks
- Practice exercises
- Export/share capabilities

**Implementation**:

- Use StoreKit 2 for in-app purchases
- Implement subscription model (monthly/yearly) or one-time purchase
- Store subscription status in UserDefaults or Keychain
- Gate premium content with `SubscriptionService.isPremiumUser`
- Show upgrade prompts at premium content boundaries

## Data Models

### Lesson Model

```swift
struct Lesson: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let content: [LessonContent]
    let isPremium: Bool
    let order: Int
    let estimatedTime: TimeInterval
}

enum LessonContent {
    case text(String)
    case fretboardDemo(Pattern)
    case audioExample(URL)
    case exercise(Exercise)
}
```



### Pattern Model

```swift
struct Pattern: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: PatternType
    let key: Key
    let positions: [FretboardPosition]
    let description: String
}

enum PatternType {
    case spiralMapping
    case jumping
    case familyOfChords
    case familialHierarchy
}

struct FretboardPosition {
    let string: Int // 1-6
    let fret: Int
    let note: Note
    let isRoot: Bool
}
```



### Subscription Model

```swift
@Model
class Subscription {
    var isPremium: Bool
    var purchaseDate: Date?
    var expirationDate: Date?
    var productId: String?
}
```



## User Interface Design

### Main Navigation

- Tab-based or navigation stack
- Home/Lessons tab
- Fretboard Explorer tab
- Progress/Profile tab
- Settings tab

### Key Screens

1. **Lesson List View**: Grid/list of available lessons with premium badges
2. **Lesson Detail View**: Scrollable content with embedded fretboard demos
3. **Fretboard Explorer**: Interactive fretboard with pattern overlays
4. **Pattern View**: Focused view for learning specific patterns
5. **Premium Gate View**: Upgrade prompt with feature comparison
6. **Subscription View**: Purchase options and subscription management

### Design Principles

- Clean, modern iOS design following Human Interface Guidelines
- Dark mode support
- Accessibility (VoiceOver, Dynamic Type)
- Smooth animations for pattern transitions
- Visual feedback for interactions

## Services Layer

### AudioService

- Load and play audio files
- Manage audio session
- Handle interruptions
- Cache audio samples

### SubscriptionService

- Manage StoreKit 2 transactions
- Verify subscription status
- Handle purchase flow
- Restore purchases

### ProgressService

- Track lesson completion
- Save user progress
- Bookmark favorite patterns
- Analytics (optional)

### ContentService

- Load lesson content (JSON/bundle)
- Manage pattern definitions
- Handle content updates

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

- Project setup and architecture
- Basic fretboard visualization
- Note calculation and rendering
- Basic UI navigation

### Phase 2: Core Patterns (Weeks 3-4)

- Implement Spiral Mapping visualization
- Implement Jumping rules and visualization
- Pattern overlay system
- Basic audio playback

### Phase 3: Lessons & Content (Weeks 5-6)

- Lesson structure and content loading
- Lesson detail views
- Interactive demonstrations
- Content for free tier (Introduction, Spiral Mapping, Jumping)

### Phase 4: Premium Features (Weeks 7-8)

- Family of Chords implementation
- Familial Hierarchy implementation
- Advanced patterns
- Premium content gating

### Phase 5: Subscription & Polish (Weeks 9-10)

- StoreKit 2 integration
- Subscription management UI
- Premium gate implementation
- Testing and bug fixes
- App Store assets and metadata

## Technical Considerations

### Performance

- Efficient fretboard rendering (use Canvas or optimized drawing)
- Lazy loading for lesson content
- Audio file optimization (compressed formats)
- Image caching for pattern overlays

### Testing

- Unit tests for pattern calculations
- UI tests for critical user flows
- Subscription flow testing (sandbox environment)
- Device testing (iPhone, iPad)

### App Store Requirements

- Privacy policy (if collecting any data)
- App Store Connect setup
- Screenshots and app preview
- Age rating (likely 4+)
- In-app purchase configuration

## Future Enhancements (Post-MVP)

- Practice mode with exercises
- Progress tracking and achievements
- Social sharing of patterns
- Custom tunings support
- Multiple instruments (bass, ukulele)
- Offline mode improvements
- iPad-optimized layout
- Apple Watch companion (practice reminders)

## Dependencies

- StoreKit 2 (native)
- AVFoundation (native)
- SwiftData (native, iOS 17+)
- No external dependencies required for MVP

## Content Requirements

- Lesson text content (from rSoGuitar book/materials)
- Audio samples for notes and chords
- Pattern definitions and positions
- Visual assets (icons, illustrations if needed)

## Success Metrics

- User engagement: Lesson completion rates