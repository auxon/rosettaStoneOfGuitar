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

    /// The spiral run: ascending 3-notes-per-string through the key, winding
    /// low E (6) → high E (1). After the high-E row, the helix wraps onto low E
    /// at the **same frets** (in C: F G A on high e → F G A on low E), then
    /// continues up the neck. High E and low E are the same string around the
    /// cylinder — that wrap is the spiral, not a jump to the next scale degree.
    ///
    /// The canonical shape is C major starting on open low-E (scale degree 2,
    /// the major third — “mi”). Every other key uses that same 3NPS phase, so
    /// the geometry is identical and only shifts by `root − C` frets. Starting
    /// at “lowest in-key fret” instead would desync the phase (e.g. G major
    /// beginning on open E / degree 5) and scramble HEAD/BRIDGE/TRIPLE.
    static func spiralRun(for key: Key, maxFret: Int) -> [FretboardPosition] {
        var run = spiralHelix(for: key, maxFret: maxFret)
        let scale = FretboardCalculator.notesInKey(key)
        var covered = Set(run.map(\.coordinateKey))
        for string in stride(from: Constants.numberOfStrings, through: 1, by: -1) {
            for fret in 0...maxFret {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                guard scale.contains(note) else { continue }
                let pos = FretboardPosition(
                    string: string,
                    fret: fret,
                    note: note,
                    isRoot: note == key.rootNote,
                    scaleDegree: FretboardCalculator.scaleDegree(of: note, in: key)
                )
                guard covered.insert(pos.coordinateKey).inserted else { continue }
                run.append(pos)
            }
        }
        return run
    }
    
    /// Helix-only walk used for HEAD/BRIDGE/TRIPLE tiling (no leftover fill).
    static func spiralHelix(for key: Key, maxFret: Int) -> [FretboardPosition] {
        let scale = FretboardCalculator.notesInKey(key)
        guard scale.count == 7 else { return [] }
        
        // Same scale role as open E in C (degree index 2). For key K this lands
        // on low E at fret (K.root − C), i.e. the transposed home position.
        var nextDegree = 2
        var run: [FretboardPosition] = []
        var overlapFloor: [Int: Int] = [:]
        var lastHighEChunk: [FretboardPosition] = []
        let maxPasses = max(1, maxFret / 2 + 4)
        
        passLoop: for pass in 0..<maxPasses {
            // Helix wrap: high E and low E are the same string around the
            // cylinder. After F G A on high e, the TRIPLE's third row continues
            // as F G A on low E at the same frets — not a jump to the next
            // scale degree (B) further up the neck.
            if pass > 0 {
                guard lastHighEChunk.count == 3 else { break passLoop }
                var wrap: [FretboardPosition] = []
                wrap.reserveCapacity(3)
                for pos in lastHighEChunk {
                    guard pos.fret <= maxFret else { break passLoop }
                    wrap.append(FretboardPosition(
                        string: Constants.numberOfStrings,
                        fret: pos.fret,
                        note: pos.note,
                        isRoot: pos.note == key.rootNote,
                        scaleDegree: pos.scaleDegree
                    ))
                }
                run.append(contentsOf: wrap)
            }
            
            // Pass 0 walks all 6 strings. Later passes start on A (5): the next
            // HEAD is B–C–D / E–F–G on A–D, tiling horizontally. Low E already
            // received the wrap row.
            let strings: [Int] = pass == 0
                ? Array(stride(from: Constants.numberOfStrings, through: 1, by: -1))
                : Array(stride(from: Constants.numberOfStrings - 1, through: 1, by: -1))
            
            var placedThisPass = 0
            for string in strings {
                // Pass 0: nutward 3NPS. Later: overlap the previous chunk's
                // 2nd note so the next in-key fret (D on A, G on D, …) is not skipped.
                var fretFloor = pass == 0 ? 0 : (overlapFloor[string] ?? 0)
                var chunk: [FretboardPosition] = []
                chunk.reserveCapacity(3)
                
                for _ in 0..<3 {
                    let note = scale[nextDegree % 7]
                    guard let fret = Self.fret(
                        for: note,
                        on: string,
                        minFret: fretFloor,
                        maxFret: maxFret
                    ) else {
                        break passLoop
                    }
                    chunk.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == key.rootNote,
                        scaleDegree: nextDegree % 7
                    ))
                    fretFloor = fret + 1
                    nextDegree += 1
                }
                
                run.append(contentsOf: chunk)
                placedThisPass += chunk.count
                if chunk.count >= 2 {
                    overlapFloor[string] = chunk[1].fret
                }
                if string == 1 {
                    lastHighEChunk = chunk
                }
            }
            if placedThisPass == 0 { break }
        }
        return run
    }
    
    /// Lowest fret of `note` on `string` that is ≥ `minFret` and ≤ `maxFret`.
    private static func fret(
        for note: Note,
        on string: Int,
        minFret: Int,
        maxFret: Int
    ) -> Int? {
        guard string >= 1, string <= FretboardCalculator.standardTuning.count else { return nil }
        let open = FretboardCalculator.standardTuning[string - 1]
        var fret = (note.semitonesFromC - open.semitonesFromC + 12) % 12
        while fret < minFret { fret += 12 }
        return fret <= maxFret ? fret : nil
    }

    /// Partition the 3NPS helix into HEAD → BRIDGE → TRIPLE.
    ///
    /// Each helix row is 3 notes on one string. Fret spacing picks the rule:
    /// HEAD XX-X `[0,1,3]`, BRIDGE X-XX `[0,2,3]`, TRIPLE X-X-X `[0,2,4]`.
    ///
    /// Blocks are only those shapes, walking strings down the neck (6→1):
    /// - HEAD:   two adjacent strings, or one XX-X row at the nut (partial).
    /// - BRIDGE: two adjacent strings.
    /// - TRIPLE: three adjacent strings. High e’s unison copy on low E is the
    ///   wrap (same notes/frets), not a 1→6 string step. After a wrap, the next
    ///   TRIPLE may *start* on low E (6→5→4): in C, G A B at 3-5-7, then
    ///   C D E / F G A on A–D. High e just before that wrap is the same unison.
    static func tiledBlocks(for key: Key, maxFret: Int) -> [Block] {
        let run = spiralHelix(for: key, maxFret: maxFret)
        let rows = spiralRows(from: run)
        
        var blocks: [Block] = []
        var sequenceIndex = 0
        var i = 0
        
        func emit(_ type: BlockType, from used: [SpiralRow]) {
            let positions = used.flatMap(\.positions)
            guard !positions.isEmpty else { return }
            blocks.append(makeBlock(
                type: type,
                name: RSOGConceptInfo.blockTitle(type),
                description: tiledBlockDescription(type, notes: positions.count),
                positions: positions,
                anchorFret: positions.map(\.fret).min() ?? 0,
                sequenceIndex: sequenceIndex,
                runStart: used.map(\.runStart).min() ?? 0,
                runEnd: used.map(\.runEnd).max() ?? 0
            ))
            sequenceIndex += 1
        }
        
        func descending(_ strings: [Int]) -> Bool {
            zip(strings, strings.dropFirst()).allSatisfy { $0 - 1 == $1 }
        }
        
        func isUnisonWrap(_ a: SpiralRow, _ b: SpiralRow) -> Bool {
            a.string == 1 && b.isWrap && b.string == Constants.numberOfStrings
                && zip(a.positions, b.positions).allSatisfy { $0.fret == $1.fret && $0.note == $1.note }
        }
        
        /// Three XXX rows on n, n-1, n-2. Wrap-started 6→5→4 also consumes the
        /// high-e unison sitting immediately before the wrap.
        func takeTriple(at index: Int) -> (used: [SpiralRow], consumed: Int)? {
            func trio(at start: Int) -> [SpiralRow]? {
                guard start + 2 < rows.count else { return nil }
                let group = Array(rows[start..<(start + 3)])
                guard group.allSatisfy({ $0.rule == .tripleBlock }),
                      descending(group.map(\.string)) else { return nil }
                return group
            }
            
            let wrapStart: Int?
            if rows[index].isWrap {
                wrapStart = index
            } else if index + 1 < rows.count, isUnisonWrap(rows[index], rows[index + 1]) {
                wrapStart = index + 1
            } else {
                wrapStart = nil
            }
            
            if let wrapStart, let group = trio(at: wrapStart) {
                if wrapStart > index {
                    return ([rows[index]] + group, 4)
                }
                return (group, 3)
            }
            
            guard let group = trio(at: index) else { return nil }
            if group[2].string == 1,
               index + 3 < rows.count,
               rows[index + 3].isWrap {
                return (group + [rows[index + 3]], 4)
            }
            return (group, 3)
        }
        
        func takePair(at index: Int, rule: BlockType) -> [SpiralRow]? {
            guard index + 1 < rows.count,
                  rows[index].rule == rule,
                  rows[index + 1].rule == rule,
                  descending([rows[index].string, rows[index + 1].string]) else {
                return nil
            }
            return Array(rows[index..<(index + 2)])
        }
        
        while i < rows.count {
            if let taken = takeTriple(at: i) {
                emit(.tripleBlock, from: taken.used)
                i += taken.consumed
                continue
            }
            if let pair = takePair(at: i, rule: .headBlock) {
                emit(.headBlock, from: pair)
                i += 2
                continue
            }
            if let pair = takePair(at: i, rule: .bridgeBlock) {
                emit(.bridgeBlock, from: pair)
                i += 2
                continue
            }
            if rows[i].rule == .headBlock, !rows[i].isWrap {
                emit(.headBlock, from: [rows[i]])
            }
            i += 1
        }
        
        return blocks
    }
    
    private struct SpiralRow {
        let runStart: Int
        let runEnd: Int
        let string: Int
        let positions: [FretboardPosition]
        let isWrap: Bool
        
        var rule: BlockType? {
            let frets = positions.map(\.fret)
            if RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets) { return .headBlock }
            if RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.bridgeOffsets) { return .bridgeBlock }
            if RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.tripleOffsets) { return .tripleBlock }
            return nil
        }
    }
    
    /// 3-note helix rows, marking unison e→E copies as wraps (not their own block row).
    private static func spiralRows(from run: [FretboardPosition]) -> [SpiralRow] {
        var rows: [SpiralRow] = []
        var index = 0
        while index + 2 < run.count {
            let slice = Array(run[index..<(index + 3)])
            guard slice.allSatisfy({ $0.string == slice[0].string }) else {
                index += 1
                continue
            }
            let isWrap: Bool
            if let prev = rows.last, !prev.isWrap, prev.string == 1, slice[0].string == Constants.numberOfStrings {
                isWrap = zip(prev.positions, slice).allSatisfy { $0.fret == $1.fret && $0.note == $1.note }
            } else {
                isWrap = false
            }
            rows.append(SpiralRow(
                runStart: index,
                runEnd: index + 3,
                string: slice[0].string,
                positions: slice,
                isWrap: isWrap
            ))
            index += 3
        }
        return rows
    }
    
    /// The HEAD/BRIDGE/TRIPLE cycle that contains `runIndex` (scrubber-synced).
    static func visibleTiledBlocks(for key: Key, maxFret: Int, atRunIndex runIndex: Int) -> [Block] {
        cycleContaining(runIndex: runIndex, in: tiledBlocks(for: key, maxFret: maxFret))
    }
    
    static func cycleContaining(runIndex: Int, in blocks: [Block]) -> [Block] {
        guard !blocks.isEmpty else { return [] }
        let match = blocks.last(where: { $0.coversRunIndex(runIndex) }) ?? blocks[0]
        let cycleStart = (match.sequenceIndex / 3) * 3
        return blocks.filter { $0.sequenceIndex >= cycleStart && $0.sequenceIndex < cycleStart + 3 }
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
            return "\(label) TRIPLE block — 3 notes per string across G, B, and high E. The third row wraps onto low E as the same notes (the helix), then the B-string row shifts one fret at the G–B crossing."
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
        sequenceIndex: Int = 0,
        runStart: Int = 0,
        runEnd: Int = 0
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
            sequenceIndex: sequenceIndex,
            runStart: runStart,
            runEnd: runEnd
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
