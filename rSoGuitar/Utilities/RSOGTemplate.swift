//
//  RSOGTemplate.swift
//  rSoGuitar
//
//  Canonical Rosetta Stone of Guitar (rSoG) block templates.
//  The fretboard is one repeating diatonic pattern subdivided into
//  HEAD (XX-X), BRIDGE (X-XX), and TRIPLE (X-X-X / stacked triads).
//

import Foundation

// MARK: - Spacing Patterns

/// Relative fret offsets that define HEAD / BRIDGE spacing on a string.
enum RSOGSpacingPattern {
    /// XX-X — two adjacent frets, gap, then one fret.
    static let headOffsets = [0, 1, 3]
    /// X-XX — one fret, gap, then two adjacent frets.
    static let bridgeOffsets = [0, 2, 3]
    
    static func offsets(for type: BlockType) -> [Int]? {
        switch type {
        case .headBlock: return headOffsets
        case .bridgeBlock: return bridgeOffsets
        case .tripleBlock: return nil
        }
    }
    
    static var headSpan: Int { headOffsets.max()! - headOffsets.min()! }
    static var bridgeSpan: Int { bridgeOffsets.max()! - bridgeOffsets.min()! }
}

// MARK: - Note Slot / Block Template

/// A single note slot in a block template, relative to the block anchor.
struct RSOGNoteSlot: Equatable {
    /// String number offset from the template's base string (0-based).
    let stringOffset: Int
    /// Fret offset from the block anchor fret.
    let fretOffset: Int
}

/// Canonical block shape: absolute string range + relative fret slots.
struct RSOGBlockTemplate: Equatable {
    let type: BlockType
    /// Preferred open-position string pair / window (1-based string numbers).
    let primaryStrings: [Int]
    let slots: [RSOGNoteSlot]
    
    var noteCount: Int { slots.count }
    
    /// HEAD: XX-X on the top string pair (high E + B), 3 notes × 2 strings = 6.
    static let head = RSOGBlockTemplate(
        type: .headBlock,
        primaryStrings: [1, 2],
        slots: RSOGSpacingPattern.headOffsets.flatMap { fret in
            [RSOGNoteSlot(stringOffset: 0, fretOffset: fret),
             RSOGNoteSlot(stringOffset: 1, fretOffset: fret)]
        }
    )
    
    /// BRIDGE: X-XX on the middle string pair (D + A), 3 notes × 2 strings = 6.
    static let bridge = RSOGBlockTemplate(
        type: .bridgeBlock,
        primaryStrings: [4, 5],
        slots: RSOGSpacingPattern.bridgeOffsets.flatMap { fret in
            [RSOGNoteSlot(stringOffset: 0, fretOffset: fret),
             RSOGNoteSlot(stringOffset: 1, fretOffset: fret)]
        }
    )
    
    static func template(for type: BlockType) -> RSOGBlockTemplate? {
        switch type {
        case .headBlock: return .head
        case .bridgeBlock: return .bridge
        case .tripleBlock: return nil
        }
    }
}

// MARK: - String Pairs

enum RSOGStringPairs {
    /// Perfect-4th adjacent pairs — same fret numbers share diatonic alignment
    /// when both pitches fall in-key (interval matches open-string P4).
    static let perfectFourthPairs: [(Int, Int)] = [
        (1, 2), // e–B  (primary HEAD region)
        (3, 4), // G–D
        (4, 5), // D–A  (primary BRIDGE region)
        (5, 6)  // A–E
    ]
    
    static var primaryHeadPair: (Int, Int) { (1, 2) }
    static var primaryBridgePair: (Int, Int) { (4, 5) }
}

// MARK: - Diatonic Triad Degrees

struct RSOGScaleDegree: Equatable {
    let degreeIndex: Int          // 0 = I … 6 = vii
    let intervalFromRoot: Int     // semitones
    let quality: ChordQuality
    let romanNumeral: String
    
