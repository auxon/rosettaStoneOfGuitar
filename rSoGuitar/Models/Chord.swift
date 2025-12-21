//
//  Chord.swift
//  rSoGuitar
//
//  Chord model and definitions
//

import Foundation

struct Chord: Identifiable, Codable {
    let id: UUID
    let name: String
    let rootNote: Note
    let quality: ChordQuality
    let positions: [FretboardPosition]
    let description: String
    
    init(id: UUID = UUID(), name: String, rootNote: Note, quality: ChordQuality, positions: [FretboardPosition], description: String) {
        self.id = id
        self.name = name
        self.rootNote = rootNote
        self.quality = quality
        self.positions = positions
        self.description = description
    }
}

enum ChordQuality: String, Codable {
    case major
    case minor
    case dominant
    case diminished
    case augmented
    case sus2
    case sus4
    case add9
    case maj7
    case min7
    case dom7
}

