//
//  FretboardViewModel.swift
//  rSoGuitar
//
//  ViewModel for fretboard interaction
//

import Foundation
import SwiftUI
import Combine

class FretboardViewModel: ObservableObject {
    @Published var selectedKey: Key = .C
    @Published var selectedPattern: Pattern?
    @Published var selectedPosition: FretboardPosition?
    @Published var highlightedPositions: [FretboardPosition] = []
    @Published var showPatternOverlay = false
    @Published var patternType: PatternType = .spiralMapping
    @Published var maxFret: Int = Constants.defaultFretCount
    @Published var showBlocks: Bool = false
    @Published var selectedBlockTypes: Set<BlockType> = []
    @Published var blocks: [Block] = []
    @Published var showFullPattern: Bool = false
    @Published var diatonicPattern: [FretboardPosition] = []
    @Published var blockOffsets: [UUID: CGSize] = [:]  // Track drag offsets for each block
    @Published var draggedBlockId: UUID? = nil  // Currently dragged block
    @Published var showInfiniteBassPattern: Bool = false
    @Published var infiniteBassPattern: [FretboardPosition] = []
    @Published var patternOffsetFret: Int = 0  // Fret offset for shifting the pattern
    @Published var patternOffsetString: Int = 0  // String offset for shifting the pattern
    @Published var extendedStringCount: Int = 12  // Show 6 strings above and below (total 18 strings visible)
    @Published var showCAGED: Bool = false
    @Published var cagedShapes: [CAGEDShape] = []
    @Published var selectedCAGEDForms: Set<CAGEDForm> = []
    @Published var isSoundEnabled: Bool = true
    @Published var volume: Float = 0.7
    
    var patternOffset: (fret: Int, string: Int) {
        (patternOffsetFret, patternOffsetString)
    }
    
    private let audioService = AudioService.shared
    private let contentService = ContentService.shared
    
    var audioServicePublisher: AudioService {
        audioService
    }
    
    init() {
        updateBlocks()
        updateDiatonicPattern()
        updateInfiniteBassPattern()
        updateCAGEDShapes()
    }
    
    func selectKey(_ key: Key) {
        selectedKey = key
        if showPatternOverlay {
            updatePattern()
        }
        updateBlocks()
        updateDiatonicPattern()
        // Always update CAGED shapes when key changes, even if not currently showing
        updateCAGEDShapes()
    }
    
    func selectPosition(_ position: FretboardPosition) {
        selectedPosition = position
        // Play the note at the correct octave based on string/fret position
        audioService.playNoteAt(string: position.string, fret: position.fret)
    }
    
    // MARK: - Audio Control
    