    /// Major-key diatonic triad degrees.
    static let majorKeyTriads: [RSOGScaleDegree] = [
        RSOGScaleDegree(degreeIndex: 0, intervalFromRoot: 0,  quality: .major,      romanNumeral: "I"),
        RSOGScaleDegree(degreeIndex: 1, intervalFromRoot: 2,  quality: .minor,      romanNumeral: "ii"),
        RSOGScaleDegree(degreeIndex: 2, intervalFromRoot: 4,  quality: .minor,      romanNumeral: "iii"),
        RSOGScaleDegree(degreeIndex: 3, intervalFromRoot: 5,  quality: .major,      romanNumeral: "IV"),
        RSOGScaleDegree(degreeIndex: 4, intervalFromRoot: 7,  quality: .major,      romanNumeral: "V"),
        RSOGScaleDegree(degreeIndex: 5, intervalFromRoot: 9,  quality: .minor,      romanNumeral: "vi"),
        RSOGScaleDegree(degreeIndex: 6, intervalFromRoot: 11, quality: .diminished, romanNumeral: "vii°")
    ]
    
    func chordTones(in key: Key) -> (root: Note, third: Note, fifth: Note) {
        let root = key.rootNote.addingSemitones(intervalFromRoot)
        let thirdInterval: Int
        let fifthInterval: Int
        switch quality {
        case .minor, .diminished:
            thirdInterval = 3
        default:
            thirdInterval = 4
        }
        switch quality {
        case .diminished:
            fifthInterval = 6
        default:
            fifthInterval = 7
        }
        return (
            root,
            root.addingSemitones(thirdInterval),
            root.addingSemitones(fifthInterval)
        )
    }
}

struct RSOGTriadVoicing: Equatable {
    let degree: RSOGScaleDegree
    let positions: [FretboardPosition] // exactly 3 — one per string
}

// MARK: - Template Engine

enum RSOGTemplate {
    
    // MARK: Spacing Placement
    
    /// Returns anchor frets where `offsets` lands entirely on in-key notes for both strings.
    static func spacingAnchors(
        offsets: [Int],
        stringPair: (Int, Int),
        key: Key,
        maxFret: Int
    ) -> [Int] {
        let keyNotes = Set(FretboardCalculator.notesInKey(key))
        let span = (offsets.max() ?? 0)
        var anchors: [Int] = []
        
        for anchor in 0...(maxFret) {
            guard anchor + span <= maxFret else { break }
            
            let allInKey = offsets.allSatisfy { offset in
                let fret = anchor + offset
                let noteA = FretboardCalculator.noteAt(string: stringPair.0, fret: fret)
                let noteB = FretboardCalculator.noteAt(string: stringPair.1, fret: fret)
                return keyNotes.contains(noteA) && keyNotes.contains(noteB)
            }
            
            if allInKey {
                anchors.append(anchor)
            }
        }
        
        return anchors
    }
    
    /// Materialize fretboard positions for a HEAD or BRIDGE template at an anchor.
    static func positions(
        for template: RSOGBlockTemplate,
        baseString: Int,
        anchorFret: Int,
        key: Key
    ) -> [FretboardPosition]? {
        var result: [FretboardPosition] = []
        let keyNotes = Set(FretboardCalculator.notesInKey(key))
        
        for slot in template.slots {
            let string = baseString + slot.stringOffset
            let fret = anchorFret + slot.fretOffset
            guard string >= 1 && string <= Constants.numberOfStrings else { return nil }
            guard fret >= 0 else { return nil }
            
            let note = FretboardCalculator.noteAt(string: string, fret: fret)
            guard keyNotes.contains(note) else { return nil }
            
            result.append(FretboardPosition(
                string: string,
                fret: fret,
                note: note,
                isRoot: note == key.rootNote
            ))
        }
        
        return result
    }
    
    /// Validate that a set of frets on a string matches XX-X or X-XX exactly.
    static func matchesSpacing(_ frets: [Int], pattern: [Int]) -> Bool {
        let sorted = frets.sorted()
        guard let minFret = sorted.first, sorted.count == pattern.count else { return false }
        let normalized = sorted.map { $0 - minFret }
        return normalized == pattern
    }
    
    // MARK: Block Discovery
    
    /// All valid HEAD (XX-X) placements across P4 string pairs.
    static func allHeadPlacements(for key: Key, maxFret: Int) -> [(pair: (Int, Int), anchor: Int, positions: [FretboardPosition])] {
        placements(for: .head, key: key, maxFret: maxFret)
    }
    
    /// All valid BRIDGE (X-XX) placements across P4 string pairs.
    static func allBridgePlacements(for key: Key, maxFret: Int) -> [(pair: (Int, Int), anchor: Int, positions: [FretboardPosition])] {
        placements(for: .bridge, key: key, maxFret: maxFret)
    }
    
