//
//  PatternGenerator.swift
//  rSoGuitar
//
//  Generates rSoGuitar patterns: Spiral Mapping, Jumping,
//  Family of Chords, and Familial Hierarchy.
//

import Foundation
import Combine

struct PatternGenerator {
    
    // MARK: - Spiral Mapping
    
    /// Ordered vertical spiral across the fretboard with path connections.
    /// The neck is treated as a helix: 3 in-key notes per string, winding
    /// low E (6) → high E (1), then WRAPPING AROUND — the last high-E note
    /// connects to the continuing note on the low E string. Direction never
    /// reverses; that wrap is the spiral.
    ///
    /// This is the exact same run `BlockGenerator.tiledBlocks` partitions into
    /// HEAD/BRIDGE/TRIPLE, so step-through playback walks the blocks in order.
    static func spiralMappingPattern(
        for key: Key,
        maxFret: Int = Constants.defaultFretCount
    ) -> Pattern {
        let positions = BlockGenerator.spiralRun(for: key, maxFret: maxFret)

        var connections: [PatternConnection] = []
        for i in 1..<positions.count {
            connections.append(PatternConnection(from: positions[i - 1], to: positions[i], kind: .spiral))
        }

        return Pattern(
            name: "Spiral Mapping - \(key.rootNote.rawValue)",
            type: .spiralMapping,
            key: key,
            positions: positions,
            description: "Spiral mapping winds up the neck like a helix: 3 notes per string, low E → high E, wrapping around to the continuing note on the low E string — never retracing, leaving no in-key note unmapped.",
            connections: connections
        )
    }
    
    // MARK: - Jumping
    
    /// Generate jumping pattern - shows valid horizontal movements
    static func jumpingPattern(
        from startPosition: FretboardPosition,
        in key: Key,
        maxFret: Int = Constants.defaultFretCount
    ) -> Pattern {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        var connections: [PatternConnection] = []
        
        let enrichedStart = FretboardCalculator.enrich(startPosition, in: key)
        positions.append(enrichedStart)
        
        var jumpTargets: [FretboardPosition] = []
        for fret in 0...maxFret {
            if fret == startPosition.fret { continue }
            
            let note = FretboardCalculator.noteAt(string: startPosition.string, fret: fret)
            if keyNotes.contains(note) {
                let degree = FretboardCalculator.scaleDegree(of: note, in: key)
                let pos = FretboardPosition(
                    string: startPosition.string,
                    fret: fret,
                    note: note,
                    isRoot: note == key.rootNote,
                    scaleDegree: degree
                )
                jumpTargets.append(pos)
                connections.append(PatternConnection(from: enrichedStart, to: pos, kind: .jump))
            }
        }
        
        // Keep start first, then targets ordered by fret for a readable path.
        positions.append(contentsOf: jumpTargets.sorted { $0.fret < $1.fret })
        
        return Pattern(
            name: "Jumping Pattern - \(key.rootNote.rawValue)",
            type: .jumping,
            key: key,
            positions: positions,
            description: "Valid jump positions from the starting position, staying within the key.",
            connections: connections
        )
    }
    
    // MARK: - Family of Chords (horizontal triad voicings)
    
    /// Primary chord family (I–IV–V or i–iv–v) as triad voicings across the neck.
    static func familyOfChordsPattern(
        for key: Key,
        chordQuality: ChordQuality = .major,
        maxFret: Int = Constants.defaultFretCount
    ) -> Pattern {
        // Family degrees: major → I, IV, V; minor quality param → i, iv, v (degrees 0, 3, 4).
        let degreeIndices = [0, 3, 4]
        let degrees: [RSOGScaleDegree] = degreeIndices.map { index in
            var degree = RSOGScaleDegree.majorKeyTriads[index]
            if chordQuality == .minor {
                // Display as minor-family numerals while keeping diatonic tones of the major parent for now.
                let minorNumeral: String
                switch index {
                case 0: minorNumeral = "i"
                case 3: minorNumeral = "iv"
                case 4: minorNumeral = "v"
                default: minorNumeral = degree.romanNumeral
                }
                degree = RSOGScaleDegree(
                    degreeIndex: degree.degreeIndex,
                    intervalFromRoot: degree.intervalFromRoot,
                    quality: .minor,
                    romanNumeral: minorNumeral
                )
            }
            return degree
        }
        
        var chordGroups: [ChordGroup] = []
        var allPositions: [FretboardPosition] = []
        var allConnections: [PatternConnection] = []
        var seenCoords: Set<String> = []
        
        for degree in degrees {
            let group = buildChordGroup(
                degree: degree,
                key: key,
                maxFret: maxFret,
                connectionKind: .triad,
                maxVoicings: 8
            )
            chordGroups.append(group)
            allConnections.append(contentsOf: group.connections)
            
            for pos in group.positions {
                if seenCoords.insert(pos.coordinateKey).inserted {
                    allPositions.append(pos)
                }
            }
        }
        
        let qualityLabel = chordQuality == .minor ? "minor family" : "major"
        return Pattern(
            name: "Family of Chords - \(key.rootNote.rawValue) \(qualityLabel)",
            type: .familyOfChords,
            key: key,
            positions: allPositions,
            description: "Horizontal family of triad voicings — Papa, Mama, oBro (I, IV, V) — in the key of \(key.rootNote.rawValue). Each color is a chord; lines connect root → 3rd → 5th within a voicing.",
            connections: allConnections,
            chordGroups: chordGroups
        )
    }
    
