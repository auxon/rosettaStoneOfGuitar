//
//  ContentService.swift
//  rSoGuitar
//
//  Manages lesson content and pattern definitions
//

import Foundation
import Combine

class ContentService {
    static let shared = ContentService()
    
    private var lessons: [Lesson] = []
    private var patterns: [Pattern] = []
    
    private init() {
        loadDefaultContent()
    }
    
    /// Load all lessons
    func getAllLessons() -> [Lesson] {
        return lessons
    }
    
    /// Get lesson by ID
    func getLesson(by id: UUID) -> Lesson? {
        return lessons.first { $0.id == id }
    }
    
    /// Get free lessons
    func getFreeLessons() -> [Lesson] {
        return lessons.filter { !$0.isPremium }
    }
    
    /// Get premium lessons
    func getPremiumLessons() -> [Lesson] {
        return lessons.filter { $0.isPremium }
    }
    
    /// Load patterns for a specific type
    func getPatterns(type: PatternType, key: Key) -> [Pattern] {
        return patterns.filter { $0.type == type && $0.key == key }
    }
    
    /// Generate pattern on demand
    func generatePattern(type: PatternType, key: Key, startPosition: FretboardPosition? = nil) -> Pattern {
        switch type {
        case .spiralMapping:
            return FretboardCalculator.spiralMappingPattern(for: key)
        case .jumping:
            if let start = startPosition {
                return PatternGenerator.jumpingPattern(from: start, in: key)
            } else {
                // Default starting position
                let defaultPos = FretboardPosition(string: 3, fret: 0, note: key.rootNote, isRoot: true)
                return PatternGenerator.jumpingPattern(from: defaultPos, in: key)
            }
        case .familyOfChords:
            return PatternGenerator.familyOfChordsPattern(for: key)
        case .familialHierarchy:
            return PatternGenerator.familialHierarchyPattern(for: key)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultContent() {
        // Create default lessons
        lessons = createDefaultLessons()
    }
    
    private func createDefaultLessons() -> [Lesson] {
        var lessons: [Lesson] = []
        
        // 1. Introduction (Free)
        let introPattern = FretboardCalculator.spiralMappingPattern(for: .C)
        let introContent: [LessonContent] = [
            .text("Welcome to the Rosetta Stone of Guitar! This method will teach you to understand the guitar fretboard through four core concepts: Spiral Mapping, Jumping, Family of Chords, and Familial Hierarchy."),
            .text("The guitar fretboard may seem complex, but with the rSoGuitar method, you'll learn to see patterns that make navigation intuitive and musical."),
            .text("The fretboard is divided into three main blocks: HEAD block (lower frets 0-4), BRIDGE block (middle frets 5-9), and TRIPLE BLOCK (higher frets 10+). These blocks help organize the fretboard into manageable regions."),
            .text("Let's start by exploring the fretboard. Tap on any note in the demo below to hear it play. You can toggle the blocks overlay to see how the fretboard is organized."),
            .fretboardDemo(introPattern)
        ]
        
        lessons.append(Lesson(
            title: "Introduction to rSoGuitar",
            description: "Learn the fundamentals of the Rosetta Stone of Guitar method",
            content: introContent,
            isPremium: false,
            order: 1,
            estimatedTime: 300 // 5 minutes
        ))
        
        // 2. Spiral Mapping (Free)
        let spiralPattern = FretboardCalculator.spiralMappingPattern(for: .C)
        let spiralContent: [LessonContent] = [
            .text("Spiral Mapping is the first core concept. It shows how notes in a key form a vertical pattern that spirals across the fretboard."),
            .text("The spiral pattern connects notes of the same key from one end of the fretboard to the other, creating a visual map you can follow."),
            .text("The HEAD block contains the foundational notes of the key in the lower frets (0-4). As you follow the spiral mapping pattern, you'll see how it connects through the HEAD block to other regions."),
            .fretboardDemo(spiralPattern),
            .text("Try exploring the spiral mapping pattern for different keys. Notice how the pattern maintains its structure regardless of the starting key."),
            .text("In the pattern above, the blue circles represent root notes (the key note), and green circles show other notes in the key. The orange lines connect the pattern positions. Toggle the blocks overlay to see how the HEAD block relates to the spiral pattern."),
            .exercise(Exercise(
                title: "Spiral Mapping Practice",
                instructions: "Explore the fretboard demo above. Try tapping on different notes to hear them. Notice how the pattern forms a spiral across the strings. Enable the HEAD block overlay to see how the foundational notes are organized.",
                pattern: spiralPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Spiral Mapping",
            description: "Master the vertical pattern that spirals across the fretboard",
            content: spiralContent,
            isPremium: false,
            order: 2,
            estimatedTime: 600 // 10 minutes
        ))
        
        // 3. Jumping (Free)
        let jumpingStartPos = FretboardPosition(string: 3, fret: 0, note: .D, isRoot: false)
        let jumpingPattern = PatternGenerator.jumpingPattern(from: jumpingStartPos, in: .C)
        let jumpingContent: [LessonContent] = [
            .text("Jumping is about horizontal movement on the fretboard. It teaches you which frets you can move to while staying in key."),
            .text("By understanding jumping rules, you can navigate horizontally without hitting 'bad' notes that are outside your current key."),
            .text("The BRIDGE block (also called tail block) is the middle region (frets 5-9). Jumping rules help you navigate horizontally within this block while staying in key. Understanding the BRIDGE block helps you see where you can safely jump."),
            .fretboardDemo(jumpingPattern),
            .text("In the demo above, you can see valid jump positions from a starting position. All highlighted positions are notes that are in the key, so you can safely jump to them."),
            .text("Toggle the BRIDGE block overlay to see how the middle frets relate to jumping. Notice how many valid jump positions fall within the BRIDGE block region."),
            .exercise(Exercise(
                title: "Jumping Practice",
                instructions: "Study the jumping pattern above. Notice how you can move horizontally (same string, different frets) while staying in key. Try tapping different positions to hear the notes. Enable the BRIDGE block to see how jumping works within this region.",
                pattern: jumpingPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Jumping",
            description: "Learn horizontal movement rules on the fretboard",
            content: jumpingContent,
            isPremium: false,
            order: 3,
            estimatedTime: 600 // 10 minutes
        ))
        
        // 4. Family of Chords (Premium)
        let familyPattern = PatternGenerator.familyOfChordsPattern(for: .C)
        let familyContent: [LessonContent] = [
            .text("The Family of Chords shows all available chord positions horizontally across the fretboard for a given key."),
            .text("In any key, certain chords naturally belong together. The Family of Chords helps you see where these related chords are located."),
            .fretboardDemo(familyPattern),
            .text("The pattern above shows all the primary chord positions (I, IV, V) in the key of C major. These are the most important chords in any major key."),
            .text("Understanding chord families is essential for rhythm playing and accompaniment."),
            .exercise(Exercise(
                title: "Family of Chords Practice",
                instructions: "Explore the chord positions shown above. Notice how they're distributed horizontally across the fretboard. Try to identify the root notes (blue circles) for each chord.",
                pattern: familyPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Family of Chords",
            description: "Discover chord relationships across the fretboard",
            content: familyContent,
            isPremium: true,
            order: 4,
            estimatedTime: 900 // 15 minutes
        ))
        
        // 5. Familial Hierarchy (Premium)
        let hierarchyPattern = PatternGenerator.familialHierarchyPattern(for: .C)
        let hierarchyContent: [LessonContent] = [
            .text("Familial Hierarchy shows the natural chord progression order in a key. It displays chords vertically, showing their relative importance."),
            .text("The hierarchy follows the circle of fifths and shows which chords naturally lead to others in a progression."),
            .fretboardDemo(hierarchyPattern),
            .text("The pattern above shows the complete chord hierarchy: I, ii, iii, IV, V, vi, and vii°. The I chord (blue) is the root, and the others follow in order of importance."),
            .text("Mastering familial hierarchy helps you understand song structure and create your own progressions."),
            .exercise(Exercise(
                title: "Familial Hierarchy Practice",
                instructions: "Study the hierarchy pattern. Notice how chords are arranged vertically. The most common progressions use I, IV, and V chords. Try creating a simple progression using these positions.",
                pattern: hierarchyPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Familial Hierarchy",
            description: "Understand the natural chord progression hierarchy",
            content: hierarchyContent,
            isPremium: true,
            order: 5,
            estimatedTime: 900 // 15 minutes
        ))
        
        // 6. Advanced Patterns (Premium)
        lessons.append(Lesson(
            title: "Advanced Patterns",
            description: "Explore advanced fretboard patterns and techniques",
            content: [.text("Advanced patterns combine multiple concepts for complex musical applications.")],
            isPremium: true,
            order: 6,
            estimatedTime: 1200 // 20 minutes
        ))
        
        // 7. Key Changes & Modes (Premium)
        lessons.append(Lesson(
            title: "Key Changes & Modes",
            description: "Learn to navigate key changes and modal playing",
            content: [.text("Understanding key changes and modes expands your musical vocabulary.")],
            isPremium: true,
            order: 7,
            estimatedTime: 1200 // 20 minutes
        ))
        
        // 8. Exotic Scales (Premium)
        lessons.append(Lesson(
            title: "Exotic Scales",
            description: "Explore harmonic minor, diminished, blues, and other scales",
            content: [.text("Exotic scales add color and character to your playing.")],
            isPremium: true,
            order: 8,
            estimatedTime: 1200 // 20 minutes
        ))
        
        return lessons
    }
}

