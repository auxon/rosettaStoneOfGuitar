//
//  ContentService.swift
//  rSoGuitar
//
//  Manages lesson content and pattern definitions.
//  Lesson copy is aligned with https://www.rsoguitar.com/rsoguitar/
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
        lessons = createDefaultLessons()
    }
    
    private func createDefaultLessons() -> [Lesson] {
        var lessons: [Lesson] = []
        
        // 1. Introduction (Free)
        let introPattern = FretboardCalculator.spiralMappingPattern(for: .C)
        let introContent: [LessonContent] = [
            .text("Welcome to the Rosetta Stone of Guitar (rSoGuitar). Traditional theory studies patterns on the staff — this method studies the patterns your eyes already look at: the fretboard."),
            .text(RSOGConceptInfo.methodBlurb),
            .text("The entire neck is one repeating diatonic pattern. Within it, three milestones repeat: HEAD (XX-X), BRIDGE (X-XX), and TRIPLE (stacked 1–3–5 triads). Learn to read those landmarks and the whole pattern snaps into place."),
            .text("The four core concepts are Spiral Mapping, Jumping, Family of Chords, and Familial Hierarchy — the same sequence taught at rsoguitar.com/rsoguitar."),
            .text("Explore the demo below. HEAD, BRIDGE, and TRIPLE overlays are available — tap notes to hear them, and watch how the spiral path threads the pattern."),
            .fretboardDemo(introPattern)
        ]
        
        lessons.append(Lesson(
            title: "Introduction to rSoGuitar",
            description: "See the fretboard as one repeating pattern with HEAD, BRIDGE, and TRIPLE milestones",
            content: introContent,
            isPremium: false,
            order: 1,
            estimatedTime: 300
        ))
        
        // 2. Spiral Mapping (Free) — emphasize HEAD
        let spiralPattern = FretboardCalculator.spiralMappingPattern(for: .C)
        let spiralContent: [LessonContent] = [
            .text("Spiral Mapping teaches you to navigate the naturally occurring pattern vertically across the fretboard — spiraling from one end of the neck to the other so no in-key note is left unmapped."),
            .text("Follow the orange path column by column. The HEAD block (XX-X on the high strings) is your entry milestone: once you spot it, you know where the entire pattern sits."),
            .text("Root notes are emphasized; other diatonic notes fill the spiral. Toggle blocks to isolate HEAD while you learn the path."),
            .fretboardDemo(spiralPattern),
            .text("Change keys later in the Fretboard Explorer — the spiral shape stays the same; only its position on the neck moves. That is key-independent projection."),
            .exercise(Exercise(
                title: "Spiral Mapping Practice",
                instructions: "Trace the spiral path in C major. Enable the HEAD block and notice how the XX-X landmark anchors the pattern. Tap roots along the path to hear the key center.",
                pattern: spiralPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Spiral Mapping",
            description: "Navigate the diatonic pattern vertically with HEAD as your milestone",
            content: spiralContent,
            isPremium: false,
            order: 2,
            estimatedTime: 600
        ))
        
        // 3. Jumping (Free) — emphasize BRIDGE
        let jumpingStartPos = FretboardPosition(string: 3, fret: 0, note: .D, isRoot: false)
        let jumpingPattern = PatternGenerator.jumpingPattern(from: jumpingStartPos, in: .C)
        let jumpingContent: [LessonContent] = [
            .text("Jumping teaches the simple rules that let you move freely in the horizontal direction without ever hitting a bad note or getting lost."),
            .text("From any in-key starting note, every highlighted fret on the same string is a safe landing. You are still inside the one diatonic pattern — just traveling sideways."),
            .text("The BRIDGE block (X-XX on the D/A pair) is the transitional zone. It connects HEAD and TRIPLE regions and makes position shifts feel like walking two blocks from the bank — relative, not absolute."),
            .fretboardDemo(jumpingPattern),
            .text("Practice hearing the jumps. Then open the Fretboard Explorer, pick Jumping, and tap a new starting note to regenerate valid landings."),
            .exercise(Exercise(
                title: "Jumping Practice",
                instructions: "Study the highlighted frets on the starting string. Enable the BRIDGE block and notice how the X-XX landmark sits in the middle of the neck geography.",
                pattern: jumpingPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Jumping",
            description: "Move horizontally in key using BRIDGE as the transitional landmark",
            content: jumpingContent,
            isPremium: false,
            order: 3,
            estimatedTime: 600
        ))
        
        // 4. Family of Chords (Premium) — emphasize TRIPLE
        let familyPattern = PatternGenerator.familyOfChordsPattern(for: .C)
        let familyContent: [LessonContent] = [
            .text("Family of Chords reveals the relationship between chord positions across the fretboard in the horizontal direction."),
            .text("In a major key the primary family is I, IV, and V — shown here as real 1–3–5 triad voicings, not just root dots. Each color is a chord; lines connect tones inside a voicing."),
            .text("The TRIPLE block is the chord-building landmark: three stacked diatonic triads that make available harmony visible anywhere you stand on the neck."),
            .fretboardDemo(familyPattern),
            .text("Once you can see the family horizontally, accompaniment stops being a scavenger hunt — you already know where the next chord lives relative to the one you are on."),
            .exercise(Exercise(
                title: "Family of Chords Practice",
                instructions: "Identify I (blue), IV (green), and V (orange). Enable the TRIPLE block and relate those voicings to the stacked-triad landmark.",
                pattern: familyPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Family of Chords",
            description: "Discover horizontal I–IV–V triad relationships on the fretboard",
            content: familyContent,
            isPremium: true,
            order: 4,
            estimatedTime: 900
        ))
        
        // 5. Familial Hierarchy (Premium)
        let hierarchyPattern = PatternGenerator.familialHierarchyPattern(for: .C)
        let hierarchyContent: [LessonContent] = [
            .text("Familial Hierarchy teaches the relative positions of all naturally occurring chords in the vertical direction."),
            .text("Every diatonic chord — I, ii, iii, IV, V, vi, vii° — appears as a compact 1–3–5 stack labeled by roman numeral. Moving vertically shows how the family is ordered."),
            .fretboardDemo(hierarchyPattern),
            .text("Mastering the hierarchy helps you understand song structure and invent progressions without leaving the pattern."),
            .exercise(Exercise(
                title: "Familial Hierarchy Practice",
                instructions: "Find I, IV, and V first, then locate ii, iii, vi, and vii°. Keep the TRIPLE block on so each stack reads as a chord shape, not a scatter of roots.",
                pattern: hierarchyPattern
            ))
        ]
        
        lessons.append(Lesson(
            title: "Familial Hierarchy",
            description: "See all diatonic chords stacked vertically by scale degree",
            content: hierarchyContent,
            isPremium: true,
            order: 5,
            estimatedTime: 900
        ))
        
        // 6. Advanced Patterns (Premium)
        lessons.append(Lesson(
            title: "Advanced Patterns",
            description: "Combine spiral, jumping, and chord families into fluid fretboard fluency",
            content: [
                .text("Advanced practice means using Overview mode in the Fretboard Explorer: HEAD → BRIDGE → TRIPLE visible together with the spiral path."),
                .text("Shift keys without relearning shapes. Treat milestones relatively — two blocks from the HEAD, not “fret 8, string 2”.")
            ],
            isPremium: true,
            order: 6,
            estimatedTime: 1200
        ))
        
        // 7. Key Changes & Modes (Premium)
        lessons.append(Lesson(
            title: "Key Changes & Modes",
            description: "Project the same pattern into new keys and modal colors",
            content: [
                .text("Because rSoG is key-independent, changing keys is relocating the pattern — not learning a new map."),
                .text("Modes color the same geography. Use the Modes overlay in the Explorer after the four core concepts feel natural.")
            ],
            isPremium: true,
            order: 7,
            estimatedTime: 1200
        ))
        
        // 8. Exotic Scales (Premium)
        lessons.append(Lesson(
            title: "Exotic Scales",
            description: "Layer blues, harmonic minor, and other colors onto the rSoG map",
            content: [
                .text("Exotic scales become manageable once the diatonic skeleton is visible. You are adding color tones to a geography you already trust."),
                .text("Return to Spiral Mapping and Family of Chords whenever a new scale feels disorienting — the milestones are still there.")
            ],
            isPremium: true,
            order: 8,
            estimatedTime: 1200
        ))
        
        return lessons
    }
}
