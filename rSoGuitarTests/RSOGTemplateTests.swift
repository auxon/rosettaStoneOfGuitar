//
//  RSOGTemplateTests.swift
//  rSoGuitarTests
//
//  Reference-position tests for the rSoG template engine (Phase 1).
//  C major open position is the canonical fixture.
//

import Testing
@testable import rSoGuitar

struct RSOGTemplateTests {
    
    // MARK: - Spacing Pattern Constants
    
    @Test func headSpacingIsXX_X() {
        #expect(RSOGSpacingPattern.headOffsets == [0, 1, 3])
        #expect(RSOGTemplate.matchesSpacing([0, 1, 3], pattern: RSOGSpacingPattern.headOffsets))
        #expect(RSOGTemplate.matchesSpacing([5, 6, 8], pattern: RSOGSpacingPattern.headOffsets))
        #expect(!RSOGTemplate.matchesSpacing([0, 2, 3], pattern: RSOGSpacingPattern.headOffsets))
    }
    
    @Test func bridgeSpacingIsX_XX() {
        #expect(RSOGSpacingPattern.bridgeOffsets == [0, 2, 3])
        #expect(RSOGTemplate.matchesSpacing([0, 2, 3], pattern: RSOGSpacingPattern.bridgeOffsets))
        #expect(RSOGTemplate.matchesSpacing([5, 7, 8], pattern: RSOGSpacingPattern.bridgeOffsets))
        #expect(!RSOGTemplate.matchesSpacing([0, 1, 3], pattern: RSOGSpacingPattern.bridgeOffsets))
    }
    
    @Test func headAndBridgeSpacingAreDistinct() {
        #expect(RSOGSpacingPattern.headOffsets != RSOGSpacingPattern.bridgeOffsets)
    }
    
    // MARK: - C Major HEAD (XX-X on e–B, frets 0/1/3)
    
    @Test func cMajorPrimaryHeadPositions() {
        let head = BlockGenerator.headBlock(for: .C, maxFret: 12)
        
        #expect(head.type == .headBlock)
        #expect(head.positions.count == 6)
        #expect(head.anchorFret == 0)
        #expect(head.stringRange == 1...2)
        
        let expected: Set<String> = [
            "1,0,E", "1,1,F", "1,3,G",
            "2,0,B", "2,1,C", "2,3,D"
        ]
        let actual = Set(head.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
        
        // Per-string frets must be XX-X.
        for string in 1...2 {
            let frets = head.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
        }
    }
    
    @Test func cMajorHeadNotesAreDiatonic() {
        let keyNotes = Set(FretboardCalculator.notesInKey(.C))
        let head = BlockGenerator.headBlock(for: .C, maxFret: 12)
        #expect(head.positions.allSatisfy { keyNotes.contains($0.note) })
    }
    
    // MARK: - C Major BRIDGE (X-XX on D–A, frets 0/2/3)
    
    @Test func cMajorPrimaryBridgePositions() {
        let bridge = BlockGenerator.bridgeBlock(for: .C, maxFret: 12)
        
        #expect(bridge.type == .bridgeBlock)
        #expect(bridge.positions.count == 6)
        #expect(bridge.anchorFret == 0)
        #expect(bridge.stringRange == 4...5)
        
        let expected: Set<String> = [
            "4,0,D", "4,2,E", "4,3,F",
            "5,0,A", "5,2,B", "5,3,C"
        ]
        let actual = Set(bridge.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
        
        for string in 4...5 {
            let frets = bridge.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.bridgeOffsets))
        }
    }
    
