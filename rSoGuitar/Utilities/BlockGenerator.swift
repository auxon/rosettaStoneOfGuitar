//
//  BlockGenerator.swift
//  rSoGuitar
//
//  Generates block overlays for the fretboard based on rSoGuitar methodology
//

import Foundation

struct BlockGenerator {
    /// Generate HEAD block - 6 notes arranged as XX-X pattern
    /// Pattern: XX-X (2 notes, 2 notes, 1 note) on two rows
    /// Contains specific scale degrees in the head region
    static func headBlock(for key: Key, maxFret: Int = 12) -> Block {
        let root = key.rootNote
        let keyNotes = FretboardCalculator.notesInKey(key)
        
        // HEAD block pattern: XX-X (6 notes total)
        // Based on rSoGuitar, this is typically: root, 2nd on one set, root, 3rd on another, 5th
        // Pattern appears on strings 1-3, arranged as:
        // Row 1: 2 notes, 2 notes, 1 note
        // Row 2: 2 notes, 2 notes, 1 note
        // Total: 6 notes
        
        // Find the first occurrence of the head block pattern starting from open strings
        // HEAD block typically starts around frets 0-3 on strings 1-3
        var positions: [FretboardPosition] = []
        var foundPositions: Set<String> = []
        
        // Look for the XX-X pattern on strings 1-3
        // Try to find root positions first, then build the pattern around them
        for startFret in 0...3 {
            // Check if we can form the head block pattern starting at this fret
            // Pattern: XX-X means 2 notes close, 2 notes close, 1 note separated
            
            // Try string 1 (high E) - look for root and 2nd
            let root1 = FretboardCalculator.noteAt(string: 1, fret: startFret)
            if root1 == root {
                let second1 = root.addingSemitones(2) // Major 2nd
                let second1Fret = findFretForNote(second1, on: 1, near: startFret, maxFret: maxFret)
                
                if let second1Fret = second1Fret {
                    // String 2 (B) - look for root and 3rd
                    let root2 = FretboardCalculator.noteAt(string: 2, fret: startFret)
                    if root2 == root || root2 == second1 {
                        let third2 = root.addingSemitones(4) // Major 3rd
                        let third2Fret = findFretForNote(third2, on: 2, near: startFret, maxFret: maxFret)
                        
                        if let third2Fret = third2Fret {
                            // String 3 (G) - look for 5th
                            let fifth3 = root.addingSemitones(7) // Perfect 5th
                            let fifth3Fret = findFretForNote(fifth3, on: 3, near: startFret, maxFret: maxFret)
                            
                            if let fifth3Fret = fifth3Fret {
                                // Found a head block! Add all 6 positions
                                addPositionIfNew(&positions, &foundPositions, string: 1, fret: startFret, note: root1, isRoot: true)
                                addPositionIfNew(&positions, &foundPositions, string: 1, fret: second1Fret, note: second1, isRoot: false)
                                addPositionIfNew(&positions, &foundPositions, string: 2, fret: startFret, note: root2, isRoot: root2 == root)
                                addPositionIfNew(&positions, &foundPositions, string: 2, fret: third2Fret, note: third2, isRoot: false)
                                addPositionIfNew(&positions, &foundPositions, string: 3, fret: fifth3Fret, note: fifth3, isRoot: false)
                                
                                // Add second row (octave up or continuation)
                                let root1Octave = FretboardCalculator.noteAt(string: 1, fret: startFret + 12)
                                if root1Octave == root && startFret + 12 <= maxFret {
                                    addPositionIfNew(&positions, &foundPositions, string: 1, fret: startFret + 12, note: root1Octave, isRoot: true)
                                }
                                
                                // If we found 6 positions, we're done
                                if positions.count >= 6 {
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: if we didn't find the exact pattern, use a simpler approach
        // Find root, 2nd, 3rd, 5th, 6th, 7th on strings 1-3 in the lower frets
        if positions.count < 6 {
            positions = []
            foundPositions = []
            let scaleDegrees: [(interval: Int, priority: Int)] = [
                (0, 1),   // Root - highest priority
                (2, 2),   // 2nd
                (4, 3),   // 3rd
                (7, 4),   // 5th
                (9, 5),   // 6th
                (11, 6)   // 7th
            ]
            
            for (interval, _) in scaleDegrees.sorted(by: { $0.priority < $1.priority }) {
                let note = root.addingSemitones(interval)
                // Find this note on strings 1-3 in frets 0-4
                for string in 1...3 {
                    for fret in 0...4 {
                        let fretNote = FretboardCalculator.noteAt(string: string, fret: fret)
                        if fretNote == note {
                            let key = "\(string),\(fret)"
                            if !foundPositions.contains(key) && positions.count < 6 {
                                positions.append(FretboardPosition(
                                    string: string,
                                    fret: fret,
                                    note: note,
                                    isRoot: interval == 0
                                ))
                                foundPositions.insert(key)
                                break
                            }
                        }
                    }
                    if positions.count >= 6 { break }
                }
                if positions.count >= 6 { break }
            }
        }
        
        // Ensure exactly 6 notes (take first 6 if we found more)
        positions = Array(positions.prefix(6))
        
        let frets = positions.map { $0.fret }
        let fretRange = (frets.min() ?? 0)...(frets.max() ?? 4)
        let stringRange = 1...3
        
        return Block(
            type: .headBlock,
            name: "HEAD",
            description: "The HEAD block is a 6-note pattern (XX-X) containing root, 2nd, 3rd, 5th, 6th, and 7th scale degrees on the top three strings.",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    /// Generate BRIDGE block - 6 notes arranged as X-XX pattern
    /// Pattern: X-XX (1 note, 1 note, 2 notes) on two rows
    static func bridgeBlock(for key: Key, maxFret: Int = 12) -> Block {
        let root = key.rootNote
        let keyNotes = FretboardCalculator.notesInKey(key)
        
        // BRIDGE block pattern: X-XX (6 notes total)
        // Pattern appears on strings 4-5, arranged as:
        // Row 1: 1 note, 1 note, 2 notes
        // Row 2: 1 note, 1 note, 2 notes
        // Total: 6 notes
        
        var positions: [FretboardPosition] = []
        var foundPositions: Set<String> = []
        
        // Find 6 notes on strings 4-5 in the bridge region (typically frets 2-7)
        // Bridge contains: 4th, 5th, 6th, 7th, root octave, 2nd
        let scaleDegrees: [(interval: Int, priority: Int)] = [
            (5, 1),   // 4th
            (7, 2),   // 5th
            (9, 3),   // 6th
            (11, 4),  // 7th
            (0, 5),   // Root octave
            (2, 6)    // 2nd/9th
        ]
        
        for (interval, _) in scaleDegrees.sorted(by: { $0.priority < $1.priority }) {
            let note = root.addingSemitones(interval)
            // Find this note on strings 4-5 in frets 2-7
            for string in 4...5 {
                for fret in 2...7 {
                    let fretNote = FretboardCalculator.noteAt(string: string, fret: fret)
                    if fretNote == note {
                        let key = "\(string),\(fret)"
                        if !foundPositions.contains(key) && positions.count < 6 {
                            positions.append(FretboardPosition(
                                string: string,
                                fret: fret,
                                note: note,
                                isRoot: interval == 0
                            ))
                            foundPositions.insert(key)
                            break
                        }
                    }
                }
                if positions.count >= 6 { break }
            }
            if positions.count >= 6 { break }
        }
        
        // Ensure exactly 6 notes (take first 6 if we found more)
        positions = Array(positions.prefix(6))
        
        let frets = positions.map { $0.fret }
        let fretRange = (frets.min() ?? 2)...(frets.max() ?? 7)
        let stringRange = 4...5
        
        return Block(
            type: .bridgeBlock,
            name: "BRIDGE",
            description: "The BRIDGE block is a 6-note pattern (X-XX) containing connecting notes like 4th, 5th, 6th, 7th, root octave, and 2nd on the middle strings.",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    // Helper function to find fret for a note on a specific string
    private static func findFretForNote(_ targetNote: Note, on string: Int, near fret: Int, maxFret: Int) -> Int? {
        for offset in 0...3 {
            // Check frets near the reference fret
            for delta in [-offset, offset] {
                let checkFret = fret + delta
                if checkFret >= 0 && checkFret <= maxFret {
                    let note = FretboardCalculator.noteAt(string: string, fret: checkFret)
                    if note == targetNote {
                        return checkFret
                    }
                }
            }
        }
        return nil
    }
    
    // Helper function to add position if not already found
    private static func addPositionIfNew(_ positions: inout [FretboardPosition], _ found: inout Set<String>, string: Int, fret: Int, note: Note, isRoot: Bool) {
        let key = "\(string),\(fret)"
        if !found.contains(key) {
            positions.append(FretboardPosition(
                string: string,
                fret: fret,
                note: note,
                isRoot: isRoot
            ))
            found.insert(key)
        }
    }
    
    /// Generate TRIPLE BLOCK - 9 notes arranged as X-X-X pattern
    /// Pattern: X-X-X (1 note, 1 note, 1 note) on three rows
    /// This is the 1-3-5 triad pattern appearing three times (9 notes total)
    static func tripleBlock(for key: Key, maxFret: Int = 12) -> Block {
        let root = key.rootNote
        let third = root.addingSemitones(4)  // Major 3rd
        let fifth = root.addingSemitones(7)  // Perfect 5th
        var positions: [FretboardPosition] = []
        var seenPositions: Set<String> = []
        
        // TRIPLE BLOCK pattern: X-X-X (9 notes total)
        // Three instances of the 1-3-5 triad pattern
        // Find three sets of root-3rd-5th on three consecutive strings
        
        var triadCount = 0
        // Try different string groups: (1,2,3), (2,3,4), (3,4,5), (4,5,6)
        for startString in 1...4 {
            if triadCount >= 3 { break }
            
            let string1 = startString
            let string2 = startString + 1
            let string3 = startString + 2
            
            // Find root positions on string1
            for fret1 in 0...maxFret {
                if triadCount >= 3 { break }
                
                let note1 = FretboardCalculator.noteAt(string: string1, fret: fret1)
                if note1 == root {
                    // Look for 3rd on string2 and 5th on string3
                    for fret2 in max(0, fret1 - 2)...min(maxFret, fret1 + 3) {
                        let note2 = FretboardCalculator.noteAt(string: string2, fret: fret2)
                        if note2 == third {
                            for fret3 in max(0, fret2 - 2)...min(maxFret, fret2 + 3) {
                                let note3 = FretboardCalculator.noteAt(string: string3, fret: fret3)
                                if note3 == fifth {
                                    // Found a triple block triad! Add all three positions
                                    let pos1Key = "\(string1),\(fret1)"
                                    let pos2Key = "\(string2),\(fret2)"
                                    let pos3Key = "\(string3),\(fret3)"
                                    
                                    if !seenPositions.contains(pos1Key) {
                                        positions.append(FretboardPosition(
                                            string: string1,
                                            fret: fret1,
                                            note: root,
                                            isRoot: true
                                        ))
                                        seenPositions.insert(pos1Key)
                                    }
                                    if !seenPositions.contains(pos2Key) {
                                        positions.append(FretboardPosition(
                                            string: string2,
                                            fret: fret2,
                                            note: third,
                                            isRoot: false
                                        ))
                                        seenPositions.insert(pos2Key)
                                    }
                                    if !seenPositions.contains(pos3Key) {
                                        positions.append(FretboardPosition(
                                            string: string3,
                                            fret: fret3,
                                            note: fifth,
                                            isRoot: false
                                        ))
                                        seenPositions.insert(pos3Key)
                                    }
                                    
                                    triadCount += 1
                                    if positions.count >= 9 { break }
                                }
                            }
                        }
                        if positions.count >= 9 { break }
                    }
                }
                if positions.count >= 9 { break }
            }
        }
        
        // Ensure exactly 9 notes (take first 9 if we found more)
        positions = Array(positions.prefix(9))
        
        // Calculate fret range for visualization
        let frets = positions.map { $0.fret }
        let fretRange = (frets.min() ?? 0)...(frets.max() ?? maxFret)
        let stringRange = 1...6  // Triple blocks can appear on any string group
        
        return Block(
            type: .tripleBlock,
            name: "TRIPLE BLOCK",
            description: "The TRIPLE BLOCK is a 9-note pattern (X-X-X) showing three instances of the 1-3-5 triad (root, major 3rd, perfect 5th) on three consecutive strings.",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    /// Generate all blocks for a key
    /// Finds all blocks of each type independently within the continuous diatonic pattern
    /// Returns all HEAD, BRIDGE, and TRIPLE blocks found across the fretboard
    static func allBlocks(for key: Key, maxFret: Int = 12, startBlockType: BlockType = .tripleBlock) -> [Block] {
        // First, get the full diatonic pattern
        let pattern = diatonicPattern(for: key, maxFret: maxFret)
        
        // Find all blocks of each type independently
        var allBlocks: [Block] = []
        
        // Find all HEAD blocks
        let headBlocks = findBlocksInPattern(pattern: pattern, key: key, maxFret: maxFret, blockType: .headBlock)
        allBlocks.append(contentsOf: headBlocks)
        
        // Find all BRIDGE blocks
        let bridgeBlocks = findBlocksInPattern(pattern: pattern, key: key, maxFret: maxFret, blockType: .bridgeBlock)
        allBlocks.append(contentsOf: bridgeBlocks)
        
        // Find all TRIPLE blocks
        let tripleBlocks = findBlocksInPattern(pattern: pattern, key: key, maxFret: maxFret, blockType: .tripleBlock)
        allBlocks.append(contentsOf: tripleBlocks)
        
        return allBlocks
    }
    
    /// Get the next block type in sequence
    private static func nextBlockType(after type: BlockType) -> BlockType {
        switch type {
        case .headBlock: return .bridgeBlock
        case .bridgeBlock: return .tripleBlock
        case .tripleBlock: return .headBlock
        }
    }
    
    /// Generate the full diatonic pattern for a key
    /// Returns all notes in the key across the fretboard
    /// The pattern follows the continuous diatonic scale with B string shift
    /// Pattern repeats vertically: XX-X-XX-X-X-XX-X-XX-X-X-XX-X-XX-X-X
    static func diatonicPattern(for key: Key, maxFret: Int = 12) -> [FretboardPosition] {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Find all positions of notes in the key across the fretboard
        // The B string (string 2) causes a 1-fret shift in the pattern
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
        
        // Sort positions by string and fret for easier block identification
        positions.sort { pos1, pos2 in
            if pos1.string != pos2.string {
                return pos1.string < pos2.string
            }
            return pos1.fret < pos2.fret
        }
        
        return positions
    }
    
    /// Generate infinite bass pattern that extends beyond the 6 strings
    /// This creates a continuous pattern that can be shifted to show different modes/keys
    /// The pattern continues the diatonic scale infinitely in both string directions
    /// stringOffset: allows shifting the pattern up/down (negative = lower strings, positive = higher strings)
    /// fretOffset: allows shifting the pattern left/right
    /// extendedStringCount: number of virtual strings to show (centered around the 6 physical strings)
    static func infiniteBassPattern(
        for key: Key,
        maxFret: Int = 24,
        stringOffset: Int = 0,
        fretOffset: Int = 0,
        extendedStringCount: Int = 12
    ) -> [FretboardPosition] {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Calculate the range of virtual strings to display
        // Center the extended strings around the physical strings (1-6)
        // Physical strings are 1-6, so we'll show strings from (1 - extendedStringCount/2) to (6 + extendedStringCount/2)
        let startVirtualString = 1 - extendedStringCount / 2 + stringOffset
        let endVirtualString = Constants.numberOfStrings + extendedStringCount / 2 + stringOffset
        
        // Generate pattern for extended string range
        for virtualString in startVirtualString...endVirtualString {
            // Map virtual string to a base string (1-6) and calculate octave offset
            // Strings repeat every 6, but with octave shifts
            // Handle negative virtual strings correctly
            let normalizedString = ((virtualString - 1) % Constants.numberOfStrings + Constants.numberOfStrings) % Constants.numberOfStrings
            let baseString = normalizedString + 1  // Now guaranteed to be 1-6
            let octaveOffset = (virtualString - 1) / Constants.numberOfStrings
            
            // Ensure baseString is in valid range before accessing array
            guard baseString >= 1 && baseString <= Constants.numberOfStrings else {
                continue  // Skip invalid strings
            }
            
            // Get the open string note for the base string
            let openStringNote = Constants.standardTuning[baseString - 1]
            
            for fret in 0...maxFret {
                let adjustedFret = fret + fretOffset
                if adjustedFret < 0 || adjustedFret > maxFret { continue }
                
                // Calculate note at this position
                // Start from the open string note, add fret offset, then add octave offset
                let semitonesFromOpen = adjustedFret
                let octaveSemitones = octaveOffset * 12
                let totalSemitones = semitonesFromOpen + octaveSemitones
                let note = openStringNote.addingSemitones(totalSemitones)
                
                // Check if this note is in the key
                if keyNotes.contains(note) {
                    positions.append(FretboardPosition(
                        string: virtualString,  // Use virtual string number for display
                        fret: adjustedFret,
                        note: note,
                        isRoot: note == key.rootNote
                    ))
                }
            }
        }
        
        return positions
    }
    
    /// Find blocks within the continuous diatonic pattern
    /// Accounts for B string shift (string 2 shifts by 1 fret)
    private static func findBlocksInPattern(pattern: [FretboardPosition], key: Key, maxFret: Int, blockType: BlockType) -> [Block] {
        var blocks: [Block] = []
        var usedPositions: Set<String> = []
        
        // Create a map of pattern positions for quick lookup
        var patternMap: [String: FretboardPosition] = [:]
        for pos in pattern {
            patternMap["\(pos.string),\(pos.fret)"] = pos
        }
        
        // Blocks can appear on any strings - search the entire pattern
        // For triple blocks, we need to search more thoroughly since they require 9 notes
        let searchPositions = blockType == .tripleBlock ? 
            pattern.sorted(by: { $0.fret < $1.fret || ($0.fret == $1.fret && $0.string < $1.string) }) :
            pattern
        
        for startPos in searchPositions {
            let posKey = "\(startPos.string),\(startPos.fret)"
            if usedPositions.contains(posKey) && blockType != .tripleBlock { 
                // For triple blocks, allow starting from used positions since they need more notes
                continue 
            }
            
            if let block = identifyBlock(
                startingFrom: startPos,
                blockType: blockType,
                patternMap: patternMap,
                key: key,
                maxFret: maxFret
            ) {
                // Allow blocks to overlap - they can share positions where appropriate
                // Only skip if this block is completely identical to an existing one
                let blockPositions = Set(block.positions.map { "\($0.string),\($0.fret)" })
                let isDuplicate = blocks.contains { existingBlock in
                    let existingPositions = Set(existingBlock.positions.map { "\($0.string),\($0.fret)" })
                    return blockPositions == existingPositions
                }
                
                if !isDuplicate {
                    blocks.append(block)
                    // Track positions but allow overlap
                    usedPositions.formUnion(blockPositions)
                    
                    // Limit number of blocks to avoid too many
                    if blocks.count >= 10 { break }
                }
            }
        }
        
        return blocks
    }
    
    /// Identify a block starting from a given position within the pattern
    /// Accounts for B string shift (string 2 = B string shifts by 1 fret)
    private static func identifyBlock(
        startingFrom startPos: FretboardPosition,
        blockType: BlockType,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        switch blockType {
        case .tripleBlock:
            return identifyTripleBlock(startingFrom: startPos, patternMap: patternMap, key: key, maxFret: maxFret)
        case .headBlock:
            return identifyHeadBlock(startingFrom: startPos, patternMap: patternMap, key: key, maxFret: maxFret)
        case .bridgeBlock:
            return identifyBridgeBlock(startingFrom: startPos, patternMap: patternMap, key: key, maxFret: maxFret)
        }
    }
    
    /// Identify TRIPLE block: X-X-X pattern (three 1-3-5 triads on three consecutive strings)
    /// Finds triads within the continuous diatonic pattern
    /// Accounts for B string shift: when crossing string 2 (B string), shift by 1 fret
    static func identifyTripleBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        // TRIPLE block contains three 1-3-5 triads (9 notes total)
        // Find triads by looking for root-3rd-5th relationships within the pattern
        let root = key.rootNote
        let third = root.addingSemitones(4)  // Major 3rd
        let fifth = root.addingSemitones(7)  // Perfect 5th
        
        var positions: [FretboardPosition] = []
        var foundTriads = 0
        
        // Find three triads: can be diagonal, vertical, or a combination
        // Try different string groups to find triads
        // We'll search more broadly to find triads on different string combinations
        var searchedTriads: Set<String> = [] // Track triads we've already found to avoid duplicates
        
        // Search for triads on all possible string combinations
        for startString in 1...4 {
            if foundTriads >= 3 { break }
            
            let string1 = startString
            let string2 = startString + 1
            let string3 = startString + 2
            
            // Find all root positions on string1 within the pattern, sorted by fret
            let rootPositions = patternMap.values
                .filter { $0.string == string1 && $0.note == root }
                .sorted(by: { $0.fret < $1.fret })
            
            for pos1 in rootPositions {
                if foundTriads >= 3 { break }
                
                let fret1 = pos1.fret
                
                // Find 3rd on string2 - account for B string shift
                // When going from string N to string N+1:
                // - If string N+1 is NOT the B string (string 2): perfect 4th interval (5 semitones)
                // - If string N+1 IS the B string: major 3rd interval (4 semitones) = 1 fret shift
                let isBString = (string2 == 2)
                let intervalToThird = isBString ? 4 : 5  // semitones
                
                // Calculate expected fret for 3rd on string2
                // The interval from root to 3rd is 4 semitones
                // But the string interval affects the fret position
                let openString1 = FretboardCalculator.standardTuning[string1 - 1]
                let openString2 = FretboardCalculator.standardTuning[string2 - 1]
                let stringInterval = (openString2.semitonesFromC - openString1.semitonesFromC + 12) % 12
                
                // Expected fret for 3rd on string2
                let expectedFret2 = fret1 + (4 - stringInterval + 12) % 12
                if expectedFret2 < 0 { continue }
                
                // Look for 3rd on string2 near expected position - expand search range
                for offset in -2...2 {
                    let fret2 = expectedFret2 + offset
                    if fret2 < 0 || fret2 > maxFret { continue }
                    
                    let pos2Key = "\(string2),\(fret2)"
                    if let pos2 = patternMap[pos2Key], pos2.note == third {
                        // Find 5th on string3
                        let openString3 = FretboardCalculator.standardTuning[string3 - 1]
                        let stringInterval23 = (openString3.semitonesFromC - openString2.semitonesFromC + 12) % 12
                        let isBString3 = (string3 == 2)
                        
                        // Interval from 3rd to 5th is 3 semitones
                        let expectedFret3 = fret2 + (3 - stringInterval23 + 12) % 12
                        if expectedFret3 < 0 { continue }
                        
                        for offset3 in -2...2 {
                            let fret3 = expectedFret3 + offset3
                            if fret3 < 0 || fret3 > maxFret { continue }
                            
                            let pos3Key = "\(string3),\(fret3)"
                            if let pos3 = patternMap[pos3Key], pos3.note == fifth {
                                // Found a complete triad - check if we've seen this exact triad before
                                let triadKey = "\(string1),\(fret1)-\(string2),\(fret2)-\(string3),\(fret3)"
                                if searchedTriads.contains(triadKey) { continue }
                                searchedTriads.insert(triadKey)
                                
                                // Add all three positions if not already present
                                if !positions.contains(where: { $0.string == string1 && $0.fret == fret1 }) {
                                    positions.append(pos1)
                                }
                                if !positions.contains(where: { $0.string == string2 && $0.fret == fret2 }) {
                                    positions.append(pos2)
                                }
                                if !positions.contains(where: { $0.string == string3 && $0.fret == fret3 }) {
                                    positions.append(pos3)
                                }
                                foundTriads += 1
                                if positions.count >= 9 { break }
                            }
                        }
                    }
                    if positions.count >= 9 { break }
                }
                if positions.count >= 9 { break }
            }
        }
        
        // Return block if we found at least 6 positions (2 triads) - prefer 9 (3 triads) but allow 6
        // Triple blocks should ideally have 9 notes, but we'll accept 6+ to ensure blocks are found
        if positions.count >= 6 {
            // Take up to 9 positions if we found more
            let finalPositions = Array(positions.prefix(9))
            let frets = finalPositions.map { $0.fret }
            let strings = finalPositions.map { $0.string }
            return Block(
                type: .tripleBlock,
                name: "TRIPLE BLOCK",
                description: "The TRIPLE BLOCK is a 9-note pattern (X-X-X) showing three instances of the 1-3-5 triad (root, major 3rd, perfect 5th) on three consecutive strings.",
                fretRange: (frets.min() ?? 0)...(frets.max() ?? maxFret),
                stringRange: (strings.min() ?? 1)...(strings.max() ?? 6),
                positions: finalPositions
            )
        }
        
        return nil
    }
    
    /// Identify HEAD block: XX-X XX-X pattern (6 notes)
    /// Pattern: XX-X on two rows
    /// Row 1: XX-X (2 notes, 2 notes, 1 note)
    /// Row 2: XX-X (2 notes, 2 notes, 1 note)
    /// Total: 6 notes arranged in this specific pattern
    /// Can appear on any strings - the pattern shifts with the starting position
    static func identifyHeadBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        // HEAD block can be on any strings - find the pattern starting from this position
        guard startPos.string >= 1 && startPos.string <= Constants.numberOfStrings else {
            return nil
        }
        
        let baseFret = startPos.fret
        let baseString = startPos.string
        
        // HEAD block pattern: XX-X XX-X means exactly 6 notes in a compact cluster
        // Find exactly 6 notes within a tight range (max 3 frets)
        // The pattern can span across multiple strings
        let maxSearchRange = 3
        
        // Collect candidate notes, prioritizing by proximity
        var candidates: [(pos: FretboardPosition, distance: Int)] = []
        for fretOffset in -maxSearchRange...maxSearchRange {
            // Search on nearby strings (within 2 strings of the starting string)
            for stringOffset in -2...2 {
                let string = baseString + stringOffset
                guard string >= 1 && string <= Constants.numberOfStrings else { continue }
                
                // Account for B string shift (string 2 shifts by 1 fret)
                let bStringShift = (string == 2) ? 1 : 0
                let fret = baseFret + fretOffset + bStringShift
                
                guard fret >= 0 && fret <= maxFret else { continue }
                
                let posKey = "\(string),\(fret)"
                if let pos = patternMap[posKey] {
                    // Calculate distance from starting position
                    let fretDistance = abs(fret - baseFret)
                    let stringDistance = abs(string - baseString)
                    let totalDistance = fretDistance + stringDistance
                    candidates.append((pos: pos, distance: totalDistance))
                }
            }
        }
        
        // Sort by distance (closest first) and take exactly 6
        candidates.sort { $0.distance < $1.distance }
        let positions = candidates.prefix(6).map { $0.pos }
        
        // Only return if we found exactly 6 notes in a compact range
        if positions.count == 6 {
            let frets = positions.map { $0.fret }
            let strings = positions.map { $0.string }
            let minFret = frets.min() ?? 0
            let maxFretFound = frets.max() ?? maxFret
            let fretSpan = maxFretFound - minFret
            
            // HEAD blocks should be compact (span of 3 frets max)
            if fretSpan <= 3 {
                return Block(
                    type: .headBlock,
                    name: "HEAD",
                    description: "The HEAD block is a 6-note pattern (XX-X) containing root, 2nd, 3rd, 5th, 6th, and 7th scale degrees.",
                    fretRange: minFret...maxFretFound,
                    stringRange: (strings.min() ?? 1)...(strings.max() ?? 6),
                    positions: positions
                )
            }
        }
        
        return nil
    }
    
    /// Identify BRIDGE block: X-XX pattern (6 notes)
    /// Pattern forms a cluster within the continuous diagonal pattern
    /// BRIDGE block pattern: X-XX means 1 note, 1 note, 2 notes on two rows
    /// Can appear on any strings - the pattern shifts with the starting position
    static func identifyBridgeBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        // BRIDGE block can be on any strings - find the pattern starting from this position
        guard startPos.string >= 1 && startPos.string <= Constants.numberOfStrings else {
            return nil
        }
        
        var positions: [FretboardPosition] = []
        positions.append(startPos)
        
        // Find 5 more notes following the diagonal pattern
        let baseFret = startPos.fret
        let baseString = startPos.string
        
        // Search for nearby notes following the diagonal pattern
        // BRIDGE block should form clusters: X-XX pattern
        let maxSearchRange = 3
        var candidates: [(pos: FretboardPosition, distance: Int)] = []
        
        for fretOffset in -maxSearchRange...maxSearchRange {
            // Search on nearby strings (within 2 strings of the starting string)
            for stringOffset in -2...2 {
                let string = baseString + stringOffset
                guard string >= 1 && string <= Constants.numberOfStrings else { continue }
                
                // Account for B string shift (string 2 shifts by 1 fret)
                let bStringShift = (string == 2) ? 1 : 0
                let fret = baseFret + fretOffset + bStringShift
                guard fret >= 0 && fret <= maxFret else { continue }
                
                let posKey = "\(string),\(fret)"
                if let pos = patternMap[posKey],
                   !positions.contains(where: { $0.string == string && $0.fret == fret }) {
                    let fretDistance = abs(fret - baseFret)
                    let stringDistance = abs(string - baseString)
                    let totalDistance = fretDistance + stringDistance
                    candidates.append((pos: pos, distance: totalDistance))
                }
            }
        }
        
        // Sort by distance and take the 5 closest (we already have the starting position)
        candidates.sort { $0.distance < $1.distance }
        positions.append(contentsOf: candidates.prefix(5).map { $0.pos })
        
        // Only return if we found exactly 6 notes in a compact range
        if positions.count == 6 {
            let frets = positions.map { $0.fret }
            let strings = positions.map { $0.string }
            let minFret = frets.min() ?? 0
            let maxFretFound = frets.max() ?? maxFret
            let fretSpan = maxFretFound - minFret
            
            // BRIDGE blocks should be compact (span of 3 frets max)
            if fretSpan <= 3 {
                return Block(
                    type: .bridgeBlock,
                    name: "BRIDGE",
                    description: "The BRIDGE block is a 6-note pattern (X-XX) containing connecting notes like 4th, 5th, 6th, 7th, root octave, and 2nd.",
                    fretRange: minFret...maxFretFound,
                    stringRange: (strings.min() ?? 1)...(strings.max() ?? 6),
                    positions: positions
                )
            }
        }
        
        return nil
    }
    
    /// Find the next block in sequence after a given block
    private static func findNextBlockInSequence(
        after previousBlock: Block,
        blockType: BlockType,
        pattern: [FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        // Find the next block by looking for it in the pattern after the previous block
        // The next block should be positioned after the previous block in the diagonal pattern
        let patternMap = Dictionary(uniqueKeysWithValues: pattern.map { ("\($0.string),\($0.fret)", $0) })
        
        // Find a starting position after the previous block
        let previousMaxFret = previousBlock.positions.map { $0.fret }.max() ?? 0
        let searchStartFret = previousMaxFret + 1
        
        // Search for the next block starting from positions after the previous block
        for pos in pattern {
            if pos.fret >= searchStartFret && pos.fret <= min(maxFret, searchStartFret + 5) {
                if let nextBlock = identifyBlock(
                    startingFrom: pos,
                    blockType: blockType,
                    patternMap: patternMap,
                    key: key,
                    maxFret: maxFret
                ) {
                    // Allow blocks to overlap - only skip if this is a complete duplicate
                    let prevPositions = Set(previousBlock.positions.map { "\($0.string),\($0.fret)" })
                    let nextPositions = Set(nextBlock.positions.map { "\($0.string),\($0.fret)" })
                    // Allow overlap - blocks can share positions
                    if nextPositions != prevPositions {
                        return nextBlock
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Find all HEAD blocks in the key (legacy method - kept for compatibility)
    /// HEAD block pattern: XX-X (6 notes) on strings 1-3
    private static func findHeadBlocks(for key: Key, maxFret: Int) -> [Block] {
        let root = key.rootNote
        let keyNotes = FretboardCalculator.notesInKey(key)
        var headBlocks: [Block] = []
        var usedPositions: Set<String> = []
        
        // Find HEAD blocks starting from open strings
        // HEAD block contains: root, 2nd, 3rd, 5th, 6th, 7th on strings 1-3
        // Pattern: XX-X means clusters of notes
        for startFret in 0...maxFret {
            var positions: [FretboardPosition] = []
            var foundPositions: Set<String> = []
            
            // Try to find the HEAD block pattern starting at this fret
            // Look for notes in key on strings 1-3 within a reasonable range
            let scaleDegrees: [(interval: Int, priority: Int)] = [
                (0, 1),   // Root
                (2, 2),   // 2nd
                (4, 3),   // 3rd
                (7, 4),   // 5th
                (9, 5),   // 6th
                (11, 6)   // 7th
            ]
            
            for (interval, _) in scaleDegrees.sorted(by: { $0.priority < $1.priority }) {
                let note = root.addingSemitones(interval)
                // Find this note on strings 1-3 near the start fret (within 5 frets)
                for string in 1...3 {
                    var found = false
                    for fretOffset in 0...5 {
                        let fret = startFret + fretOffset
                        if fret > maxFret { continue }
                        
                        let fretNote = FretboardCalculator.noteAt(string: string, fret: fret)
                        if fretNote == note {
                            let posKey = "\(string),\(fret)"
                            if !foundPositions.contains(posKey) && positions.count < 6 {
                                positions.append(FretboardPosition(
                                    string: string,
                                    fret: fret,
                                    note: note,
                                    isRoot: interval == 0
                                ))
                                foundPositions.insert(posKey)
                                found = true
                                break
                            }
                        }
                    }
                    if found { break }
                }
                if positions.count >= 6 { break }
            }
            
            if positions.count == 6 {
                // Allow blocks to overlap - only skip if this is a complete duplicate
                let posKeys = Set(positions.map { "\($0.string),\($0.fret)" })
                let isDuplicate = headBlocks.contains { existingBlock in
                    let existingPositions = Set(existingBlock.positions.map { "\($0.string),\($0.fret)" })
                    return posKeys == existingPositions
                }
                
                if !isDuplicate {
                    let frets = positions.map { $0.fret }
                    let fretRange = (frets.min() ?? 0)...(frets.max() ?? maxFret)
                    let stringRange = 1...3
                    
                    headBlocks.append(Block(
                        type: .headBlock,
                        name: "HEAD",
                        description: "The HEAD block is a 6-note pattern (XX-X) containing root, 2nd, 3rd, 5th, 6th, and 7th scale degrees on the top three strings.",
                        fretRange: fretRange,
                        stringRange: stringRange,
                        positions: positions
                    ))
                    
                    usedPositions.formUnion(posKeys)
                    
                    // Continue to find more HEAD blocks
                    if headBlocks.count >= 10 { break }
                }
            }
        }
        
        return headBlocks
    }
    
    /// Find BRIDGE block that follows a HEAD block
    private static func findBridgeBlockFollowing(headBlock: Block, key: Key, maxFret: Int) -> Block? {
        let root = key.rootNote
        
        // BRIDGE block follows HEAD block, typically on strings 4-5
        // Find the highest fret in the HEAD block to determine where BRIDGE starts
        let headMaxFret = headBlock.positions.map { $0.fret }.max() ?? 0
        let bridgeStartFret = headMaxFret + 1
        
        var positions: [FretboardPosition] = []
        var foundPositions: Set<String> = []
        
        // BRIDGE block pattern: X-XX on strings 4-5
        let scaleDegrees: [(interval: Int, priority: Int)] = [
            (5, 1),   // 4th
            (7, 2),   // 5th
            (9, 3),   // 6th
            (11, 4),  // 7th
            (0, 5),   // Root octave
            (2, 6)    // 2nd/9th
        ]
        
        for (interval, _) in scaleDegrees.sorted(by: { $0.priority < $1.priority }) {
            let note = root.addingSemitones(interval)
            // Find this note on strings 4-5 starting from bridgeStartFret
            for string in 4...5 {
                for fret in bridgeStartFret...min(maxFret, bridgeStartFret + 5) {
                    let fretNote = FretboardCalculator.noteAt(string: string, fret: fret)
                    if fretNote == note {
                        let key = "\(string),\(fret)"
                        if !foundPositions.contains(key) && positions.count < 6 {
                            positions.append(FretboardPosition(
                                string: string,
                                fret: fret,
                                note: note,
                                isRoot: interval == 0
                            ))
                            foundPositions.insert(key)
                            break
                        }
                    }
                }
                if positions.count >= 6 { break }
            }
            if positions.count >= 6 { break }
        }
        
        if positions.count == 6 {
            let frets = positions.map { $0.fret }
            let fretRange = (frets.min() ?? bridgeStartFret)...(frets.max() ?? maxFret)
            let stringRange = 4...5
            
            return Block(
                type: .bridgeBlock,
                name: "BRIDGE",
                description: "The BRIDGE block is a 6-note pattern (X-XX) containing connecting notes like 4th, 5th, 6th, 7th, root octave, and 2nd on the middle strings.",
                fretRange: fretRange,
                stringRange: stringRange,
                positions: positions
            )
        }
        
        return nil
    }
    
    /// Find TRIPLE block that follows a BRIDGE block
    private static func findTripleBlockFollowing(bridgeBlock: Block, key: Key, maxFret: Int) -> Block? {
        let root = key.rootNote
        let third = root.addingSemitones(4)  // Major 3rd
        let fifth = root.addingSemitones(7)  // Perfect 5th
        
        // TRIPLE block follows BRIDGE block
        // Find the highest fret in the BRIDGE block to determine where TRIPLE starts
        let bridgeMaxFret = bridgeBlock.positions.map { $0.fret }.max() ?? 0
        let tripleStartFret = bridgeMaxFret + 1
        
        var positions: [FretboardPosition] = []
        var seenPositions: Set<String> = []
        var triadCount = 0
        
        // TRIPLE block pattern: X-X-X (three 1-3-5 triads = 9 notes total)
        // Try different string groups starting from tripleStartFret
        for startString in 1...4 {
            if triadCount >= 3 { break }
            
            let string1 = startString
            let string2 = startString + 1
            let string3 = startString + 2
            
            // Find root positions on string1 starting from tripleStartFret
            for fret1 in tripleStartFret...maxFret {
                if triadCount >= 3 { break }
                
                let note1 = FretboardCalculator.noteAt(string: string1, fret: fret1)
                if note1 == root {
                    // Look for 3rd on string2 and 5th on string3
                    for fret2 in max(tripleStartFret, fret1 - 2)...min(maxFret, fret1 + 3) {
                        let note2 = FretboardCalculator.noteAt(string: string2, fret: fret2)
                        if note2 == third {
                            for fret3 in max(tripleStartFret, fret2 - 2)...min(maxFret, fret2 + 3) {
                                let note3 = FretboardCalculator.noteAt(string: string3, fret: fret3)
                                if note3 == fifth {
                                    // Found a triple block triad!
                                    let pos1Key = "\(string1),\(fret1)"
                                    let pos2Key = "\(string2),\(fret2)"
                                    let pos3Key = "\(string3),\(fret3)"
                                    
                                    if !seenPositions.contains(pos1Key) {
                                        positions.append(FretboardPosition(
                                            string: string1,
                                            fret: fret1,
                                            note: root,
                                            isRoot: true
                                        ))
                                        seenPositions.insert(pos1Key)
                                    }
                                    if !seenPositions.contains(pos2Key) {
                                        positions.append(FretboardPosition(
                                            string: string2,
                                            fret: fret2,
                                            note: third,
                                            isRoot: false
                                        ))
                                        seenPositions.insert(pos2Key)
                                    }
                                    if !seenPositions.contains(pos3Key) {
                                        positions.append(FretboardPosition(
                                            string: string3,
                                            fret: fret3,
                                            note: fifth,
                                            isRoot: false
                                        ))
                                        seenPositions.insert(pos3Key)
                                    }
                                    
                                    triadCount += 1
                                    if positions.count >= 9 { break }
                                }
                            }
                        }
                        if positions.count >= 9 { break }
                    }
                }
                if positions.count >= 9 { break }
            }
        }
        
        if positions.count >= 9 {
            // Ensure exactly 9 notes
            positions = Array(positions.prefix(9))
            
            let frets = positions.map { $0.fret }
            let fretRange = (frets.min() ?? tripleStartFret)...(frets.max() ?? maxFret)
            let stringRange = 1...6
            
            return Block(
                type: .tripleBlock,
                name: "TRIPLE BLOCK",
                description: "The TRIPLE BLOCK is a 9-note pattern (X-X-X) showing three instances of the 1-3-5 triad (root, major 3rd, perfect 5th) on three consecutive strings.",
                fretRange: fretRange,
                stringRange: stringRange,
                positions: positions
            )
        }
        
        return nil
    }
}

