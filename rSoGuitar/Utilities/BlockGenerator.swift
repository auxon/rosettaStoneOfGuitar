//
//  BlockGenerator.swift
//  rSoGuitar
//
//  Generates block overlays for the fretboard based on rSoGuitar methodology
//  The rSoGuitar method reveals that the entire fretboard is one repeating diatonic pattern
//  containing HEAD, BRIDGE, and TRIPLE blocks that repeat in sequence.
//

import Foundation

struct BlockGenerator {
    
    // MARK: - Main Entry Point
    
    /// Generate all blocks for a given key across the fretboard
    /// Blocks repeat in sequence: HEAD → BRIDGE → TRIPLE → HEAD → BRIDGE → TRIPLE...
    static func allBlocks(for key: Key, maxFret: Int = 24, startBlockType: BlockType = .tripleBlock) -> [Block] {
        var allBlocks: [Block] = []
        
        // Find all HEAD blocks
        let headBlocks = findAllHeadBlocks(for: key, maxFret: maxFret)
        allBlocks.append(contentsOf: headBlocks)
        
        // Find all BRIDGE blocks
        let bridgeBlocks = findAllBridgeBlocks(for: key, maxFret: maxFret)
        allBlocks.append(contentsOf: bridgeBlocks)
        
        // Find all TRIPLE blocks
        let tripleBlocks = findAllTripleBlocks(for: key, maxFret: maxFret)
        allBlocks.append(contentsOf: tripleBlocks)
        
        return allBlocks
    }
    
    // MARK: - Diatonic Pattern Generation
    
