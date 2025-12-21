//
//  FretboardNote.swift
//  rSoGuitar
//
//  Represents a note on the fretboard
//

import Foundation

enum Note: String, Codable, CaseIterable {
    case C = "C"
    case CSharp = "C#"
    case D = "D"
    case DSharp = "D#"
    case E = "E"
    case F = "F"
    case FSharp = "F#"
    case G = "G"
    case GSharp = "G#"
    case A = "A"
    case ASharp = "A#"
    case B = "B"
    
    var semitonesFromC: Int {
        switch self {
        case .C: return 0
        case .CSharp: return 1
        case .D: return 2
        case .DSharp: return 3
        case .E: return 4
        case .F: return 5
        case .FSharp: return 6
        case .G: return 7
        case .GSharp: return 8
        case .A: return 9
        case .ASharp: return 10
        case .B: return 11
        }
    }
    
    func addingSemitones(_ semitones: Int) -> Note {
        let totalSemitones = (semitonesFromC + semitones) % 12
        return Note.allCases.first { $0.semitonesFromC == totalSemitones } ?? .C
    }
}

enum Key: String, Codable, CaseIterable {
    case C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B
    
    var rootNote: Note {
        switch self {
        case .C: return .C
        case .CSharp: return .CSharp
        case .D: return .D
        case .DSharp: return .DSharp
        case .E: return .E
        case .F: return .F
        case .FSharp: return .FSharp
        case .G: return .G
        case .GSharp: return .GSharp
        case .A: return .A
        case .ASharp: return .ASharp
        case .B: return .B
        }
    }
}

