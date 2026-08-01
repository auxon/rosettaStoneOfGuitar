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
    /// Top of the string band (y where string index 0 would start). Non-zero when
    /// the physical neck is vertically centered inside a taller infinite-bass canvas.
    var originY: CGFloat
    
    init(
        maxFret: Int,
        fretWidth: CGFloat,
        stringSpacing: CGFloat,
        labelOffset: CGFloat = 24,
        stringCount: Int = Constants.numberOfStrings,
        size: CGSize = .zero,
        originY: CGFloat = 0
    ) {
        self.maxFret = maxFret
        self.fretWidth = fretWidth
        self.stringSpacing = stringSpacing
        self.labelOffset = labelOffset
        self.stringCount = stringCount
        self.size = size
        self.originY = originY
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
    
    /// Layout for the infinite-bass wallpaper: physical neck centered, virtual strings above/below.
    static func infiniteBass(
        canvasWidth: CGFloat,
        maxFret: Int,
        stringSpacing: CGFloat,
        extendedStringCount: Int,
        labelOffset: CGFloat = 24
    ) -> FretboardLayout {
        let totalVirtual = Constants.numberOfStrings + extendedStringCount
        let height = CGFloat(totalVirtual) * stringSpacing
        let usableWidth = max(1, canvasWidth - labelOffset)
        let fretWidth = usableWidth / CGFloat(maxFret + 1)
        // Center the 6-string neck inside the taller canvas.
        let originY = height / 2 - CGFloat(Constants.numberOfStrings) / 2 * stringSpacing
        return FretboardLayout(
            maxFret: maxFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: labelOffset,
            stringCount: Constants.numberOfStrings,
            size: CGSize(width: canvasWidth, height: height),
            originY: originY
        )
    }
    
    /// Total virtual strings produced by `BlockGenerator.infiniteBassPattern`.
    static func infiniteBassVirtualCount(extendedStringCount: Int) -> Int {
        Constants.numberOfStrings + extendedStringCount
    }
    
    /// X center of a fret column.
    func fretCenterX(_ fret: Int) -> CGFloat {
        CGFloat(fret) * fretWidth + fretWidth / 2 + labelOffset
    }
    
    /// Left edge of a fret column (nut / fret wire).
    func fretLineX(_ fret: Int) -> CGFloat {
        CGFloat(fret) * fretWidth + labelOffset
    }
    
    /// Y of a string. String 1 (high E) is at the top. Works for virtual string indices too.
    func stringY(_ string: Int) -> CGFloat {
        originY + (CGFloat(string - 1) + 0.5) * stringSpacing
    }
    
    /// Vertical band covering the physical 6-string neck.
    var neckRect: CGRect {
        let top = stringY(1) - stringSpacing / 2
        let bottom = stringY(Constants.numberOfStrings) + stringSpacing / 2
        let left = labelOffset
        let right = labelOffset + CGFloat(maxFret + 1) * fretWidth
        return CGRect(x: left, y: top, width: max(0, right - left), height: max(0, bottom - top))
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
        let string = Int((location.y - originY) / stringSpacing) + 1
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
    
    /// Draw HEAD / BRIDGE / TRIPLE as outlined regions (rSoG spiral-map style),
    /// not filled note squares. Labels are placed outside outlines with collision avoidance.
    static func drawBlocks(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        blocks: [Block],
        selectedTypes: Set<BlockType>,
        offsets: [UUID: CGSize] = [:],
        showOutlines: Bool = true,
        showNotePips: Bool = true,
        showLabels: Bool = true,
        /// When true, only primary teaching placements are outlined (e–B HEAD, D–A BRIDGE, strings 3–5 TRIPLE).
        /// Default false so every valid landmark on the board is outlined.
        preferPrimaryPlacements: Bool = false,
        /// Legacy flags kept for call-site compatibility; ignored in outline mode.
        showRegions: Bool = true,
        showSpacingMarkers: Bool = false,
        showBrackets: Bool = false
    ) {
        _ = showRegions
        _ = showSpacingMarkers
        _ = showBrackets
        
        // Stable draw order: HEAD under BRIDGE under TRIPLE so nested outlines stay readable.
        let typeOrder: [BlockType: Int] = [.headBlock: 0, .bridgeBlock: 1, .tripleBlock: 2]
        let visibleBlocks = blocks
            .filter { selectedTypes.contains($0.type) && !$0.positions.isEmpty }
            .filter { preferPrimaryPlacements ? isPrimaryPlacement($0) : true }
            .sorted {
                let lhs = typeOrder[$0.type, default: 9]
                let rhs = typeOrder[$1.type, default: 9]
                if lhs != rhs { return lhs < rhs }
                if $0.anchorFret != $1.anchorFret { return $0.anchorFret < $1.anchorFret }
                return $0.stringRange.lowerBound < $1.stringRange.lowerBound
            }
        
        var occupiedLabelRects: [CGRect] = []
        
        for block in visibleBlocks {
            let offset = offsets[block.id] ?? .zero
            let color = RSOGPalette.blockColor(block.type)
            let visiblePositions = block.positions.filter { $0.fret <= layout.maxFret }
            guard !visiblePositions.isEmpty else { continue }
            
            let outlineRect = blockOutlineRect(
                layout: layout,
                positions: visiblePositions,
                offset: offset
            )
            
            if showOutlines {
                drawBlockOutline(
                    context: &context,
                    rect: outlineRect,
                    color: color,
                    lineWidth: block.type == .tripleBlock ? 2.0 : 2.0,
                    fillOpacity: block.type == .tripleBlock ? 0.04 : 0.07
                )
            }
            
            if showNotePips {
                for position in visiblePositions {
                    let p = layout.point(for: position, offset: offset)
                    strokeCircle(context: &context, center: p, radius: 3.5, color: color.opacity(0.9), lineWidth: 1.5)
                }
            }
            
            if showLabels {
                drawBlockOutlineLabel(
                    context: &context,
                    layout: layout,
                    block: block,
                    outlineRect: outlineRect,
                    color: color,
                    occupiedRects: &occupiedLabelRects
                )
            }
        }
    }
    
    /// Tight padded bounds around the block's visible note positions.
    private static func blockOutlineRect(
        layout: FretboardLayout,
        positions: [FretboardPosition],
        offset: CGSize,
        padding: CGFloat = 10
    ) -> CGRect {
        let points = positions.map { layout.point(for: $0, offset: offset) }
        guard let minX = points.map(\.x).min(),
              let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(),
              let maxY = points.map(\.y).max() else {
            return .zero
        }
        // Expand toward fret/string cell edges so the outline reads as a zone.
        let padX = max(padding, layout.fretWidth * 0.35)
        let padY = max(padding, layout.stringSpacing * 0.4)
        return CGRect(
            x: minX - padX,
            y: minY - padY,
            width: (maxX - minX) + padX * 2,
            height: (maxY - minY) + padY * 2
        )
    }
    
    private static func drawBlockOutline(
        context: inout GraphicsContext,
        rect: CGRect,
        color: Color,
        lineWidth: CGFloat,
        fillOpacity: Double = 0.07
    ) {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 8, height: 8))
        // Very light wash so overlapping zones (BRIDGE ∩ TRIPLE) stay transparent.
        context.fill(path, with: .color(color.opacity(fillOpacity)))
        context.stroke(path, with: .color(color.opacity(0.95)), lineWidth: lineWidth)
    }
    
    private static func drawBlockOutlineLabel(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        block: Block,
        outlineRect: CGRect,
        color: Color,
        occupiedRects: inout [CGRect]
    ) {
        let title = shortBlockLabel(for: block)
        let fontSize: CGFloat = block.type == .tripleBlock ? 10 : 11
        let labelWidth = CGFloat(max(36, title.count * 7 + 10))
        let labelHeight: CGFloat = 16
        let midX = outlineRect.midX
        
        // Prefer above the outline; fall back to below / inside-top if crowded.
        let candidates: [CGPoint] = [
            CGPoint(x: midX, y: outlineRect.minY - labelHeight * 0.65),
            CGPoint(x: midX, y: outlineRect.maxY + labelHeight * 0.65),
            CGPoint(x: midX, y: outlineRect.minY + labelHeight * 0.85),
            CGPoint(x: outlineRect.minX + labelWidth * 0.55, y: outlineRect.minY - labelHeight * 0.65),
            CGPoint(x: outlineRect.maxX - labelWidth * 0.55, y: outlineRect.minY - labelHeight * 0.65)
        ]
        
        for center in candidates {
            let rect = CGRect(
                x: center.x - labelWidth / 2,
                y: center.y - labelHeight / 2,
                width: labelWidth,
                height: labelHeight
            )
            // Keep labels on-canvas and non-overlapping.
            guard rect.minY >= -2,
                  rect.maxY <= layout.size.height + 2 || layout.size.height == 0,
                  !occupiedRects.contains(where: { $0.insetBy(dx: -3, dy: -2).intersects(rect) })
            else { continue }
            
            var bg = Path()
            bg.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
            // Outline-style chip: mostly transparent fill, strong border.
            context.fill(bg, with: .color(color.opacity(0.18)))
            context.stroke(bg, with: .color(color), lineWidth: 1.25)
            
            let text = Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(color)
            context.draw(text, at: center)
            occupiedRects.append(rect)
            return
        }
        // If every slot is taken, skip the label — the outline still identifies the block.
    }
    
    private static func shortBlockLabel(for block: Block) -> String {
        switch block.type {
        case .headBlock: return "HEAD"
        case .bridgeBlock: return "BRIDGE"
        case .tripleBlock: return "TRIPLE"
        }
    }
    
    /// Primary rSoG landmark placements used on the lesson diagrams.
    private static func isPrimaryPlacement(_ block: Block) -> Bool {
        switch block.type {
        case .headBlock:
            return block.stringRange == 1...2
        case .bridgeBlock:
            return block.stringRange == 4...5
        case .tripleBlock:
            // Full on-board sets, plus edge overflows that show 6 of 9 notes (1–2 or 5–6).
            switch block.stringRange {
            case 1...2, 3...5, 4...6, 5...6: return true
            default: return false
            }
        }
    }
    
    // MARK: Patterns
    
    static func drawPattern(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        pattern: Pattern,
        showLabels: Bool = true
    ) {
        // Spiral / jump paths still draw as lines; triad outlines replace connection clutter
        // for Family of Chords / Familial Hierarchy.
        let hasChordShapes = pattern.chordGroups.contains { !$0.voicings.isEmpty }
        if !hasChordShapes {
            drawConnections(context: &context, layout: layout, connections: pattern.connections)
        }
        
        if !pattern.chordGroups.isEmpty {
            var occupiedLabelRects: [CGRect] = []
            for group in pattern.chordGroups {
                drawChordGroupShapes(
                    context: &context,
                    layout: layout,
                    group: group,
                    showLabels: showLabels,
                    occupiedLabelRects: &occupiedLabelRects
                )
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
    
    /// Outline each triad voicing so Papa / Mama / yBro shapes read as zones, not loose dots.
    private static func drawChordGroupShapes(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        group: ChordGroup,
        showLabels: Bool,
        occupiedLabelRects: inout [CGRect]
    ) {
        let color = RSOGPalette.color(for: group)
        let shapes = group.voicings.isEmpty
            ? [ChordVoicing(positions: group.positions)]
            : group.voicings
        
        for voicing in shapes {
            let visible = voicing.positions.filter { $0.fret <= layout.maxFret }
            guard visible.count >= 2 else { continue }
            
            let outlineRect = blockOutlineRect(
                layout: layout,
                positions: visible,
                offset: .zero,
                padding: 8
            )
            drawBlockOutline(
                context: &context,
                rect: outlineRect,
                color: color,
                lineWidth: 2.0,
                fillOpacity: 0.08
            )
            
            for position in visible {
                let p = layout.point(for: position)
                let isRoot = position.isTriadRoot || position.isRoot
                // Hollow pips (block style); slightly larger pip on the triad root.
                strokeCircle(
                    context: &context,
                    center: p,
                    radius: isRoot ? 4.5 : 3.5,
                    color: color.opacity(0.95),
                    lineWidth: isRoot ? 2.0 : 1.5
                )
            }
            
            if showLabels {
                drawChordVoicingLabel(
                    context: &context,
                    layout: layout,
                    group: group,
                    outlineRect: outlineRect,
                    color: color,
                    occupiedRects: &occupiedLabelRects
                )
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
    
    private static func drawChordVoicingLabel(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        group: ChordGroup,
        outlineRect: CGRect,
        color: Color,
        occupiedRects: inout [CGRect]
    ) {
        let title = group.familyName
        let fontSize: CGFloat = 10
        let labelWidth = CGFloat(max(30, title.count * 7 + 10))
        let labelHeight: CGFloat = 16
        let midX = outlineRect.midX
        
        let candidates: [CGPoint] = [
            CGPoint(x: midX, y: outlineRect.minY - labelHeight * 0.65),
            CGPoint(x: midX, y: outlineRect.maxY + labelHeight * 0.65),
            CGPoint(x: midX, y: outlineRect.minY + labelHeight * 0.85),
            CGPoint(x: outlineRect.minX + labelWidth * 0.55, y: outlineRect.minY - labelHeight * 0.65),
            CGPoint(x: outlineRect.maxX - labelWidth * 0.55, y: outlineRect.minY - labelHeight * 0.65)
        ]
        
        for center in candidates {
            let rect = CGRect(
                x: center.x - labelWidth / 2,
                y: center.y - labelHeight / 2,
                width: labelWidth,
                height: labelHeight
            )
            guard rect.minY >= -2,
                  rect.maxY <= layout.size.height + 2 || layout.size.height == 0,
                  !occupiedRects.contains(where: { $0.insetBy(dx: -3, dy: -2).intersects(rect) })
            else { continue }
            
            var bg = Path()
            bg.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
            context.fill(bg, with: .color(color.opacity(0.2)))
            context.stroke(bg, with: .color(color), lineWidth: 1.25)
            
            let text = Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(color)
            context.draw(text, at: center)
            occupiedRects.append(rect)
            return
        }
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
    
    // MARK: Infinite bass scene
    
    /// White wallpaper + wood neck + metallic frets/strings + charcoal spheres.
    static func drawInfiniteBassScene(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        positions: [FretboardPosition]
    ) {
        drawInfiniteBassBackground(context: &context, layout: layout)
        drawGuitarBody(context: &context, layout: layout)
        drawHeadstock(context: &context, layout: layout)
        drawWoodNeck(context: &context, layout: layout)
        drawMetallicFrets(context: &context, layout: layout)
        drawPhysicalStrings(context: &context, layout: layout)
        drawInfiniteBassSpheres(context: &context, layout: layout, positions: positions)
    }
    
    static func drawInfiniteBassBackground(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let rect = CGRect(origin: .zero, size: layout.size)
        context.fill(Path(rect), with: .color(RSOGPalette.infiniteBassBackground))
    }
    
    static func drawWoodNeck(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let neck = layout.neckRect
        var path = Path()
        path.addRoundedRect(in: neck, cornerSize: CGSize(width: 2, height: 2))
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    RSOGPalette.fretboardWoodLight,
                    RSOGPalette.fretboardWoodMid,
                    RSOGPalette.fretboardWoodDark
                ]),
                startPoint: CGPoint(x: neck.midX, y: neck.minY),
                endPoint: CGPoint(x: neck.midX, y: neck.maxY)
            )
        )
        // Subtle edge shade
        context.stroke(path, with: .color(.black.opacity(0.18)), lineWidth: 1)
    }
    
    static func drawMetallicFrets(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let neck = layout.neckRect
        for fret in 0...layout.maxFret {
            let x = layout.fretLineX(fret)
            let isNut = fret == 0
            let width: CGFloat = isNut ? 3.5 : 2.0
            
            // Shadow edge
            var shadow = Path()
            shadow.move(to: CGPoint(x: x + 0.6, y: neck.minY))
            shadow.addLine(to: CGPoint(x: x + 0.6, y: neck.maxY))
            context.stroke(shadow, with: .color(.black.opacity(0.2)), lineWidth: width)
            
            // Main silver wire
            var wire = Path()
            wire.move(to: CGPoint(x: x, y: neck.minY))
            wire.addLine(to: CGPoint(x: x, y: neck.maxY))
            context.stroke(wire, with: .color(RSOGPalette.fretWire), lineWidth: width)
            
            // Highlight line for a double-wire look
            if !isNut {
                var highlight = Path()
                highlight.move(to: CGPoint(x: x - 0.7, y: neck.minY))
                highlight.addLine(to: CGPoint(x: x - 0.7, y: neck.maxY))
                context.stroke(highlight, with: .color(RSOGPalette.fretWireHighlight.opacity(0.85)), lineWidth: 0.8)
            }
        }
    }
    
    static func drawPhysicalStrings(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let neck = layout.neckRect
        for string in 1...Constants.numberOfStrings {
            let y = layout.stringY(string)
            // High E is thinner; low E is thicker.
            let lineWidth: CGFloat = 0.7 + CGFloat(string - 1) * 0.22
            var path = Path()
            path.move(to: CGPoint(x: neck.minX, y: y))
            path.addLine(to: CGPoint(x: neck.maxX, y: y))
            context.stroke(path, with: .color(RSOGPalette.stringMetal.opacity(0.85)), lineWidth: lineWidth)
        }
    }
    
    static func drawHeadstock(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let neck = layout.neckRect
        let width: CGFloat = max(18, layout.labelOffset - 4)
        let rect = CGRect(
            x: neck.minX - width,
            y: neck.minY - 4,
            width: width,
            height: neck.height + 8
        )
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.fill(path, with: .color(RSOGPalette.headstock))
        
        // Tuning pegs
        let pegRadius: CGFloat = 2.2
        for string in 1...Constants.numberOfStrings {
            let y = layout.stringY(string)
            let pegCenter = CGPoint(x: rect.minX + width * 0.45, y: y)
            fillCircle(
                context: &context,
                center: pegCenter,
                radius: pegRadius,
                color: Color(white: 0.75)
            )
        }
    }
    
    static func drawGuitarBody(
        context: inout GraphicsContext,
        layout: FretboardLayout
    ) {
        let neck = layout.neckRect
        let bodyWidth = neck.height * 1.15
        let bodyHeight = neck.height * 1.65
        let rect = CGRect(
            x: neck.maxX - 10,
            y: neck.midY - bodyHeight / 2,
            width: bodyWidth,
            height: bodyHeight
        )
        context.fill(Path(ellipseIn: rect), with: .color(RSOGPalette.guitarBody))
        // Sound hole hint
        let holeCenter = CGPoint(x: rect.midX + bodyWidth * 0.08, y: rect.midY)
        strokeCircle(
            context: &context,
            center: holeCenter,
            radius: min(bodyWidth, bodyHeight) * 0.12,
            color: Color.black.opacity(0.35),
            lineWidth: 3
        )
    }
    
    static func drawInfiniteBassSpheres(
        context: inout GraphicsContext,
        layout: FretboardLayout,
        positions: [FretboardPosition]
    ) {
        let radius = max(5.5, min(layout.stringSpacing * 0.38, layout.fretWidth * 0.28))
        for position in positions where position.fret <= layout.maxFret {
            let center = layout.point(for: position)
            drawCharcoalSphere(context: &context, center: center, radius: radius)
        }
    }
    
    /// Glossy charcoal sphere matching the rSoG infinite-bass reference art.
    static func drawCharcoalSphere(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat
    ) {
        // Soft contact shadow
        let shadowRect = CGRect(
            x: center.x - radius + 0.6,
            y: center.y - radius + 1.2,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.18)))
        
        let sphereRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(
            Path(ellipseIn: sphereRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color(white: 0.55),
                    RSOGPalette.infiniteBassSphere,
                    Color(white: 0.08)
                ]),
                center: CGPoint(x: center.x - radius * 0.32, y: center.y - radius * 0.38),
                startRadius: 0,
                endRadius: radius * 1.25
            )
        )
        
        // Specular highlight
        let highlight = CGRect(
            x: center.x - radius * 0.5,
            y: center.y - radius * 0.55,
            width: radius * 0.5,
            height: radius * 0.35
        )
        context.fill(Path(ellipseIn: highlight), with: .color(.white.opacity(0.32)))
    }
}