    /// Generate the full diatonic pattern for a key
    /// Returns all notes in the key across the fretboard
    static func diatonicPattern(for key: Key, maxFret: Int = 24) -> [FretboardPosition] {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        for string in 1...Constants.numberOfStrings {
            for fret in 0...maxFret {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if keyNotes.contains(note) {
                    positions.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == key.rootNote
                    ))
                }
            }
        }
        
        return positions
    }
    
    // MARK: - HEAD Block (XX-X pattern)
    // HEAD blocks have 6 notes arranged as: two notes close, gap, one note - repeated on pairs of strings
    // Pattern on fretboard: Two adjacent notes on one string, then one note on the next string (shifted)
    
    private static func findAllHeadBlocks(for key: Key, maxFret: Int) -> [Block] {
        var blocks: [Block] = []
        var foundBlockKeys: Set<String> = []
        
        // Search for HEAD blocks starting from different positions
        // HEAD blocks span 3 consecutive strings and typically 2-3 frets
        for startString in 1...4 {  // Can start on strings 1-4 (need 3 strings)
            for startFret in 0...maxFret {
                if let block = identifyHeadBlockAt(
                    startString: startString,
                    startFret: startFret,
                    key: key,
                    maxFret: maxFret
                ) {
                    // Create a unique key for this block based on its positions
                    let blockKey = block.positions.map { "\($0.string),\($0.fret)" }.sorted().joined(separator: "|")
                    if !foundBlockKeys.contains(blockKey) {
                        blocks.append(block)
                        foundBlockKeys.insert(blockKey)
                    }
                }
            }
        }
        
        return blocks
    }
    
    private static func identifyHeadBlockAt(startString: Int, startFret: Int, key: Key, maxFret: Int) -> Block? {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // HEAD block pattern: XX-X on each pair of strings
        // String 1 (relative): 2 notes at fret and fret+2 (or nearby diatonic positions)
        // String 2 (relative): 2 notes
        // String 3 (relative): 2 notes
        // Total: 6 notes
        
        let strings = [startString, startString + 1, startString + 2]
        guard strings.allSatisfy({ $0 >= 1 && $0 <= Constants.numberOfStrings }) else { return nil }
        
        // For each of the 3 strings, find 2 consecutive diatonic notes near the start fret
        for string in strings {
            var notesOnString: [FretboardPosition] = []
            
            // Search within a small fret range for diatonic notes
            let searchRange = max(0, startFret - 1)...min(maxFret, startFret + 4)
            for fret in searchRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if keyNotes.contains(note) {
                    notesOnString.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == key.rootNote
                    ))
                    if notesOnString.count >= 2 { break }  // Take first 2 diatonic notes
                }
            }
            
            positions.append(contentsOf: notesOnString)
        }
        
        // HEAD block needs exactly 6 notes (2 per string)
        guard positions.count == 6 else { return nil }
        
        // Verify the notes form a compact cluster (XX-X pattern)
        let frets = positions.map { $0.fret }
        let fretSpan = (frets.max() ?? 0) - (frets.min() ?? 0)
        guard fretSpan <= 4 else { return nil }  // Should be within ~4 frets
        
        let minFret = frets.min() ?? 0
        let maxFretFound = frets.max() ?? maxFret
        
        return Block(
            type: .headBlock,
            name: "HEAD",
            description: "HEAD block: 6-note XX-X pattern containing scale degrees on 3 consecutive strings.",
            fretRange: minFret...maxFretFound,
            stringRange: strings.min()!...strings.max()!,
            positions: positions
        )
    }
    
    // MARK: - BRIDGE Block (X-XX pattern)
    // BRIDGE blocks have 6 notes arranged as: one note, gap, two notes close - repeated on pairs of strings
    
    private static func findAllBridgeBlocks(for key: Key, maxFret: Int) -> [Block] {
        var blocks: [Block] = []
        var foundBlockKeys: Set<String> = []
        
        for startString in 1...4 {
            for startFret in 0...maxFret {
                if let block = identifyBridgeBlockAt(
                    startString: startString,
                    startFret: startFret,
                    key: key,
                    maxFret: maxFret
                ) {
                    let blockKey = block.positions.map { "\($0.string),\($0.fret)" }.sorted().joined(separator: "|")
                    if !foundBlockKeys.contains(blockKey) {
                        blocks.append(block)
                        foundBlockKeys.insert(blockKey)
                    }
                }
            }
        }
        
        return blocks
    }
    
    private static func identifyBridgeBlockAt(startString: Int, startFret: Int, key: Key, maxFret: Int) -> Block? {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        let strings = [startString, startString + 1, startString + 2]
        guard strings.allSatisfy({ $0 >= 1 && $0 <= Constants.numberOfStrings }) else { return nil }
        
        // For BRIDGE, we look for the X-XX pattern
        // Similar to HEAD but the grouping is different
        for string in strings {
            var notesOnString: [FretboardPosition] = []
            
            let searchRange = max(0, startFret - 1)...min(maxFret, startFret + 4)
            for fret in searchRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if keyNotes.contains(note) {
                    notesOnString.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == key.rootNote
                    ))
                    if notesOnString.count >= 2 { break }
                }
            }
            
            positions.append(contentsOf: notesOnString)
        }
        
        guard positions.count == 6 else { return nil }
        
        let frets = positions.map { $0.fret }
        let fretSpan = (frets.max() ?? 0) - (frets.min() ?? 0)
        guard fretSpan <= 4 else { return nil }
        
        let minFret = frets.min() ?? 0
        let maxFretFound = frets.max() ?? maxFret
        
        return Block(
            type: .bridgeBlock,
            name: "BRIDGE",
            description: "BRIDGE block: 6-note X-XX pattern connecting HEAD and TRIPLE blocks.",
            fretRange: minFret...maxFretFound,
            stringRange: strings.min()!...strings.max()!,
            positions: positions
        )
    }
    
    // MARK: - TRIPLE Block (X-X-X pattern - three triads)
    // TRIPLE blocks contain three 1-3-5 triads (9 notes total)
    // Each triad spans 3 consecutive strings
    
    private static func findAllTripleBlocks(for key: Key, maxFret: Int) -> [Block] {
        var blocks: [Block] = []
        var foundBlockKeys: Set<String> = []
        
        // TRIPLE blocks need more strings since they contain 3 triads
        for startString in 1...4 {
            for startFret in 0...maxFret {
                if let block = identifyTripleBlockAt(
                    startString: startString,
                    startFret: startFret,
                    key: key,
                    maxFret: maxFret
                ) {
                    let blockKey = block.positions.map { "\($0.string),\($0.fret)" }.sorted().joined(separator: "|")
                    if !foundBlockKeys.contains(blockKey) {
                        blocks.append(block)
                        foundBlockKeys.insert(blockKey)
                    }
                }
            }
        }
        
        return blocks
    }
    
    private static func identifyTripleBlockAt(startString: Int, startFret: Int, key: Key, maxFret: Int) -> Block? {
        let root = key.rootNote
        let third = root.addingSemitones(4)  // Major 3rd
        let fifth = root.addingSemitones(7)  // Perfect 5th
        let triadNotes: Set<Note> = [root, third, fifth]
        
        var positions: [FretboardPosition] = []
        
        let strings = [startString, startString + 1, startString + 2]
        guard strings.allSatisfy({ $0 >= 1 && $0 <= Constants.numberOfStrings }) else { return nil }
        
        // Find triad notes (root, 3rd, 5th) on each string
        for string in strings {
            var notesOnString: [FretboardPosition] = []
            
            let searchRange = max(0, startFret - 1)...min(maxFret, startFret + 5)
            for fret in searchRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if triadNotes.contains(note) {
                    notesOnString.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == root
                    ))
                    if notesOnString.count >= 3 { break }  // Up to 3 triad notes per string
                }
            }
            
            positions.append(contentsOf: notesOnString)
        }
        
        // TRIPLE block needs at least 6 notes (2 triads), prefer 9 (3 triads)
        guard positions.count >= 6 else { return nil }
        
        // Verify we have a mix of root, 3rd, and 5th
        let hasRoot = positions.contains { $0.note == root }
        let hasThird = positions.contains { $0.note == third }
        let hasFifth = positions.contains { $0.note == fifth }
        guard hasRoot && hasThird && hasFifth else { return nil }
        
        let frets = positions.map { $0.fret }
        let fretSpan = (frets.max() ?? 0) - (frets.min() ?? 0)
        guard fretSpan <= 5 else { return nil }
        
        let minFret = frets.min() ?? 0
        let maxFretFound = frets.max() ?? maxFret
        
        return Block(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block: \(positions.count)-note X-X-X pattern containing stacked 1-3-5 triads.",
            fretRange: minFret...maxFretFound,
            stringRange: strings.min()!...strings.max()!,
            positions: positions
        )
    }
    
    // MARK: - Public Block Identification (for dragging)
    
    /// Identify HEAD block starting from a given position
    static func identifyHeadBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        return identifyHeadBlockAt(
            startString: max(1, startPos.string - 1),
            startFret: startPos.fret,
            key: key,
            maxFret: maxFret
        )
    }
    
    /// Identify BRIDGE block starting from a given position
    static func identifyBridgeBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        return identifyBridgeBlockAt(
            startString: max(1, startPos.string - 1),
            startFret: startPos.fret,
            key: key,
            maxFret: maxFret
        )
    }
    
    /// Identify TRIPLE block starting from a given position
    static func identifyTripleBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        return identifyTripleBlockAt(
            startString: max(1, startPos.string - 1),
            startFret: startPos.fret,
            key: key,
            maxFret: maxFret
        )
    }
    
    // MARK: - Infinite Bass Pattern
    
    /// Generate infinite bass pattern that extends beyond the 6 strings
    static func infiniteBassPattern(
        for key: Key,
        maxFret: Int = 24,
        stringOffset: Int = 0,
        fretOffset: Int = 0,
        extendedStringCount: Int = 12
    ) -> [FretboardPosition] {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        let startVirtualString = 1 - extendedStringCount / 2 + stringOffset
        let endVirtualString = Constants.numberOfStrings + extendedStringCount / 2 + stringOffset
        
        for virtualString in startVirtualString...endVirtualString {
            let normalizedString = ((virtualString - 1) % Constants.numberOfStrings + Constants.numberOfStrings) % Constants.numberOfStrings
            let baseString = normalizedString + 1
            let octaveOffset = (virtualString - 1) / Constants.numberOfStrings
            
            guard baseString >= 1 && baseString <= Constants.numberOfStrings else { continue }
            
            let openStringNote = Constants.standardTuning[baseString - 1]
            
            for fret in 0...maxFret {
                let adjustedFret = fret + fretOffset
                if adjustedFret < 0 || adjustedFret > maxFret { continue }
                
                let semitonesFromOpen = adjustedFret
                let octaveSemitones = octaveOffset * 12
                let totalSemitones = semitonesFromOpen + octaveSemitones
                let note = openStringNote.addingSemitones(totalSemitones)
                
                if keyNotes.contains(note) {
                    positions.append(FretboardPosition(
                        string: virtualString,
                        fret: adjustedFret,
                        note: note,
                        isRoot: note == key.rootNote
                    ))
                }
            }
        }
        
        return positions
    }
    
    // MARK: - Legacy Functions (kept for compatibility)
    
    /// Generate HEAD block using the legacy approach
    static func headBlock(for key: Key, maxFret: Int = 12) -> Block {
        let blocks = findAllHeadBlocks(for: key, maxFret: maxFret)
        return blocks.first ?? Block(
            type: .headBlock,
            name: "HEAD",
            description: "HEAD block not found for this key.",
            fretRange: 0...4,
            stringRange: 1...3,
            positions: []
        )
    }
    
    /// Generate BRIDGE block using the legacy approach
    static func bridgeBlock(for key: Key, maxFret: Int = 12) -> Block {
        let blocks = findAllBridgeBlocks(for: key, maxFret: maxFret)
        return blocks.first ?? Block(
            type: .bridgeBlock,
            name: "BRIDGE",
            description: "BRIDGE block not found for this key.",
            fretRange: 2...7,
            stringRange: 4...5,
            positions: []
        )
    }
    
    /// Generate TRIPLE block using the legacy approach
    static func tripleBlock(for key: Key, maxFret: Int = 12) -> Block {
        let blocks = findAllTripleBlocks(for: key, maxFret: maxFret)
        return blocks.first ?? Block(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block not found for this key.",
            fretRange: 0...5,
            stringRange: 1...6,
            positions: []
        )
    }
}
