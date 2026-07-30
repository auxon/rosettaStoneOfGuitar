//
//  BlockGenerator.swift
//  rSoGuitar
//
//  Generates block overlays for the fretboard based on rSoGuitar methodology.
//  The entire fretboard is one repeating diatonic pattern containing
//  HEAD (XX-X), BRIDGE (X-XX), and TRIPLE (stacked 1-3-5 triads) blocks
//  that tile in sequence: HEAD → BRIDGE → TRIPLE → HEAD → …
//

import Foundation

struct BlockGenerator {
    
    // MARK: - Main Entry Point
    
    /// Generate all blocks for a given key across the fretboard.
    /// Blocks are returned in canonical sequence order beginning at `startBlockType`.
    static func allBlocks(
        for key: Key,
        maxFret: Int = 24,
        startBlockType: BlockType = .headBlock
    ) -> [Block] {
        let headBlocks = buildHeadBlocks(for: key, maxFret: maxFret)
        let bridgeBlocks = buildBridgeBlocks(for: key, maxFret: maxFret)
        let tripleBlocks = buildTripleBlocks(for: key, maxFret: maxFret)
        
        // Group by type for sequenced interleaving.
        var byType: [BlockType: [Block]] = [
            .headBlock: headBlocks,
            .bridgeBlock: bridgeBlocks,
            .tripleBlock: tripleBlocks
        ]
        
        // Assign sequence indices following HEAD → BRIDGE → TRIPLE, rotated to startBlockType.
        let order = RSOGTemplate.sequencedTypes(startingFrom: startBlockType)
        var sequenced: [Block] = []
        var sequenceIndex = 0
        
        let maxCount = max(headBlocks.count, bridgeBlocks.count, tripleBlocks.count)
        for i in 0..<maxCount {
            for type in order {
                guard var pool = byType[type], i < pool.count else { continue }
                let block = pool[i]
                let indexed = Block(
                    id: block.id,
                    type: block.type,
                    name: block.name,
                    description: block.description,
                    fretRange: block.fretRange,
                    stringRange: block.stringRange,
                    positions: block.positions,
                    anchorFret: block.anchorFret,
                    sequenceIndex: sequenceIndex
                )
                sequenced.append(indexed)
                sequenceIndex += 1
            }
        }
        
        return sequenced
    }
    
    // MARK: - Diatonic Pattern Generation
    
    /// Generate the full diatonic pattern for a key.
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
    
    // MARK: - HEAD Blocks (XX-X)
    
    private static func buildHeadBlocks(for key: Key, maxFret: Int) -> [Block] {
        let placements = RSOGTemplate.allHeadPlacements(for: key, maxFret: maxFret)
        
        // Prefer primary pair first, then others by anchor fret.
        let primary = RSOGStringPairs.primaryHeadPair
        let sorted = placements.sorted { lhs, rhs in
            let leftPrimary = lhs.pair.0 == primary.0 && lhs.pair.1 == primary.1
            let rightPrimary = rhs.pair.0 == primary.0 && rhs.pair.1 == primary.1
            if leftPrimary != rightPrimary { return leftPrimary && !rightPrimary }
            if lhs.anchor != rhs.anchor { return lhs.anchor < rhs.anchor }
            return lhs.pair.0 < rhs.pair.0
        }
        
        return sorted.map { placement in
            makeBlock(
                type: .headBlock,
                name: "HEAD",
                description: "HEAD block: 6-note XX-X pattern on strings \(placement.pair.0)–\(placement.pair.1).",
                positions: placement.positions,
                anchorFret: placement.anchor
            )
        }
    }
    
    // MARK: - BRIDGE Blocks (X-XX)
    
    private static func buildBridgeBlocks(for key: Key, maxFret: Int) -> [Block] {
        let placements = RSOGTemplate.allBridgePlacements(for: key, maxFret: maxFret)
        
        let primary = RSOGStringPairs.primaryBridgePair
        let sorted = placements.sorted { lhs, rhs in
            let leftPrimary = lhs.pair.0 == primary.0 && lhs.pair.1 == primary.1
            let rightPrimary = rhs.pair.0 == primary.0 && rhs.pair.1 == primary.1
            if leftPrimary != rightPrimary { return leftPrimary && !rightPrimary }
            if lhs.anchor != rhs.anchor { return lhs.anchor < rhs.anchor }
            return lhs.pair.0 < rhs.pair.0
        }
        
        return sorted.map { placement in
            makeBlock(
                type: .bridgeBlock,
                name: "BRIDGE",
                description: "BRIDGE block: 6-note X-XX pattern on strings \(placement.pair.0)–\(placement.pair.1).",
                positions: placement.positions,
                anchorFret: placement.anchor
            )
        }
    }
    
