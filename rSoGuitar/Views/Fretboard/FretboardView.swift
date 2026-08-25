//
//  FretboardView.swift
//  rSoGuitar
//
//  Interactive fretboard visualization
//

import SwiftUI

struct FretboardView: View {
    @StateObject private var viewModel = FretboardViewModel()
    @StateObject private var player = PatternPlayer()
    @State private var fretWidth: CGFloat = 40
    @State private var stringSpacing: CGFloat = 30
    @State private var showAdvancedControls = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                controlsView
            }
            .frame(maxHeight: showAdvancedControls ? 360 : 220)
            
            // Fretboard
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                fretboardCanvas
                    .frame(width: canvasMinWidth, height: canvasMinHeight)
                    .background(viewModel.showInfiniteBassPattern ? Color.white : Color.clear)
                    // Reserve headroom so the fret-number row never overlaps the high-E string.
                    .padding(.top, 26)
                    .padding([.horizontal, .bottom])
            }
            
            if showsPatternPlayer {
                VStack(spacing: 8) {
                    PatternDisplayModePicker(player: player)
                        .padding(.horizontal)
                    if player.isStepMode {
                        PatternPlayerPanel(player: player, blockCaption: blockCaption)
                    }
                }
                .padding(.bottom, 8)
                .background(Color(.systemGray6))
            }
        }
        .navigationTitle("Fretboard Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.inspectedBlock) { block in
            BlockDetailSheet(block: block)
        }
        .onAppear {
            player.load(viewModel.selectedPattern)
            if ProcessInfo.processInfo.arguments.contains("-rsogAutoPlay") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    player.setDisplayMode(.step)
                    if !player.isPlaying {
                        player.playPause()
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedPattern?.id) { _, _ in
            player.load(viewModel.selectedPattern)
        }
        .onChange(of: viewModel.showInfiniteBassPattern) { _, enabled in
            if enabled { player.stop() }
        }
        .onDisappear {
            player.stop()
        }
    }
    
    private var showsPatternPlayer: Bool {
        viewModel.selectedPattern != nil && !viewModel.showInfiniteBassPattern
    }
    
    private var blockCaption: String {
        guard viewModel.showBlocks, !displayedBlocks.isEmpty else { return "" }
        return displayedBlocks.map { RSOGConceptInfo.blockTitle($0.type) }.joined(separator: " · ")
    }
    
    private var displayedBlocks: [Block] {
        if player.displayMode == .step, viewModel.selectedPattern != nil, !player.steps.isEmpty {
            return BlockGenerator.visibleTiledBlocks(
                for: viewModel.selectedKey,
                maxFret: viewModel.maxFret,
                atRunIndex: max(0, player.clampedStep)
            )
        }
        return viewModel.blocks
    }
    
    private var canvasMinWidth: CGFloat {
        CGFloat(viewModel.maxFret + 1) * fretWidth + 24 + (viewModel.showInfiniteBassPattern ? 80 : 0)
    }
    
    private var canvasMinHeight: CGFloat {
        if viewModel.showInfiniteBassPattern {
            let total = FretboardLayout.infiniteBassVirtualCount(
                extendedStringCount: viewModel.extendedStringCount
            )
            return CGFloat(total) * stringSpacing
        }
        return CGFloat(Constants.numberOfStrings) * stringSpacing
    }
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            // RSOG concept picker — front and center
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("rSoG Concept")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button {
                        viewModel.enableOverviewMode()
                    } label: {
                        Label("Overview", systemImage: "square.3.layers.3d")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(viewModel.isOverviewMode ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(viewModel.isOverviewMode ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                Picker("Concept", selection: Binding(
                    get: { viewModel.patternType },
                    set: { viewModel.setPatternType($0) }
                )) {
                    ForEach(RSOGConceptInfo.allConcepts, id: \.self) { type in
                        Text(RSOGConceptInfo.title(for: type)).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Text(viewModel.isOverviewMode
                      ? "Overview: HEAD → BRIDGE → TRIPLE with the spiral path of all correct notes."
                      : RSOGConceptInfo.shortDescription(for: viewModel.patternType))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
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
            
            // Block legend + toggles
            VStack(spacing: 8) {
                RSOGBlockLegendView(selectedTypes: viewModel.selectedBlockTypes, compact: true)
                
                HStack(spacing: 12) {
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
                
                if let groups = viewModel.selectedPattern?.chordGroups, !groups.isEmpty {
                    RSOGChordLegendView(groups: groups)
                }
            }
            
            DisclosureGroup("More controls", isExpanded: $showAdvancedControls) {
                VStack(spacing: 10) {
                    Toggle("Show Pattern Overlay", isOn: Binding(
                        get: { viewModel.showPatternOverlay },
                        set: { viewModel.setShowPatternOverlay($0) }
                    ))
                    
                    Toggle("Show Blocks", isOn: Binding(
                        get: { viewModel.showBlocks },
                        set: { viewModel.setShowBlocks($0) }
                    ))
                    
                    Toggle("Show Full Diatonic Pattern", isOn: $viewModel.showFullPattern)
                        .onChange(of: viewModel.showFullPattern) { _, newValue in
                            if newValue { viewModel.updateDiatonicPattern() }
                            viewModel.isOverviewMode = false
                        }
                    
                    Toggle("Show Infinite Bass Pattern", isOn: Binding(
                        get: { viewModel.showInfiniteBassPattern },
                        set: { newValue in
                            if newValue != viewModel.showInfiniteBassPattern {
                                viewModel.toggleInfiniteBassPattern()
                            }
                        }
                    ))
                    
                    if viewModel.showInfiniteBassPattern {
                        HStack(spacing: 12) {
                            Button("←") { viewModel.shiftPattern(fretDelta: -1, stringDelta: 0) }
                            Button("→") { viewModel.shiftPattern(fretDelta: 1, stringDelta: 0) }
                            Button("↑") { viewModel.shiftPattern(fretDelta: 0, stringDelta: 1) }
                            Button("↓") { viewModel.shiftPattern(fretDelta: 0, stringDelta: -1) }
                            Text("Shift Pattern").font(.caption)
                        }
                    }
                    
                    Toggle("Show CAGED", isOn: Binding(
                        get: { viewModel.showCAGED },
                        set: { newValue in
                            if newValue != viewModel.showCAGED {
                                viewModel.toggleCAGED()
                            }
                        }
                    ))
                    
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
                    }
                    
                    Toggle("Show Modes", isOn: Binding(
                        get: { viewModel.showModes },
                        set: { newValue in
                            if newValue != viewModel.showModes {
                                viewModel.toggleModes()
                            }
                        }
                    ))
                    
                    if viewModel.showModes {
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
                        }
                        
                        if let shape = viewModel.modeShape {
                            Text("\(viewModel.selectedKey.rootNote.rawValue) \(viewModel.selectedMode.rawValue) — \(shape.description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
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
                TimelineView(
                    .animation(
                        minimumInterval: 1.0 / 24.0,
                        paused: !(player.displayMode == .step && player.isPlaying)
                    )
                ) { timeline in
                    Canvas { context, size in
                        let cycle = 1.2
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: cycle) / cycle
                        drawFretboard(context: context, size: size, pulsePhase: phase)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let layout = currentLayout(for: geometry.size)
                            
                            // Check if we're in infinite bass pattern mode and should shift the pattern
                            if viewModel.showInfiniteBassPattern && viewModel.draggedBlockId == nil {
                                let fretDelta = Int(round(value.translation.width / layout.fretWidth))
                                let stringDelta = Int(round(-value.translation.height / layout.stringSpacing))
                                if abs(fretDelta) > 0 || abs(stringDelta) > 0 {
                                    viewModel.shiftPattern(fretDelta: fretDelta, stringDelta: stringDelta)
                                }
                            } else {
                                handleDragChanged(value, fretWidth: layout.fretWidth, stringSpacing: layout.stringSpacing)
                            }
                        }
                        .onEnded { value in
                            let layout = currentLayout(for: geometry.size)
                            
                            if viewModel.draggedBlockId == nil {
                                handleTap(
                                    at: value.location,
                                    fretWidth: layout.fretWidth,
                                    stringSpacing: layout.stringSpacing
                                )
                            } else {
                                handleDragEnded(value, fretWidth: layout.fretWidth, stringSpacing: layout.stringSpacing)
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
    
    private func drawFretboard(context: GraphicsContext, size: CGSize, pulsePhase: Double) {
        var context = context
        
        let layout: FretboardLayout
        if viewModel.showInfiniteBassPattern {
            layout = FretboardLayout.infiniteBass(
                canvasWidth: size.width,
                maxFret: viewModel.maxFret,
                stringSpacing: stringSpacing,
                extendedStringCount: viewModel.extendedStringCount
            )
            // Match GeometryReader-provided size (width may differ slightly from minWidth).
            var fitted = layout
            fitted.size = size
            fitted.originY = size.height / 2 - CGFloat(Constants.numberOfStrings) / 2 * fitted.stringSpacing
            fitted.fretWidth = max(1, size.width - fitted.labelOffset) / CGFloat(viewModel.maxFret + 1)
            
            FretboardRenderer.drawInfiniteBassScene(
                context: &context,
                layout: fitted,
                positions: viewModel.infiniteBassPattern
            )
            // Wallpaper mode matches the rSoG infinite-bass reference: spheres only.
            return
        }
        
        let fretWidth = size.width / CGFloat(viewModel.maxFret + 1)
        let stringSpacing = size.height / CGFloat(Constants.numberOfStrings)
        layout = FretboardLayout(
            maxFret: viewModel.maxFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: 24,
            stringCount: Constants.numberOfStrings,
            size: size
        )
        
        // Frets
        FretboardRenderer.drawGrid(context: &context, layout: layout, drawFrets: true, drawStrings: false)
        FretboardRenderer.drawGrid(context: &context, layout: layout, drawFrets: false, drawStrings: true)
        
        if viewModel.showBlocks && !viewModel.selectedBlockTypes.isEmpty {
            if viewModel.showFullPattern {
                FretboardRenderer.drawDiatonicPattern(
                    context: &context,
                    layout: layout,
                    positions: viewModel.diatonicPattern
                )
            }
            
            var offsets: [UUID: CGSize] = [:]
            for block in displayedBlocks {
                offsets[block.id] = viewModel.getBlockOffset(block.id)
            }
            FretboardRenderer.drawBlocks(
                context: &context,
                layout: layout,
                blocks: displayedBlocks,
                selectedTypes: viewModel.selectedBlockTypes,
                offsets: offsets,
                showOutlines: true,
                showNotePips: true,
                showLabels: true,
                preferPrimaryPlacements: false
            )
        }
        
        if viewModel.showCAGED {
            drawCAGEDShapes(context: context, size: size, layout: layout)
        }
        
        if viewModel.showModes {
            drawModeShape(context: context, size: size, layout: layout)
        }
        
        if viewModel.showPatternOverlay, let pattern = viewModel.selectedPattern, player.displayMode == .step {
            FretboardRenderer.drawPatternPlayer(
                context: &context,
                layout: layout,
                pattern: pattern,
                steps: player.steps,
                currentStep: player.clampedStep,
                pulsePhase: pulsePhase
            )
        } else if viewModel.showPatternOverlay, let pattern = viewModel.selectedPattern {
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
                blocks: displayedBlocks,
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
    
    private func currentLayout(for size: CGSize) -> FretboardLayout {
        if viewModel.showInfiniteBassPattern {
            var layout = FretboardLayout.infiniteBass(
                canvasWidth: size.width,
                maxFret: viewModel.maxFret,
                stringSpacing: stringSpacing,
                extendedStringCount: viewModel.extendedStringCount
            )
            layout.size = size
            layout.originY = size.height / 2 - CGFloat(Constants.numberOfStrings) / 2 * layout.stringSpacing
            layout.fretWidth = max(1, size.width - layout.labelOffset) / CGFloat(viewModel.maxFret + 1)
            return layout
        }
        return FretboardLayout(
            maxFret: viewModel.maxFret,
            fretWidth: max(1, size.width - 24) / CGFloat(viewModel.maxFret + 1),
            stringSpacing: size.height / CGFloat(Constants.numberOfStrings),
            labelOffset: 24,
            stringCount: Constants.numberOfStrings,
            size: size
        )
    }
    
    private func handleTap(at location: CGPoint, fretWidth: CGFloat, stringSpacing: CGFloat) {
        // Prefer a layout that includes originY when infinite bass is active.
        let layout: FretboardLayout
        if viewModel.showInfiniteBassPattern {
            layout = currentLayout(for: CGSize(
                width: CGFloat(viewModel.maxFret + 1) * fretWidth + 24,
                height: canvasMinHeight
            ))
        } else {
            layout = FretboardLayout(
                maxFret: viewModel.maxFret,
                fretWidth: fretWidth,
                stringSpacing: stringSpacing,
                labelOffset: 24
            )
        }
        
        // In step mode, tapping a pattern note jumps the scrubber.
        if player.displayMode == .step, !player.steps.isEmpty,
           let hit = layout.hitTest(at: location) {
            let probe = FretboardPosition(string: hit.string, fret: hit.fret, note: .C)
            if let index = PatternSequencer.stepIndex(at: probe, in: player.steps) {
                player.seek(index)
                return
            }
        }
        
        // Prefer inspecting a block when the tap lands on a block note.
        if viewModel.showBlocks && !viewModel.showInfiniteBassPattern,
           let block = blockAt(location: location, layout: layout) {
            viewModel.inspectBlock(block)
            return
        }
        
        guard let hit = layout.hitTest(at: location) else { return }
        let note = viewModel.getNoteAt(string: hit.string, fret: hit.fret)
        viewModel.selectPosition(FretboardPosition(string: hit.string, fret: hit.fret, note: note))
    }
    
    private func blockAt(location: CGPoint, layout: FretboardLayout) -> Block? {
        let hitRadius: CGFloat = 14
        var best: (block: Block, distance: CGFloat)?
        
        for block in displayedBlocks {
            guard viewModel.selectedBlockTypes.contains(block.type) else { continue }
            let offset = viewModel.getBlockOffset(block.id)
            for position in block.positions {
                let p = layout.point(for: position, offset: offset)
                let distance = hypot(location.x - p.x, location.y - p.y)
                if distance <= hitRadius {
                    if best == nil || distance < best!.distance {
                        best = (block, distance)
                    }
                }
            }
        }
        return best?.block
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
            for block in displayedBlocks {
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

