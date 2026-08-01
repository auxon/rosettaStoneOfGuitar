//
//  BlockOverlayView.swift
//  rSoGuitar
//
//  Overlay view for displaying HEAD / BRIDGE / TRIPLE blocks.
//  Thin wrapper around FretboardRenderer.
//

import SwiftUI

struct BlockOverlayView: View {
    let blocks: [Block]
    let selectedBlockTypes: Set<BlockType>
    let diatonicPattern: [FretboardPosition]
    let showFullPattern: Bool
    let fretboardSize: CGSize
    let fretWidth: CGFloat
    let stringSpacing: CGFloat
    let maxFret: Int
    var labelOffset: CGFloat = 0
    var blockOffsets: [UUID: CGSize] = [:]
    
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
            
            if showFullPattern {
                FretboardRenderer.drawDiatonicPattern(
                    context: &context,
                    layout: layout,
                    positions: diatonicPattern
                )
            }
            
            FretboardRenderer.drawBlocks(
                context: &context,
                layout: layout,
                blocks: blocks,
                selectedTypes: selectedBlockTypes,
                offsets: blockOffsets,
                showOutlines: true,
                showNotePips: true,
                showLabels: true
            )
        }
        .frame(width: fretboardSize.width, height: fretboardSize.height)
    }
}

#Preview {
    let blocks = BlockGenerator.allBlocks(for: .C, maxFret: 12)
    let pattern = BlockGenerator.diatonicPattern(for: .C, maxFret: 12)
    BlockOverlayView(
        blocks: blocks,
        selectedBlockTypes: [.headBlock, .bridgeBlock, .tripleBlock],
        diatonicPattern: pattern,
        showFullPattern: true,
        fretboardSize: CGSize(width: 520, height: 200),
        fretWidth: 40,
        stringSpacing: 30,
        maxFret: 12
    )
}
