//
//  RSOGValidationTests.swift
//  rSoGuitarTests
//
//  Phase 6: end-to-end RSOG validation — cross-key blocks, family/hierarchy
//  geometry, lesson alignment, key changes, and UX integrity.
//

import Testing
@testable import rSoGuitar

struct RSOGValidationTests {
    
    // MARK: - Cross-key block integrity
    
    @Test func everyReferenceKeyProducesAllThreeBlockTypes() {
        for key in RSOGTestSupport.referenceKeys {
            let blocks = BlockGenerator.allBlocks(for: key, maxFret: 15, startBlockType: .headBlock)
            let types = Set(blocks.map(\.type))
            
            #expect(types.contains(.headBlock), "Missing HEAD in \(key.rawValue)")
            #expect(types.contains(.bridgeBlock), "Missing BRIDGE in \(key.rawValue)")
            #expect(types.contains(.tripleBlock), "Missing TRIPLE in \(key.rawValue)")
            
            #expect(RSOGTestSupport.assertAllDiatonic(blocks.flatMap(\.positions), key: key))
        }
    }
    
    @Test func headAndBridgeRemainStructurallyDistinctAcrossKeys() {
        for key in RSOGTestSupport.referenceKeys {
            let head = BlockGenerator.headBlock(for: key, maxFret: 15)
            let bridge = BlockGenerator.bridgeBlock(for: key, maxFret: 15)
            
            #expect(head.positions.count == 6, "HEAD note count in \(key.rawValue)")
            #expect(bridge.positions.count == 6, "BRIDGE note count in \(key.rawValue)")
            
            for string in head.stringRange {
                let frets = RSOGTestSupport.frets(on: string, in: head.positions)
                #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.headOffsets))
            }
            for string in bridge.stringRange {
                let frets = RSOGTestSupport.frets(on: string, in: bridge.positions)
                #expect(RSOGTemplate.matchesSpacing(frets, pattern: RSOGSpacingPattern.bridgeOffsets))
            }
            
            let headKeys = RSOGTestSupport.coordinateKeys(in: head.positions)
            let bridgeKeys = RSOGTestSupport.coordinateKeys(in: bridge.positions)
            #expect(headKeys.isDisjoint(with: bridgeKeys), "HEAD∩BRIDGE overlap in \(key.rawValue)")
        }
    }
    
    @Test func tripleBlocksContainThreeVoicingsAcrossKeys() {
        for key in [.C, .G, .F, .D] as [Key] {
            guard let triple = RSOGTemplate.primaryTriple(for: key, maxFret: 15) else {
                Issue.record("No primary TRIPLE for \(key.rawValue)")
                continue
            }
            #expect(triple.voicings.count == 3, "TRIPLE voicing count in \(key.rawValue)")
            #expect(triple.positions.count >= 5)
            #expect(RSOGTestSupport.assertAllDiatonic(triple.positions, key: key))
            
            for voicing in triple.voicings {
                #expect(Set(voicing.positions.map(\.string)).count == 3)
                #expect(RSOGTestSupport.fretSpan(of: voicing.positions) <= 5)
            }
        }
    }
    
    // MARK: - Sequence / tiling
    
    @Test func firstSequenceCycleIsHeadBridgeTriple() {
        let blocks = BlockGenerator.allBlocks(for: .C, maxFret: 12, startBlockType: .headBlock)
        #expect(blocks.count >= 3)
        
        let firstThree = blocks.prefix(3).map(\.type)
        #expect(Array(firstThree) == [.headBlock, .bridgeBlock, .tripleBlock])
        
        // Contiguous sequence indices with no gaps.
        let indices = blocks.map(\.sequenceIndex)
        #expect(indices == Array(0..<blocks.count))
    }
    
    @Test func blockTypeToggleIsolatesCoordinates() {
        let blocks = BlockGenerator.allBlocks(for: .C, maxFret: 12)
        
        let headOnly = FretboardRenderer.blockCoordinateKeys(
            blocks: blocks,
            selectedTypes: [.headBlock]
        )
        let bridgeOnly = FretboardRenderer.blockCoordinateKeys(
            blocks: blocks,
            selectedTypes: [.bridgeBlock]
        )
        let tripleOnly = FretboardRenderer.blockCoordinateKeys(
            blocks: blocks,
            selectedTypes: [.tripleBlock]
        )
        
        #expect(!headOnly.isEmpty)
        #expect(!bridgeOnly.isEmpty)
        #expect(!tripleOnly.isEmpty)
        
        // Independent toggles must not suddenly include the other primary landmarks.
        let primaryHead = RSOGTestSupport.coordinateKeys(
            in: BlockGenerator.headBlock(for: .C, maxFret: 12).positions
        )
        let primaryBridge = RSOGTestSupport.coordinateKeys(
            in: BlockGenerator.bridgeBlock(for: .C, maxFret: 12).positions
        )
        
        #expect(primaryHead.isSubset(of: headOnly))
        #expect(primaryBridge.isSubset(of: bridgeOnly))
        #expect(primaryHead.isDisjoint(with: bridgeOnly))
        #expect(primaryBridge.isDisjoint(with: headOnly))
    }
    
