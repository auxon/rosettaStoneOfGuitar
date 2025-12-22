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
    let diatonicPattern: [FretboardPosition]
    let showFullPattern: Bool
    let fretboardSize: CGSize
    let fretWidth: CGFloat
    let stringSpacing: CGFloat
    let maxFret: Int
    
    var body: some View {
        Canvas { context, size in
            drawPatternAndBlocks(context: context, size: size)
        }
    }
    
    private func drawPatternAndBlocks(context: GraphicsContext, size: CGSize) {
        let fretWidth = size.width / CGFloat(maxFret + 1)
        let stringSpacing = size.height / CGFloat(Constants.numberOfStrings)
        
        // Draw full diatonic pattern if enabled
        if showFullPattern {
            drawDiatonicPattern(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw blocks by highlighting each note with a colored square
        for block in blocks {
            guard selectedBlockTypes.contains(block.type) else { continue }
            
            guard !block.positions.isEmpty else { continue }
            
            let color = blockColor(block.type)
            let squareSize: CGFloat = 16  // Size of the square highlight
            
            // Draw a colored square for each note in the block
            for position in block.positions {
                let x = CGFloat(position.fret) * fretWidth + fretWidth / 2
                let y = (CGFloat(Constants.numberOfStrings - position.string) + 0.5) * stringSpacing
                
                let squareRect = CGRect(
                    x: x - squareSize / 2,
                    y: y - squareSize / 2,
                    width: squareSize,
                    height: squareSize
                )
                
                // Draw filled square with the block's color
                var squarePath = Path()
                squarePath.addRect(squareRect)
                
                context.fill(squarePath, with: .color(color.opacity(0.6)))
                context.stroke(squarePath, with: .color(color), lineWidth: 2)
            }
            
            // Draw block label at the first note position
            if let firstPos = block.positions.first {
                let labelX = CGFloat(firstPos.fret) * fretWidth + fretWidth / 2
                let labelY = (CGFloat(Constants.numberOfStrings - firstPos.string) + 0.5) * stringSpacing - 20
                
                // Draw background rectangle for label
                let labelWidth = CGFloat(max(60, block.name.count * 7))
                let labelHeight: CGFloat = 18
                let labelRect = CGRect(
                    x: labelX - labelWidth / 2,
                    y: labelY - labelHeight / 2,
                    width: labelWidth,
                    height: labelHeight
                )
                
                var bgPath = Path()
                bgPath.addRoundedRect(in: labelRect, cornerSize: CGSize(width: 4, height: 4))
                context.fill(bgPath, with: .color(color.opacity(0.9)))
                context.stroke(bgPath, with: .color(color), lineWidth: 1)
                
                // Draw label text
                let text = Text(block.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                context.draw(text, at: CGPoint(x: labelX, y: labelY))
            }
        }
    }
    
    private func drawDiatonicPattern(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        // Draw all diatonic notes as light dots
        for position in diatonicPattern {
            let x = CGFloat(position.fret) * fretWidth + fretWidth / 2
            let y = (CGFloat(Constants.numberOfStrings - position.string) + 0.5) * stringSpacing
            
            let color: Color = position.isRoot ? .blue.opacity(0.2) : .gray.opacity(0.15)
            let radius: CGFloat = position.isRoot ? 6 : 4
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .color(color)
            )
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
    let pattern = BlockGenerator.diatonicPattern(for: .C)
    BlockOverlayView(
        blocks: blocks,
        selectedBlockTypes: [.headBlock, .bridgeBlock, .tripleBlock],
        diatonicPattern: pattern,
        showFullPattern: true,
        fretboardSize: CGSize(width: 500, height: 200),
        fretWidth: 40,
        stringSpacing: 30,
        maxFret: 12
    )
}

