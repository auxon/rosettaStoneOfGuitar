//
//  CAGEDGenerator.swift
//  rSoGuitar
//
//  Generates CAGED chord shapes for the fretboard
//

import Foundation

struct CAGEDGenerator {
    /// Generate all CAGED forms for a given root note
    /// Returns all CAGED shapes positioned on the fretboard for the root note
    static func allCAGEDForms(for rootNote: Note, maxFret: Int = 24) -> [CAGEDShape] {
        var shapes: [CAGEDShape] = []
        
        // Calculate chord tones for major chord
        let third = rootNote.addingSemitones(4)  // Major 3rd
        let fifth = rootNote.addingSemitones(7)   // Perfect 5th
        
        // Generate each CAGED form - each form can return multiple shapes
        for form in CAGEDForm.allCases {
            let formShapes = generateShapes(
                form: form,
                rootNote: rootNote,
                third: third,
                fifth: fifth,
                maxFret: maxFret
            )
            shapes.append(contentsOf: formShapes)
        }
        
        return shapes
    }
    
    /// Generate all instances of a specific CAGED form
    private static func generateShapes(
        form: CAGEDForm,
        rootNote: Note,
        third: Note,
        fifth: Note,
        maxFret: Int
    ) -> [CAGEDShape] {
        var shapes: [CAGEDShape] = []
        
        // Find all root positions on the primary string for this form
        let primaryString = primaryStringForForm(form)
        
        for fret in 0...maxFret {
            let note = FretboardCalculator.noteAt(string: primaryString, fret: fret)
            if note == rootNote {
                let rootPos = FretboardPosition(string: primaryString, fret: fret, note: rootNote, isRoot: true)
                if let shape = generateShapeAt(form: form, rootNote: rootNote, third: third, fifth: fifth, rootPosition: rootPos, maxFret: maxFret) {
                    shapes.append(shape)
                }
            }
        }
        
        return shapes
    }
    
    /// Get the primary string for each CAGED form (where the main root note is)
    private static func primaryStringForForm(_ form: CAGEDForm) -> Int {
        switch form {
        case .C: return 5  // A string
        case .A: return 5  // A string
        case .G: return 6  // Low E string
        case .E: return 6  // Low E string
        case .D: return 4  // D string
        }
    }
    
    /// Generate a single CAGED shape at a specific root position
    private static func generateShapeAt(
        form: CAGEDForm,
        rootNote: Note,
        third: Note,
        fifth: Note,
        rootPosition: FretboardPosition,
        maxFret: Int
    ) -> CAGEDShape? {
        let rootFret = rootPosition.fret
        var positions: [FretboardPosition] = [rootPosition]
        
        // Get the pattern offsets for this form
        let offsets = patternOffsetsForForm(form)
        
        // Build the chord shape by finding notes at the pattern positions
        for (string, expectedOffset, chordTone) in offsets {
            let targetFret = rootFret + expectedOffset
            
            // Skip if fret is out of range
            guard targetFret >= 0 && targetFret <= maxFret else { continue }
            
            // Determine which note we're looking for
            let targetNote: Note
            let isRoot: Bool
            switch chordTone {
            case .root:
                targetNote = rootNote
                isRoot = true
            case .third:
                targetNote = third
                isRoot = false
            case .fifth:
                targetNote = fifth
                isRoot = false
            }
            
            // Verify the note at this position matches what we expect
            let actualNote = FretboardCalculator.noteAt(string: string, fret: targetFret)
            if actualNote == targetNote {
                positions.append(FretboardPosition(string: string, fret: targetFret, note: targetNote, isRoot: isRoot))
            }
        }
        
        // Return shape if we found at least 3 notes (triad minimum)
        guard positions.count >= 3 else { return nil }
        
        return CAGEDShape(
            form: form,
            rootNote: rootNote,
            rootPosition: rootPosition,
            positions: positions,
            description: descriptionForForm(form)
        )
    }
    
    /// Chord tone identifier
    private enum ChordTone {
        case root, third, fifth
    }
    
