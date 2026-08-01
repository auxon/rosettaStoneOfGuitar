//
//  RSOGConceptInfo.swift
//  rSoGuitar
//
//  Canonical rSoG concept copy and UI presets, aligned with
//  https://www.rsoguitar.com/rsoguitar/
//

import Foundation

enum RSOGConceptInfo {
    
    static let siteURL = URL(string: "https://www.rsoguitar.com/rsoguitar/")!
    
    static let methodBlurb =
        "Learn to play by studying the visual pattern all the correct notes make on the fretboard — milestones, geography, and relativistic navigation instead of absolute note names."
    
    // MARK: - Concepts
    
    static func title(for type: PatternType) -> String {
        switch type {
        case .spiralMapping: return "Spiral Mapping"
        case .jumping: return "Jumping"
        case .familyOfChords: return "Family of Chords"
        case .familialHierarchy: return "Familial Hierarchy"
        }
    }
    
    static func shortDescription(for type: PatternType) -> String {
        switch type {
        case .spiralMapping:
            return "Navigate the diatonic pattern vertically across the fretboard in a spiral from one end of the neck to the other."
        case .jumping:
            return "Move freely horizontally without hitting a bad note — simple rules that keep you in key."
        case .familyOfChords:
            return "See how related chords sit across the fretboard in the horizontal direction — Papa, Mama, and oBro (I, IV, V)."
        case .familialHierarchy:
            return "Learn the relative positions of all naturally occurring chords in the vertical direction — Papa through ySis."
        }
    }
    
    static func detailDescription(for type: PatternType) -> String {
        switch type {
        case .spiralMapping:
            return "Spiral Mapping teaches you to read the repeating diatonic pattern as one continuous vertical path. Follow the spiral column by column and the HEAD block milestones tell you where the whole pattern sits."
        case .jumping:
            return "Jumping is horizontal freedom inside the key. From any in-key note you can leap to other frets on the same string that belong to the pattern. The BRIDGE block is the transitional zone that makes position shifts feel natural."
        case .familyOfChords:
            return "The Family of Chords shows Papa, Mama, and oBro (I, IV, V) as compact 1–3–5 triad voicings spread horizontally. Once you can see the family, accompaniment and key-center chords stop being a scavenger hunt."
        case .familialHierarchy:
            return "Familial Hierarchy stacks every diatonic chord — Papa, yBro, aBoy, Mama, oBro, oSis, ySis (I–vii°) — vertically so you can see how the family is ordered. Family nicknames are the primary labels; roman numerals are the traditional translation."
        }
    }
    
    /// Blocks to emphasize when a concept is selected in the Explorer.
    static func suggestedBlocks(for type: PatternType) -> Set<BlockType> {
        switch type {
        case .spiralMapping:
            return [.headBlock, .bridgeBlock, .tripleBlock]
        case .jumping:
            return [.bridgeBlock, .headBlock]
        case .familyOfChords:
            return [.tripleBlock, .headBlock]
        case .familialHierarchy:
            return [.tripleBlock]
        }
    }
    
    /// Default blocks for lesson / concept demos of a pattern type.
    static func demoBlocks(for type: PatternType) -> Set<BlockType> {
        switch type {
        case .spiralMapping:
            // Full landmark set — Concepts legend can also toggle each type.
            return [.headBlock, .bridgeBlock, .tripleBlock]
        case .jumping:
            return [.bridgeBlock]
        case .familyOfChords, .familialHierarchy:
            return [.tripleBlock]
        }
    }
    
    // MARK: - Blocks
    
    static func blockTitle(_ type: BlockType) -> String {
        switch type {
        case .headBlock: return "HEAD"
        case .bridgeBlock: return "BRIDGE"
        case .tripleBlock: return "TRIPLE"
        }
    }
    
    static func blockSubtitle(_ type: BlockType) -> String {
        switch type {
        case .headBlock: return "XX-X · entry milestone"
        case .bridgeBlock: return "X-XX · transitional zone"
        case .tripleBlock: return "X-X-X · every other half-step (9 notes)"
        }
    }
    
    static func blockDescription(_ type: BlockType) -> String {
        switch type {
        case .headBlock:
            return "The HEAD block is a 6-note XX-X pattern — two adjacent frets, a gap, then one fret — on a perfect-4th string pair (primarily high E and B). It is the entry landmark that tells you where the whole diatonic pattern is sitting."
        case .bridgeBlock:
            return "The BRIDGE block is a 6-note X-XX pattern — one fret, a gap, then two adjacent frets — on the middle string pair (D and A). It connects HEAD and TRIPLE regions and supports horizontal jumping and position shifts."
        case .tripleBlock:
            return "The TRIPLE block is a 9-note X-X-X pattern — three notes per string on every other half-step (frets 0, 2, 4 relative to the anchor) across three consecutive strings. It is always that spacing, never a variable shape."
        }
    }
    
    static var allBlockTypes: [BlockType] {
        [.headBlock, .bridgeBlock, .tripleBlock]
    }
    
    static var allConcepts: [PatternType] {
        [.spiralMapping, .jumping, .familyOfChords, .familialHierarchy]
    }
}
