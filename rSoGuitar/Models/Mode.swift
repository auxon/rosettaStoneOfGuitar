//
//  Mode.swift
//  rSoGuitar
//
//  Traditional musical modes model
//

import Foundation

enum Mode: String, CaseIterable, Codable {
    case ionian = "Ionian"          // I - Major scale
    case dorian = "Dorian"          // II - Minor with raised 6th
    case phrygian = "Phrygian"      // III - Minor with lowered 2nd
    case lydian = "Lydian"          // IV - Major with raised 4th
    case mixolydian = "Mixolydian"  // V - Major with lowered 7th
    case aeolian = "Aeolian"        // VI - Natural minor
    case locrian = "Locrian"        // VII - Diminished (lowered 2nd and 5th)
    
    var degree: Int {
        switch self {
        case .ionian: return 1
        case .dorian: return 2
        case .phrygian: return 3
        case .lydian: return 4
        case .mixolydian: return 5
        case .aeolian: return 6
        case .locrian: return 7
        }
    }
    
    var romanNumeral: String {
        switch self {
        case .ionian: return "I"
        case .dorian: return "II"
        case .phrygian: return "III"
        case .lydian: return "IV"
        case .mixolydian: return "V"
        case .aeolian: return "VI"
        case .locrian: return "VII"
        }
    }
    
    /// Intervals from the root in semitones for each mode
    var intervals: [Int] {
        switch self {
        case .ionian:     return [0, 2, 4, 5, 7, 9, 11]  // W-W-H-W-W-W-H
        case .dorian:     return [0, 2, 3, 5, 7, 9, 10]  // W-H-W-W-W-H-W
        case .phrygian:   return [0, 1, 3, 5, 7, 8, 10]  // H-W-W-W-H-W-W
        case .lydian:     return [0, 2, 4, 6, 7, 9, 11]  // W-W-W-H-W-W-H
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]  // W-W-H-W-W-H-W
        case .aeolian:    return [0, 2, 3, 5, 7, 8, 10]  // W-H-W-W-H-W-W
        case .locrian:    return [0, 1, 3, 5, 6, 8, 10]  // H-W-W-H-W-W-W
        }
    }
    
    /// Quality description (major, minor, diminished)
    var quality: String {
        switch self {
        case .ionian, .lydian, .mixolydian:
            return "Major"
        case .dorian, .phrygian, .aeolian:
            return "Minor"
        case .locrian:
            return "Diminished"
        }
    }
    
    /// Brief description of the mode's character
    var description: String {
        switch self {
        case .ionian:
            return "The standard major scale. Bright and happy."
        case .dorian:
            return "Minor with a raised 6th. Jazzy, sophisticated minor sound."
        case .phrygian:
            return "Minor with a flat 2nd. Spanish, exotic character."
        case .lydian:
            return "Major with a raised 4th. Dreamy, floating quality."
        case .mixolydian:
            return "Major with a flat 7th. Bluesy, rock feel."
        case .aeolian:
            return "Natural minor scale. Sad, melancholic."
        case .locrian:
            return "Diminished mode with flat 2nd and 5th. Unstable, tense."
        }
    }
    
    /// Characteristic note (the note that distinguishes this mode)
    var characteristicInterval: Int {
        switch self {
        case .ionian: return 4      // Major 3rd
        case .dorian: return 9      // Major 6th (in a minor context)
        case .phrygian: return 1    // Minor 2nd
        case .lydian: return 6      // Augmented 4th
        case .mixolydian: return 10 // Minor 7th
        case .aeolian: return 8     // Minor 6th
        case .locrian: return 6     // Diminished 5th
        }
    }
}

struct ModeShape: Identifiable {
    let id = UUID()
    let mode: Mode
    let rootNote: Note
    let positions: [FretboardPosition]
    let description: String
}