    /// Get pattern offsets for each CAGED form
    /// Returns tuples of (string, fretOffset from root, chordTone)
    /// These are based on the standard open chord shapes
    private static func patternOffsetsForForm(_ form: CAGEDForm) -> [(Int, Int, ChordTone)] {
        switch form {
        case .C:
            // Open C: X-3-2-0-1-0 (strings 6-1, low to high)
            // Root on string 5 (A string)
            // Pattern relative to root at fret 3 on string 5:
            // String 4: E at fret 2 (root - 1), which is 3rd
            // String 3: G at fret 0 (root - 3), which is 5th (for C major: G)
            // String 2: C at fret 1 (root - 2), which is root
            // String 1: E at fret 0 (root - 3), which is 3rd
            return [
                (4, -1, .third),  // String 4 (D string): 3rd
                (3, -3, .fifth),  // String 3 (G string): 5th
                (2, -2, .root),   // String 2 (B string): root
                (1, -3, .third),  // String 1 (high E): 3rd
            ]
            
        case .A:
            // Open A: X-0-2-2-2-0 (strings 6-1, low to high)
            // Root on string 5 (A string) at fret 0
            // Pattern relative to root:
            // String 4: E at fret 2 (root + 2), which is 5th (for A: E)
            // String 3: A at fret 2 (root + 2), which is root
            // String 2: C# at fret 2 (root + 2), which is 3rd
            // String 1: E at fret 0 (root + 0), which is 5th
            return [
                (4, +2, .fifth),  // String 4 (D string): 5th
                (3, +2, .root),   // String 3 (G string): root
                (2, +2, .third),  // String 2 (B string): 3rd
                (1, +0, .fifth),  // String 1 (high E): 5th
            ]
            
        case .G:
            // Open G: 3-2-0-0-0-3 (strings 6-1, low to high)
            // Root on string 6 (low E string) at fret 3
            // Pattern relative to root:
            // String 5: B at fret 2 (root - 1), which is 3rd
            // String 4: D at fret 0 (root - 3), open D = 5th
            // String 3: G at fret 0 (root - 3), open G = root
            // String 2: B at fret 0 (root - 3), open B = 3rd
            // String 1: G at fret 3 (root + 0), which is root
            return [
                (5, -1, .third),  // String 5 (A string): 3rd
                (4, -3, .fifth),  // String 4 (D string): 5th
                (3, -3, .root),   // String 3 (G string): root
                (2, -3, .third),  // String 2 (B string): 3rd
                (1, +0, .root),   // String 1 (high E): root
            ]
            
        case .E:
            // Open E: 0-2-2-1-0-0 (strings 6-1, low to high)
            // Root on string 6 (low E string) at fret 0
            // Pattern relative to root:
            // String 5: B at fret 2 (root + 2), which is 5th
            // String 4: E at fret 2 (root + 2), which is root
            // String 3: G# at fret 1 (root + 1), which is 3rd
            // String 2: B at fret 0 (root + 0), which is 5th
            // String 1: E at fret 0 (root + 0), which is root
            return [
                (5, +2, .fifth),  // String 5 (A string): 5th
                (4, +2, .root),   // String 4 (D string): root
                (3, +1, .third),  // String 3 (G string): 3rd
                (2, +0, .fifth),  // String 2 (B string): 5th
                (1, +0, .root),   // String 1 (high E): root
            ]
            
        case .D:
            // Open D: X-X-0-2-3-2 (strings 6-1, low to high)
            // Root on string 4 (D string) at fret 0
            // Pattern relative to root:
            // String 3: F# at fret 2 (root + 2), which is 3rd
            // String 2: A at fret 3 (root + 3), which is 5th
            // String 1: D at fret 2 (root + 2), which is root
            return [
                (3, +2, .third),  // String 3 (G string): 3rd
                (2, +3, .fifth),  // String 2 (B string): 5th
                (1, +2, .root),   // String 1 (high E): root
            ]
        }
    }
    
    /// Get description for each form
    private static func descriptionForForm(_ form: CAGEDForm) -> String {
        switch form {
        case .C:
            return "C shape: Root on string 5 (A string). Classic open C chord shape, movable up the neck."
        case .A:
            return "A shape: Root on string 5 (A string). Classic open A chord shape, commonly barred."
        case .G:
            return "G shape: Root on string 6 (low E string). Classic open G chord shape."
        case .E:
            return "E shape: Root on string 6 (low E string). Classic open E chord shape, commonly barred."
        case .D:
            return "D shape: Root on string 4 (D string). Classic open D chord shape."
        }
    }
}
