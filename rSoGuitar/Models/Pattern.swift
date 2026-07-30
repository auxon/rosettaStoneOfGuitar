//
//  Pattern.swift
//  rSoGuitar
//
//  Pattern models for rSoGuitar concepts
//

import Foundation

// MARK: - Pattern

struct Pattern: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: PatternType
    let key: Key
    let positions: [FretboardPosition]
    let description: String
    /// Ordered musical edges (spiral path, triad outlines, hierarchy links).
    let connections: [PatternConnection]
    /// Grouped chord voicings for Family of Chords / Familial Hierarchy.
    let chordGroups: [ChordGroup]
    
    init(
        id: UUID = UUID(),
        name: String,
        type: PatternType,
        key: Key,
        positions: [FretboardPosition],
        description: String,
        connections: [PatternConnection] = [],
        chordGroups: [ChordGroup] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.key = key
        self.positions = positions
        self.description = description
        self.connections = connections
        self.chordGroups = chordGroups
    }
}

enum PatternType: String, Codable {
    case spiralMapping
    case jumping
    case familyOfChords
    case familialHierarchy
}

// MARK: - Fretboard Position

struct FretboardPosition: Identifiable, Codable, Equatable {
    let id: UUID
    let string: Int // 1-6 (1 = high E, 6 = low E)
    let fret: Int
    let note: Note
    let isRoot: Bool
    /// Scale degree index in the key (0 = I … 6 = vii), when known.
    let scaleDegree: Int?
    /// Functional role when this note belongs to a chord-family display.
    let chordRole: ChordRole?
    /// Block membership when derived from a HEAD/BRIDGE/TRIPLE overlay.
    let blockType: BlockType?
    let isTriadRoot: Bool
    let isTriadThird: Bool
    let isTriadFifth: Bool
    
    init(
        id: UUID = UUID(),
        string: Int,
        fret: Int,
        note: Note,
        isRoot: Bool = false,
        scaleDegree: Int? = nil,
        chordRole: ChordRole? = nil,
        blockType: BlockType? = nil,
        isTriadRoot: Bool = false,
        isTriadThird: Bool = false,
        isTriadFifth: Bool = false
    ) {
        self.id = id
        self.string = string
        self.fret = fret
        self.note = note
        self.isRoot = isRoot
        self.scaleDegree = scaleDegree
        self.chordRole = chordRole
        self.blockType = blockType
        self.isTriadRoot = isTriadRoot
        self.isTriadThird = isTriadThird
        self.isTriadFifth = isTriadFifth
    }
    
    /// Stable coordinate key (ignores UUID) for deduplication.
    var coordinateKey: String { "\(string),\(fret)" }
    
    static func == (lhs: FretboardPosition, rhs: FretboardPosition) -> Bool {
        lhs.string == rhs.string && lhs.fret == rhs.fret && lhs.note == rhs.note
    }
}

// MARK: - Chord Role / Connections / Groups

enum ChordRole: String, Codable, CaseIterable {
    case tonic
    case supertonic
    case mediant
    case subdominant
    case dominant
    case submediant
    case leadingTone
    
    static func from(degreeIndex: Int) -> ChordRole? {
        switch degreeIndex {
        case 0: return .tonic
        case 1: return .supertonic
        case 2: return .mediant
        case 3: return .subdominant
        case 4: return .dominant
        case 5: return .submediant
        case 6: return .leadingTone
        default: return nil
        }
    }
    
    /// Primary family roles for major/minor Family of Chords (I/i, IV/iv, V/v).
    static var primaryFamily: [ChordRole] { [.tonic, .subdominant, .dominant] }
}

enum ConnectionKind: String, Codable {
    case spiral
    case triad
    case hierarchy
    case jump
}

struct PatternConnection: Identifiable, Codable, Equatable {
    let id: UUID
    let fromString: Int
    let fromFret: Int
    let toString: Int
    let toFret: Int
    let kind: ConnectionKind
    
    init(
        id: UUID = UUID(),
        from: FretboardPosition,
        to: FretboardPosition,
        kind: ConnectionKind
    ) {
        self.id = id
        self.fromString = from.string
        self.fromFret = from.fret
        self.toString = to.string
        self.toFret = to.fret
        self.kind = kind
    }
    
    init(
        id: UUID = UUID(),
        fromString: Int,
        fromFret: Int,
        toString: Int,
        toFret: Int,
        kind: ConnectionKind
    ) {
        self.id = id
        self.fromString = fromString
        self.fromFret = fromFret
        self.toString = toString
        self.toFret = toFret
        self.kind = kind
    }
}

struct ChordGroup: Identifiable, Codable, Equatable {
    let id: UUID
    let romanNumeral: String
    let quality: ChordQuality
    let root: Note
    let scaleDegree: Int
    let chordRole: ChordRole?
    let positions: [FretboardPosition]
    let connections: [PatternConnection]
    
    init(
        id: UUID = UUID(),
        romanNumeral: String,
        quality: ChordQuality,
        root: Note,
        scaleDegree: Int,
        chordRole: ChordRole? = nil,
        positions: [FretboardPosition],
        connections: [PatternConnection] = []
    ) {
        self.id = id
        self.romanNumeral = romanNumeral
        self.quality = quality
        self.root = root
        self.scaleDegree = scaleDegree
        self.chordRole = chordRole ?? ChordRole.from(degreeIndex: scaleDegree)
        self.positions = positions
        self.connections = connections
    }
}

// MARK: - Blocks

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
    /// Anchor fret for the block's spacing template (lowest template fret).
    let anchorFret: Int
    /// Index in the HEAD → BRIDGE → TRIPLE repeating sequence (0-based).
    let sequenceIndex: Int
    
    init(
        id: UUID = UUID(),
        type: BlockType,
        name: String,
        description: String,
        fretRange: ClosedRange<Int>,
        stringRange: ClosedRange<Int>,
        positions: [FretboardPosition],
        anchorFret: Int? = nil,
        sequenceIndex: Int = 0
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.fretRange = fretRange
        self.stringRange = stringRange
        self.positions = positions
        self.anchorFret = anchorFret ?? fretRange.lowerBound
        self.sequenceIndex = sequenceIndex
    }
}
