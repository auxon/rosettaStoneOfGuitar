//
//  FretboardRenderer.swift
//  rSoGuitar
//
//  Shared fretboard geometry and Canvas drawing for rSoG overlays.
//  Coordinate system: string 1 (high E) at top, string 6 (low E) at bottom.
//

import SwiftUI

// MARK: - Layout

struct FretboardLayout: Equatable {
    var maxFret: Int
    var fretWidth: CGFloat
    var stringSpacing: CGFloat
    var labelOffset: CGFloat
    var stringCount: Int
    var size: CGSize
    
    init(
        maxFret: Int,
        fretWidth: CGFloat,
        stringSpacing: CGFloat,
        labelOffset: CGFloat = 24,
        stringCount: Int = Constants.numberOfStrings,
        size: CGSize = .zero
    ) {
        self.maxFret = maxFret
        self.fretWidth = fretWidth
        self.stringSpacing = stringSpacing
        self.labelOffset = labelOffset
        self.stringCount = stringCount
        self.size = size
    }
    
    /// Convenience: derive cell sizes from a canvas size.
    static func fitting(
        size: CGSize,
        maxFret: Int,
        stringCount: Int = Constants.numberOfStrings,
        labelOffset: CGFloat = 24
    ) -> FretboardLayout {
        let usableWidth = max(1, size.width - labelOffset)
        let fretWidth = usableWidth / CGFloat(maxFret + 1)
        let stringSpacing = size.height / CGFloat(stringCount)
        return FretboardLayout(
            maxFret: maxFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: labelOffset,
            stringCount: stringCount,
            size: size
        )
    }
    
    /// X center of a fret column.
    func fretCenterX(_ fret: Int) -> CGFloat {
        CGFloat(fret) * fretWidth + fretWidth / 2 + labelOffset
    }
    
    /// Left edge of a fret column (nut / fret wire).
    func fretLineX(_ fret: Int) -> CGFloat {
        CGFloat(fret) * fretWidth + labelOffset
    }
    
    /// Y of a string. String 1 (high E) is at the top.
    func stringY(_ string: Int) -> CGFloat {
        (CGFloat(string - 1) + 0.5) * stringSpacing
    }
    
    func point(string: Int, fret: Int, offset: CGSize = .zero) -> CGPoint {
        CGPoint(
            x: fretCenterX(fret) + offset.width,
            y: stringY(string) + offset.height
        )
    }
    
    func point(for position: FretboardPosition, offset: CGSize = .zero) -> CGPoint {
        point(string: position.string, fret: position.fret, offset: offset)
    }
    
    /// Hit-test a canvas location → (string, fret), if in range.
    func hitTest(at location: CGPoint) -> (string: Int, fret: Int)? {
        let adjustedX = location.x - labelOffset
        guard adjustedX >= 0 else { return nil }
        let fret = Int(adjustedX / fretWidth)
        let string = Int(location.y / stringSpacing) + 1
        guard fret >= 0 && fret <= maxFret,
              string >= 1 && string <= stringCount else {
            return nil
        }
        return (string, fret)
    }
    
    /// Bounding rect covering a block's string/fret ranges (padded).
    func regionRect(
        stringRange: ClosedRange<Int>,
        fretRange: ClosedRange<Int>,
        offset: CGSize = .zero,
        padding: CGFloat = 8
    ) -> CGRect {
        let top = stringY(stringRange.lowerBound) - stringSpacing / 2 + offset.height
        let bottom = stringY(stringRange.upperBound) + stringSpacing / 2 + offset.height
        let left = fretLineX(fretRange.lowerBound) - padding + offset.width
        let right = fretLineX(fretRange.upperBound) + fretWidth + padding + offset.width
        return CGRect(x: left, y: top, width: max(0, right - left), height: max(0, bottom - top))
    }
}

// MARK: - Renderer

enum FretboardRenderer {
    
    // MARK: Grid
    