    // MARK: - TRIPLE Blocks (X-X-X / three triads)
    
    private static func buildTripleBlocks(for key: Key, maxFret: Int) -> [Block] {
        let placements = RSOGTemplate.allTriplePlacements(for: key, maxFret: maxFret)
        
        let sorted = placements.sorted { lhs, rhs in
            if lhs.startFret != rhs.startFret { return lhs.startFret < rhs.startFret }
            return lhs.startString < rhs.startString
        }
        
        return sorted.map { placement in
            let numerals = placement.voicings.map(\.degree.romanNumeral).joined(separator: "–")
            return makeBlock(
                type: .tripleBlock,
                name: "TRIPLE",
                description: "TRIPLE block: stacked 1-3-5 triads (\(numerals)) on strings \(placement.startString)–\(placement.startString + 2).",
                positions: placement.positions,
                anchorFret: placement.startFret
            )
        }
    }
    
    // MARK: - Block Factory
    
    private static func makeBlock(
        type: BlockType,
        name: String,
        description: String,
        positions: [FretboardPosition],
        anchorFret: Int,
        sequenceIndex: Int = 0
    ) -> Block {
        let frets = positions.map(\.fret)
        let strings = positions.map(\.string)
        let minFret = frets.min() ?? anchorFret
        let maxFretFound = frets.max() ?? anchorFret
        let minString = strings.min() ?? 1
        let maxString = strings.max() ?? 1
        
        return Block(
            type: type,
            name: name,
            description: description,
            fretRange: minFret...maxFretFound,
            stringRange: minString...maxString,
            positions: positions,
            anchorFret: anchorFret,
            sequenceIndex: sequenceIndex
        )
    }
    
    // MARK: - Public Block Identification (for dragging)
    