    // MARK: - Familial Hierarchy (vertical chord stacks)
    
    /// All seven diatonic chords as vertical triad stacks with roman numerals.
    static func familialHierarchyPattern(
        for key: Key,
        maxFret: Int = Constants.defaultFretCount
    ) -> Pattern {
        var chordGroups: [ChordGroup] = []
        var allPositions: [FretboardPosition] = []
        var allConnections: [PatternConnection] = []
        var seenCoords: Set<String> = []
        
        for degree in RSOGScaleDegree.majorKeyTriads {
            // Prefer compact (vertical) voicings: smaller window emphasizes stacked shapes.
            let group = buildChordGroup(
                degree: degree,
                key: key,
                maxFret: maxFret,
                connectionKind: .hierarchy,
                maxVoicings: 4,
                windowSize: 3,
                preferVertical: true
            )
            chordGroups.append(group)
            allConnections.append(contentsOf: group.connections)
            
            for pos in group.positions {
                if seenCoords.insert(pos.coordinateKey).inserted {
                    allPositions.append(pos)
                }
            }
        }
        
        return Pattern(
            name: "Familial Hierarchy - \(key.rootNote.rawValue)",
            type: .familialHierarchy,
            key: key,
            positions: allPositions,
            description: "Vertical hierarchy of all diatonic chords in \(key.rootNote.rawValue) — Papa, yBro, aBoy, Mama, oBro, oSis, ySis (I–vii°). Each stack is a 1-3-5 triad labeled by family name.",
            connections: allConnections,
            chordGroups: chordGroups
        )
    }
    
    // MARK: - Chord Group Builder
    
    private static func buildChordGroup(
        degree: RSOGScaleDegree,
        key: Key,
        maxFret: Int,
        connectionKind: ConnectionKind,
        maxVoicings: Int,
        windowSize: Int = 4,
        preferVertical: Bool = false
    ) -> ChordGroup {
        let tones = degree.chordTones(in: key)
        let role = ChordRole.from(degreeIndex: degree.degreeIndex)
        
        var voicings = RSOGTemplate.allTriadVoicings(
            for: degree,
            key: key,
            maxFret: maxFret,
            windowSize: windowSize
        )
        
        if preferVertical {
            // Prefer voicings with smaller fret span (more "stacked" vertically).
            voicings.sort {
                span(of: $0) < span(of: $1)
            }
        }
        
        // Thin out overlapping voicings so the display stays readable.
        var selected: [RSOGTriadVoicing] = []
        var occupied: Set<String> = []
        for voicing in voicings {
            let keys = Set(voicing.positions.map(\.coordinateKey))
            // Allow mild overlap but skip near-duplicates.
            let overlap = keys.intersection(occupied).count
            if overlap >= 2 { continue }
            selected.append(voicing)
            occupied.formUnion(keys)
            if selected.count >= maxVoicings { break }
        }
        
        var positions: [FretboardPosition] = []
        var connections: [PatternConnection] = []
        var chordVoicings: [ChordVoicing] = []
        var seen: Set<String> = []
        
        for voicing in selected {
            let enriched = voicing.positions.map { pos -> FretboardPosition in
                annotatedTriadPosition(
                    pos,
                    tones: tones,
                    degree: degree,
                    role: role,
                    key: key
                )
            }
            
            chordVoicings.append(ChordVoicing(positions: enriched))
            
            // Connect in string order (vertical feel): root→3rd→5th by string descending.
            let ordered = enriched.sorted { $0.string > $1.string }
            for i in 0..<(ordered.count - 1) {
                connections.append(PatternConnection(
                    from: ordered[i],
                    to: ordered[i + 1],
                    kind: connectionKind
                ))
            }
            
            for pos in enriched {
                if seen.insert(pos.coordinateKey).inserted {
                    positions.append(pos)
                }
            }
        }
        
        return ChordGroup(
            romanNumeral: degree.romanNumeral,
            quality: degree.quality,
            root: tones.root,
            scaleDegree: degree.degreeIndex,
            chordRole: role,
            positions: positions,
            connections: connections,
            voicings: chordVoicings
        )
    }
    
    private static func span(of voicing: RSOGTriadVoicing) -> Int {
        let frets = voicing.positions.map(\.fret)
        return (frets.max() ?? 0) - (frets.min() ?? 0)
    }
    
    private static func annotatedTriadPosition(
        _ pos: FretboardPosition,
        tones: (root: Note, third: Note, fifth: Note),
        degree: RSOGScaleDegree,
        role: ChordRole?,
        key: Key
    ) -> FretboardPosition {
        FretboardPosition(
            string: pos.string,
            fret: pos.fret,
            note: pos.note,
            isRoot: pos.note == tones.root,
            scaleDegree: degree.degreeIndex,
            chordRole: role,
            isTriadRoot: pos.note == tones.root,
            isTriadThird: pos.note == tones.third,
            isTriadFifth: pos.note == tones.fifth
        )
    }
}
