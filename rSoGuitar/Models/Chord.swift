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
    let scaleDegree: Int?
    let romanNumeral: String?
    let chordRole: ChordRole?
    
    init(
        id: UUID = UUID(),
        name: String,
        rootNote: Note,
        quality: ChordQuality,
        positions: [FretboardPosition],
        description: String,
        scaleDegree: Int? = nil,
        romanNumeral: String? = nil,
        chordRole: ChordRole? = nil
    ) {
        self.id = id
        self.name = name
        self.rootNote = rootNote
        self.quality = quality
        self.positions = positions
        self.description = description
        self.scaleDegree = scaleDegree
        self.romanNumeral = romanNumeral
        self.chordRole = chordRole
    }
    
    /// Chord tones for this quality (root, third, fifth).
    var chordTones: (root: Note, third: Note, fifth: Note) {
        let thirdInterval: Int
        let fifthInterval: Int
        switch quality {
        case .minor, .diminished, .min7:
            thirdInterval = 3
        default:
            thirdInterval = 4
        }
        switch quality {
        case .diminished:
            fifthInterval = 6
        case .augmented:
            fifthInterval = 8
        default:
            fifthInterval = 7
        }
        return (
            rootNote,
            rootNote.addingSemitones(thirdInterval),
            rootNote.addingSemitones(fifthInterval)
        )
    }
    
    /// Build a diatonic triad chord from an rSoG scale degree.
    static func diatonic(
        degree: RSOGScaleDegree,
        in key: Key,
        positions: [FretboardPosition] = []
    ) -> Chord {
        let tones = degree.chordTones(in: key)
        let qualityName: String
        switch degree.quality {
        case .major: qualityName = "major"
        case .minor: qualityName = "minor"
        case .diminished: qualityName = "diminished"
        default: qualityName = degree.quality.rawValue
        }
        
        return Chord(
            name: "\(tones.root.rawValue) \(qualityName)",
            rootNote: tones.root,
            quality: degree.quality,
            positions: positions,
            description: "\(degree.romanNumeral) — \(tones.root.rawValue) \(qualityName) in \(key.rootNote.rawValue) major",
            scaleDegree: degree.degreeIndex,
            romanNumeral: degree.romanNumeral,
            chordRole: ChordRole.from(degreeIndex: degree.degreeIndex)
        )
    }
    
    /// Convert this chord into a `ChordGroup` for pattern display.
    func asChordGroup(connections: [PatternConnection] = []) -> ChordGroup {
        ChordGroup(
            romanNumeral: romanNumeral ?? rootNote.rawValue,
            quality: quality,
            root: rootNote,
            scaleDegree: scaleDegree ?? 0,
            chordRole: chordRole,
            positions: positions,
            connections: connections
        )
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
