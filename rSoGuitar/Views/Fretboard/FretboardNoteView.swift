//
//  FretboardNoteView.swift
//  rSoGuitar
//
//  Individual note view on the fretboard (SwiftUI, non-Canvas).
//  Sizing/colors align with FretboardRenderer / RSOGPalette.
//

import SwiftUI

struct FretboardNoteView: View {
    let position: FretboardPosition
    let isSelected: Bool
    let isHighlighted: Bool
    let isRoot: Bool
    var chordRole: ChordRole? = nil
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(noteColor)
            .frame(width: noteSize, height: noteSize)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .overlay(
                Text(position.note.rawValue)
                    .font(.caption2)
                    .foregroundColor(textColor)
            )
            .onTapGesture {
                onTap()
            }
    }
    
    private var noteColor: Color {
        if isSelected {
            return RSOGPalette.selectedNote
        } else if let role = chordRole ?? position.chordRole {
            return RSOGPalette.color(for: role).opacity(0.85)
        } else if isRoot || position.isTriadRoot {
            return Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.85)
        } else if isHighlighted {
            return RSOGPalette.diatonicNote.opacity(0.55)
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var strokeColor: Color {
        if isSelected {
            return RSOGPalette.selectedNote
        } else if isRoot || position.isTriadRoot {
            return .white.opacity(0.8)
        } else if isHighlighted {
            return .white.opacity(0.5)
        } else {
            return .gray
        }
    }
    
    private var strokeWidth: CGFloat {
        isSelected ? 3 : ((isRoot || position.isTriadRoot) ? 2 : 1)
    }
    
    private var noteSize: CGFloat {
        isSelected ? 24 : ((isRoot || position.isTriadRoot) ? 20 : 16)
    }
    
    private var textColor: Color {
        isSelected || isRoot || position.isTriadRoot ? .white : .primary
    }
}

#Preview {
    HStack {
        FretboardNoteView(
            position: FretboardPosition(string: 1, fret: 0, note: .E),
            isSelected: false,
            isHighlighted: false,
            isRoot: false,
            onTap: {}
        )
        FretboardNoteView(
            position: FretboardPosition(string: 2, fret: 1, note: .C, isRoot: true, isTriadRoot: true),
            isSelected: true,
            isHighlighted: false,
            isRoot: true,
            onTap: {}
        )
        FretboardNoteView(
            position: FretboardPosition(
                string: 3,
                fret: 0,
                note: .G,
                chordRole: .tonic,
                isTriadFifth: true
            ),
            isSelected: false,
            isHighlighted: true,
            isRoot: false,
            chordRole: .tonic,
            onTap: {}
        )
    }
    .padding()
}