    // MARK: - Family / hierarchy geometry
    
    @Test func familyOfChordsIsHorizontallyDistributed() {
        for key in [.C, .G, .A] as [Key] {
            let pattern = PatternGenerator.familyOfChordsPattern(for: key, maxFret: 12)
            #expect(pattern.chordGroups.count == 3)
            
            // Each group has at least one compact triad voicing footprint.
            for group in pattern.chordGroups {
                #expect(group.positions.count >= 3)
                #expect(group.positions.contains(where: \.isTriadRoot))
                #expect(group.positions.contains(where: \.isTriadThird))
                #expect(group.positions.contains(where: \.isTriadFifth))
            }
            
            // Horizontal family: roots of I/IV/V are not all the same note.
            let roots = Set(pattern.chordGroups.map(\.root))
            #expect(roots.count == 3)
            
            // Frets used by the family span more than a single column.
            let allFrets = Set(pattern.positions.map(\.fret))
            #expect(allFrets.count >= 3, "Family should spread horizontally in \(key.rawValue)")
            
            // Triad connections prefer vertical string motion over huge fret jumps.
            if !pattern.connections.isEmpty {
                let stringDelta = RSOGTestSupport.meanAbsoluteStringDelta(in: pattern.connections)
                #expect(stringDelta >= 0.5)
            }
        }
    }
    
    @Test func familialHierarchyStacksAreVerticallyBiased() {
        let pattern = PatternGenerator.familialHierarchyPattern(for: .C, maxFret: 12)
        #expect(pattern.chordGroups.count == 7)
        
        for group in pattern.chordGroups {
            #expect(!group.positions.isEmpty, "Empty hierarchy group \(group.romanNumeral)")
            
            // Compact stacks: available positions for a degree stay within a modest fret window
            // when considering the densest cluster of 3 consecutive-string notes.
            let byFret = Dictionary(grouping: group.positions, by: \.fret)
            let hasCompactColumn = byFret.values.contains { cluster in
                Set(cluster.map(\.string)).count >= 2
            }
            // Prefer vertical presence; if connections exist they should move more by string than fret.
            if !group.connections.isEmpty {
                let stringDelta = RSOGTestSupport.meanAbsoluteStringDelta(in: group.connections)
                let fretDelta = RSOGTestSupport.meanAbsoluteFretDelta(in: group.connections)
                #expect(stringDelta >= fretDelta, "Hierarchy \(group.romanNumeral) should be vertically biased")
            } else {
                #expect(hasCompactColumn || RSOGTestSupport.fretSpan(of: group.positions) <= 5)
            }
        }
    }
    
    @Test func spiralPathIsContinuousAndCoverageComplete() {
        for key in [.C, .G] as [Key] {
            let pattern = PatternGenerator.spiralMappingPattern(for: key, maxFret: 12)
            #expect(pattern.connections.count == max(0, pattern.positions.count - 1))
            
            // Each connection endpoint exists in the position set.
            let coords = RSOGTestSupport.coordinateKeys(in: pattern.positions)
            for connection in pattern.connections {
                #expect(coords.contains("\(connection.fromString),\(connection.fromFret)"))
                #expect(coords.contains("\(connection.toString),\(connection.toFret)"))
            }
            
            #expect(RSOGTestSupport.assertAllDiatonic(pattern.positions, key: key))
        }
    }
    
    // MARK: - Key change regeneration
    
    @Test func changingKeyRegeneratesBlocksAndPatterns() {
        let vm = FretboardViewModel()
        let cHead = Set(vm.blocks.filter { $0.type == .headBlock }.flatMap(\.positions).map(\.coordinateKey))
        let cPatternID = vm.selectedPattern?.id
        
        vm.selectKey(.G)
        
        let gHead = Set(vm.blocks.filter { $0.type == .headBlock }.flatMap(\.positions).map(\.coordinateKey))
        #expect(vm.selectedKey == .G)
        #expect(cHead != gHead, "HEAD coordinates should move when key changes")
        #expect(vm.selectedPattern?.key == .G)
        #expect(vm.selectedPattern?.id != cPatternID)
        
        let gNotes = Set(FretboardCalculator.notesInKey(.G))
        #expect(vm.blocks.flatMap(\.positions).allSatisfy { gNotes.contains($0.note) })
    }
    
    @Test func identifyRebuildsPreserveBlockTypeAcrossDragAnchors() {
        let maxFret = 12
        let cases: [(BlockType, FretboardPosition)] = [
            (.headBlock, FretboardPosition(string: 1, fret: 0, note: .E)),
            (.bridgeBlock, FretboardPosition(string: 4, fret: 0, note: .D)),
            (.tripleBlock, FretboardPosition(string: 3, fret: 0, note: .G))
        ]
        
        for (type, start) in cases {
            let rebuilt: Block?
            switch type {
            case .headBlock:
                rebuilt = BlockGenerator.identifyHeadBlock(
                    startingFrom: start, patternMap: [:], key: .C, maxFret: maxFret
                )
            case .bridgeBlock:
                rebuilt = BlockGenerator.identifyBridgeBlock(
                    startingFrom: start, patternMap: [:], key: .C, maxFret: maxFret
                )
            case .tripleBlock:
                rebuilt = BlockGenerator.identifyTripleBlock(
                    startingFrom: start, patternMap: [:], key: .C, maxFret: maxFret
                )
            }
            
            #expect(rebuilt != nil, "Failed to rebuild \(type.rawValue)")
            #expect(rebuilt?.type == type)
            #expect(!(rebuilt?.positions.isEmpty ?? true))
        }
    }
    
