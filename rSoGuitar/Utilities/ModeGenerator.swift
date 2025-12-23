//
//  ModeGenerator.swift
//  rSoGuitar
//
//  Generates mode patterns for the fretboard
//

import Foundation

struct ModeGenerator {
    
    /// Generate all positions for a mode across the fretboard
    static func generateMode(
        _ mode: Mode,
        rootNote: Note,
        maxFret: Int = 24
    ) -> ModeShape {
        var positions: [FretboardPosition] = []
        
        // Get the notes in this mode
        let modeNotes = notesInMode(mode, rootNote: rootNote)
        
        // Find all occurrences of these notes on the fretboard
        for string in 1...Constants.numberOfStrings {
            for fret in 0...maxFret {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if modeNotes.contains(note) {
                    positions.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == rootNote
                    ))
                }
            }
        }
        
        return ModeShape(
            mode: mode,
            rootNote: rootNote,
            positions: positions,
            description: mode.description
        )
    }
    
    /// Generate a single-position mode shape (3 notes per string pattern)
    static func generateModePosition(
        _ mode: Mode,
        rootNote: Note,
        startFret: Int,
        maxFret: Int = 24
    ) -> ModeShape {
        var positions: [FretboardPosition] = []
        let modeNotes = notesInMode(mode, rootNote: rootNote)
        
        // Generate a box pattern around the start fret
        let fretRange = max(0, startFret - 2)...min(maxFret, startFret + 4)
        
        for string in 1...Constants.numberOfStrings {
            var notesOnString: [FretboardPosition] = []
            
            for fret in fretRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
                if modeNotes.contains(note) {
                    notesOnString.append(FretboardPosition(
                        string: string,
                        fret: fret,
                        note: note,
                        isRoot: note == rootNote
                    ))
                }
            }
            
            // Take up to 3 notes per string for standard mode shape
            positions.append(contentsOf: notesOnString.prefix(3))
        }
        
        return ModeShape(
            mode: mode,
            rootNote: rootNote,
            positions: positions,
            description: "\(mode.rawValue) position at fret \(startFret)"
        )
    }
    
    /// Get all notes in a mode starting from a root note
    static func notesInMode(_ mode: Mode, rootNote: Note) -> Set<Note> {
        var notes: Set<Note> = []
        
        for interval in mode.intervals {
            let note = rootNote.addingSemitones(interval)
            notes.insert(note)
        }
        
        return notes
    }
    
    /// Generate all 7 modes for a given parent major scale
    static func allModesFromParent(parentKey: Key, maxFret: Int = 24) -> [ModeShape] {
        var shapes: [ModeShape] = []
        
        // Get the notes in the parent major scale
        let parentNotes = FretboardCalculator.notesInKey(parentKey)
        let parentNotesArray = Array(parentNotes).sorted { $0.semitonesFromC < $1.semitonesFromC }
        
        // Generate each mode starting on each scale degree
        for (index, mode) in Mode.allCases.enumerated() {
            // The root of each mode is the (index)th note of the parent scale
            let modeRoot = parentNotesArray[index % parentNotesArray.count]
            let shape = generateMode(mode, rootNote: modeRoot, maxFret: maxFret)
            shapes.append(shape)
        }
        
        return shapes
    }
    
    /// Generate a mode starting from any root note
    static func modeFromRoot(_ mode: Mode, rootNote: Note, maxFret: Int = 24) -> ModeShape {
        return generateMode(mode, rootNote: rootNote, maxFret: maxFret)
    }
    
    /// Get scale degree names for a mode
    static func scaleDegreeNames(for mode: Mode) -> [String] {
        switch mode {
        case .ionian:
            return ["1", "2", "3", "4", "5", "6", "7"]
        case .dorian:
            return ["1", "2", "♭3", "4", "5", "6", "♭7"]
        case .phrygian:
            return ["1", "♭2", "♭3", "4", "5", "♭6", "♭7"]
        case .lydian:
            return ["1", "2", "3", "♯4", "5", "6", "7"]
        case .mixolydian:
            return ["1", "2", "3", "4", "5", "6", "♭7"]
        case .aeolian:
            return ["1", "2", "♭3", "4", "5", "♭6", "♭7"]
        case .locrian:
            return ["1", "♭2", "♭3", "4", "♭5", "♭6", "♭7"]
        }
    }
    
    /// Get the interval name for a note in a mode
    static func intervalName(for note: Note, in mode: Mode, rootNote: Note) -> String {
        let semitones = (note.semitonesFromC - rootNote.semitonesFromC + 12) % 12
        
        if let index = mode.intervals.firstIndex(of: semitones) {
            return scaleDegreeNames(for: mode)[index]
        }
        
        return ""
    }
}

