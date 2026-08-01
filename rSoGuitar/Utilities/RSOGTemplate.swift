//
//  RSOGTemplate.swift
//  rSoGuitar
//
//  Canonical Rosetta Stone of Guitar (rSoG) block templates.
//  The fretboard is one repeating diatonic pattern subdivided into
//  HEAD (XX-X), BRIDGE (X-XX), and TRIPLE (X-X-X — every other fret).
//

import Foundation

// MARK: - Spacing Patterns

/// Relative fret offsets that define HEAD / BRIDGE / TRIPLE spacing on a string.
enum RSOGSpacingPattern {
    /// XX-X — two adjacent frets, gap, then one fret.
    static let headOffsets = [0, 1, 3]
    /// X-XX — one fret, gap, then two adjacent frets.
    static let bridgeOffsets = [0, 2, 3]
    /// X-X-X — every other half-step (whole-step spacing): note, skip, note, skip, note.
    static let tripleOffsets = [0, 2, 4]
    
    static func offsets(for type: BlockType) -> [Int]? {
        switch type {
        case .headBlock: return headOffsets
        case .bridgeBlock: return bridgeOffsets
        case .tripleBlock: return tripleOffsets
        }
    }
    
    static var headSpan: Int { headOffsets.max()! - headOffsets.min()! }
    static var bridgeSpan: Int { bridgeOffsets.max()! - bridgeOffsets.min()! }
    static var tripleSpan: Int { tripleOffsets.max()! - tripleOffsets.min()! }
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
    
    /// TRIPLE: X-X-X on three consecutive P4-aligned strings, 3 notes × 3 strings = 9.
    /// Always every-other-fret spacing — never a variable triad search.
    static let triple = RSOGBlockTemplate(
        type: .tripleBlock,
        primaryStrings: [3, 4, 5],
        slots: RSOGSpacingPattern.tripleOffsets.flatMap { fret in
            [RSOGNoteSlot(stringOffset: 0, fretOffset: fret),
             RSOGNoteSlot(stringOffset: 1, fretOffset: fret),
             RSOGNoteSlot(stringOffset: 2, fretOffset: fret)]
        }
    )
    
    static func template(for type: BlockType) -> RSOGBlockTemplate? {
        switch type {
        case .headBlock: return .head
        case .bridgeBlock: return .bridge
        case .tripleBlock: return .triple
        }
    }
}

// MARK: - String Pairs / Triples

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

enum RSOGStringTriples {
    /// Three consecutive strings in a continuous P4 chain (same fret columns stay aligned).
    /// Includes one-string overflows past the physical nut-side / bridge-side edges:
    /// string 0 = P4 above high E, string 7 = P4 below low E. Those host TRIPLEs whose
    /// visible footprint is 6 of 9 notes on the real fretboard.
    static let perfectFourthTriples: [(Int, Int, Int)] = [
        (0, 1, 2), // (virtual)–e–B  — overflows above the nut-side high strings
        (3, 4, 5), // G–D–A  (primary TRIPLE region)
        (4, 5, 6), // D–A–E
        (5, 6, 7)  // A–E–(virtual) — overflows below the low E
    ]
    
    static var primaryTriple: (Int, Int, Int) { (3, 4, 5) }
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
    
    /// rSoG familial nickname (Papa / Mama / yBro …) — primary teaching label.
    var familyName: String { Self.familyName(forDegreeIndex: degreeIndex) }
    
    /// Canonical family names used on rsoguitar.com / Pool’s materials.
    /// Mapped to modes: Papa=Ionian, yBro=Dorian, aBoy=Phrygian, Mama=Lydian,
    /// oBro=Mixolydian, oSis=Aeolian, ySis=Locrian.
    static func familyName(forDegreeIndex index: Int) -> String {
        switch index {
        case 0: return "Papa"
        case 1: return "yBro"
        case 2: return "aBoy"
        case 3: return "Mama"
        case 4: return "oBro"
        case 5: return "oSis"
        case 6: return "ySis"
        default: return "—"
        }
    }
    
    static let familyNameOrder: [String] = [
        "Papa", "yBro", "aBoy", "Mama", "oBro", "oSis", "ySis"
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
        spacingAnchors(offsets: offsets, strings: [stringPair.0, stringPair.1], key: key, maxFret: maxFret)
    }
    
    /// Returns anchor frets where `offsets` lands entirely on in-key notes for every string.
    static func spacingAnchors(
        offsets: [Int],
        strings: [Int],
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
                return strings.allSatisfy { string in
                    guard let note = noteOnString(string, fret: fret) else { return false }
                    return keyNotes.contains(note)
                }
            }
            