    @Test func cMajorBridgeIsDistinctFromHead() {
        let head = BlockGenerator.headBlock(for: .C, maxFret: 12)
        let bridge = BlockGenerator.bridgeBlock(for: .C, maxFret: 12)
        
        let headKeys = Set(head.positions.map { "\($0.string),\($0.fret)" })
        let bridgeKeys = Set(bridge.positions.map { "\($0.string),\($0.fret)" })
        
        #expect(headKeys.isDisjoint(with: bridgeKeys))
        #expect(head.positions.map(\.fret).sorted() != bridge.positions.map(\.fret).sorted()
                || head.stringRange != bridge.stringRange)
    }
    
    // MARK: - C Major TRIPLE (three stacked triads)
    
    @Test func cMajorPrimaryTripleHasThreeTriads() {
        let triple = BlockGenerator.tripleBlock(for: .C, maxFret: 12)
        
        #expect(triple.type == .tripleBlock)
        #expect(triple.positions.count >= 5)
        #expect(triple.positions.count <= 9)
        #expect(triple.stringRange.count == 3)
        
        // Must include chord tones covering at least root-class diversity.
        let notes = Set(triple.positions.map(\.note))
        #expect(notes.count >= 3)
        
        // All notes diatonic to C major.
        let keyNotes = Set(FretboardCalculator.notesInKey(.C))
        #expect(triple.positions.allSatisfy { keyNotes.contains($0.note) })
    }
    
    @Test func cMajorTripleFindsPreferredDegreeSet() {
        guard let primary = RSOGTemplate.primaryTriple(for: .C, maxFret: 12) else {
            Issue.record("Expected a primary TRIPLE in C major")
            return
        }
        
        #expect(primary.voicings.count == 3)
        let numerals = Set(primary.voicings.map(\.degree.romanNumeral))
        
        // Open-position C major prefers the I–iii–V stacked-triad landmark.
        #expect(numerals == ["I", "iii", "V"])
        
        for voicing in primary.voicings {
            #expect(voicing.positions.count == 3)
            let strings = Set(voicing.positions.map(\.string))
            #expect(strings.count == 3)
        }
        
        // Reference open-position stack on strings 3–5 includes the C triad landmark.
        let keys = Set(primary.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(keys.contains("3,0,G"))
        #expect(keys.contains("4,2,E"))
        #expect(keys.contains("5,3,C"))
    }
    
    // MARK: - Sequential Tiling
    
    @Test func allBlocksHonorsStartBlockType() {
        let fromHead = BlockGenerator.allBlocks(for: .C, maxFret: 12, startBlockType: .headBlock)
        let fromBridge = BlockGenerator.allBlocks(for: .C, maxFret: 12, startBlockType: .bridgeBlock)
        let fromTriple = BlockGenerator.allBlocks(for: .C, maxFret: 12, startBlockType: .tripleBlock)
        
        #expect(!fromHead.isEmpty)
        #expect(fromHead.first?.type == .headBlock)
        #expect(fromBridge.first?.type == .bridgeBlock)
        #expect(fromTriple.first?.type == .tripleBlock)
    }
    
    @Test func allBlocksSequenceAlternatesTypes() {
        let blocks = BlockGenerator.allBlocks(for: .C, maxFret: 12, startBlockType: .headBlock)
        #expect(blocks.count >= 3)
        
        // First cycle should be HEAD, BRIDGE, TRIPLE when all three exist.
        let headCount = blocks.filter { $0.type == .headBlock }.count
        let bridgeCount = blocks.filter { $0.type == .bridgeBlock }.count
        let tripleCount = blocks.filter { $0.type == .tripleBlock }.count
        
        #expect(headCount >= 1)
        #expect(bridgeCount >= 1)
        #expect(tripleCount >= 1)
        
        // Sequence indices are unique and contiguous from 0.
        let indices = blocks.map(\.sequenceIndex).sorted()
        #expect(indices == Array(0..<blocks.count))
    }
    
    @Test func sequencedTypesRotatesCorrectly() {
        #expect(RSOGTemplate.sequencedTypes(startingFrom: .headBlock) == [.headBlock, .bridgeBlock, .tripleBlock])
        #expect(RSOGTemplate.sequencedTypes(startingFrom: .bridgeBlock) == [.bridgeBlock, .tripleBlock, .headBlock])
        #expect(RSOGTemplate.sequencedTypes(startingFrom: .tripleBlock) == [.tripleBlock, .headBlock, .bridgeBlock])
    }
    
    // MARK: - Template vs Heuristic Distinctions
    
    @Test func headPlacementsNeverMatchBridgeSpacing() {
        let heads = RSOGTemplate.allHeadPlacements(for: .C, maxFret: 12)
        #expect(!heads.isEmpty)
        
        for placement in heads {
            for string in [placement.pair.0, placement.pair.1] {
                let frets = placement.positions.filter { $0.string == string }.map(\.fret)
                #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
                #expect(!RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.bridgeOffsets))
            }
        }
    }
    
    @Test func bridgePlacementsNeverMatchHeadSpacing() {
        let bridges = RSOGTemplate.allBridgePlacements(for: .C, maxFret: 12)
        #expect(!bridges.isEmpty)
        
        for placement in bridges {
            for string in [placement.pair.0, placement.pair.1] {
                let frets = placement.positions.filter { $0.string == string }.map(\.fret)
                #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.bridgeOffsets))
                #expect(!RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
            }
        }
    }
    
    // MARK: - Key Independence (shape preserved)
    
    @Test func gMajorHeadHasSameSpacingShape() {
        let head = BlockGenerator.headBlock(for: .G, maxFret: 12)
        #expect(head.positions.count == 6)
        
        for string in head.stringRange {
            let frets = head.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
        }
        
        let keyNotes = Set(FretboardCalculator.notesInKey(.G))
        #expect(head.positions.allSatisfy { keyNotes.contains($0.note) })
    }
    
    @Test func identifyHeadNearOpenPositionReturnsCanonicalHead() {
        let start = FretboardPosition(string: 1, fret: 0, note: .E, isRoot: false)
        let block = BlockGenerator.identifyHeadBlock(
            startingFrom: start,
            patternMap: [:],
            key: .C,
            maxFret: 12
        )
        
        #expect(block != nil)
        #expect(block?.positions.count == 6)
        #expect(block?.anchorFret == 0)
    }
}
