//
//  PatternGeneratorTests.swift
//  rSoGuitarTests
//
//  Phase 2/3 tests: chord groups, spiral connections, hierarchy.
//

import Testing
@testable import rSoGuitar

struct PatternGeneratorTests {
    
    // MARK: - Family of Chords
    
    @Test func familyOfChordsHasI_IV_VGroups() {
        let pattern = PatternGenerator.familyOfChordsPattern(for: .C, maxFret: 12)
        
        #expect(pattern.type == .familyOfChords)
        #expect(pattern.chordGroups.count == 3)
        
        let numerals = pattern.chordGroups.map(\.romanNumeral)
        #expect(numerals == ["I", "IV", "V"])
        
        let roots = pattern.chordGroups.map(\.root)
        #expect(roots == [.C, .F, .G])
    }
    
    @Test func familyOfChordsUsesTriadVoicingsNotRootsOnly() {
        let pattern = PatternGenerator.familyOfChordsPattern(for: .C, maxFret: 12)
        
        for group in pattern.chordGroups {
            #expect(group.positions.count >= 3, "Group \(group.romanNumeral) should have triad tones")
            
            let hasRoot = group.positions.contains(where: \.isTriadRoot)
            let hasThird = group.positions.contains(where: \.isTriadThird)
            let hasFifth = group.positions.contains(where: \.isTriadFifth)
            #expect(hasRoot && hasThird && hasFifth)
        }
        
        #expect(!pattern.connections.isEmpty)
        #expect(pattern.connections.allSatisfy { $0.kind == .triad })
    }
    
    @Test func familyOfChordsPositionsCarryChordRole() {
        let pattern = PatternGenerator.familyOfChordsPattern(for: .C, maxFret: 12)
        
        let iGroup = pattern.chordGroups.first { $0.romanNumeral == "I" }
        #expect(iGroup?.chordRole == .tonic)
        
        let ivGroup = pattern.chordGroups.first { $0.romanNumeral == "IV" }
        #expect(ivGroup?.chordRole == .subdominant)
        
        let vGroup = pattern.chordGroups.first { $0.romanNumeral == "V" }
        #expect(vGroup?.chordRole == .dominant)
        
        #expect(pattern.positions.contains { $0.chordRole == .tonic })
    }
    
    @Test func familyOfChordsHasAtLeastOneVoicingPerChord() {
        let pattern = PatternGenerator.familyOfChordsPattern(for: .C, maxFret: 12)
        for group in pattern.chordGroups {
            // A voicing is evidenced by triad connections or ≥3 distinct chord-tone positions.
            let toneClasses = Set(group.positions.compactMap { pos -> String? in
                if pos.isTriadRoot { return "R" }
                if pos.isTriadThird { return "3" }
                if pos.isTriadFifth { return "5" }
                return nil
            })
            #expect(toneClasses == Set(["R", "3", "5"]), "Incomplete triad for \(group.romanNumeral)")
            #expect(!group.connections.isEmpty || group.positions.count >= 3)
        }
        
        // Horizontal separation: the three family roots differ.
        #expect(Set(pattern.chordGroups.map(\.root)).count == 3)
        #expect(Set(pattern.positions.map(\.fret)).count >= 3)
    }
    
    // MARK: - Familial Hierarchy
    
    @Test func familialHierarchyHasSevenDegrees() {
        let pattern = PatternGenerator.familialHierarchyPattern(for: .C, maxFret: 12)
        
        #expect(pattern.type == .familialHierarchy)
        #expect(pattern.chordGroups.count == 7)
        
        let numerals = pattern.chordGroups.map(\.romanNumeral)
        #expect(numerals == ["I", "ii", "iii", "IV", "V", "vi", "vii°"])
    }
    
    @Test func familialHierarchyVoicingsAreVerticalStacks() {
        let pattern = PatternGenerator.familialHierarchyPattern(for: .C, maxFret: 12)
        
        for group in pattern.chordGroups {
            #expect(!group.positions.isEmpty, "Missing voicing for \(group.romanNumeral)")
            #expect(group.positions.contains(where: \.isTriadRoot))
            
            // Hierarchy connections run along the stack.
            if !group.connections.isEmpty {
                #expect(group.connections.allSatisfy { $0.kind == .hierarchy })
                let stringDelta = RSOGTestSupport.meanAbsoluteStringDelta(in: group.connections)
                let fretDelta = RSOGTestSupport.meanAbsoluteFretDelta(in: group.connections)
                #expect(stringDelta >= fretDelta)
            }
        }
        
        #expect(!pattern.connections.isEmpty)
        #expect(Set(pattern.chordGroups.map(\.scaleDegree)).count == 7)
    }
    
    // MARK: - Spiral Mapping
    
    @Test func spiralMappingHasOrderedConnections() {
        let pattern = PatternGenerator.spiralMappingPattern(for: .C, maxFret: 12)
        
        #expect(pattern.type == .spiralMapping)
        #expect(!pattern.positions.isEmpty)
        #expect(pattern.connections.count == pattern.positions.count - 1)
        #expect(pattern.connections.allSatisfy { $0.kind == .spiral })
    }
    
    @Test func spiralMappingCoversAllDiatonicNotes() {
        let pattern = PatternGenerator.spiralMappingPattern(for: .C, maxFret: 12)
        let keyNotes = Set(FretboardCalculator.notesInKey(.C))
        
        #expect(pattern.positions.allSatisfy { keyNotes.contains($0.note) })
        
        // Every diatonic fretboard coordinate in range should appear once in the path.
        var expected = 0
        for string in 1...6 {
            for fret in 0...12 {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if keyNotes.contains(note) { expected += 1 }
            }
        }
        #expect(pattern.positions.count == expected)
        
        let coords = Set(pattern.positions.map(\.coordinateKey))
        #expect(coords.count == pattern.positions.count)
    }
    
    @Test func spiralMappingMarksScaleDegrees() {
        let pattern = PatternGenerator.spiralMappingPattern(for: .C, maxFret: 5)
        #expect(pattern.positions.allSatisfy { $0.scaleDegree != nil })
        #expect(pattern.positions.contains { $0.scaleDegree == 0 && $0.isRoot })
    }
    
    // MARK: - Chord model wiring
    
    @Test func diatonicChordFactoryBuildsIChord() {
        let degree = RSOGScaleDegree.majorKeyTriads[0]
        let chord = Chord.diatonic(degree: degree, in: .C)
        
        #expect(chord.rootNote == .C)
        #expect(chord.quality == .major)
        #expect(chord.romanNumeral == "I")
        #expect(chord.chordRole == .tonic)
        
        let tones = chord.chordTones
        #expect(tones.root == .C)
        #expect(tones.third == .E)
        #expect(tones.fifth == .G)
    }
    
    @Test func fretboardPositionMetadataRoundTripDefaults() {
        let pos = FretboardPosition(string: 2, fret: 1, note: .C, isRoot: true)
        #expect(pos.scaleDegree == nil)
        #expect(pos.chordRole == nil)
        #expect(pos.blockType == nil)
        #expect(!pos.isTriadRoot)
        
        let enriched = FretboardCalculator.enrich(pos, in: .C)
        #expect(enriched.scaleDegree == 0)
        #expect(enriched.isRoot)
    }
}
