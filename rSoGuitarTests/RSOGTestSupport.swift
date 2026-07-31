//
//  RSOGTestSupport.swift
//  rSoGuitarTests
//
//  Shared helpers for Phase 6 validation.
//

import Foundation
@testable import rSoGuitar

enum RSOGTestSupport {
    
    static let referenceKeys: [Key] = [.C, .G, .D, .A, .F, .E]
    
    static func coordinateKeys(in positions: [FretboardPosition]) -> Set<String> {
        Set(positions.map(\.coordinateKey))
    }
    
    static func frets(on string: Int, in positions: [FretboardPosition]) -> [Int] {
        positions.filter { $0.string == string }.map(\.fret).sorted()
    }
    
    static func assertAllDiatonic(_ positions: [FretboardPosition], key: Key) -> Bool {
        let keyNotes = Set(FretboardCalculator.notesInKey(key))
        return positions.allSatisfy { keyNotes.contains($0.note) }
    }
    
    /// Compactness of a voicing: fret span across its positions.
    static func fretSpan(of positions: [FretboardPosition]) -> Int {
        let frets = positions.map(\.fret)
        guard let minF = frets.min(), let maxF = frets.max() else { return 0 }
        return maxF - minF
    }
    
    /// Average absolute string delta along hierarchy/triad connections.
    static func meanAbsoluteStringDelta(in connections: [PatternConnection]) -> Double {
        guard !connections.isEmpty else { return 0 }
        let total = connections.reduce(0) { $0 + abs($1.toString - $1.fromString) }
        return Double(total) / Double(connections.count)
    }
    
    static func meanAbsoluteFretDelta(in connections: [PatternConnection]) -> Double {
        guard !connections.isEmpty else { return 0 }
        let total = connections.reduce(0) { $0 + abs($1.toFret - $1.fromFret) }
        return Double(total) / Double(connections.count)
    }
}
