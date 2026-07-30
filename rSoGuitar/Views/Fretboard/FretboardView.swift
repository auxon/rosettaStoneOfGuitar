//
//  FretboardView.swift
//  rSoGuitar
//
//  Interactive fretboard visualization
//

import SwiftUI

struct FretboardView: View {
    @StateObject private var viewModel = FretboardViewModel()
    @State private var fretWidth: CGFloat = 40
    @State private var stringSpacing: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            // Controls
            controlsView
            
            // Fretboard
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                fretboardCanvas
                    .frame(minWidth: CGFloat(viewModel.maxFret + 1) * fretWidth + 24, // Add space for string labels
                           minHeight: CGFloat(Constants.numberOfStrings) * stringSpacing)
                    .padding()
            }
        }
        .navigationTitle("Fretboard Explorer")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            // Key selector
            HStack {
                Text("Key:")
                Picker("Key", selection: $viewModel.selectedKey) {
                    ForEach(Key.allCases, id: \.self) { key in
                        Text(key.rootNote.rawValue).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedKey) { _, newKey in
                    viewModel.selectKey(newKey)
                }
            }
            .padding(.horizontal)
            
            // Pattern type selector
            HStack {
                Text("Pattern:")
                Picker("Pattern Type", selection: $viewModel.patternType) {
                    Text("Spiral Mapping").tag(PatternType.spiralMapping)
                    Text("Jumping").tag(PatternType.jumping)
                    Text("Family of Chords").tag(PatternType.familyOfChords)
                    Text("Familial Hierarchy").tag(PatternType.familialHierarchy)
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.patternType) { _, newType in
                    viewModel.setPatternType(newType)
                }
            }
            .padding(.horizontal)
            
            // Toggle pattern overlay
            Toggle("Show Pattern Overlay", isOn: $viewModel.showPatternOverlay)
                .padding(.horizontal)
                .onChange(of: viewModel.showPatternOverlay) { _, _ in
                    viewModel.togglePatternOverlay()
                }
            
            // Block controls
            VStack(spacing: 8) {
                Toggle("Show Blocks", isOn: $viewModel.showBlocks)
                    .padding(.horizontal)
                    .onChange(of: viewModel.showBlocks) { _, _ in
                        viewModel.toggleBlocks()
                    }
                
                if viewModel.showBlocks {
                    Toggle("Show Full Pattern", isOn: $viewModel.showFullPattern)
                        .padding(.horizontal)
                        .onChange(of: viewModel.showFullPattern) { _, _ in
                            viewModel.toggleFullPattern()
                        }
                    
                    Toggle("Show Infinite Bass Pattern", isOn: $viewModel.showInfiniteBassPattern)
                        .padding(.horizontal)
                        .onChange(of: viewModel.showInfiniteBassPattern) { _, _ in
                            viewModel.toggleInfiniteBassPattern()
                        }
                    
                    if viewModel.showInfiniteBassPattern {
                        HStack(spacing: 12) {
                            Button("←") {
                                viewModel.shiftPattern(fretDelta: -1, stringDelta: 0)
                            }
                            Button("→") {
                                viewModel.shiftPattern(fretDelta: 1, stringDelta: 0)
                            }
                            Button("↑") {
                                viewModel.shiftPattern(fretDelta: 0, stringDelta: 1)
                            }
                            Button("↓") {
                                viewModel.shiftPattern(fretDelta: 0, stringDelta: -1)
                            }
                            Text("Shift Pattern")
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 16) {
                        BlockToggleButton(
                            title: "HEAD",
                            isSelected: viewModel.selectedBlockTypes.contains(.headBlock),
                            color: RSOGPalette.blockColor(.headBlock)
                        ) {
                            viewModel.toggleBlock(.headBlock)
                        }
                        
                        BlockToggleButton(
                            title: "BRIDGE",
                            isSelected: viewModel.selectedBlockTypes.contains(.bridgeBlock),
                            color: RSOGPalette.blockColor(.bridgeBlock)
                        ) {
                            viewModel.toggleBlock(.bridgeBlock)
                        }
                        
                        BlockToggleButton(
                            title: "TRIPLE",
                            isSelected: viewModel.selectedBlockTypes.contains(.tripleBlock),
                            color: RSOGPalette.blockColor(.tripleBlock)
                        ) {
                            viewModel.toggleBlock(.tripleBlock)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // CAGED controls (independent of blocks)
            VStack(spacing: 8) {
                Toggle("Show CAGED", isOn: $viewModel.showCAGED)
                    .padding(.horizontal)
                    .onChange(of: viewModel.showCAGED) { _, _ in
                        viewModel.toggleCAGED()
                    }
                
                if viewModel.showCAGED {
                    HStack(spacing: 12) {
                        ForEach(CAGEDForm.allCases, id: \.self) { form in
                            BlockToggleButton(
                                title: form.rawValue,
                                isSelected: viewModel.selectedCAGEDForms.contains(form),
                                color: .purple
                            ) {
                                viewModel.toggleCAGEDForm(form)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Mode controls
            VStack(spacing: 8) {
                Toggle("Show Modes", isOn: $viewModel.showModes)
                    .padding(.horizontal)
                    .onChange(of: viewModel.showModes) { _, _ in
                        viewModel.toggleModes()
                    }
                
                if viewModel.showModes {
                    // Mode selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Mode.allCases, id: \.self) { mode in
                                ModeToggleButton(
                                    mode: mode,
                                    isSelected: viewModel.selectedMode == mode
                                ) {
                                    viewModel.selectMode(mode)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Mode info
                    if let shape = viewModel.modeShape {
                        VStack(spacing: 4) {
                            HStack {
                                Text("\(viewModel.selectedKey.rootNote.rawValue) \(viewModel.selectedMode.rawValue)")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                Text("(\(viewModel.selectedMode.quality))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(shape.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Sound controls
            HStack(spacing: 16) {
                // Sound toggle
                Button(action: {
                    viewModel.toggleSound()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(viewModel.isSoundEnabled ? .blue : .gray)
                        Text(viewModel.isSoundEnabled ? "Sound On" : "Sound Off")
                            .font(.caption)
                            .foregroundColor(viewModel.isSoundEnabled ? .blue : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.isSoundEnabled ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // Volume slider
                if viewModel.isSoundEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Slider(value: $viewModel.volume, in: 0...1, step: 0.1)
                            .frame(width: 100)
                            .onChange(of: viewModel.volume) { _, newValue in
                                viewModel.setVolume(newValue)
                            }
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                // Play selected notes button
                if viewModel.selectedPosition != nil || !viewModel.highlightedPositions.isEmpty {
                    Button(action: {
                        viewModel.playSelectedNotes()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                            Text("Play")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
    
    private struct BlockToggleButton: View {
        let title: String
        let isSelected: Bool
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSelected ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                    )
                    .cornerRadius(6)
            }
        }
    }
    
    private struct ModeToggleButton: View {
        let mode: Mode
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 2) {
                    Text(mode.romanNumeral)
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text(mode.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(isSelected ? .white : .purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.purple, lineWidth: 2)
                )
                .cornerRadius(6)
            }
        }
    }
    
    private var fretboardCanvas: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Main fretboard canvas
                Canvas { context, size in
                    drawFretboard(context: context, size: size)
                }
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let totalStrings = viewModel.showInfiniteBassPattern ? viewModel.extendedStringCount : Constants.numberOfStrings
                            let calculatedFretWidth = geometry.size.width / CGFloat(viewModel.maxFret + 1)
                            let calculatedStringSpacing = geometry.size.height / CGFloat(totalStrings)
                            
                            // Check if we're in infinite bass pattern mode and should shift the pattern
                            if viewModel.showInfiniteBassPattern && viewModel.draggedBlockId == nil {
                                // Shift the pattern based on drag
                                let fretDelta = Int(round(value.translation.width / calculatedFretWidth))
                                let stringDelta = Int(round(-value.translation.height / calculatedStringSpacing))
                                if abs(fretDelta) > 0 || abs(stringDelta) > 0 {
                                    viewModel.shiftPattern(fretDelta: fretDelta, stringDelta: stringDelta)
                                }
                            } else {
                                // Block hit-testing uses the physical 6-string layout.
                                let blockStringSpacing = geometry.size.height / CGFloat(Constants.numberOfStrings)
                                handleDragChanged(value, fretWidth: calculatedFretWidth, stringSpacing: blockStringSpacing)
                            }
                        }
                        .onEnded { value in
                            let totalStrings = viewModel.showInfiniteBassPattern ? viewModel.extendedStringCount : Constants.numberOfStrings
                            let calculatedFretWidth = geometry.size.width / CGFloat(viewModel.maxFret + 1)
                            let calculatedStringSpacing = geometry.size.height / CGFloat(totalStrings)
                            let blockStringSpacing = geometry.size.height / CGFloat(Constants.numberOfStrings)
                            
                            if viewModel.draggedBlockId == nil {
                                // If not dragging a block, treat as tap
                                handleTap(
                                    at: value.location,
                                    fretWidth: calculatedFretWidth,
                                    stringSpacing: blockStringSpacing
                                )
                            } else {
                                // End block drag
                                handleDragEnded(value, fretWidth: calculatedFretWidth, stringSpacing: blockStringSpacing)
                            }
                        }
                )
            
            // String labels on the left - simplified for now, will be drawn in canvas
            EmptyView()
            
                // Fret numbers above
                HStack(spacing: 0) {
                    ForEach(0...viewModel.maxFret, id: \.self) { fret in
                        let calculatedFretWidth = geometry.size.width / CGFloat(viewModel.maxFret + 1)
                        if fret % 3 == 0 || fret == 0 || fret == viewModel.maxFret {
                            Text("\(fret)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: calculatedFretWidth)
                        } else {
                            Spacer()
                                .frame(width: calculatedFretWidth)
                        }
                    }
                }
                .padding(.top, -20)
                .padding(.leading, 24 + (geometry.size.width / CGFloat(viewModel.maxFret + 1)) / 2)
            }
        }
    }
    
    private func drawFretboard(context: GraphicsContext, size: CGSize) {
        var context = context
        let totalStrings = viewModel.showInfiniteBassPattern ? viewModel.extendedStringCount : Constants.numberOfStrings
        let fretWidth = size.width / CGFloat(viewModel.maxFret + 1)
        let stringSpacing = size.height / CGFloat(totalStrings)
        
        // Standard layout: string 1 (high E) at top. Used for blocks/patterns/notes.
        let layout = FretboardLayout(
            maxFret: viewModel.maxFret,
            fretWidth: fretWidth,
            stringSpacing: viewModel.showInfiniteBassPattern
                ? size.height / CGFloat(Constants.numberOfStrings)
                : stringSpacing,
            labelOffset: 24,
            stringCount: Constants.numberOfStrings,
            size: size
        )
        
        // Frets
        FretboardRenderer.drawGrid(context: &context, layout: layout, drawFrets: true, drawStrings: false)
        
        // Strings — extended virtual strings when infinite bass is on
        if viewModel.showInfiniteBassPattern {
            let stringRange = (1 - viewModel.extendedStringCount / 2 + viewModel.patternOffset.string)...(Constants.numberOfStrings + viewModel.extendedStringCount / 2 + viewModel.patternOffset.string)
            let physicalStringCenter = CGFloat(Constants.numberOfStrings) / 2.0 + 0.5
            for virtualString in stringRange {
                let virtualStringOffset = CGFloat(virtualString - Int(physicalStringCenter))
                let y = size.height / 2.0 + virtualStringOffset * stringSpacing
                let isPhysical = virtualString >= 1 && virtualString <= Constants.numberOfStrings
                var path = Path()
                path.move(to: CGPoint(x: layout.labelOffset, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(isPhysical ? Color.gray : Color.gray.opacity(0.3)),
                    lineWidth: isPhysical ? 2 : 0.5
                )
            }
        } else {
            FretboardRenderer.drawGrid(context: &context, layout: layout, drawFrets: false, drawStrings: true)
        }
        
        if viewModel.showBlocks && !viewModel.selectedBlockTypes.isEmpty {
            if viewModel.showFullPattern {
                FretboardRenderer.drawDiatonicPattern(
                    context: &context,
                    layout: layout,
                    positions: viewModel.diatonicPattern
                )
            }
            
            var offsets: [UUID: CGSize] = [:]
            for block in viewModel.blocks {
                offsets[block.id] = viewModel.getBlockOffset(block.id)
            }
            FretboardRenderer.drawBlocks(
                context: &context,
                layout: layout,
                blocks: viewModel.blocks,
                selectedTypes: viewModel.selectedBlockTypes,
                offsets: offsets,
                showRegions: true,
                showSpacingMarkers: true,
                showBrackets: true
            )
        }
        
        if viewModel.showInfiniteBassPattern {
            drawInfiniteBassPattern(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        if viewModel.showCAGED {
            drawCAGEDShapes(context: context, size: size, layout: layout)
        }
        
        if viewModel.showModes {
            drawModeShape(context: context, size: size, layout: layout)
        }
        
        if viewModel.showPatternOverlay, let pattern = viewModel.selectedPattern {
            FretboardRenderer.drawPattern(context: &context, layout: layout, pattern: pattern)
        } else if viewModel.showPatternOverlay {
            // Fallback: highlighted positions without a full Pattern model
            for position in viewModel.highlightedPositions {
                let p = layout.point(for: position)
                let color: Color = position.isRoot
                    ? Color(red: 0.3, green: 0.7, blue: 1.0)
                    : Color(red: 0.3, green: 0.9, blue: 0.4)
                FretboardRenderer.fillCircle(
                    context: &context,
                    center: p,
                    radius: position.isRoot ? 12 : 8,
                    color: color.opacity(0.8)
                )
            }
        }
        
        let suppressed = (viewModel.showBlocks && !viewModel.selectedBlockTypes.isEmpty)
            ? FretboardRenderer.blockCoordinateKeys(
                blocks: viewModel.blocks,
                selectedTypes: viewModel.selectedBlockTypes
            )
            : []
        let highlighted = Set(viewModel.highlightedPositions.map(\.coordinateKey))
        FretboardRenderer.drawBaseNotes(
            context: &context,
            layout: layout,
            selected: viewModel.selectedPosition,
            highlightedKeys: highlighted,
            suppressedKeys: suppressed
        )
    }
    
    private func drawInfiniteBassPattern(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let labelOffset: CGFloat = 24
        
        // Calculate the center position (physical strings 1-6 are centered)
        let physicalStringCenter = CGFloat(Constants.numberOfStrings) / 2.0 + 0.5
        
        for position in viewModel.infiniteBassPattern {
            // Calculate visual position for virtual strings
            let virtualStringOffset = CGFloat(position.string - Int(physicalStringCenter))
            let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
            let y = size.height / 2.0 + virtualStringOffset * stringSpacing
            
            // Use bright colors visible in dark mode
            let isPhysicalString = position.string >= 1 && position.string <= Constants.numberOfStrings
            let brightBlue = Color(red: 0.3, green: 0.7, blue: 1.0)
            let brightGreen = Color(red: 0.3, green: 0.9, blue: 0.4)
            let color: Color = position.isRoot ? 
                (isPhysicalString ? brightBlue.opacity(0.75) : brightBlue.opacity(0.5)) :
                (isPhysicalString ? brightGreen.opacity(0.6) : brightGreen.opacity(0.4))
            let radius: CGFloat = isPhysicalString ? 6 : 5
            
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
    
    private func drawCAGEDShapes(context: GraphicsContext, size: CGSize, layout: FretboardLayout) {
        guard !viewModel.cagedShapes.isEmpty else { return }
        
        let brightCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
        let rootOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
        let squareSize: CGFloat = 18
        
        for shape in viewModel.cagedShapes {
            guard viewModel.selectedCAGEDForms.contains(shape.form) else { continue }
            guard !shape.positions.isEmpty else { continue }
            
            for position in shape.positions {
                guard position.fret >= 0 && position.fret <= viewModel.maxFret else { continue }
                guard position.string >= 1 && position.string <= Constants.numberOfStrings else { continue }
                
                let p = layout.point(for: position)
                let squareRect = CGRect(
                    x: p.x - squareSize / 2,
                    y: p.y - squareSize / 2,
                    width: squareSize,
                    height: squareSize
                )
                var squarePath = Path()
                squarePath.addRect(squareRect)
                context.fill(squarePath, with: .color((position.isRoot ? rootOrange : brightCyan).opacity(0.9)))
                context.stroke(squarePath, with: .color(.white), lineWidth: 2.0)
            }
            
            let rootPoint = layout.point(for: shape.rootPosition)
            let labelWidth = CGFloat(max(40, shape.form.rawValue.count * 8))
            let labelRect = CGRect(
                x: rootPoint.x - labelWidth / 2,
                y: rootPoint.y - 20 - 9,
                width: labelWidth,
                height: 18
            )
            var bgPath = Path()
            bgPath.addRoundedRect(in: labelRect, cornerSize: CGSize(width: 4, height: 4))
            context.fill(bgPath, with: .color(Color(red: 0.2, green: 0.2, blue: 0.3).opacity(0.95)))
            context.stroke(bgPath, with: .color(.white), lineWidth: 1.5)
            let text = Text(shape.form.rawValue)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
            context.draw(text, at: CGPoint(x: rootPoint.x, y: rootPoint.y - 20))
        }
    }
    
    private func drawModeShape(context: GraphicsContext, size: CGSize, layout: FretboardLayout) {
        var context = context
        guard let shape = viewModel.modeShape else { return }
        
        let rootColor = Color(red: 0.7, green: 0.3, blue: 0.9)
        let characteristicColor = Color(red: 1.0, green: 0.5, blue: 0.8)
        let normalColor = Color(red: 0.6, green: 0.4, blue: 0.8)
        let characteristicInterval = viewModel.selectedMode.characteristicInterval
        
        for position in shape.positions {
            guard position.fret >= 0 && position.fret <= viewModel.maxFret else { continue }
            guard position.string >= 1 && position.string <= Constants.numberOfStrings else { continue }
            
            let p = layout.point(for: position)
            let semitones = (position.note.semitonesFromC - viewModel.selectedKey.rootNote.semitonesFromC + 12) % 12
            let isCharacteristic = semitones == characteristicInterval
            
            let fillColor: Color
            let radius: CGFloat
            if position.isRoot {
                fillColor = rootColor
                radius = 12
            } else if isCharacteristic {
                fillColor = characteristicColor
                radius = 10
            } else {
                fillColor = normalColor
                radius = 8
            }
            
            FretboardRenderer.fillCircle(context: &context, center: p, radius: radius, color: fillColor.opacity(0.85))
            FretboardRenderer.strokeCircle(context: &context, center: p, radius: radius, color: .white, lineWidth: 1.5)
            
            if position.isRoot {
                let intervalText = Text("R")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                context.draw(intervalText, at: p)
            }
        }
    }
    
    private func handleTap(at location: CGPoint, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let layout = FretboardLayout(
            maxFret: viewModel.maxFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: 24
        )
        guard let hit = layout.hitTest(at: location) else { return }
        let note = viewModel.getNoteAt(string: hit.string, fret: hit.fret)
        viewModel.selectPosition(FretboardPosition(string: hit.string, fret: hit.fret, note: note))
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let layout = FretboardLayout(
            maxFret: viewModel.maxFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: 24
        )
        let startLocation = value.startLocation
        
        if viewModel.draggedBlockId == nil {
            let hitRadius: CGFloat = 13
            for block in viewModel.blocks {
                guard viewModel.selectedBlockTypes.contains(block.type) else { continue }
                for position in block.positions {
                    let p = layout.point(for: position)
                    let distance = hypot(startLocation.x - p.x, startLocation.y - p.y)
                    if distance <= hitRadius {
                        viewModel.startDraggingBlock(block.id)
                        break
                    }
                }
                if viewModel.draggedBlockId != nil { break }
            }
        }
        
        if let blockId = viewModel.draggedBlockId {
            viewModel.updateBlockDrag(blockId, offset: value.translation)
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, fretWidth: CGFloat, stringSpacing: CGFloat) {
        if let blockId = viewModel.draggedBlockId {
            viewModel.endDraggingBlock(blockId, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
    }
}

#Preview {
    NavigationView {
        FretboardView()
    }
}

