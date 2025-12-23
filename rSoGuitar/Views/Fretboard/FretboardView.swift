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
                            color: .blue
                        ) {
                            viewModel.toggleBlock(.headBlock)
                        }
                        
                        BlockToggleButton(
                            title: "BRIDGE",
                            isSelected: viewModel.selectedBlockTypes.contains(.bridgeBlock),
                            color: .green
                        ) {
                            viewModel.toggleBlock(.bridgeBlock)
                        }
                        
                        BlockToggleButton(
                            title: "TRIPLE",
                            isSelected: viewModel.selectedBlockTypes.contains(.tripleBlock),
                            color: .orange
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
                                handleDragChanged(value, fretWidth: calculatedFretWidth, stringSpacing: calculatedStringSpacing)
                            }
                        }
                        .onEnded { value in
                            let totalStrings = viewModel.showInfiniteBassPattern ? viewModel.extendedStringCount : Constants.numberOfStrings
                            let calculatedFretWidth = geometry.size.width / CGFloat(viewModel.maxFret + 1)
                            let calculatedStringSpacing = geometry.size.height / CGFloat(totalStrings)
                            
                            if viewModel.draggedBlockId == nil {
                                // If not dragging a block, treat as tap
                                handleTap(at: value.location)
                            } else {
                                // End block drag
                                handleDragEnded(value, fretWidth: calculatedFretWidth, stringSpacing: calculatedStringSpacing)
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
        // Calculate string spacing based on extended string count if infinite bass pattern is shown
        let totalStrings = viewModel.showInfiniteBassPattern ? viewModel.extendedStringCount : Constants.numberOfStrings
        let fretWidth = size.width / CGFloat(viewModel.maxFret + 1)
        let stringSpacing = size.height / CGFloat(totalStrings)
        
        // Offset for string labels
        let labelOffset: CGFloat = 24
        
        // Draw frets (vertical lines)
        for fret in 0...viewModel.maxFret {
            let x = CGFloat(fret) * fretWidth + labelOffset
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(.gray),
                lineWidth: fret == 0 ? 3 : 1
            )
        }
        
        // Draw strings (horizontal lines)
        // If showing infinite bass pattern, draw extended strings
        let stringRange = viewModel.showInfiniteBassPattern ? 
            (1 - viewModel.extendedStringCount / 2 + viewModel.patternOffset.string)...(Constants.numberOfStrings + viewModel.extendedStringCount / 2 + viewModel.patternOffset.string) :
            (1...Constants.numberOfStrings)
        
        for virtualString in stringRange {
            // Calculate visual position (centered around physical strings 1-6)
            let physicalStringCenter = CGFloat(Constants.numberOfStrings) / 2.0 + 0.5
            let virtualStringOffset = CGFloat(virtualString - Int(physicalStringCenter))
            let y = size.height / 2.0 + virtualStringOffset * stringSpacing
            
            // Highlight physical strings (1-6) with thicker lines
            let isPhysicalString = virtualString >= 1 && virtualString <= Constants.numberOfStrings
            let lineWidth: CGFloat = isPhysicalString ? 2 : 0.5
            let lineColor: Color = isPhysicalString ? .gray : .gray.opacity(0.3)
            
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: labelOffset, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(lineColor),
                lineWidth: lineWidth
            )
        }
        
        // Draw block overlay if enabled (draw first so it's behind patterns)
        if viewModel.showBlocks && !viewModel.selectedBlockTypes.isEmpty {
            drawBlockOverlay(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw infinite bass pattern if enabled
        if viewModel.showInfiniteBassPattern {
            drawInfiniteBassPattern(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw CAGED shapes if enabled
        if viewModel.showCAGED {
            drawCAGEDShapes(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw pattern overlay if enabled
        if viewModel.showPatternOverlay {
            drawPatternOverlay(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw note positions (but skip positions that are in selected blocks to avoid covering them)
        drawNotePositions(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
    }
    
    private func drawBlockOverlay(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let labelOffset: CGFloat = 24
        
        // Draw full diatonic pattern if enabled
        if viewModel.showFullPattern {
        for position in viewModel.diatonicPattern {
                let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
                let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
                
                // Use bright green for diatonic pattern notes - visible in dark mode
                let color: Color = position.isRoot ? Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.7) : Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.45)
                let radius: CGFloat = position.isRoot ? 6 : 5
                
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
        
        // Draw blocks by highlighting each note with a colored square
        for block in viewModel.blocks {
            guard viewModel.selectedBlockTypes.contains(block.type) else { continue }
            
            guard !block.positions.isEmpty else { continue }
            
            // Get drag offset for this block
            let offset = viewModel.getBlockOffset(block.id)
            
            let color = blockColor(block.type)
            let squareSize: CGFloat = 16  // Size of the square highlight
            
            // Draw a colored square for each note in the block
            for position in block.positions {
                let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset + offset.width
                let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing + offset.height
                
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
                let labelX = CGFloat(firstPos.fret) * fretWidth + fretWidth / 2 + labelOffset + offset.width
                let labelY = (CGFloat(firstPos.string - 1) + 0.5) * stringSpacing + offset.height - 20
                
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
    
    private func drawCAGEDShapes(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let labelOffset: CGFloat = 24
        
        guard !viewModel.cagedShapes.isEmpty else { return }
        
        // Draw each selected CAGED shape
        for shape in viewModel.cagedShapes {
            guard viewModel.selectedCAGEDForms.contains(shape.form) else { continue }
            guard !shape.positions.isEmpty else { continue }
            
            // Vibrant colors that work in both light and dark mode
            let brightCyan: Color = Color(red: 0.0, green: 0.9, blue: 1.0)  // Bright cyan for chord tones
            let rootOrange: Color = Color(red: 1.0, green: 0.6, blue: 0.0)  // Orange for root notes
            let squareSize: CGFloat = 18  // Larger for better visibility
            
            // Draw a colored square for each note in the CAGED shape
            for position in shape.positions {
                // Calculate position - ensure fret and string are valid
                guard position.fret >= 0 && position.fret <= viewModel.maxFret else { continue }
                guard position.string >= 1 && position.string <= Constants.numberOfStrings else { continue }
                
                let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
                let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
                
                let squareRect = CGRect(
                    x: x - squareSize / 2,
                    y: y - squareSize / 2,
                    width: squareSize,
                    height: squareSize
                )
                
                var squarePath = Path()
                squarePath.addRect(squareRect)
                
                // Use orange for root notes, bright cyan for others - high visibility in dark mode
                let fillColor = position.isRoot ? rootOrange : brightCyan
                let strokeColor: Color = .white  // White outline for dark mode visibility
                
                context.fill(squarePath, with: .color(fillColor.opacity(0.9)))
                context.stroke(squarePath, with: .color(strokeColor), lineWidth: 2.0)
            }
            
            // Draw CAGED form label at the root position
            let labelX = CGFloat(shape.rootPosition.fret) * fretWidth + fretWidth / 2 + labelOffset
            let labelY = (CGFloat(shape.rootPosition.string - 1) + 0.5) * stringSpacing - 20
            
            // Draw background rectangle for label
            let labelWidth = CGFloat(max(40, shape.form.rawValue.count * 8))
            let labelHeight: CGFloat = 18
            let labelRect = CGRect(
                x: labelX - labelWidth / 2,
                y: labelY - labelHeight / 2,
                width: labelWidth,
                height: labelHeight
            )
            
            var bgPath = Path()
            bgPath.addRoundedRect(in: labelRect, cornerSize: CGSize(width: 4, height: 4))
            let labelBgColor = Color(red: 0.2, green: 0.2, blue: 0.3)  // Dark gray-blue background
            context.fill(bgPath, with: .color(labelBgColor.opacity(0.95)))
            context.stroke(bgPath, with: .color(.white), lineWidth: 1.5)
            
            // Draw label text
            let text = Text(shape.form.rawValue)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
            context.draw(text, at: CGPoint(x: labelX, y: labelY))
        }
    }
    
    private func blockColor(_ type: BlockType) -> Color {
        switch type {
        case .headBlock:
            return Color(red: 0.4, green: 0.8, blue: 1.0)  // Bright sky blue
        case .bridgeBlock:
            return Color(red: 0.4, green: 1.0, blue: 0.6)  // Bright mint green
        case .tripleBlock:
            return Color(red: 1.0, green: 0.7, blue: 0.3)  // Bright orange-yellow
        }
    }
    
    private func drawPatternOverlay(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let labelOffset: CGFloat = 24
        for position in viewModel.highlightedPositions {
            let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
            let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
            
            // Bright colors for dark mode visibility
            let rootColor = Color(red: 0.3, green: 0.7, blue: 1.0)  // Bright blue for root
            let noteColor = Color(red: 0.3, green: 0.9, blue: 0.4)  // Bright green for other notes
            let color: Color = position.isRoot ? rootColor : noteColor
            let radius: CGFloat = position.isRoot ? 12 : 8
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .color(color.opacity(0.8))
            )
        }
    }
    
    private func drawNotePositions(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        // Draw all note positions as tappable circles
        for string in 1...Constants.numberOfStrings {
            for fret in 0...viewModel.maxFret {
                let note = viewModel.getNoteAt(string: string, fret: fret)
                let position = FretboardPosition(string: string, fret: fret, note: note)
                
                let labelOffset: CGFloat = 24
                let x = CGFloat(fret) * fretWidth + fretWidth / 2 + labelOffset
                let y = (CGFloat(string - 1) + 0.5) * stringSpacing
                
                let isSelected = viewModel.isPositionSelected(position)
                let isHighlighted = viewModel.isPositionHighlighted(position)
                
                // Check if this position is in a selected block - if so, skip drawing here (already drawn in block overlay)
                let isInSelectedBlock = viewModel.showBlocks && 
                    viewModel.blocks.contains { block in
                        viewModel.selectedBlockTypes.contains(block.type) &&
                        block.positions.contains { blockPos in
                            blockPos.string == position.string && blockPos.fret == position.fret
                        }
                    }
                
                // Skip drawing if it's in a selected block (already drawn above)
                if isInSelectedBlock && !isSelected {
                    continue
                }
                
                let color: Color = isSelected ? Color(red: 1.0, green: 0.3, blue: 0.3) : (isHighlighted ? .clear : .gray.opacity(0.5))
                let radius: CGFloat = isSelected ? 10 : 6
                
                if !isHighlighted || isSelected {
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
                
                // Draw note name
                if isSelected {
                    let text = Text(note.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white)
                    context.draw(text, at: CGPoint(x: x, y: y))
                }
            }
        }
    }
    
    private func handleTap(at location: CGPoint) {
        let fretWidth = CGFloat(viewModel.maxFret + 1) * 40
        let stringSpacing = CGFloat(Constants.numberOfStrings) * 30
        let labelOffset: CGFloat = 24
        
        // Account for label offset when calculating fret
        let adjustedX = location.x - labelOffset
        let fret = Int(adjustedX / (fretWidth / CGFloat(viewModel.maxFret + 1)))
        // Invert string calculation: y=0 is now string 6 (low E), y=max is string 1 (high E)
        let stringIndex = Int(location.y / (stringSpacing / CGFloat(Constants.numberOfStrings)))
        let string = stringIndex + 1
        
        guard fret >= 0 && fret <= viewModel.maxFret &&
              string >= 1 && string <= Constants.numberOfStrings else {
            return
        }
        
        let note = viewModel.getNoteAt(string: string, fret: fret)
        let position = FretboardPosition(string: string, fret: fret, note: note)
        viewModel.selectPosition(position)
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, fretWidth: CGFloat, stringSpacing: CGFloat) {
        let labelOffset: CGFloat = 24
        let startLocation = value.startLocation
        
        // If we're not already dragging a block, check if we're starting to drag one
        if viewModel.draggedBlockId == nil {
            // Find which block contains the start point by checking if it's near any note square
            let squareSize: CGFloat = 16
            let hitRadius = squareSize / 2 + 5  // Add some padding for easier dragging
            
            for block in viewModel.blocks {
                guard viewModel.selectedBlockTypes.contains(block.type) else { continue }
                guard !block.positions.isEmpty else { continue }
                
                // Check if the start location is within any note square in this block
                for position in block.positions {
                    let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
                    let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
                    
                    let distance = sqrt(pow(startLocation.x - x, 2) + pow(startLocation.y - y, 2))
                    if distance <= hitRadius {
                        // Start dragging this block
                        viewModel.startDraggingBlock(block.id)
                        break
                    }
                }
                
                if viewModel.draggedBlockId != nil { break }
            }
        }
        
        // Update drag offset if we're dragging a block
        if let blockId = viewModel.draggedBlockId {
            let offset = value.translation
            viewModel.updateBlockDrag(blockId, offset: offset)
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