    // MARK: - Lesson / content alignment
    
    @Test func lessonsCoverFourCoreConceptsInOrder() {
        let lessons = ContentService.shared.getAllLessons().sorted { $0.order < $1.order }
        #expect(lessons.count >= 5)
        
        let titles = lessons.map(\.title)
        #expect(titles.contains("Introduction to rSoGuitar"))
        #expect(titles.contains("Spiral Mapping"))
        #expect(titles.contains("Jumping"))
        #expect(titles.contains("Family of Chords"))
        #expect(titles.contains("Familial Hierarchy"))
        
        let spiral = lessons.first { $0.title == "Spiral Mapping" }
        let jumping = lessons.first { $0.title == "Jumping" }
        let family = lessons.first { $0.title == "Family of Chords" }
        let hierarchy = lessons.first { $0.title == "Familial Hierarchy" }
        
        #expect(spiral?.isPremium == false)
        #expect(jumping?.isPremium == false)
        #expect(family?.isPremium == true)
        #expect(hierarchy?.isPremium == true)
        
        #expect(demoPatternType(in: spiral) == .spiralMapping)
        #expect(demoPatternType(in: jumping) == .jumping)
        #expect(demoPatternType(in: family) == .familyOfChords)
        #expect(demoPatternType(in: hierarchy) == .familialHierarchy)
    }
    
    @Test func lessonDemoBlockPresetsMatchConceptTeaching() {
        #expect(RSOGConceptInfo.demoBlocks(for: .spiralMapping) == [.headBlock])
        #expect(RSOGConceptInfo.demoBlocks(for: .jumping) == [.bridgeBlock])
        #expect(RSOGConceptInfo.demoBlocks(for: .familyOfChords).contains(.tripleBlock))
        #expect(RSOGConceptInfo.demoBlocks(for: .familialHierarchy) == [.tripleBlock])
        
        // ContentService demos should be generatable for each mapped type.
        for type in RSOGConceptInfo.allConcepts {
            let pattern = ContentService.shared.generatePattern(type: type, key: .C)
            #expect(pattern.type == type)
            #expect(!pattern.positions.isEmpty)
        }
    }
    
    // MARK: - Visual / palette integrity
    
    @Test func blockColorsAreDistinct() {
        let head = RSOGPalette.blockColor(.headBlock)
        let bridge = RSOGPalette.blockColor(.bridgeBlock)
        let triple = RSOGPalette.blockColor(.tripleBlock)
        
        // Distinct semantic colors (compare description strings as a stable proxy).
        #expect(String(describing: head) != String(describing: bridge))
        #expect(String(describing: bridge) != String(describing: triple))
        #expect(String(describing: head) != String(describing: triple))
    }
    
    @Test func chordRoleColorsCoverPrimaryFamily() {
        let roles: [ChordRole] = [.tonic, .subdominant, .dominant]
        let descriptions = roles.map { String(describing: RSOGPalette.color(for: $0)) }
        #expect(Set(descriptions).count == 3)
    }
    
    // MARK: - Orientation parity
    
    @Test func explorerAndLessonLayoutsShareStringAxis() {
        let explorer = FretboardLayout(maxFret: 24, fretWidth: 40, stringSpacing: 30, labelOffset: 24)
        let lesson = FretboardLayout(maxFret: 12, fretWidth: 40, stringSpacing: 30, labelOffset: 0)
        
        for string in 1...6 {
            #expect(explorer.stringY(string) == lesson.stringY(string))
        }
        #expect(explorer.stringY(1) < explorer.stringY(6))
    }
    
    // MARK: - Overview UX integration
    
    @Test func overviewModeSurfacesBlocksPatternAndDiatonic() {
        let vm = FretboardViewModel()
        vm.setPatternType(.jumping)
        vm.enableOverviewMode()
        
        #expect(vm.isOverviewMode)
        #expect(vm.showBlocks)
        #expect(vm.showFullPattern)
        #expect(vm.showPatternOverlay)
        #expect(vm.patternType == .spiralMapping)
        #expect(vm.selectedBlockTypes == [.headBlock, .bridgeBlock, .tripleBlock])
        #expect(vm.selectedPattern?.type == .spiralMapping)
        #expect(!vm.blocks.isEmpty)
        #expect(!vm.diatonicPattern.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func demoPatternType(in lesson: Lesson?) -> PatternType? {
        guard let lesson else { return nil }
        for content in lesson.content {
            if case .fretboardDemo(let pattern) = content {
                return pattern.type
            }
        }
        return nil
    }
}