    private static func placements(
        for template: RSOGBlockTemplate,
        key: Key,
        maxFret: Int
    ) -> [(pair: (Int, Int), anchor: Int, positions: [FretboardPosition])] {
        guard let offsets = RSOGSpacingPattern.offsets(for: template.type) else { return [] }
        
        var results: [(pair: (Int, Int), anchor: Int, positions: [FretboardPosition])] = []
        
        for pair in RSOGStringPairs.perfectFourthPairs {
            let anchors = spacingAnchors(
                offsets: offsets,
                stringPair: pair,
                key: key,
                maxFret: maxFret
            )
            for anchor in anchors {
                if let positions = positions(
                    for: template,
                    baseString: pair.0,
                    anchorFret: anchor,
                    key: key
                ) {
                    results.append((pair, anchor, positions))
                }
            }
        }
        
        return results
    }
    
    /// Preferred open-position HEAD for a key (primary e–B pair, lowest anchor).
    static func primaryHead(for key: Key, maxFret: Int) -> (anchor: Int, positions: [FretboardPosition])? {
        let pair = RSOGStringPairs.primaryHeadPair
        let anchors = spacingAnchors(
            offsets: RSOGSpacingPattern.headOffsets,
            stringPair: pair,
            key: key,
            maxFret: maxFret
        )
        guard let anchor = anchors.first,
              let positions = positions(for: .head, baseString: pair.0, anchorFret: anchor, key: key)
        else { return nil }
        return (anchor, positions)
    }
    
    /// Preferred open-position BRIDGE for a key (primary D–A pair, lowest anchor).
    static func primaryBridge(for key: Key, maxFret: Int) -> (anchor: Int, positions: [FretboardPosition])? {
        let pair = RSOGStringPairs.primaryBridgePair
        let anchors = spacingAnchors(
            offsets: RSOGSpacingPattern.bridgeOffsets,
            stringPair: pair,
            key: key,
            maxFret: maxFret
        )
        guard let anchor = anchors.first,
              let positions = positions(for: .bridge, baseString: pair.0, anchorFret: anchor, key: key)
        else { return nil }
        return (anchor, positions)
    }
    
    // MARK: TRIPLE (stacked triads)
    
    /// Find a TRIPLE block: three diatonic triad voicings (9 notes) on three consecutive strings.
    /// Prefers I–iii–V, then I–IV–V, then any three consecutive degrees.
    static func tripleBlock(
        atStartString startString: Int,
        startFret: Int,
        key: Key,
        maxFret: Int,
        windowSize: Int = 5
    ) -> (voicings: [RSOGTriadVoicing], positions: [FretboardPosition])? {
        let strings = [startString, startString + 1, startString + 2]
        guard strings.allSatisfy({ $0 >= 1 && $0 <= Constants.numberOfStrings }) else { return nil }
        
        let windowEnd = min(maxFret, startFret + windowSize)
        guard windowEnd >= startFret else { return nil }
        
        // Preferred degree sets for a TRIPLE landmark.
        let preferredSets: [[Int]] = [
            [0, 2, 4], // I, iii, V
            [0, 3, 4], // I, IV, V
            [0, 1, 2], // I, ii, iii
            [2, 4, 5], // iii, V, vi
            [3, 4, 5], // IV, V, vi
            [4, 5, 6], // V, vi, vii°
            [1, 2, 3]  // ii, iii, IV
        ]
        
        for degreeSet in preferredSets {
            var voicings: [RSOGTriadVoicing] = []
            
            for degreeIndex in degreeSet {
                let degree = RSOGScaleDegree.majorKeyTriads[degreeIndex]
                if let voicing = findTriadVoicing(
                    degree: degree,
                    strings: strings,
                    fretRange: startFret...windowEnd,
                    key: key
                ) {
                    voicings.append(voicing)
                }
            }
            
            guard voicings.count == 3 else { continue }
            
            // Deduplicate shared fret positions across stacked triads.
            var seen: Set<String> = []
            var uniquePositions: [FretboardPosition] = []
            for pos in voicings.flatMap(\.positions) {
                let keyStr = "\(pos.string),\(pos.fret)"
                if seen.insert(keyStr).inserted {
                    uniquePositions.append(pos)
                }
            }
            
            // First preferred set that forms a complete triple wins
            // (I–iii–V, then I–IV–V, then neighbors). Shared tones are expected.
            if uniquePositions.count >= 5 {
                return (voicings, uniquePositions)
            }
        }
        
        return nil
    }
    
