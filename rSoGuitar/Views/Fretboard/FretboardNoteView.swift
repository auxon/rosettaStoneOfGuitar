//
//  FretboardNoteView.swift
//  rSoGuitar
//
//  Individual note view on the fretboard
//

import SwiftUI

struct FretboardNoteView: View {
    let position: FretboardPosition
    let isSelected: Bool
    let isHighlighted: Bool
    let isRoot: Bool
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
            return .red
        } else if isRoot {
            return .blue.opacity(0.7)
        } else if isHighlighted {
            return .green.opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var strokeColor: Color {
        if isSelected {
            return .red
        } else if isRoot {
            return .blue
        } else if isHighlighted {
            return .green
        } else {
            return .gray
        }
    }
    
    private var strokeWidth: CGFloat {
        isSelected ? 3 : (isRoot ? 2 : 1)
    }
    
    private var noteSize: CGFloat {
        isSelected ? 24 : (isRoot ? 20 : 16)
    }
    
    private var textColor: Color {
        isSelected || isRoot ? .white : .primary
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
            position: FretboardPosition(string: 2, fret: 3, note: .G),
            isSelected: true,
            isHighlighted: false,
            isRoot: false,
            onTap: {}
        )
        FretboardNoteView(
            position: FretboardPosition(string: 3, fret: 0, note: .D),
            isSelected: false,
            isHighlighted: true,
            isRoot: true,
            onTap: {}
        )
    }
    .padding()
}

