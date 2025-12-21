//
//  PatternView.swift
//  rSoGuitar
//
//  View for displaying patterns on the fretboard
//

import SwiftUI

struct PatternView: View {
    let pattern: Pattern
    @State private var fretWidth: CGFloat = 40
    @State private var stringSpacing: CGFloat = 30
    @State private var selectedPosition: FretboardPosition?
    @State private var showBlocks: Bool = false
    @State private var selectedBlockTypes: Set<BlockType> = []
    
    private let audioService = AudioService.shared
    private var blocks: [Block] {
        BlockGenerator.allBlocks(for: pattern.key, maxFret: 12)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Pattern info
            HStack {
                Text(pattern.name)
                    .font(.headline)
                Spacer()
                Text("\(pattern.positions.count) positions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Block toggle
            Toggle("Show Blocks", isOn: $showBlocks)
                .padding(.horizontal)
                .onChange(of: showBlocks) { _, newValue in
                    if newValue && selectedBlockTypes.isEmpty {
                        selectedBlockTypes = [.headBlock, .bridgeBlock, .tripleBlock]
                    } else if !newValue {
                        selectedBlockTypes.removeAll()
                    }
                }
            
            // Fretboard with pattern
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    // Draw fretboard background
                    fretboardBackground
                    
                    // Draw block overlay if enabled (behind pattern)
                    if showBlocks && !selectedBlockTypes.isEmpty {
                        blockOverlay
                    }
                    
                    // Draw pattern overlay
                    patternOverlay
                    
                    // Draw note positions
                    notePositions
                }
                .frame(
                    minWidth: CGFloat(12 + 1) * fretWidth,
                    minHeight: CGFloat(Constants.numberOfStrings) * stringSpacing
                )
                .padding()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleTap(at: value.location)
                    }
            )
        }
    }
    
    private var blockOverlay: some View {
        Canvas { context, size in
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
    
    private var fretboardBackground: some View {
        Canvas { context, size in
            // Draw frets
            for fret in 0...12 {
                let x = CGFloat(fret) * fretWidth
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(.gray),
                    lineWidth: fret == 0 ? 3 : 1
                )
            }
            
            // Draw strings
            for string in 1...Constants.numberOfStrings {
                let y = (CGFloat(string - 1) + 0.5) * stringSpacing
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(.gray),
                    lineWidth: 1
                )
            }
        }
    }
    
    private var patternOverlay: some View {
        ZStack {
            // Draw connections between pattern positions
            ForEach(Array(pattern.positions.enumerated()), id: \.element.id) { index, position in
                if index < pattern.positions.count - 1 {
                    let nextPosition = pattern.positions[index + 1]
                    Path { path in
                        let startPoint = positionPoint(position)
                        let endPoint = positionPoint(nextPosition)
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.orange.opacity(0.4), lineWidth: 2)
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
    
    private var notePositions: some View {
        ZStack {
            ForEach(pattern.positions) { position in
                Circle()
                    .fill(selectedPosition?.id == position.id ? Color.red : Color.clear)
                    .frame(width: 24, height: 24)
                    .position(positionPoint(position))
                    .onTapGesture {
                        selectedPosition = position
                        audioService.playNote(position.note)
                    }
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
    
    private func handleTap(at location: CGPoint) {
        // Calculate which position was tapped
        let fret = Int(location.x / fretWidth)
        let string = Int(location.y / stringSpacing) + 1
        
        guard fret >= 0 && fret <= 12 &&
              string >= 1 && string <= Constants.numberOfStrings else {
            return
        }
        
        // Find matching position in pattern
        if let position = pattern.positions.first(where: { $0.string == string && $0.fret == fret }) {
            selectedPosition = position
            audioService.playNote(position.note)
        }
    }
}

#Preview {
    let pattern = FretboardCalculator.spiralMappingPattern(for: .C)
    PatternView(pattern: pattern)
}

