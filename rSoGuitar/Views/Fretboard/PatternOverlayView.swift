//
//  PatternOverlayView.swift
//  rSoGuitar
//
//  Overlay view for displaying patterns on the fretboard.
//  Thin wrapper around FretboardRenderer.
//

import SwiftUI

struct PatternOverlayView: View {
    let pattern: Pattern
    let fretboardSize: CGSize
    let fretWidth: CGFloat
    let stringSpacing: CGFloat
    var labelOffset: CGFloat = 0
    var maxFret: Int = 12
    
    var body: some View {
        Canvas { context, size in
            var context = context
            let layout = FretboardLayout(
                maxFret: maxFret,
                fretWidth: fretWidth,
                stringSpacing: stringSpacing,
                labelOffset: labelOffset,
                size: size.width > 0 ? size : fretboardSize
            )
            FretboardRenderer.drawPattern(context: &context, layout: layout, pattern: pattern)
        }
        .frame(width: fretboardSize.width, height: fretboardSize.height)
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
