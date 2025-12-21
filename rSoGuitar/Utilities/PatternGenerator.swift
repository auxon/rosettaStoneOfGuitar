//
//  PatternGenerator.swift
//  rSoGuitar
//
//  Generates various rSoGuitar patterns
//

import Foundation
import Combine

struct PatternGenerator {
    /// Generate jumping pattern - shows valid horizontal movements
    static func jumpingPattern(from startPosition: FretboardPosition, in key: Key, maxFret: Int = Constants.defaultFretCount) -> Pattern {
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = [startPosition]
        
        // Jumping allows horizontal movement (same string, different frets)
        // that stay within the key
        let startNote = startPosition.note
        
        // Find valid jump positions on the same string
        for fret in 0...maxFret {
            if fret == startPosition.fret { continue }
            
            let note = FretboardCalculator.noteAt(string: startPosition.string, fret: fret)
            if keyNotes.contains(note) {
                let isRoot = note == key.rootNote
                positions.append(FretboardPosition(
                    string: startPosition.string,
                    fret: fret,
                    note: note,
                    isRoot: isRoot
                ))
            }
        }
        
        return Pattern(
            name: "Jumping Pattern - \(key.rootNote.rawValue)",
            type: .jumping,
            key: key,
            positions: positions,
            description: "Valid jump positions from the starting position, staying within the key."
        )
    }
    
    /// Generate family of chords pattern - shows all chord positions horizontally
    static func familyOfChordsPattern(for key: Key, chordQuality: ChordQuality = .major, maxFret: Int = Constants.defaultFretCount) -> Pattern {
        let rootNote = key.rootNote
        var positions: [FretboardPosition] = []
        
        // For major key, show I, IV, V chords (C, F, G in C major)
        let chordRoots: [Note]
        switch chordQuality {
        case .major:
            // I, IV, V
            chordRoots = [
                rootNote,
                rootNote.addingSemitones(5), // IV
                rootNote.addingSemitones(7)  // V
            ]
        case .minor:
            // i, iv, v
            chordRoots = [
                rootNote,
                rootNote.addingSemitones(5),
                rootNote.addingSemitones(7)
            ]
        default:
            chordRoots = [rootNote]
        }
        
        // Find positions for each chord root across the fretboard
        for chordRoot in chordRoots {
            let rootPositions = FretboardCalculator.positionsFor(note: chordRoot, maxFret: maxFret)
            positions.append(contentsOf: rootPositions.map { pos in
                FretboardPosition(
                    string: pos.string,
                    fret: pos.fret,
                    note: pos.note,
                    isRoot: true
                )
            })
        }
        
        return Pattern(
            name: "Family of Chords - \(key.rootNote.rawValue) \(chordQuality.rawValue)",
            type: .familyOfChords,
            key: key,
            positions: positions,
            description: "All available positions for the primary chords in the key of \(key.rootNote.rawValue)."
        )
    }
    
    /// Generate familial hierarchy pattern - shows vertical chord relationships
    static func familialHierarchyPattern(for key: Key, maxFret: Int = Constants.defaultFretCount) -> Pattern {
        let rootNote = key.rootNote
        var positions: [FretboardPosition] = []
        
        // Familial hierarchy shows chord relationships vertically
        // I, ii, iii, IV, V, vi, vii°
        let scaleDegrees: [(interval: Int, isMajor: Bool)] = [
            (0, true),   // I
            (2, false),  // ii
            (4, false),  // iii
            (5, true),   // IV
            (7, true),   // V
            (9, false), // vi
            (11, false) // vii°
        ]
        
        for (interval, _) in scaleDegrees {
            let chordRoot = rootNote.addingSemitones(interval)
            let rootPositions = FretboardCalculator.positionsFor(note: chordRoot, maxFret: maxFret)
            positions.append(contentsOf: rootPositions.map { pos in
                FretboardPosition(
                    string: pos.string,
                    fret: pos.fret,
                    note: pos.note,
                    isRoot: interval == 0 // Mark the I chord as root
                )
            })
        }
        
        return Pattern(
            name: "Familial Hierarchy - \(key.rootNote.rawValue)",
            type: .familialHierarchy,
            key: key,
            positions: positions,
            description: "The natural chord progression hierarchy in the key of \(key.rootNote.rawValue)."
        )
    }
}

