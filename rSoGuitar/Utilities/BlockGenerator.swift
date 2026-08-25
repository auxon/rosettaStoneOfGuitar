//
//  BlockGenerator.swift
//  rSoGuitar
//
//  Generates block overlays for the fretboard based on rSoGuitar methodology.
//  The entire fretboard is one repeating diatonic pattern containing
//  HEAD (XX-X), BRIDGE (X-XX), and TRIPLE (X-X-X) blocks
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
    
    // MARK: - Spiral Run & Block Tiling

    /// The spiral run: the diatonic walk used by Spiral Mapping and block
    /// tiling alike. Takes consecutive groups of 3 in-key notes per string,
    /// winding low E (6) → high E (1), wrapping around to the next group on
    /// the low E string each pass — 3 notes per string, no note unmapped.
    static func spiralRun(for key: Key, maxFret: Int) -> [FretboardPosition] {
        let keyNotes = Set(FretboardCalculator.notesInKey(key))
        var perString: [(notes: [FretboardPosition], count: Int)] = []

        for string in stride(from: Constants.numberOfStrings, through: 1, by: -1) {
            var notes: [FretboardPosition] = []
            for fret in 0...maxFret {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                guard keyNotes.contains(note) else { continue }
                notes.append(FretboardPosition(
                    string: string,
                    fret: fret,
                    note: note,
                    isRoot: note == key.rootNote,
                    scaleDegree: FretboardCalculator.scaleDegree(of: note, in: key)
                ))
            }
            perString.append((notes, notes.count))
        }

        var run: [FretboardPosition] = []
        var pass = 0
        while true {
            var addedAny = false
            for entry in perString {
                let start = pass * 3
                guard start < entry.count else { continue }
                let slice = entry.notes[start..<min(start + 3, entry.count)]
                run.append(contentsOf: slice)
                addedAny = addedAny || !slice.isEmpty
            }
            if !addedAny { break }
            pass += 1
        }
        return run
    }

    /// Tile the spiral run with the canonical block cycle
    /// [HEAD · 6 notes][BRIDGE · 6 notes][TRIPLE · 9 notes], anchored per key.
    ///
    /// Anchor rule: the cycle begins 3 run-notes before the low-E string's
    /// tonic fret (for C, fret 0). The first HEAD therefore spans the virtual
    /// string 7 (perfect 4th below low E) plus the low E itself — only its
    /// low-E half is visible, so home position shows HALF a HEAD block.
    /// The first TRIPLE spans strings G–B–e; its B-string row sits one fret
    /// off the P4 lattice — the G–B major-third shift — which emerges
    /// automatically because every note is a real fretboard position.
    /// Blocks cut off at the fretboard edges render as partial blocks.
    static func tiledBlocks(for key: Key, maxFret: Int) -> [Block] {
        let run = spiralRun(for: key, maxFret: maxFret)
        let delta = ((key.rootNote.semitonesFromC % 12) + 12) % 12

        guard let anchor = run.firstIndex(where: {
            $0.string == Constants.numberOfStrings && $0.fret == delta
        }) else { return [] }

        // Virtual prepend — degrees ti–do–re on virtual string 7 (open B),
        // completing the first HEAD below the physical low E string.
        let prepend: [FretboardPosition] = [11, 0, 2].map { interval in
            let letter = key.rootNote.addingSemitones(interval)
            let fret = ((letter.semitonesFromC - Note.B.semitonesFromC) % 12 + 12) % 12
            return FretboardPosition(
                string: 7,
                fret: fret,
                note: letter,
                isRoot: letter == key.rootNote
            )
        }

        func position(at index: Int) -> FretboardPosition? {
            if index < 0 {
                let idx = index + prepend.count
                return idx >= 0 ? prepend[idx] : nil
            }
            return index < run.count ? run[index] : nil
        }

        let cycle: [(type: BlockType, size: Int)] = [
            (.headBlock, 6), (.bridgeBlock, 6), (.tripleBlock, 9)
        ]

        var blocks: [Block] = []
        var sequenceIndex = 0
        var sliceStart = anchor - 3

        while sliceStart < run.count {
            for (type, size) in cycle {
                var positions: [FretboardPosition] = []
                var seen: Set<String> = []
                for i in sliceStart..<(sliceStart + size) {
                    guard let pos = position(at: i),
                          (1...Constants.numberOfStrings).contains(pos.string),
                          seen.insert(pos.coordinateKey).inserted else { continue }
                    positions.append(pos)
                }

                if !positions.isEmpty {
                    blocks.append(makeBlock(
                        type: type,
                        name: RSOGConceptInfo.blockTitle(type),
                        description: tiledBlockDescription(type, notes: positions.count),
                        positions: positions,
                        anchorFret: positions.map(\.fret).min() ?? 0,
                        sequenceIndex: sequenceIndex
                    ))
                    sequenceIndex += 1
                }
                sliceStart += size
            }
        }

        return blocks
    }

    private static func tiledBlockDescription(_ type: BlockType, notes: Int) -> String {
        let fullCount: Int
        switch type {
        case .headBlock, .bridgeBlock: fullCount = 6
        case .tripleBlock: fullCount = 9
        }
        let label = notes < fullCount ? "Partial" : "Full"
        switch type {
        case .headBlock:
            return "\(label) HEAD block — 3 notes per string on the low-E pair. In home position half of the block lives on the virtual string below the nut, so only the low-E row shows."
        case .bridgeBlock:
            return "\(label) BRIDGE block — 3 notes per string on the A and D strings, the transitional zone between HEAD and TRIPLE."
        case .tripleBlock:
            return "\(label) TRIPLE block — 3 notes per string across G, B, and high E. The B-string row shifts one fret at the G–B major-third crossing."
        }
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
    
    // MARK: - TRIPLE Blocks (X-X-X — every other half-step)
    
    private static func buildTripleBlocks(for key: Key, maxFret: Int) -> [Block] {
        let placements = RSOGTemplate.allTriplePlacements(for: key, maxFret: maxFret)
        
        let primary = RSOGStringTriples.primaryTriple
        let sorted = placements.sorted { lhs, rhs in
            let leftPrimary = lhs.startString == primary.0
            let rightPrimary = rhs.startString == primary.0
            if leftPrimary != rightPrimary { return leftPrimary && !rightPrimary }
            if lhs.anchor != rhs.anchor { return lhs.anchor < rhs.anchor }
            return lhs.startString < rhs.startString
        }
        
        return sorted.map { placement in
            makeBlock(
                type: .tripleBlock,
                name: "TRIPLE",
                description: "TRIPLE block: 9-note X-X-X pattern (every other half-step) on strings \(placement.startString)–\(placement.startString + 2).",
                positions: placement.positions,
                anchorFret: placement.anchor
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
        let placements = RSOGTemplate.allTriplePlacements(for: key, maxFret: maxFret)
        guard let nearest = placements.min(by: {
            abs($0.anchor - startPos.fret) + abs($0.startString - startPos.string)
            < abs($1.anchor - startPos.fret) + abs($1.startString - startPos.string)
        }) else { return nil }
        
        return makeBlock(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block: 9-note X-X-X pattern (every other half-step) on strings \(nearest.startString)–\(nearest.startString + 2).",
            positions: nearest.positions,
            anchorFret: nearest.anchor
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
    
    /// Primary TRIPLE block for the key (9-note X-X-X).
    static func tripleBlock(for key: Key, maxFret: Int = 15) -> Block {
        if let primary = RSOGTemplate.primaryTriple(for: key, maxFret: maxFret) {
            return makeBlock(
                type: .tripleBlock,
                name: "TRIPLE",
                description: "TRIPLE block: 9-note X-X-X pattern (every other half-step).",
                positions: primary.positions,
                anchorFret: primary.anchor
            )
        }
        return Block(
            type: .tripleBlock,
            name: "TRIPLE",
            description: "TRIPLE block not found for this key.",
            fretRange: 0...4,
            stringRange: 3...5,
            positions: [],
            anchorFret: 0
        )
    }
}
