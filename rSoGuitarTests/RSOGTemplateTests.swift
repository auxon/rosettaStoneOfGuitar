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
    
    @Test func familyNamesMatchRSOGConvention() {
        let expected = ["Papa", "yBro", "aBoy", "Mama", "oBro", "oSis", "ySis"]
        #expect(RSOGScaleDegree.familyNameOrder == expected)
        #expect(RSOGScaleDegree.majorKeyTriads.map(\.familyName) == expected)
        // Fred Pool: yBro is the Dorian / ii chord.
        #expect(RSOGScaleDegree.familyName(forDegreeIndex: 1) == "yBro")
        #expect(RSOGScaleDegree.majorKeyTriads[1].romanNumeral == "ii")
    }
    
    @Test func tripleSpacingIsX_X_X() {
        #expect(RSOGSpacingPattern.tripleOffsets == [0, 2, 4])
        #expect(RSOGTemplate.matchesSpacing([0, 2, 4], pattern: RSOGSpacingPattern.tripleOffsets))
        #expect(RSOGTemplate.matchesSpacing([2, 4, 6], pattern: RSOGSpacingPattern.tripleOffsets))
        #expect(!RSOGTemplate.matchesSpacing([0, 1, 3], pattern: RSOGSpacingPattern.tripleOffsets))
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
    
    // MARK: - E Major TRIPLE (canonical X-X-X — every other half-step)
    
    @Test func eMajorPrimaryTripleIsNineNotesEveryOtherFret() {
        let triple = BlockGenerator.tripleBlock(for: .E, maxFret: 15)
        
        #expect(triple.type == .tripleBlock)
        #expect(triple.positions.count == 9)
        #expect(triple.anchorFret == 2)
        #expect(triple.stringRange == 3...5)
        
        let expected: Set<String> = [
            "3,2,A", "3,4,B", "3,6,C#",
            "4,2,E", "4,4,F#", "4,6,G#",
            "5,2,B", "5,4,C#", "5,6,D#"
        ]
        let actual = Set(triple.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
        
        for string in 3...5 {
            let frets = triple.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.tripleOffsets))
        }
    }
    
    @Test func cMajorPrimaryTripleIsNineNoteXXX() {
        // G–D–A X-X-X at fret 10 extends to fret 14 — still discovered when maxFret is 12
        // so the on-board columns can render clipped.
        let triple = BlockGenerator.tripleBlock(for: .C, maxFret: 12)
        
        #expect(triple.positions.count == 9)
        #expect(triple.anchorFret == 10)
        #expect(triple.stringRange == 3...5)
        
        let keyNotes = Set(FretboardCalculator.notesInKey(.C))
        #expect(triple.positions.allSatisfy { keyNotes.contains($0.note) })
        
        for string in triple.stringRange {
            let frets = triple.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.tripleOffsets))
        }
    }
    
    @Test func allTriplePlacementsIncludesEdgeClippedAndSecondarySets() {
        let placements = RSOGTemplate.allTriplePlacements(for: .E, maxFret: 24)
        let keys = Set(placements.map { "\($0.startString):\($0.anchor)" })
        
        // On-board sets and octaves.
        #expect(keys.contains("3:2"))
        #expect(keys.contains("3:14"))
        #expect(keys.contains("4:7"))
        #expect(keys.contains("4:19"))
        
        // Overflow past low E / high e — visible 6-note footprints at the start of E.
        #expect(keys.contains("5:0"))
        #expect(keys.contains("0:0"))
    }
    
    @Test func eMajorOverflowTripleShowsTwoThirdsAtNut() {
        let placements = RSOGTemplate.allTriplePlacements(for: .E, maxFret: 12)
        guard let overflow = placements.first(where: { $0.startString == 5 && $0.anchor == 0 }) else {
            Issue.record("Expected A–E–(virtual) TRIPLE at open position in E")
            return
        }
        
        // 6 physical notes (2/3 of the 9-note X-X-X); third string is below low E.
        #expect(overflow.positions.count == 6)
        #expect(Set(overflow.positions.map(\.string)) == [5, 6])
        
        let expected: Set<String> = [
            "5,0,A", "5,2,B", "5,4,C#",
            "6,0,E", "6,2,F#", "6,4,G#"
        ]
        let actual = Set(overflow.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
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
        let head = BlockGenerator.headBlock(for: .G, maxFret: 15)
        #expect(head.positions.count == 6)
        #expect(head.anchorFret == 7)
        #expect(head.stringRange == 1...2)
        
        let expected: Set<String> = [
            "1,7,B", "1,8,C", "1,10,D",
            "2,7,F#", "2,8,G", "2,10,A"
        ]
        let actual = Set(head.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
        
        for string in head.stringRange {
            let frets = head.positions.filter { $0.string == string }.map(\.fret).sorted()
            #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
        }
        
        let keyNotes = Set(FretboardCalculator.notesInKey(.G))
        #expect(head.positions.allSatisfy { keyNotes.contains($0.note) })
    }
    
    @Test func gMajorPrimaryBridgePositions() {
        let bridge = BlockGenerator.bridgeBlock(for: .G, maxFret: 15)
        #expect(bridge.positions.count == 6)
        #expect(bridge.anchorFret == 7)
        #expect(bridge.stringRange == 4...5)
        
        // X-XX on D–A at the G-major primary anchor (fret 7)
        let expected: Set<String> = [
            "4,7,A", "4,9,B", "4,10,C",
            "5,7,E", "5,9,F#", "5,10,G"
        ]
        let actual = Set(bridge.positions.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })
        #expect(actual == expected)
    }
    
    @Test func cMajorHeadRepeatsAtOctaveWhenRangeAllows() {
        let heads = RSOGTemplate.allHeadPlacements(for: .C, maxFret: 24)
            .filter { $0.pair == RSOGStringPairs.primaryHeadPair }
        let anchors = heads.map(\.anchor).sorted()
        #expect(anchors.contains(0))
        #expect(anchors.contains(12))
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
    
    // MARK: - Spiral-run tiled blocks (home-position geometry)
    
    @Test func spiralRunWrapsHighEToLowE() {
        let run = BlockGenerator.spiralRun(for: .C, maxFret: 12)
        #expect(!run.isEmpty)
        
        // First pass: strings 6→1, three notes each.
        let firstPass = Array(run.prefix(18))
        #expect(firstPass.map(\.string) == [6,6,6, 5,5,5, 4,4,4, 3,3,3, 2,2,2, 1,1,1])
        
        // Helix wrap: TRIPLE third row continues onto low E at the same frets
        // (F G A), not a jump from A on high e to B further up the neck.
        #expect(run.count > 21)
        #expect(run[17].string == 1 && run[17].note == .A)
        let wrap = Array(run[18..<21])
        #expect(wrap.map(\.string) == [6, 6, 6])
        #expect(wrap.map(\.note) == [.F, .G, .A])
        #expect(wrap.map(\.fret) == [1, 3, 5])
        // Next HEAD starts on the A string: B C D (XX-X), then E F G on D —
        // not B on low E at fret 7.
        #expect(run[21].string == 5 && run[21].note == .B && run[21].fret == 2)
        #expect(run[22].string == 5 && run[22].note == .C && run[22].fret == 3)
        #expect(run[23].string == 5 && run[23].note == .D && run[23].fret == 5)
        #expect(run[24].string == 4 && run[24].note == .E && run[24].fret == 2)
        #expect(run[25].string == 4 && run[25].note == .F && run[25].fret == 3)
        #expect(run[26].string == 4 && run[26].note == .G && run[26].fret == 5)
    }
    
    @Test func tiledBlocksContinueHorizontallyAfterWrap() {
        let blocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        #expect(blocks.count >= 4)
        #expect(blocks[0].type == .headBlock)
        #expect(blocks[1].type == .bridgeBlock)
        #expect(blocks[2].type == .tripleBlock)
        
        let nextHead = blocks[3]
        #expect(nextHead.type == .headBlock)
        #expect(Set(nextHead.positions.map(\.string)) == [4, 5])
        func notes(_ block: Block, string: Int) -> [String] {
            block.positions.filter { $0.string == string }.map(\.note.rawValue)
        }
        #expect(notes(nextHead, string: 5) == ["B", "C", "D"])
        #expect(notes(nextHead, string: 4) == ["E", "F", "G"])
    }
    
    @Test func tripleStartsAtGOnLowEInC() {
        let triples = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
            .filter { $0.type == .tripleBlock }
        
        func notes(_ block: Block, string: Int) -> [String] {
            block.positions.filter { $0.string == string }.map(\.note.rawValue)
        }
        
        let fromG = triples.first { block in
            let lowE = block.positions.filter { $0.string == 6 }
            return lowE.map(\.note) == [.G, .A, .B] && lowE.map(\.fret) == [3, 5, 7]
        }
        #expect(fromG != nil, "Expected TRIPLE starting at G on low E (3-5-7)")
        guard let triple = fromG else { return }
        #expect(Set(triple.positions.map(\.string)) == [1, 4, 5, 6])
        #expect(notes(triple, string: 1) == ["G", "A", "B"])
        #expect(notes(triple, string: 6) == ["G", "A", "B"])
        #expect(notes(triple, string: 5) == ["C", "D", "E"])
        #expect(notes(triple, string: 4) == ["F", "G", "A"])
    }
    
    @Test func tiledBlocksKeepHeadBridgeTripleCycle() {
        let blocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        #expect(blocks.count >= 6)
        let cycle: [BlockType] = [.headBlock, .bridgeBlock, .tripleBlock]
        for (index, block) in blocks.prefix(6).enumerated() {
            #expect(block.type == cycle[index % 3], "Block \(index) should be \(cycle[index % 3])")
        }
    }
    
    @Test func visibleBlocksFollowScrubberCycleOfThree() {
        let all = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        #expect(all.count >= 3)
        
        let home = BlockGenerator.cycleContaining(runIndex: 0, in: all)
        #expect(home.map(\.type) == [.headBlock, .bridgeBlock, .tripleBlock])
        #expect(home.count == 3)
        
        // After wrap, A-string B C D is the next HEAD (with its BRIDGE). A fake
        // 9-note slice is not promoted to TRIPLE.
        let next = BlockGenerator.cycleContaining(runIndex: 21, in: all)
        #expect(next.first?.type == .headBlock)
        let aString = next[0].positions.filter { $0.string == 5 }.map(\.note)
        #expect(aString == [.B, .C, .D])
        #expect(Set(next.map(\.sequenceIndex)) != Set(home.map(\.sequenceIndex)))
    }
    
    @Test func everyTripleIsThreeAdjacentStringsXXX() {
        let blocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        let triples = blocks.filter { $0.type == .tripleBlock }
        #expect(!triples.isEmpty)
        for triple in triples {
            let strings = Set(triple.positions.map(\.string))
            let highE = triple.positions.filter { $0.string == 1 }.map(\.fret).sorted()
            let lowE = triple.positions.filter { $0.string == 6 }.map(\.fret).sorted()
            let hasWrap = !highE.isEmpty && highE == lowE
            // Trailing wrap (G–B–e): drop low E. Leading wrap (e + E–A–D): drop high e.
            let core: [Int]
            if hasWrap, strings.isSuperset(of: [1, 4, 5, 6]) {
                core = [4, 5, 6]
            } else if hasWrap {
                core = strings.subtracting([6]).sorted()
            } else {
                core = strings.sorted()
            }
            #expect(core.count == 3, "TRIPLE core strings \(core) from \(strings)")
            #expect(core[0] + 1 == core[1] && core[1] + 1 == core[2])
            for string in core {
                let frets = triple.positions.filter { $0.string == string }.map(\.fret)
                #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.tripleOffsets))
            }
        }
    }
    
    @Test func spiralRunCoversEveryInKeyNoteOnEachString() {
        let maxFret = 12
        let run = BlockGenerator.spiralRun(for: .C, maxFret: maxFret)
        let covered = Set(run.map(\.coordinateKey))
        let diatonic = BlockGenerator.diatonicPattern(for: .C, maxFret: maxFret)
        let missing = diatonic.filter { !covered.contains($0.coordinateKey) }
        #expect(missing.isEmpty, "Skipped \(missing.map { "\($0.string),\($0.fret),\($0.note.rawValue)" })")
    }
    
    @Test func tiledBlocksCMajorHomePartialHeadBridgeTriple() {
        let blocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        #expect(blocks.count >= 3)
        
        let head = blocks[0]
        let bridge = blocks[1]
        let triple = blocks[2]
        
        #expect(head.type == .headBlock)
        #expect(bridge.type == .bridgeBlock)
        #expect(triple.type == .tripleBlock)
        
        // Partial home HEAD: only the low-E XX-X pair (virtual string-7 notes dropped).
        #expect(head.positions.count == 3)
        #expect(Set(head.positions.map(\.string)) == [6])
        let headKeys = Set(head.positions.map { "\($0.string),\($0.fret)" })
        #expect(headKeys == ["6,0", "6,1", "6,3"])
        
        // BRIDGE: A–D transitional zone.
        #expect(bridge.positions.count == 6)
        #expect(Set(bridge.positions.map(\.string)) == [4, 5])
        let bridgeNotes = bridge.positions.map(\.note.rawValue)
        #expect(Set(bridgeNotes) == Set(["A", "B", "C", "D", "E", "F"]))
        
        // TRIPLE: continuing 3NPS across G–B–e — G A B / C D E / F G A
        // plus the helix wrap of that third row onto low E.
        #expect(triple.positions.count == 12)
        #expect(Set(triple.positions.map(\.string)) == [1, 2, 3, 6])
        func notes(on string: Int) -> [String] {
            triple.positions.filter { $0.string == string }.map(\.note.rawValue)
        }
        #expect(notes(on: 3) == ["G", "A", "B"])
        #expect(notes(on: 2) == ["C", "D", "E"])
        #expect(notes(on: 1) == ["F", "G", "A"])
        #expect(notes(on: 6) == ["F", "G", "A"])
        let tripleFrets = Dictionary(uniqueKeysWithValues:
            [3, 2, 1, 6].map { string in
                (string, triple.positions.filter { $0.string == string }.map(\.fret))
            }
        )
        // G-string B is fret 4 (Bb at 3 is out of key); B/e rows sit on the shifted lattice.
        #expect(tripleFrets[3] == [0, 2, 4])
        #expect(tripleFrets[2] == [1, 3, 5])
        #expect(tripleFrets[1] == [1, 3, 5])
        #expect(tripleFrets[6] == [1, 3, 5])
    }
    
    @Test func spiralMappingUsesSameRunAsTiledBlocks() {
        let run = BlockGenerator.spiralRun(for: .G, maxFret: 12)
        let pattern = PatternGenerator.spiralMappingPattern(for: .G, maxFret: 12)
        #expect(pattern.positions.count == run.count)
        #expect(zip(pattern.positions, run).allSatisfy { $0.string == $1.string && $0.fret == $1.fret })
    }
    
    @Test func tripleBlockOutlineSpansShiftAcrossGB() {
        let blocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        guard let triple = blocks.first(where: { $0.type == .tripleBlock }) else {
            Issue.record("Expected a home-position TRIPLE in C")
            return
        }
        let spans = FretboardRenderer.blockOutlineSpans(for: triple.positions)
        let byString = Dictionary(uniqueKeysWithValues: spans.map { ($0.string, $0) })
        
        // G (3) and B (2) must disagree on frets — that's the major-third shift.
        guard let g = byString[3], let b = byString[2] else {
            Issue.record("TRIPLE should span G and B")
            return
        }
        #expect(g.minFret != b.minFret || g.maxFret != b.maxFret)
        
        // Aligned A–D BRIDGE stays rectangular (same frets both strings).
        guard let bridge = blocks.first(where: { $0.type == .bridgeBlock }) else {
            Issue.record("Expected a home-position BRIDGE in C")
            return
        }
        let bridgeSpans = FretboardRenderer.blockOutlineSpans(for: bridge.positions)
        #expect(bridgeSpans.count == 2)
        #expect(bridgeSpans[0].minFret == bridgeSpans[1].minFret)
        #expect(bridgeSpans[0].maxFret == bridgeSpans[1].maxFret)
    }
    
    @Test func spiralRunAndTiledBlocksTransposeWithKey() {
        let cRun = BlockGenerator.spiralRun(for: .C, maxFret: 12)
        let gRun = BlockGenerator.spiralRun(for: .G, maxFret: 12)
        let dRun = BlockGenerator.spiralRun(for: .D, maxFret: 12)
        
        #expect(cRun.first?.string == 6 && cRun.first?.fret == 0 && cRun.first?.note == .E)
        // Same shape, shifted by root − C.
        #expect(gRun.first?.string == 6 && gRun.first?.fret == 7 && gRun.first?.note == .B)
        #expect(dRun.first?.string == 6 && dRun.first?.fret == 2 && dRun.first?.note == .FSharp)
        
        let cBlocks = BlockGenerator.tiledBlocks(for: .C, maxFret: 12)
        let gBlocks = BlockGenerator.tiledBlocks(for: .G, maxFret: 15)
        #expect(cBlocks.count >= 3 && gBlocks.count >= 3)
        
        let cTriple = cBlocks[2]
        let gTriple = gBlocks[2]
        #expect(cTriple.type == .tripleBlock && gTriple.type == .tripleBlock)
        
        // G major TRIPLE is C’s TRIPLE notes transposed +7 semitones (and frets +7).
        func noteNames(_ block: Block, string: Int) -> [String] {
            block.positions.filter { $0.string == string }.map(\.note.rawValue)
        }
        #expect(noteNames(cTriple, string: 3) == ["G", "A", "B"])
        #expect(noteNames(cTriple, string: 2) == ["C", "D", "E"])
        #expect(noteNames(cTriple, string: 1) == ["F", "G", "A"])
        #expect(noteNames(cTriple, string: 6) == ["F", "G", "A"])
        
        #expect(noteNames(gTriple, string: 3) == ["D", "E", "F#"])
        #expect(noteNames(gTriple, string: 2) == ["G", "A", "B"])
        #expect(noteNames(gTriple, string: 1) == ["C", "D", "E"])
        #expect(noteNames(gTriple, string: 6) == ["C", "D", "E"])
        
        let cFrets = cTriple.positions.filter { $0.string == 3 }.map(\.fret)
        let gFrets = gTriple.positions.filter { $0.string == 3 }.map(\.fret)
        #expect(cFrets == [0, 2, 4])
        #expect(gFrets == [7, 9, 11])
    }
    
    @Test func tiledBlocksAvailableAcrossReferenceKeys() {
        for key in [Key.C, .CSharp, .D, .E, .F, .G, .A] {
            let delta = ((key.rootNote.semitonesFromC % 12) + 12) % 12
            let run = BlockGenerator.spiralRun(for: key, maxFret: 15)
            #expect(run.first?.fret == delta, "Home start fret for \(key.rawValue)")
            #expect(run.first.map { FretboardCalculator.scaleDegree(of: $0.note, in: key) } == 2)
            
            let blocks = BlockGenerator.tiledBlocks(for: key, maxFret: 15)
            let types = blocks.prefix(3).map(\.type)
            #expect(types == [.headBlock, .bridgeBlock, .tripleBlock], "Cycle in \(key.rawValue)")
        }
    }
}
