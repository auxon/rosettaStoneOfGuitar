//
//  FretboardCalculator.swift
//  rSoGuitar
//
//  Calculates note positions on the fretboard
//

import Foundation
import Combine

struct FretboardCalculator {
    // Standard tuning indexed by string number (1=high E, 6=low E)
    // String 1: E (high), String 2: B, String 3: G, String 4: D, String 5: A, String 6: E (low)
    static let standardTuning: [Note] = [.E, .B, .G, .D, .A, .E]
    
    /// Calculate the note at a specific string and fret position
    static func noteAt(string: Int, fret: Int, tuning: [Note] = standardTuning) -> Note {
        guard string >= 1 && string <= tuning.count else { return .C }
        let openStringNote = tuning[string - 1]
        return openStringNote.addingSemitones(fret)
    }
    
    /// Get all positions for a given note on the fretboard
    static func positionsFor(note: Note, maxFret: Int = Constants.defaultFretCount, tuning: [Note] = standardTuning) -> [FretboardPosition] {
        var positions: [FretboardPosition] = []
        
        for stringIndex in 0..<tuning.count {
            let stringNumber = stringIndex + 1
            let openNote = tuning[stringIndex]
            
            // Calculate how many semitones we need to add to reach the target note
            let targetSemitones = note.semitonesFromC
            let openSemitones = openNote.semitonesFromC
            var semitonesToAdd = targetSemitones - openSemitones
            
            if semitonesToAdd < 0 {
                semitonesToAdd += 12
            }
            
            if semitonesToAdd <= maxFret {
                positions.append(FretboardPosition(
                    string: stringNumber,
                    fret: semitonesToAdd,
                    note: note
                ))
            }
        }
        
        return positions
    }
    
    /// Get all notes in a key (major scale)
    static func notesInKey(_ key: Key) -> [Note] {
        let root = key.rootNote
        let majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11] // W-W-H-W-W-W-H
        
        return majorScaleIntervals.map { root.addingSemitones($0) }
    }
    
    /// Check if a note is in a given key
    static func isNoteInKey(_ note: Note, key: Key) -> Bool {
        notesInKey(key).contains(note)
    }
    
    /// Calculate spiral mapping pattern for a given key
    static func spiralMappingPattern(for key: Key, maxFret: Int = Constants.defaultFretCount) -> Pattern {
        let keyNotes = notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Spiral mapping follows a vertical pattern across strings
        for string in 1...Constants.numberOfStrings {
            for fret in 0...maxFret {
                let note = noteAt(string: string, fret: fret)
                if keyNotes.contains(note) {
                    let isRoot = note == key.rootNote
                    positions.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: isRoot
                    ))
                }
            }
        }
        
        return Pattern(
            name: "Spiral Mapping - \(key.rootNote.rawValue)",
            type: .spiralMapping,
            key: key,
            positions: positions,
            description: "The spiral mapping pattern shows all notes in the key of \(key.rootNote.rawValue) across the fretboard."
        )
    }
}