            if allInKey {
                anchors.append(anchor)
            }
        }
        
        return anchors
    }
    
    /// Open pitch for physical strings 1…6, plus P4 overflow strings 0 and 7.
    static func openNote(forString string: Int) -> Note? {
        switch string {
        case 1...Constants.numberOfStrings:
            return Constants.standardTuning[string - 1]
        case 0:
            return .A // perfect fourth above high E
        case 7:
            return .B // perfect fourth below low E
        default:
            return nil
        }
    }
    
    static func noteOnString(_ string: Int, fret: Int) -> Note? {
        guard let open = openNote(forString: string), fret >= 0 else { return nil }
        return open.addingSemitones(fret)
    }
    
    /// Materialize fretboard positions for a HEAD / BRIDGE / TRIPLE template at an anchor.
    /// TRIPLE may use overflow strings 0/7 for validation; only physical strings 1…6 are returned.
    static func positions(
        for template: RSOGBlockTemplate,
        baseString: Int,
        anchorFret: Int,
        key: Key
    ) -> [FretboardPosition]? {
        var result: [FretboardPosition] = []
        let keyNotes = Set(FretboardCalculator.notesInKey(key))
        let allowsOverflowStrings = template.type == .tripleBlock
        
        for slot in template.slots {
            let string = baseString + slot.stringOffset
            let fret = anchorFret + slot.fretOffset
            guard fret >= 0 else { return nil }
            
            if !allowsOverflowStrings {
                guard string >= 1 && string <= Constants.numberOfStrings else { return nil }
            }
            
            guard let note = noteOnString(string, fret: fret),
                  keyNotes.contains(note) else { return nil }
            
            // Keep only notes that sit on the real fretboard.
            if (1...Constants.numberOfStrings).contains(string) {
                result.append(FretboardPosition(
                    string: string,
                    fret: fret,
                    note: note,
                    isRoot: note == key.rootNote
                ))
            }
        }
        
        if template.type == .tripleBlock {
            // Full on-board TRIPLE = 9; one-string overflow = 6 visible notes.
            guard result.count == 9 || result.count == 6 else { return nil }
        } else {
            guard result.count == template.noteCount else { return nil }
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
        let span = offsets.max() ?? 0
        // Validate full XX-X / X-XX even when the last column sits past maxFret;
        // renderer clips frets beyond the visible board.
        let searchMaxFret = maxFret + span
        
        var results: [(pair: (Int, Int), anchor: Int, positions: [FretboardPosition])] = []
        
        for pair in RSOGStringPairs.perfectFourthPairs {
            let anchors = spacingAnchors(
                offsets: offsets,
                stringPair: pair,
                key: key,
                maxFret: searchMaxFret
            )
            for anchor in anchors {
                guard anchor <= maxFret else { continue }
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
    
    // MARK: TRIPLE (X-X-X — every other half-step)
    
    /// All valid TRIPLE placements: 9 in-key notes on frets [0,2,4] × 3 strings.
    /// Anchors that start on-board but extend past `maxFret` are kept so the visible
    /// portion can still be drawn (renderer clips frets beyond the board).
    static func allTriplePlacements(
        for key: Key,
        maxFret: Int
    ) -> [(startString: Int, anchor: Int, positions: [FretboardPosition])] {
        var results: [(startString: Int, anchor: Int, positions: [FretboardPosition])] = []
        // Validate the full X-X-X shape even when the last column sits past maxFret.
        let searchMaxFret = maxFret + RSOGSpacingPattern.tripleSpan
        
        for triple in RSOGStringTriples.perfectFourthTriples {
            let strings = [triple.0, triple.1, triple.2]
            let anchors = spacingAnchors(
                offsets: RSOGSpacingPattern.tripleOffsets,
                strings: strings,
                key: key,
                maxFret: searchMaxFret
            )
            for anchor in anchors {
                // Must begin on the visible board; trailing frets may be clipped.
                guard anchor <= maxFret else { continue }
                if let positions = positions(
                    for: .triple,
                    baseString: triple.0,
                    anchorFret: anchor,
                    key: key
                ) {
                    results.append((triple.0, anchor, positions))
                }
            }
        }
        
        return results
    }
    
    /// Preferred TRIPLE for a key: primary G–D–A strings, else D–A–E; lowest anchor.
    static func primaryTriple(
        for key: Key,
        maxFret: Int
    ) -> (startString: Int, anchor: Int, positions: [FretboardPosition])? {
        let primary = RSOGStringTriples.primaryTriple
        let ordered = [primary] + RSOGStringTriples.perfectFourthTriples.filter {
            !($0.0 == primary.0 && $0.1 == primary.1 && $0.2 == primary.2)
        }
        let searchMaxFret = maxFret + RSOGSpacingPattern.tripleSpan
        
        for triple in ordered {
            let anchors = spacingAnchors(
                offsets: RSOGSpacingPattern.tripleOffsets,
                strings: [triple.0, triple.1, triple.2],
                key: key,
                maxFret: searchMaxFret
            )
            if let anchor = anchors.first(where: { $0 <= maxFret }),
               let positions = positions(for: .triple, baseString: triple.0, anchorFret: anchor, key: key) {
                return (triple.0, anchor, positions)
            }
        }
        return nil
    }
    
    /// All compact triad voicings for a degree across the fretboard (Family of Chords).
    static func allTriadVoicings(
        for degree: RSOGScaleDegree,
        key: Key,
        maxFret: Int,
        windowSize: Int = 4
    ) -> [RSOGTriadVoicing] {
        var results: [RSOGTriadVoicing] = []
        var seen: Set<String> = []
        
        for startString in 1...(Constants.numberOfStrings - 2) {
            let strings = [startString, startString + 1, startString + 2]
            for startFret in 0...maxFret {
                let end = min(maxFret, startFret + windowSize)
                guard let voicing = findTriadVoicing(
                    degree: degree,
                    strings: strings,
                    fretRange: startFret...end,
                    key: key
                ) else { continue }
                
                let keyStr = voicing.positions
                    .map(\.coordinateKey)
                    .sorted()
                    .joined(separator: "|")
                if seen.insert(keyStr).inserted {
                    results.append(voicing)
                }
            }
        }
        
        return results.sorted {
            let a = $0.positions.map(\.fret).min() ?? 0
            let b = $1.positions.map(\.fret).min() ?? 0
            if a != b { return a < b }
            return ($0.positions.map(\.string).min() ?? 0) < ($1.positions.map(\.string).min() ?? 0)
        }
    }
    
    /// Find one close-position triad voicing: one chord tone on each of three strings.
    static func findTriadVoicing(
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
