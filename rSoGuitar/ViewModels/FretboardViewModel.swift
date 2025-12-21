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
    
    private let audioService = AudioService.shared
    private let contentService = ContentService.shared
    
    init() {
        updateBlocks()
    }
    
    func selectKey(_ key: Key) {
        selectedKey = key
        if showPatternOverlay {
            updatePattern()
        }
        updateBlocks()
    }
    
    func selectPosition(_ position: FretboardPosition) {
        selectedPosition = position
        audioService.playNote(position.note)
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
        blocks = BlockGenerator.allBlocks(for: selectedKey, maxFret: maxFret)
    }
    
    func isPositionInBlock(_ position: FretboardPosition, blockType: BlockType) -> Bool {
        guard let block = blocks.first(where: { $0.type == blockType }) else { return false }
        return block.fretRange.contains(position.fret) && 
               block.stringRange.contains(position.string)
    }
    
    func getBlock(for position: FretboardPosition) -> BlockType? {
        return blocks.first { block in
            block.fretRange.contains(position.fret) && 
            block.stringRange.contains(position.string)
        }?.type
    }
}

