//
//  RSOGConceptInfoTests.swift
//  rSoGuitarTests
//
//  Phase 5: concept presets and defaults.
//

import Testing
@testable import rSoGuitar

struct RSOGConceptInfoTests {
    
    @Test func demoBlocksMatchTeachingEmphasis() {
        #expect(RSOGConceptInfo.demoBlocks(for: .spiralMapping) == [.headBlock])
        #expect(RSOGConceptInfo.demoBlocks(for: .jumping) == [.bridgeBlock])
        #expect(RSOGConceptInfo.demoBlocks(for: .familyOfChords).contains(.tripleBlock))
        #expect(RSOGConceptInfo.demoBlocks(for: .familialHierarchy) == [.tripleBlock])
    }
    
    @Test func overviewSuggestedBlocksIncludeAllMilestones() {
        let blocks = RSOGConceptInfo.suggestedBlocks(for: .spiralMapping)
        #expect(blocks.contains(.headBlock))
        #expect(blocks.contains(.bridgeBlock))
        #expect(blocks.contains(.tripleBlock))
    }
    
    @Test func fretboardDefaultsAreRSOGFirst() {
        let vm = FretboardViewModel()
        #expect(vm.showBlocks)
        #expect(vm.showFullPattern)
        #expect(vm.showPatternOverlay)
        #expect(vm.patternType == .spiralMapping)
        #expect(vm.isOverviewMode)
        #expect(vm.selectedBlockTypes == [.headBlock, .bridgeBlock, .tripleBlock])
        #expect(vm.selectedPattern != nil)
    }
    
    @Test func selectingConceptExitsOverviewAndEmphasizesBlocks() {
        let vm = FretboardViewModel()
        vm.setPatternType(.jumping)
        #expect(!vm.isOverviewMode)
        #expect(vm.patternType == .jumping)
        #expect(vm.selectedBlockTypes.contains(.bridgeBlock))
        #expect(vm.showPatternOverlay)
    }
    
    @Test func enableOverviewRestoresFullStack() {
        let vm = FretboardViewModel()
        vm.setPatternType(.familialHierarchy)
        vm.enableOverviewMode()
        #expect(vm.isOverviewMode)
        #expect(vm.patternType == .spiralMapping)
        #expect(vm.selectedBlockTypes == [.headBlock, .bridgeBlock, .tripleBlock])
        #expect(vm.showFullPattern)
        #expect(vm.showPatternOverlay)
    }
    
    @Test func inspectingBlockSurfacesDetailPayload() {
        let vm = FretboardViewModel()
        let head = vm.blocks.first { $0.type == .headBlock }
        #expect(head != nil)
        vm.inspectBlock(head)
        #expect(vm.inspectedBlock?.type == .headBlock)
        #expect(!(vm.inspectedBlock?.positions.isEmpty ?? true))
        vm.inspectBlock(nil)
        #expect(vm.inspectedBlock == nil)
    }
}
