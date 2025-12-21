# rSoGuitar iOS App

A native iOS app (SwiftUI, iOS 17+) that teaches the Rosetta Stone of Guitar method through interactive fretboard visualization, pattern recognition, and audio playback.

## Features

- **Interactive Fretboard**: Tap notes to hear them play, visualize patterns
- **Pattern Learning**: Four core concepts - Spiral Mapping, Jumping, Family of Chords, Familial Hierarchy
- **Lesson System**: Structured lessons with interactive demonstrations
- **Freemium Model**: Free tier includes first 2-3 concepts, premium unlocks all content
- **Audio Playback**: Play individual notes and chords
- **Progress Tracking**: Track lesson completion and bookmarked patterns

## Project Structure

```
rSoGuitar/
├── App/
│   └── rSoGuitarApp.swift
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
│   ├── Fretboard/
│   ├── Audio/
│   ├── Premium/
│   └── Common/
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
    ├── Audio/
    └── Content/
```

## Setup Instructions

### Creating the Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose "iOS" > "App"
   - Product Name: `rSoGuitar`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum iOS Version: 17.0
   - Use SwiftData: Yes

3. Replace the default files with the files from this repository

4. Add all Swift files to the project:
   - Drag all folders into Xcode project navigator
   - Ensure "Copy items if needed" is checked
   - Add to target: rSoGuitar

5. Configure Capabilities:
   - Signing & Capabilities > Add Capability: In-App Purchase
   - This enables StoreKit 2 functionality

6. Configure Bundle Identifier:
   - Set to: `com.rsoguitar.app` (or your preferred identifier)

7. Build and run the project

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

- StoreKit 2 (native)
- AVFoundation (native)
- SwiftData (native, iOS 17+)
- SwiftUI (native)

No external dependencies required.

## StoreKit Configuration

To test in-app purchases, configure products in App Store Connect:

1. Monthly Subscription: `com.rsoguitar.premium.monthly`
2. Yearly Subscription: `com.rsoguitar.premium.yearly`
3. Lifetime Purchase: `com.rsoguitar.premium.lifetime`

## Free vs Premium

### Free Tier
- Introduction to rSoGuitar method
- Spiral Mapping concept
- Jumping concept
- Basic fretboard interaction
- Limited audio examples

### Premium Tier
- All remaining concepts (Family of Chords, Familial Hierarchy, etc.)
- Advanced patterns and exotic scales
- Key changes and modes
- Full audio library
- Progress tracking and bookmarks
- Practice exercises
- Export/share capabilities

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Audio**: AVFoundation
- **In-App Purchases**: StoreKit 2

## License

Copyright © 2024 rSoGuitar. All rights reserved.

