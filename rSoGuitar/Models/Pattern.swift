//
//  Pattern.swift
//  rSoGuitar
//
//  Pattern models for rSoGuitar concepts
//

import Foundation

struct Pattern: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: PatternType
    let key: Key
    let positions: [FretboardPosition]
    let description: String
    
    init(id: UUID = UUID(), name: String, type: PatternType, key: Key, positions: [FretboardPosition], description: String) {
        self.id = id
        self.name = name
        self.type = type
        self.key = key
        self.positions = positions
        self.description = description
    }
}

enum PatternType: String, Codable {
    case spiralMapping
    case jumping
    case familyOfChords
    case familialHierarchy
}

struct FretboardPosition: Identifiable, Codable {
    let id: UUID
    let string: Int // 1-6 (1 = high E, 6 = low E)
    let fret: Int
    let note: Note
    let isRoot: Bool
    
    init(id: UUID = UUID(), string: Int, fret: Int, note: Note, isRoot: Bool = false) {
        self.id = id
        self.string = string
        self.fret = fret
        self.note = note
        self.isRoot = isRoot
    }
}

enum BlockType: String, Codable {
    case headBlock = "HEAD"
    case bridgeBlock = "BRIDGE"  // Also referred to as tail block
    case tripleBlock = "TRIPLE BLOCK"
}

struct Block: Identifiable {
    let id: UUID
    let type: BlockType
    let name: String
    let description: String
    let fretRange: ClosedRange<Int>
    let stringRange: ClosedRange<Int>  // Typically 1-6 for all strings
    let positions: [FretboardPosition]  // Notes in key that fall within this block
    
    init(id: UUID = UUID(), type: BlockType, name: String, description: String, fretRange: ClosedRange<Int>, stringRange: ClosedRange<Int>, positions: [FretboardPosition]) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.fretRange = fretRange
        self.stringRange = stringRange
        self.positions = positions
    }
}