    static func drawGrid(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        drawFrets: Bool = true,
        drawStrings: Bool = true
    ) {
        if drawFrets {
            for fret in 0...layout.maxFret {
                let x = layout.fretLineX(fret)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: layout.size.height > 0 ? layout.size.height : CGFloat(layout.stringCount) * layout.stringSpacing))
                context.stroke(path, with: .color(.gray), lineWidth: fret == 0 ? 3 : 1)
            }
        }
        
        if drawStrings {
            let width = layout.size.width > 0
                ? layout.size.width
                : layout.labelOffset + CGFloat(layout.maxFret + 1) * layout.fretWidth
            for string in 1...layout.stringCount {
                let y = layout.stringY(string)
                var path = Path()
                path.move(to: CGPoint(x: layout.labelOffset, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
                context.stroke(path, with: .color(.gray), lineWidth: 1.5)
            }
        }
    }
    
    // MARK: Diatonic
    
    static func drawDiatonicPattern(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        positions: [FretboardPosition]
    ) {
        for position in positions where position.fret <= layout.maxFret {
            let p = layout.point(for: position)
            let radius: CGFloat = position.isRoot ? 6 : 5
            let color = position.isRoot
                ? RSOGPalette.diatonicRoot.opacity(0.7)
                : RSOGPalette.diatonicNote.opacity(0.45)
            fillCircle(context: &context, center: p, radius: radius, color: color)
        }
    }
    
    // MARK: Blocks
    
    /// Draw HEAD / BRIDGE / TRIPLE overlays with region fills, note markers,
    /// spacing ticks (XX-X / X-XX), fret-span brackets, and labels.
    static func drawBlocks(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        blocks: [Block],
        selectedTypes: Set<BlockType>,
        offsets: [UUID: CGSize] = [:],
        showRegions: Bool = true,
        showSpacingMarkers: Bool = true,
        showBrackets: Bool = true
    ) {
        for block in blocks {
            guard selectedTypes.contains(block.type) else { continue }
            guard !block.positions.isEmpty else { continue }
            
            let offset = offsets[block.id] ?? .zero
            let color = RSOGPalette.blockColor(block.type)
            let visiblePositions = block.positions.filter { $0.fret <= layout.maxFret }
            guard !visiblePositions.isEmpty else { continue }
            
            if showRegions {
                drawBlockRegion(
                    context: &context,
                    layout: layout,
                    block: block,
                    color: color,
                    offset: offset
                )
            }
            
            if showBrackets {
                drawBlockBracket(
                    context: &context,
                    layout: layout,
                    block: block,
                    color: color,
                    offset: offset
                )
            }
            
            // Note markers
            let markerSize: CGFloat = block.type == .tripleBlock ? 14 : 16
            for position in visiblePositions {
                let p = layout.point(for: position, offset: offset)
                let rect = CGRect(
                    x: p.x - markerSize / 2,
                    y: p.y - markerSize / 2,
                    width: markerSize,
                    height: markerSize
                )
                if block.type == .tripleBlock {
                    // Circles emphasize triad dots within the TRIPLE.
                    fillCircle(context: &context, center: p, radius: markerSize / 2, color: color.opacity(0.65))
                    strokeCircle(context: &context, center: p, radius: markerSize / 2, color: color, lineWidth: 2)
                } else {
                    var square = Path()
                    square.addRect(rect)
                    context.fill(square, with: .color(color.opacity(0.65)))
                    context.stroke(square, with: .color(color), lineWidth: 2)
                }
            }
            
            if showSpacingMarkers {
                drawSpacingMarkers(
                    context: &context,
                    layout: layout,
                    block: block,
                    color: color,
                    offset: offset
                )
            }
            
            drawBlockLabel(
                context: &context,
                layout: layout,
                block: block,
                color: color,
                offset: offset
            )
        }
    }
    
    private static func drawBlockRegion(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        block: Block,
        color: Color,
        offset: CGSize
    ) {
        let rect = layout.regionRect(
            stringRange: block.stringRange,
            fretRange: block.fretRange,
            offset: offset,
            padding: 6
        )
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 6))
        context.fill(path, with: .color(color.opacity(0.12)))
        context.stroke(path, with: .color(color.opacity(0.35)), lineWidth: 1)
    }
    
    private static func drawBlockBracket(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        block: Block,
        color: Color,
        offset: CGSize
    ) {
        let left = layout.fretLineX(block.fretRange.lowerBound) + offset.width
        let right = layout.fretLineX(block.fretRange.upperBound) + layout.fretWidth + offset.width
        let topY = layout.stringY(block.stringRange.lowerBound) - layout.stringSpacing * 0.45 + offset.height
        let tick: CGFloat = 6
        
        var path = Path()
        path.move(to: CGPoint(x: left, y: topY + tick))
        path.addLine(to: CGPoint(x: left, y: topY))
        path.addLine(to: CGPoint(x: right, y: topY))
        path.addLine(to: CGPoint(x: right, y: topY + tick))
        context.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 1.5)
    }
    
    /// Draw XX-X / X-XX spacing ticks under each string's notes in the block.
    private static func drawSpacingMarkers(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        block: Block,
        color: Color,
        offset: CGSize
    ) {
        let grouped = Dictionary(grouping: block.positions.filter { $0.fret <= layout.maxFret }) { $0.string }
        
        for (string, positions) in grouped {
            let frets = positions.map(\.fret).sorted()
            guard frets.count >= 2 else { continue }
            
            let y = layout.stringY(string) + 11 + offset.height
            
            // Connect consecutive notes on the string with a light rail.
            for i in 0..<(frets.count - 1) {
                let from = CGPoint(x: layout.fretCenterX(frets[i]) + offset.width, y: y)
                let to = CGPoint(x: layout.fretCenterX(frets[i + 1]) + offset.width, y: y)
                let gap = frets[i + 1] - frets[i]
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                // Adjacent frets (XX) get a solid rail; gaps (X-X) get a dashed feel via thinner/fainter line.
                let opacity = gap <= 1 ? 0.9 : 0.35
                let width: CGFloat = gap <= 1 ? 2.5 : 1
                context.stroke(path, with: .color(color.opacity(opacity)), lineWidth: width)
            }
            
            // Tick marks at each note
            for fret in frets {
                let x = layout.fretCenterX(fret) + offset.width
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: y - 3))
                tick.addLine(to: CGPoint(x: x, y: y + 3))
                context.stroke(tick, with: .color(color), lineWidth: 2)
            }
        }
    }
    
    private static func drawBlockLabel(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        block: Block,
        color: Color,
        offset: CGSize
    ) {
        // Prefer anchor fret on the topmost string of the block.
        let labelPos = block.positions
            .filter { $0.fret <= layout.maxFret }
            .sorted { lhs, rhs in
                if lhs.string != rhs.string { return lhs.string < rhs.string }
                return lhs.fret < rhs.fret
            }
            .first
        
        guard let labelPos else { return }
        let p = layout.point(for: labelPos, offset: offset)
        let labelY = p.y - 20
        let labelWidth = CGFloat(max(52, block.name.count * 7))
        let labelHeight: CGFloat = 18
        let rect = CGRect(
            x: p.x - labelWidth / 2,
            y: labelY - labelHeight / 2,
            width: labelWidth,
            height: labelHeight
        )
        
        var bg = Path()
        bg.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.fill(bg, with: .color(color.opacity(0.92)))
        context.stroke(bg, with: .color(color), lineWidth: 1)
        
        let text = Text(block.name)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
        context.draw(text, at: CGPoint(x: p.x, y: labelY))
    }
    
    // MARK: Patterns
    
    static func drawPattern(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        pattern: Pattern,
        showLabels: Bool = true
    ) {
        drawConnections(context: &context, layout: layout, connections: pattern.connections)
        
        if !pattern.chordGroups.isEmpty {
            for group in pattern.chordGroups {
                let color = RSOGPalette.color(for: group)
                for position in group.positions where position.fret <= layout.maxFret {
                    let p = layout.point(for: position)
                    let radius: CGFloat = (position.isTriadRoot || position.isRoot) ? 10 : 7
                    fillCircle(context: &context, center: p, radius: radius, color: color.opacity(0.85))
                    strokeCircle(context: &context, center: p, radius: radius, color: .white.opacity(0.7), lineWidth: 1)
                }
                
                if showLabels {
                    drawChordGroupLabel(context: &context, layout: layout, group: group)
                }
            }
        } else {
            for position in pattern.positions where position.fret <= layout.maxFret {
                let color: Color = {
                    if let role = position.chordRole {
                        return RSOGPalette.color(for: role)
                    }
                    return position.isRoot
                        ? Color(red: 0.3, green: 0.7, blue: 1.0)
                        : Color(red: 0.3, green: 0.9, blue: 0.4)
                }()
                let p = layout.point(for: position)
                let radius: CGFloat = position.isRoot ? 10 : 7
                fillCircle(context: &context, center: p, radius: radius, color: color.opacity(0.85))
            }
        }
    }
    
    static func drawConnections(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        connections: [PatternConnection]
    ) {
        for connection in connections {
            guard connection.fromFret <= layout.maxFret,
                  connection.toFret <= layout.maxFret else { continue }
            let from = layout.point(string: connection.fromString, fret: connection.fromFret)
            let to = layout.point(string: connection.toString, fret: connection.toFret)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            context.stroke(
                path,
                with: .color(RSOGPalette.connectionColor(for: connection.kind)),
                lineWidth: connection.kind == .spiral ? 2 : 1.5
            )
        }
    }
    
    private static func drawChordGroupLabel(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        group: ChordGroup
    ) {
        guard let labelPos = group.positions
            .filter({ $0.fret <= layout.maxFret && ($0.isTriadRoot || $0.isRoot) })
            .sorted(by: { $0.fret < $1.fret })
            .first
            ?? group.positions.filter({ $0.fret <= layout.maxFret }).sorted(by: { $0.fret < $1.fret }).first
        else { return }
        
        let p = layout.point(for: labelPos)
        let color = RSOGPalette.color(for: group)
        let width = CGFloat(max(20, group.romanNumeral.count * 8))
        let rect = CGRect(x: p.x - width / 2, y: p.y - 26, width: width, height: 14)
        var bg = Path()
        bg.addRoundedRect(in: rect, cornerSize: CGSize(width: 3, height: 3))
        context.fill(bg, with: .color(color.opacity(0.95)))
        
        let text = Text(group.romanNumeral)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
        context.draw(text, at: CGPoint(x: p.x, y: p.y - 19))
    }
    
    // MARK: Base note dots
    
    static func drawBaseNotes(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        selected: FretboardPosition?,
        highlightedKeys: Set<String>,
        suppressedKeys: Set<String> = []
    ) {
        for string in 1...layout.stringCount {
            for fret in 0...layout.maxFret {
                let key = "\(string),\(fret)"
                let isSelected = selected?.string == string && selected?.fret == fret
                let isHighlighted = highlightedKeys.contains(key)
                
                if suppressedKeys.contains(key) && !isSelected {
                    continue
                }
                
                let p = layout.point(string: string, fret: fret)
                let color: Color = isSelected
                    ? RSOGPalette.selectedNote
                    : (isHighlighted ? .clear : .gray.opacity(0.45))
                let radius: CGFloat = isSelected ? 10 : 5
                
                if !isHighlighted || isSelected {
                    fillCircle(context: &context, center: p, radius: radius, color: color)
                }
                
                if isSelected {
                    let note = FretboardCalculator.noteAt(string: string, fret: fret)
                    let text = Text(note.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white)
                    context.draw(text, at: p)
                }
            }
        }
    }
    
    // MARK: Primitives
    
    static func fillCircle(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(color)
        )
    }
    
    static func strokeCircle(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) {
        context.stroke(
            Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(color),
            lineWidth: lineWidth
        )
    }
    
    /// Coordinate keys for positions inside selected blocks (for suppression).
    static func blockCoordinateKeys(
        blocks: [Block],
        selectedTypes: Set<BlockType>
    ) -> Set<String> {
        var keys: Set<String> = []
        for block in blocks where selectedTypes.contains(block.type) {
            for pos in block.positions {
                keys.insert(pos.coordinateKey)
            }
        }
        return keys
    }
}