    func toggleSound() {
        isSoundEnabled.toggle()
        audioService.isSoundEnabled = isSoundEnabled
    }
    
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioService.setVolume(newVolume)
    }
    
    func playSelectedNotes() {
        // Play all highlighted/selected positions
        if !highlightedPositions.isEmpty {
            audioService.playNotes(highlightedPositions)
        } else if let selected = selectedPosition {
            audioService.playNoteAt(string: selected.string, fret: selected.fret)
        }
    }
    
    func togglePatternOverlay() {
        showPatternOverlay.toggle()
        if showPatternOverlay {
            updatePattern()
        } else {
            highlightedPositions = []
        }
    }
    
    func setPatternType(_ type: PatternType) {
        patternType = type
        if showPatternOverlay {
            updatePattern()
        }
    }
    
    func updatePattern() {
        if let startPos = selectedPosition, patternType == .jumping {
            selectedPattern = contentService.generatePattern(
                type: patternType,
                key: selectedKey,
                startPosition: startPos
            )
        } else {
            selectedPattern = contentService.generatePattern(
                type: patternType,
                key: selectedKey
            )
        }
        
        highlightedPositions = selectedPattern?.positions ?? []
    }
    
    func clearSelection() {
        selectedPosition = nil
        highlightedPositions = []
        showPatternOverlay = false
    }
    
    func getNoteAt(string: Int, fret: Int) -> Note {
        return FretboardCalculator.noteAt(string: string, fret: fret)
    }
    
    func isPositionHighlighted(_ position: FretboardPosition) -> Bool {
        highlightedPositions.contains { $0.string == position.string && $0.fret == position.fret }
    }
    
    func isPositionSelected(_ position: FretboardPosition) -> Bool {
        selectedPosition?.string == position.string && selectedPosition?.fret == position.fret
    }
    
    // MARK: - Block Methods
    
    func toggleBlocks() {
        showBlocks.toggle()
        if !showBlocks {
            selectedBlockTypes.removeAll()
        } else if selectedBlockTypes.isEmpty {
            // If showing blocks but none selected, select all
            selectedBlockTypes = [.headBlock, .bridgeBlock, .tripleBlock]
        }
    }
    
    func toggleBlock(_ type: BlockType) {
        if selectedBlockTypes.contains(type) {
            selectedBlockTypes.remove(type)
        } else {
            selectedBlockTypes.insert(type)
        }
        showBlocks = !selectedBlockTypes.isEmpty
    }
    
    func updateBlocks() {
        // Start with triple block as default (can be changed to start from any block type)
        blocks = BlockGenerator.allBlocks(for: selectedKey, maxFret: maxFret, startBlockType: .tripleBlock)
    }
    
    func updateDiatonicPattern() {
        diatonicPattern = BlockGenerator.diatonicPattern(for: selectedKey, maxFret: maxFret)
        updateInfiniteBassPattern()
    }
    
    func updateInfiniteBassPattern() {
        // Generate the infinite bass pattern that extends beyond the 6 strings
        // The pattern continues the diatonic scale pattern infinitely in both directions
        infiniteBassPattern = BlockGenerator.infiniteBassPattern(
            for: selectedKey,
            maxFret: maxFret,
            stringOffset: patternOffsetString,
            fretOffset: patternOffsetFret,
            extendedStringCount: extendedStringCount
        )
    }
    
    func shiftPattern(fretDelta: Int, stringDelta: Int) {
        patternOffsetFret += fretDelta
        patternOffsetString += stringDelta
        updateInfiniteBassPattern()
        updateBlocks()  // Update blocks based on new pattern position
    }
    
    func toggleInfiniteBassPattern() {
        showInfiniteBassPattern.toggle()
        if showInfiniteBassPattern {
            updateInfiniteBassPattern()
        }
    }
    
    func toggleFullPattern() {
        showFullPattern.toggle()
        if showFullPattern {
            updateDiatonicPattern()
        }
    }
    
    func isPositionInBlock(_ position: FretboardPosition, blockType: BlockType) -> Bool {
        return blocks.contains { block in
            block.type == blockType && block.positions.contains { blockPos in
                blockPos.string == position.string && blockPos.fret == position.fret
            }
        }
    }
    
    func getBlock(for position: FretboardPosition) -> BlockType? {
        return blocks.first { block in
            block.positions.contains { blockPos in
                blockPos.string == position.string && blockPos.fret == position.fret
            }
        }?.type
    }
    
    func isPositionInDiatonicPattern(_ position: FretboardPosition) -> Bool {
        return diatonicPattern.contains { patternPos in
            patternPos.string == position.string && patternPos.fret == position.fret
        }
    }
    
    // MARK: - Block Dragging
    
    func startDraggingBlock(_ blockId: UUID) {
        draggedBlockId = blockId
        if blockOffsets[blockId] == nil {
            blockOffsets[blockId] = .zero
        }
    }
    
    func updateBlockDrag(_ blockId: UUID, offset: CGSize) {
        blockOffsets[blockId] = offset
    }
    
    func endDraggingBlock(_ blockId: UUID, fretWidth: CGFloat, stringSpacing: CGFloat) {
        guard let offset = blockOffsets[blockId] else { return }
        
        // Find the block being dragged
        guard let blockIndex = blocks.firstIndex(where: { $0.id == blockId }) else {
            blockOffsets[blockId] = .zero
            draggedBlockId = nil
            return
        }
        
        let oldBlock = blocks[blockIndex]
        
        // Convert pixel offset to fret/string deltas
        let fretDelta = Int(round(offset.width / fretWidth))
        let stringDelta = Int(round(-offset.height / stringSpacing))  // Negative because y increases downward
        
        // Calculate the new starting position (use the first note as the anchor)
        guard let firstPos = oldBlock.positions.first else {
            blockOffsets[blockId] = .zero
            draggedBlockId = nil
            return
        }
        
        let newStartFret = max(0, min(maxFret, firstPos.fret + fretDelta))
        let newStartString = max(1, min(Constants.numberOfStrings, firstPos.string + stringDelta))
        let newStartNote = FretboardCalculator.noteAt(string: newStartString, fret: newStartFret)
        let newStartPosition = FretboardPosition(
            string: newStartString,
            fret: newStartFret,
            note: newStartNote,
            isRoot: newStartNote == selectedKey.rootNote
        )
        
        // Rebuild the block pattern from the new starting position
        // Get the current diatonic pattern
        let pattern = BlockGenerator.diatonicPattern(for: selectedKey, maxFret: maxFret)
        var patternMap: [String: FretboardPosition] = [:]
        for pos in pattern {
            patternMap["\(pos.string),\(pos.fret)"] = pos
        }
        
        // Rebuild the block starting from the new position
        let rebuiltBlock: Block?
        switch oldBlock.type {
        case .headBlock:
            rebuiltBlock = BlockGenerator.identifyHeadBlock(
                startingFrom: newStartPosition,
                patternMap: patternMap,
                key: selectedKey,
                maxFret: maxFret
            )
        case .bridgeBlock:
            rebuiltBlock = BlockGenerator.identifyBridgeBlock(
                startingFrom: newStartPosition,
                patternMap: patternMap,
                key: selectedKey,
                maxFret: maxFret
            )
        case .tripleBlock:
            rebuiltBlock = BlockGenerator.identifyTripleBlock(
                startingFrom: newStartPosition,
                patternMap: patternMap,
                key: selectedKey,
                maxFret: maxFret
            )
        }
        
        // Update the block if we successfully rebuilt it
        if let rebuilt = rebuiltBlock {
            blocks[blockIndex] = Block(
                id: oldBlock.id,  // Keep the same ID
                type: rebuilt.type,
                name: rebuilt.name,
                description: rebuilt.description,
                fretRange: rebuilt.fretRange,
                stringRange: rebuilt.stringRange,
                positions: rebuilt.positions
            )
        }
        
        // Reset the offset
        blockOffsets[blockId] = .zero
        draggedBlockId = nil
    }
    
    func getBlockOffset(_ blockId: UUID) -> CGSize {
        return blockOffsets[blockId] ?? .zero
    }
    
    // MARK: - CAGED Methods
    
    func updateCAGEDShapes() {
        cagedShapes = CAGEDGenerator.allCAGEDForms(for: selectedKey.rootNote, maxFret: maxFret)
    }
    
    func toggleCAGED() {
        showCAGED.toggle()
        if showCAGED {
            updateCAGEDShapes()
            if selectedCAGEDForms.isEmpty {
                // If showing CAGED but none selected, select all
                selectedCAGEDForms = Set(CAGEDForm.allCases)
            }
        }
    }
    
    func toggleCAGEDForm(_ form: CAGEDForm) {
        if selectedCAGEDForms.contains(form) {
            selectedCAGEDForms.remove(form)
        } else {
            selectedCAGEDForms.insert(form)
        }
        showCAGED = !selectedCAGEDForms.isEmpty
        // Ensure shapes are up to date when toggling forms
        if showCAGED {
            updateCAGEDShapes()
        }
    }
}

