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
    
    /// Major-scale intervals from the tonic.
    static let majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11]
    
    /// Get all notes in a key (major scale)
    static func notesInKey(_ key: Key) -> [Note] {
        majorScaleIntervals.map { key.rootNote.addingSemitones($0) }
    }
    
    /// Check if a note is in a given key
    static func isNoteInKey(_ note: Note, key: Key) -> Bool {
        notesInKey(key).contains(note)
    }
    
    /// Scale degree index (0–6) for a note in a major key, if diatonic.
    static func scaleDegree(of note: Note, in key: Key) -> Int? {
        let rootSemitones = key.rootNote.semitonesFromC
        let interval = (note.semitonesFromC - rootSemitones + 12) % 12
        return majorScaleIntervals.firstIndex(of: interval)
    }
    
    /// Enrich a position with scale-degree metadata for the given key.
    static func enrich(_ position: FretboardPosition, in key: Key) -> FretboardPosition {
        let degree = scaleDegree(of: position.note, in: key)
        return FretboardPosition(
            id: position.id,
            string: position.string,
            fret: position.fret,
            note: position.note,
            isRoot: position.note == key.rootNote,
            scaleDegree: degree ?? position.scaleDegree,
            chordRole: position.chordRole,
            blockType: position.blockType,
            isTriadRoot: position.isTriadRoot,
            isTriadThird: position.isTriadThird,
            isTriadFifth: position.isTriadFifth
        )
    }
    
    /// Calculate spiral mapping pattern for a given key (ordered path + connections).
    static func spiralMappingPattern(for key: Key, maxFret: Int = Constants.defaultFretCount) -> Pattern {
        PatternGenerator.spiralMappingPattern(for: key, maxFret: maxFret)
    }
}

