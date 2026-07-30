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
    private let maxDisplayFret = 12
    
    private var blocks: [Block] {
        BlockGenerator.allBlocks(for: pattern.key, maxFret: maxDisplayFret)
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
            
            if !pattern.chordGroups.isEmpty {
                chordLegend
            }
            
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
                    fretboardBackground
                    
                    if showBlocks && !selectedBlockTypes.isEmpty {
                        blockOverlay
                    }
                    
                    patternOverlay
                    
                    notePositions
                }
                .frame(
                    minWidth: CGFloat(maxDisplayFret + 1) * fretWidth,
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
    
    // MARK: - Legend
    
    private var chordLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pattern.chordGroups) { group in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(RSOGPalette.color(for: group))
                            .frame(width: 10, height: 10)
                        Text(group.romanNumeral)
                            .font(.caption.weight(.semibold))
                        Text(group.root.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSOGPalette.color(for: group).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Blocks
    
    private var blockOverlay: some View {
        Canvas { context, size in
            for block in blocks {
                guard selectedBlockTypes.contains(block.type) else { continue }
                
                for position in block.positions where position.fret <= maxDisplayFret {
                    let point = positionPoint(position)
                    let color = blockColor(block.type)
                    let radius: CGFloat = 12
                    
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: point.x - radius,
                            y: point.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .color(color.opacity(0.4))
                    )
                    
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: point.x - radius,
                            y: point.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .color(color),
                        lineWidth: 3
                    )
                }
                
                if let firstPos = block.positions.first {
                    let labelPoint = CGPoint(
                        x: positionPoint(firstPos).x,
                        y: positionPoint(firstPos).y - 20
                    )
                    let text = Text(block.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(blockColor(block.type))
                    context.draw(text, at: labelPoint)
                }
            }
        }
    }
    
    private func blockColor(_ type: BlockType) -> Color {
        switch type {
        case .headBlock: return .blue
        case .bridgeBlock: return .green
        case .tripleBlock: return .orange
        }
    }
    
    // MARK: - Fretboard
    
    private var fretboardBackground: some View {
        Canvas { context, size in
            for fret in 0...maxDisplayFret {
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
            
            // String 1 (high E) at top — matches FretboardView
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
    
    // MARK: - Pattern Overlay
    
    private var patternOverlay: some View {
        Canvas { context, _ in
            // Meaningful musical connections (not raw array order)
            let connections = pattern.connections.isEmpty
                ? legacySequentialConnections()
                : pattern.connections
            
            for connection in connections {
                let from = CGPoint(
                    x: CGFloat(connection.fromFret) * fretWidth + fretWidth / 2,
                    y: (CGFloat(connection.fromString - 1) + 0.5) * stringSpacing
                )
                let to = CGPoint(
                    x: CGFloat(connection.toFret) * fretWidth + fretWidth / 2,
                    y: (CGFloat(connection.toString - 1) + 0.5) * stringSpacing
                )
                
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(
                    path,
                    with: .color(RSOGPalette.connectionColor(for: connection.kind)),
                    lineWidth: connection.kind == .spiral ? 2 : 1.5
                )
            }
            
            // Chord-group positions (colored by role) or flat pattern positions
            if pattern.chordGroups.isEmpty {
                for position in pattern.positions where position.fret <= maxDisplayFret {
                    drawNote(position, color: positionColor(position), in: &context)
                }
            } else {
                for group in pattern.chordGroups {
                    let color = RSOGPalette.color(for: group)
                    for position in group.positions where position.fret <= maxDisplayFret {
                        drawNote(position, color: color, in: &context)
                    }
                    
                    // Roman numeral at the lowest-string root of the first voicing cluster
                    if let labelPos = group.positions
                        .filter({ $0.isTriadRoot || $0.isRoot })
                        .sorted(by: { $0.fret < $1.fret || ($0.fret == $1.fret && $0.string > $1.string) })
                        .first
                        ?? group.positions.sorted(by: { $0.fret < $1.fret }).first
                    {
                        let point = positionPoint(labelPos)
                        let label = Text(group.romanNumeral)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        let bgWidth = CGFloat(max(18, group.romanNumeral.count * 8))
                        let bgRect = CGRect(
                            x: point.x - bgWidth / 2,
                            y: point.y - 22,
                            width: bgWidth,
                            height: 14
                        )
                        var bg = Path()
                        bg.addRoundedRect(in: bgRect, cornerSize: CGSize(width: 3, height: 3))
                        context.fill(bg, with: .color(color.opacity(0.9)))
                        context.draw(label, at: CGPoint(x: point.x, y: point.y - 15))
                    }
                }
            }
        }
    }
    
    private func drawNote(_ position: FretboardPosition, color: Color, in context: inout GraphicsContext) {
        let point = positionPoint(position)
        let radius: CGFloat = (position.isTriadRoot || position.isRoot) ? 10 : 7
        
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(color.opacity(0.85))
        )
        context.stroke(
            Path(ellipseIn: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(.white.opacity(0.7)),
            lineWidth: 1
        )
    }
    
    private func legacySequentialConnections() -> [PatternConnection] {
        var result: [PatternConnection] = []
        let positions = pattern.positions
        guard positions.count > 1 else { return result }
        for i in 0..<(positions.count - 1) {
            result.append(PatternConnection(
                from: positions[i],
                to: positions[i + 1],
                kind: .spiral
            ))
        }
        return result
    }
    
    private var notePositions: some View {
        ZStack {
            ForEach(pattern.positions.filter { $0.fret <= maxDisplayFret }) { position in
                Circle()
                    .fill(selectedPosition?.coordinateKey == position.coordinateKey ? Color.red.opacity(0.5) : Color.clear)
                    .frame(width: 24, height: 24)
                    .position(positionPoint(position))
                    .onTapGesture {
                        selectedPosition = position
                        audioService.playNote(position.note)
                    }
            }
        }
    }
    
    /// String 1 (high E) at top — matches FretboardView.
    private func positionPoint(_ position: FretboardPosition) -> CGPoint {
        let x = CGFloat(position.fret) * fretWidth + fretWidth / 2
        let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
        return CGPoint(x: x, y: y)
    }
    
    private func positionColor(_ position: FretboardPosition) -> Color {
        if let role = position.chordRole {
            return RSOGPalette.color(for: role)
        }
        if position.isRoot {
            return .blue.opacity(0.7)
        }
        return .green.opacity(0.5)
    }
    
    private func handleTap(at location: CGPoint) {
        let fret = Int(location.x / fretWidth)
        let string = Int(location.y / stringSpacing) + 1
        
        guard fret >= 0 && fret <= maxDisplayFret &&
              string >= 1 && string <= Constants.numberOfStrings else {
            return
        }
        
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
