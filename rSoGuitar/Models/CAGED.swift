//
//  CAGED.swift
//  rSoGuitar
//
//  CAGED system models for guitar chord shapes
//

import Foundation

enum CAGEDForm: String, Codable, CaseIterable {
    case C = "C"
    case A = "A"
    case G = "G"
    case E = "E"
    case D = "D"
    
    var displayName: String {
        return rawValue
    }
}

struct CAGEDShape: Identifiable {
    let id: UUID
    let form: CAGEDForm
    let rootNote: Note
    let rootPosition: FretboardPosition  // The root note position for this shape
    let positions: [FretboardPosition]  // All notes in the chord shape
    let description: String
    
    init(id: UUID = UUID(), form: CAGEDForm, rootNote: Note, rootPosition: FretboardPosition, positions: [FretboardPosition], description: String) {
        self.id = id
        self.form = form
        self.rootNote = rootNote
        self.rootPosition = rootPosition
        self.positions = positions
        self.description = description
    }
}

