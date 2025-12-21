//
//  BlockOverlayView.swift
//  rSoGuitar
//
//  Overlay view for displaying blocks on the fretboard
//

import SwiftUI

struct BlockOverlayView: View {
    let blocks: [Block]
    let selectedBlockTypes: Set<BlockType>
    let fretboardSize: CGSize
    let fretWidth: CGFloat
    let stringSpacing: CGFloat
    let maxFret: Int
    
    var body: some View {
        Canvas { context, size in
            drawBlocks(context: context, size: size)
        }
    }
    
    private func drawBlocks(context: GraphicsContext, size: CGSize) {
        let fretWidth = size.width / CGFloat(maxFret + 1)
        let stringSpacing = size.height / CGFloat(Constants.numberOfStrings)
        
        for block in blocks {
            guard selectedBlockTypes.contains(block.type) else { continue }
            
            // Calculate block rectangle
            let startFret = CGFloat(block.fretRange.lowerBound)
            let endFret = CGFloat(block.fretRange.upperBound)
            let startX = startFret * fretWidth
            let endX = (endFret + 1) * fretWidth
            let startY = CGFloat(block.stringRange.lowerBound - 1) * stringSpacing
            let endY = CGFloat(block.stringRange.upperBound) * stringSpacing
            
            let blockRect = CGRect(
                x: startX,
                y: startY,
                width: endX - startX,
                height: endY - startY
            )
            
            // Draw block fill
            let fillColor = blockColor(block.type).opacity(0.2)
            var fillPath = Path()
            fillPath.addRect(blockRect)
            context.fill(
                fillPath,
                with: .color(fillColor)
            )
            
            // Draw block outline
            let outlineColor = blockColor(block.type)
            var outlinePath = Path()
            outlinePath.addRect(blockRect)
            context.stroke(
                outlinePath,
                with: .color(outlineColor),
                lineWidth: 3
            )
            
            // Draw block label
            let labelPoint = CGPoint(
                x: blockRect.midX,
                y: blockRect.minY + 15
            )
            let text = Text(block.name)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(outlineColor)
            context.draw(text, at: labelPoint)
        }
    }
    
    private func blockColor(_ type: BlockType) -> Color {
        switch type {
        case .headBlock:
            return .blue
        case .bridgeBlock:
            return .green
        case .tripleBlock:
            return .orange
        }
    }
}

#Preview {
    let blocks = BlockGenerator.allBlocks(for: .C)
    BlockOverlayView(
        blocks: blocks,
        selectedBlockTypes: [.headBlock, .bridgeBlock, .tripleBlock],
        fretboardSize: CGSize(width: 500, height: 200),
        fretWidth: 40,
        stringSpacing: 30,
        maxFret: 12
    )
}

