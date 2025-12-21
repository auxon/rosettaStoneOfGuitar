//
//  BlockGenerator.swift
//  rSoGuitar
//
//  Generates block overlays for the fretboard
//

import Foundation

struct BlockGenerator {
    /// Generate HEAD block - lower frets (0-4)
    static func headBlock(for key: Key, maxFret: Int = 12) -> Block {
        let fretRange = 0...4
        let stringRange = 1...6
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Find all notes in key within the HEAD block fret range
        for string in stringRange {
            for fret in fretRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
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
        
        return Block(
            type: .headBlock,
            name: "HEAD",
            description: "The HEAD block contains the foundational notes of the key in the lower frets (0-4).",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    /// Generate BRIDGE block - middle frets (5-9), also called tail block
    static func bridgeBlock(for key: Key, maxFret: Int = 12) -> Block {
        let fretRange = 5...9
        let stringRange = 1...6
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Find all notes in key within the BRIDGE block fret range
        for string in stringRange {
            for fret in fretRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
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
        
        return Block(
            type: .bridgeBlock,
            name: "BRIDGE",
            description: "The BRIDGE block (also called tail block) is the middle region (frets 5-9) where jumping rules help navigate horizontally.",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    /// Generate TRIPLE BLOCK - higher frets (10-12+)
    static func tripleBlock(for key: Key, maxFret: Int = 12) -> Block {
        let fretRange = 10...maxFret
        let stringRange = 1...6
        let keyNotes = FretboardCalculator.notesInKey(key)
        var positions: [FretboardPosition] = []
        
        // Find all notes in key within the TRIPLE BLOCK fret range
        for string in stringRange {
            for fret in fretRange {
                let note = FretboardCalculator.noteAt(string: string, fret: fret)
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
        
        return Block(
            type: .tripleBlock,
            name: "TRIPLE BLOCK",
            description: "The TRIPLE BLOCK covers the higher frets (10+) and contains extended range notes in the key.",
            fretRange: fretRange,
            stringRange: stringRange,
            positions: positions
        )
    }
    
    /// Generate all three blocks for a key
    static func allBlocks(for key: Key, maxFret: Int = 12) -> [Block] {
        return [
            headBlock(for: key, maxFret: maxFret),
            bridgeBlock(for: key, maxFret: maxFret),
            tripleBlock(for: key, maxFret: maxFret)
        ]
    }
}

