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
        Canvas { context, _ in
            drawConnections(context: &context)
            drawPositions(context: &context)
            drawChordLabels(context: &context)
        }
        .frame(width: fretboardSize.width, height: fretboardSize.height)
    }
    
    private func point(string: Int, fret: Int) -> CGPoint {
        // String 1 (high E) at top
        CGPoint(
            x: CGFloat(fret) * fretWidth + fretWidth / 2,
            y: (CGFloat(string - 1) + 0.5) * stringSpacing
        )
    }
    
    private func drawConnections(context: inout GraphicsContext) {
        let connections = pattern.connections
        for connection in connections {
            let from = point(string: connection.fromString, fret: connection.fromFret)
            let to = point(string: connection.toString, fret: connection.toFret)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            context.stroke(
                path,
                with: .color(RSOGPalette.connectionColor(for: connection.kind)),
                lineWidth: 2
            )
        }
    }
    
    private func drawPositions(context: inout GraphicsContext) {
        if pattern.chordGroups.isEmpty {
            for position in pattern.positions {
                let color: Color = position.isRoot
                    ? .blue.opacity(0.7)
                    : RSOGPalette.color(for: position.chordRole).opacity(0.55)
                fillNote(position, color: color, context: &context)
            }
        } else {
            for group in pattern.chordGroups {
                let color = RSOGPalette.color(for: group)
                for position in group.positions {
                    fillNote(position, color: color, context: &context)
                }
            }
        }
    }
    
    private func fillNote(_ position: FretboardPosition, color: Color, context: inout GraphicsContext) {
        let p = point(string: position.string, fret: position.fret)
        let radius: CGFloat = (position.isTriadRoot || position.isRoot) ? 10 : 7
        context.fill(
            Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(color.opacity(0.85))
        )
    }
    
    private func drawChordLabels(context: inout GraphicsContext) {
        for group in pattern.chordGroups {
            guard let labelPos = group.positions
                .filter({ $0.isTriadRoot || $0.isRoot })
                .sorted(by: { $0.fret < $1.fret })
                .first
            else { continue }
            
            let p = point(string: labelPos.string, fret: labelPos.fret)
            let color = RSOGPalette.color(for: group)
            let text = Text(group.romanNumeral)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            let width = CGFloat(max(18, group.romanNumeral.count * 8))
            let rect = CGRect(x: p.x - width / 2, y: p.y - 22, width: width, height: 14)
            var bg = Path()
            bg.addRoundedRect(in: rect, cornerSize: CGSize(width: 3, height: 3))
            context.fill(bg, with: .color(color.opacity(0.9)))
            context.draw(text, at: CGPoint(x: p.x, y: p.y - 15))
        }
    }
}

#Preview {
    let pattern = PatternGenerator.familyOfChordsPattern(for: .C, maxFret: 12)
    PatternOverlayView(
        pattern: pattern,
        fretboardSize: CGSize(width: 500, height: 200),
        fretWidth: 40,
        stringSpacing: 30
    )
}
