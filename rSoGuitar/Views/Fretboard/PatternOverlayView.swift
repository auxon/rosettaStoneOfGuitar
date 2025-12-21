//
//  PatternOverlayView.swift
//  rSoGuitar
//
//  Overlay view for displaying patterns on the fretboard
//

import SwiftUI

struct PatternOverlayView: View {
    let pattern: Pattern
    let fretboardSize: CGSize
    let fretWidth: CGFloat
    let stringSpacing: CGFloat
    
    var body: some View {
        ZStack {
            // Draw pattern connections
            ForEach(Array(pattern.positions.enumerated()), id: \.element.id) { index, position in
                if index < pattern.positions.count - 1 {
                    let nextPosition = pattern.positions[index + 1]
                    drawConnection(from: position, to: nextPosition)
                }
            }
            
            // Draw pattern positions
            ForEach(pattern.positions) { position in
                Circle()
                    .fill(positionColor(position))
                    .frame(width: positionSize(position), height: positionSize(position))
                    .position(positionPoint(position))
            }
        }
    }
    
    private func positionPoint(_ position: FretboardPosition) -> CGPoint {
        let x = CGFloat(position.fret) * fretWidth + fretWidth / 2
        let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
        return CGPoint(x: x, y: y)
    }
    
    private func positionColor(_ position: FretboardPosition) -> Color {
        if position.isRoot {
            return .blue.opacity(0.7)
        } else {
            return .green.opacity(0.5)
        }
    }
    
    private func positionSize(_ position: FretboardPosition) -> CGFloat {
        position.isRoot ? 20 : 16
    }
    
    private func drawConnection(from: FretboardPosition, to: FretboardPosition) -> some View {
        Path { path in
            let startPoint = positionPoint(from)
            let endPoint = positionPoint(to)
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(Color.orange.opacity(0.4), lineWidth: 2)
    }
}

#Preview {
    let pattern = FretboardCalculator.spiralMappingPattern(for: .C)
    PatternOverlayView(
        pattern: pattern,
        fretboardSize: CGSize(width: 500, height: 200),
        fretWidth: 40,
        stringSpacing: 30
    )
}