    /// Scan the fretboard for TRIPLE landmarks.
    static func allTriplePlacements(
        for key: Key,
        maxFret: Int
    ) -> [(startString: Int, startFret: Int, voicings: [RSOGTriadVoicing], positions: [FretboardPosition])] {
        var results: [(Int, Int, [RSOGTriadVoicing], [FretboardPosition])] = []
        var seen: Set<String> = []
        
        for startString in 1...(Constants.numberOfStrings - 2) {
            for startFret in 0...maxFret {
                guard let found = tripleBlock(
                    atStartString: startString,
                    startFret: startFret,
                    key: key,
                    maxFret: maxFret
                ) else { continue }
                
                let keyStr = found.positions
                    .map { "\($0.string),\($0.fret)" }
                    .sorted()
                    .joined(separator: "|")
                
                if seen.insert(keyStr).inserted {
                    results.append((startString, startFret, found.voicings, found.positions))
                }
            }
        }
        
        return results
    }
    
    /// Preferred open-position TRIPLE (lowest fret, favoring strings 3–5 then 2–4).
    static func primaryTriple(
        for key: Key,
        maxFret: Int
    ) -> (startString: Int, startFret: Int, voicings: [RSOGTriadVoicing], positions: [FretboardPosition])? {
        let preferredStringStarts = [3, 2, 4, 1]
        for startString in preferredStringStarts {
            for startFret in 0...min(5, maxFret) {
                if let found = tripleBlock(
                    atStartString: startString,
                    startFret: startFret,
                    key: key,
                    maxFret: maxFret
                ) {
                    return (startString, startFret, found.voicings, found.positions)
                }
            }
        }
        return allTriplePlacements(for: key, maxFret: maxFret).first.map {
            ($0.startString, $0.startFret, $0.voicings, $0.positions)
        }
    }
    
    /// Find one close-position triad voicing: one chord tone on each of three strings.
    private static func findTriadVoicing(
        degree: RSOGScaleDegree,
        strings: [Int],
        fretRange: ClosedRange<Int>,
        key: Key
    ) -> RSOGTriadVoicing? {
        let tones = degree.chordTones(in: key)
        let chordToneSet: Set<Note> = [tones.root, tones.third, tones.fifth]
        
        // Collect candidate frets per string that are chord tones in range.
        let candidates: [[FretboardPosition]] = strings.map { string in
            fretRange.compactMap { fret in
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                guard chordToneSet.contains(note) else { return nil }
                return FretboardPosition(
                    string: string,
                    fret: fret,
                    note: note,
                    isRoot: note == tones.root
                )
            }
        }
        
        guard candidates.allSatisfy({ !$0.isEmpty }) else { return nil }
        
        // Prefer the most compact voicing that covers root, 3rd, and 5th.
        var best: [FretboardPosition]?
        var bestSpan = Int.max
        
        for a in candidates[0] {
            for b in candidates[1] {
                for c in candidates[2] {
                    let combo = [a, b, c]
                    let notes = Set(combo.map(\.note))
                    guard notes.isSuperset(of: chordToneSet) else { continue }
                    let frets = combo.map(\.fret)
                    let span = (frets.max() ?? 0) - (frets.min() ?? 0)
                    if span < bestSpan {
                        bestSpan = span
                        best = combo
                    }
                }
            }
        }
        
        if let best {
            return RSOGTriadVoicing(degree: degree, positions: best)
        }
        
        return nil
    }
    
    // MARK: Sequence Order
    
    /// Canonical block type order: HEAD → BRIDGE → TRIPLE → (repeat).
    static let sequenceOrder: [BlockType] = [.headBlock, .bridgeBlock, .tripleBlock]
    
    /// Rotate sequence order so it begins with `start`.
    static func sequencedTypes(startingFrom start: BlockType) -> [BlockType] {
        guard let idx = sequenceOrder.firstIndex(of: start) else { return sequenceOrder }
        return Array(sequenceOrder[idx...]) + Array(sequenceOrder[..<idx])
    }
}
