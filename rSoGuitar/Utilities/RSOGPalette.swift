//
//  RSOGPalette.swift
//  rSoGuitar
//
//  Shared colors for rSoG chord-family and pattern displays.
//

import SwiftUI

enum RSOGPalette {
    
    /// Color for a chord role / scale degree in family & hierarchy views.
    static func color(for role: ChordRole?) -> Color {
        switch role {
        case .tonic:        return Color(red: 0.25, green: 0.55, blue: 1.0)   // blue — I
        case .subdominant:  return Color(red: 0.25, green: 0.85, blue: 0.45)  // green — IV
        case .dominant:     return Color(red: 1.0, green: 0.55, blue: 0.15)   // orange — V
        case .supertonic:   return Color(red: 0.2, green: 0.75, blue: 0.8)    // teal — ii
        case .mediant:      return Color(red: 0.65, green: 0.45, blue: 0.9)   // violet — iii
        case .submediant:   return Color(red: 0.95, green: 0.4, blue: 0.65)   // rose — vi
        case .leadingTone:  return Color(red: 0.55, green: 0.55, blue: 0.6)   // gray — vii°
        case .none:         return Color(red: 0.3, green: 0.9, blue: 0.4)
        }
    }
    
    static func color(forDegreeIndex index: Int) -> Color {
        color(for: ChordRole.from(degreeIndex: index))
    }
    
    static func color(for group: ChordGroup) -> Color {
        color(for: group.chordRole) 
    }
    
    static func connectionColor(for kind: ConnectionKind) -> Color {
        switch kind {
        case .spiral:     return Color.orange.opacity(0.55)
        case .triad:      return Color.white.opacity(0.45)
        case .hierarchy:  return Color.cyan.opacity(0.5)
        case .jump:       return Color.yellow.opacity(0.5)
        }
    }
    
    /// Block overlay colors (HEAD / BRIDGE / TRIPLE).
    static func blockColor(_ type: BlockType) -> Color {
        switch type {
        case .headBlock:
            return Color(red: 0.4, green: 0.8, blue: 1.0)   // sky blue
        case .bridgeBlock:
            return Color(red: 0.4, green: 1.0, blue: 0.6)   // mint
        case .tripleBlock:
            return Color(red: 1.0, green: 0.7, blue: 0.3)   // amber
        }
    }
    
    static let diatonicRoot = Color(red: 0.3, green: 0.9, blue: 0.4)
    static let diatonicNote = Color(red: 0.3, green: 0.9, blue: 0.4)
    static let selectedNote = Color(red: 1.0, green: 0.3, blue: 0.3)
}