    /// Identify HEAD block starting from a given position.
    static func identifyHeadBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        identifySpacingBlock(
            type: .headBlock,
            nearString: startPos.string,
            nearFret: startPos.fret,
            key: key,
            maxFret: maxFret
        )
    }
    
    /// Identify BRIDGE block starting from a given position.
    static func identifyBridgeBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        identifySpacingBlock(
            type: .bridgeBlock,
            nearString: startPos.string,
            nearFret: startPos.fret,
            key: key,
            maxFret: maxFret
        )
    }
    
    /// Identify TRIPLE block starting from a given position.
    static func identifyTripleBlock(
        startingFrom startPos: FretboardPosition,
        patternMap: [String: FretboardPosition],
        key: Key,
        maxFret: Int
    ) -> Block? {
        let startString = min(max(1, startPos.string), Constants.numberOfStrings - 2)
        if let found = RSOGTemplate.tripleBlock(
            atStartString: startString,
            startFret: startPos.fret,
            key: key,
            maxFret: maxFret
        ) {
            let numerals = found.voicings.map(\.degree.romanNumeral).joined(separator: "–")
            return makeBlock(
                type: .tripleBlock,
                name: "TRIPLE",
                description: "TRIPLE block: stacked 1-3-5 triads (\(numerals)).",
                positions: found.positions,
                anchorFret: startPos.fret
            )
        }
        
        // Fallback: nearest triple placement.
        let placements = RSOGTemplate.allTriplePlacements(for: key, maxFret: maxFret)
        guard let nearest = placements.min(by: {
            abs($0.startFret - startPos.fret) + abs($0.startString - startString)
            < abs($1.startFret - startPos.fret) + abs($1.startString - startString)
        }) else { return nil }
        
        let numerals = nearest.voicings.map(\.degree.romanNumeral).joined(separator: "–")
        return makeBlock(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block: stacked 1-3-5 triads (\(numerals)).",
            positions: nearest.positions,
            anchorFret: nearest.startFret
        )
    }
    
    private static func identifySpacingBlock(
        type: BlockType,
        nearString: Int,
        nearFret: Int,
        key: Key,
        maxFret: Int
    ) -> Block? {
        guard let template = RSOGBlockTemplate.template(for: type),
              let offsets = RSOGSpacingPattern.offsets(for: type) else { return nil }
        
        // Prefer a string pair that contains nearString.
        let candidatePairs = RSOGStringPairs.perfectFourthPairs.filter {
            $0.0 == nearString || $0.1 == nearString
        } + RSOGStringPairs.perfectFourthPairs
        
        var seen: Set<String> = []
        var uniquePairs: [(Int, Int)] = []
        for pair in candidatePairs {
            let key = "\(pair.0)-\(pair.1)"
            if seen.insert(key).inserted {
                uniquePairs.append(pair)
            }
        }
        
        for pair in uniquePairs {
            let anchors = RSOGTemplate.spacingAnchors(
                offsets: offsets,
                stringPair: pair,
                key: key,
                maxFret: maxFret
            )
            
            // Prefer anchor at/near the requested fret.
            let sortedAnchors = anchors.sorted { abs($0 - nearFret) < abs($1 - nearFret) }
            for anchor in sortedAnchors {
                if let positions = RSOGTemplate.positions(
                    for: template,
                    baseString: pair.0,
                    anchorFret: anchor,
                    key: key
                ) {
                    let name = type == .headBlock ? "HEAD" : "BRIDGE"
                    let patternName = type == .headBlock ? "XX-X" : "X-XX"
                    return makeBlock(
                        type: type,
                        name: name,
                        description: "\(name) block: 6-note \(patternName) pattern on strings \(pair.0)–\(pair.1).",
                        positions: positions,
                        anchorFret: anchor
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Infinite Bass Pattern
    
    /// Generate infinite bass pattern that extends beyond the 6 strings.
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
    
    // MARK: - Convenience: First Canonical Instance
    
    /// Primary HEAD block for the key (e–B XX-X at lowest valid anchor).
    static func headBlock(for key: Key, maxFret: Int = 12) -> Block {
        if let primary = RSOGTemplate.primaryHead(for: key, maxFret: maxFret) {
            return makeBlock(
                type: .headBlock,
                name: "HEAD",
                description: "HEAD block: 6-note XX-X pattern on strings 1–2.",
                positions: primary.positions,
                anchorFret: primary.anchor
            )
        }
        return Block(
            type: .headBlock,
            name: "HEAD",
            description: "HEAD block not found for this key.",
            fretRange: 0...3,
            stringRange: 1...2,
            positions: [],
            anchorFret: 0
        )
    }
    
    /// Primary BRIDGE block for the key (D–A X-XX at lowest valid anchor).
    static func bridgeBlock(for key: Key, maxFret: Int = 12) -> Block {
        if let primary = RSOGTemplate.primaryBridge(for: key, maxFret: maxFret) {
            return makeBlock(
                type: .bridgeBlock,
                name: "BRIDGE",
                description: "BRIDGE block: 6-note X-XX pattern on strings 4–5.",
                positions: primary.positions,
                anchorFret: primary.anchor
            )
        }
        return Block(
            type: .bridgeBlock,
            name: "BRIDGE",
            description: "BRIDGE block not found for this key.",
            fretRange: 0...3,
            stringRange: 4...5,
            positions: [],
            anchorFret: 0
        )
    }
    
    /// Primary TRIPLE block for the key (three stacked diatonic triads).
    static func tripleBlock(for key: Key, maxFret: Int = 12) -> Block {
        if let primary = RSOGTemplate.primaryTriple(for: key, maxFret: maxFret) {
            let numerals = primary.voicings.map(\.degree.romanNumeral).joined(separator: "–")
            return makeBlock(
                type: .tripleBlock,
                name: "TRIPLE",
                description: "TRIPLE block: stacked 1-3-5 triads (\(numerals)).",
                positions: primary.positions,
                anchorFret: primary.startFret
            )
        }
        return Block(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block not found for this key.",
            fretRange: 0...5,
            stringRange: 3...5,
            positions: [],
            anchorFret: 0
        )
    }
}
