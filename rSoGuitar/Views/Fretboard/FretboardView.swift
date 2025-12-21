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
                    .frame(minWidth: CGFloat(viewModel.maxFret + 1) * fretWidth,
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
        Canvas { context, size in
            drawFretboard(context: context, size: size)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTap(at: value.location)
                }
        )
    }
    
    private func drawFretboard(context: GraphicsContext, size: CGSize) {
        let fretWidth = size.width / CGFloat(viewModel.maxFret + 1)
        let stringSpacing = size.height / CGFloat(Constants.numberOfStrings)
        
        // Draw frets (vertical lines)
        for fret in 0...viewModel.maxFret {
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
        
        // Draw strings (horizontal lines)
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
        
        // Draw block overlay if enabled (draw first so it's behind patterns)
        if viewModel.showBlocks && !viewModel.selectedBlockTypes.isEmpty {
            drawBlockOverlay(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw pattern overlay if enabled
        if viewModel.showPatternOverlay {
            drawPatternOverlay(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
        }
        
        // Draw note positions
        drawNotePositions(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing)
    }
    
    private func drawBlockOverlay(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        for block in viewModel.blocks {
            guard viewModel.selectedBlockTypes.contains(block.type) else { continue }
            
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
    
    private func drawPatternOverlay(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        for position in viewModel.highlightedPositions {
            let x = CGFloat(position.fret) * fretWidth + fretWidth / 2
            let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
            
            let color: Color = position.isRoot ? .blue : .green
            let radius: CGFloat = position.isRoot ? 12 : 8
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .color(color.opacity(0.6))
            )
        }
    }
    
    private func drawNotePositions(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat) {
        // Draw all note positions as tappable circles
        for string in 1...Constants.numberOfStrings {
            for fret in 0...viewModel.maxFret {
                let note = viewModel.getNoteAt(string: string, fret: fret)
                let position = FretboardPosition(string: string, fret: fret, note: note)
                
                let x = CGFloat(fret) * fretWidth + fretWidth / 2
                let y = (CGFloat(string - 1) + 0.5) * stringSpacing
                
                let isSelected = viewModel.isPositionSelected(position)
                let isHighlighted = viewModel.isPositionHighlighted(position)
                
                let color: Color = isSelected ? .red : (isHighlighted ? .clear : .gray.opacity(0.3))
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
        
        let fret = Int(location.x / (fretWidth / CGFloat(viewModel.maxFret + 1)))
        let string = Int(location.y / (stringSpacing / CGFloat(Constants.numberOfStrings))) + 1
        
        guard fret >= 0 && fret <= viewModel.maxFret &&
              string >= 1 && string <= Constants.numberOfStrings else {
            return
        }
        
        let note = viewModel.getNoteAt(string: string, fret: fret)
        let position = FretboardPosition(string: string, fret: fret, note: note)
        viewModel.selectPosition(position)
    }
}

#Preview {
    NavigationView {
        FretboardView()
    }
}

