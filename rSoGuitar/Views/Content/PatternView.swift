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
                chordLegend
            }
            
            Toggle("Show Blocks", isOn: $showBlocks)
                .padding(.horizontal)
                .onChange(of: showBlocks) { _, newValue in
                    if newValue && selectedBlockTypes.isEmpty {
                        selectedBlockTypes = [.headBlock, .bridgeBlock, .tripleBlock]
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
    }
    
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
