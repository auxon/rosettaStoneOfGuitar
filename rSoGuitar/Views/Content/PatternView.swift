//
//  PatternView.swift
//  rSoGuitar
//
//  View for displaying patterns on the fretboard
//

import SwiftUI

struct PatternView: View {
    let pattern: Pattern
    var initialShowBlocks: Bool = false
    var initialBlockTypes: Set<BlockType> = []
    
    @State private var fretWidth: CGFloat = 40
    @State private var stringSpacing: CGFloat = 30
    @State private var selectedPosition: FretboardPosition?
    @State private var showBlocks: Bool = false
    @State private var selectedBlockTypes: Set<BlockType> = []
    @State private var didApplyInitialBlocks = false
    
    private let audioService = AudioService.shared
    private let maxDisplayFret = 12
    
    private var blocks: [Block] {
        BlockGenerator.allBlocks(for: pattern.key, maxFret: maxDisplayFret)
    }
    
    private var boardSize: CGSize {
        CGSize(
            width: CGFloat(maxDisplayFret + 1) * fretWidth,
            height: CGFloat(Constants.numberOfStrings) * stringSpacing
        )
    }
    
    private var layout: FretboardLayout {
        FretboardLayout(
            maxFret: maxDisplayFret,
            fretWidth: fretWidth,
            stringSpacing: stringSpacing,
            labelOffset: 0,
            stringCount: Constants.numberOfStrings,
            size: boardSize
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
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
                RSOGChordLegendView(groups: pattern.chordGroups)
            }
            
            if showBlocks || !selectedBlockTypes.isEmpty {
                // Binding makes chips tappable so HEAD / BRIDGE / TRIPLE can be mixed.
                RSOGBlockLegendView(selectedTypes: $selectedBlockTypes, compact: true)
                    .onChange(of: selectedBlockTypes) { _, newValue in
                        if !newValue.isEmpty && !showBlocks {
                            showBlocks = true
                        } else if newValue.isEmpty && showBlocks {
                            showBlocks = false
                        }
                    }
            }
            
            Toggle("Show Blocks", isOn: $showBlocks)
                .padding(.horizontal)
                .onChange(of: showBlocks) { _, newValue in
                    if newValue && selectedBlockTypes.isEmpty {
                        selectedBlockTypes = initialBlockTypes.isEmpty
                            ? RSOGConceptInfo.demoBlocks(for: pattern.type)
                            : initialBlockTypes
                    } else if !newValue {
                        selectedBlockTypes.removeAll()
                    }
                }
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Canvas { context, size in
                    var context = context
                    let layout = FretboardLayout(
                        maxFret: maxDisplayFret,
                        fretWidth: fretWidth,
                        stringSpacing: stringSpacing,
                        labelOffset: 0,
                        size: size
                    )
                    
                    FretboardRenderer.drawGrid(context: &context, layout: layout)
                    
                    if showBlocks && !selectedBlockTypes.isEmpty {
                        FretboardRenderer.drawBlocks(
                            context: &context,
                            layout: layout,
                            blocks: blocks,
                            selectedTypes: selectedBlockTypes
                        )
                    }
                    
                    FretboardRenderer.drawPattern(context: &context, layout: layout, pattern: pattern)
                    
                    if let selected = selectedPosition {
                        let p = layout.point(for: selected)
                        FretboardRenderer.fillCircle(
                            context: &context,
                            center: p,
                            radius: 12,
                            color: RSOGPalette.selectedNote.opacity(0.55)
                        )
                    }
                }
                .frame(width: boardSize.width, height: boardSize.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleTap(at: value.location)
                        }
                )
                .padding()
            }
        }
        .onAppear {
            applyInitialBlocksIfNeeded()
        }
    }
    
    private func applyInitialBlocksIfNeeded() {
        guard !didApplyInitialBlocks else { return }
        didApplyInitialBlocks = true
        if initialShowBlocks {
            showBlocks = true
            selectedBlockTypes = initialBlockTypes.isEmpty
                ? RSOGConceptInfo.demoBlocks(for: pattern.type)
                : initialBlockTypes
        }
    }
    
    private func handleTap(at location: CGPoint) {
        // Account for padding in the gesture location roughly via layout hit-test
        // Location is relative to the padded content; Canvas gesture is on the frame.
        guard let hit = layout.hitTest(at: location) else { return }
        if let position = pattern.positions.first(where: { $0.string == hit.string && $0.fret == hit.fret }) {
            selectedPosition = position
            audioService.playNote(position.note)
        } else {
            let note = FretboardCalculator.noteAt(string: hit.string, fret: hit.fret)
            selectedPosition = FretboardPosition(string: hit.string, fret: hit.fret, note: note)
            audioService.playNote(note)
        }
    }
}

#Preview {
    let pattern = FretboardCalculator.spiralMappingPattern(for: .C)
    PatternView(pattern: pattern)
}
