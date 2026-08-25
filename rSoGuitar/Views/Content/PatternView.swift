//
//  PatternView.swift
//  rSoGuitar
//
//  View for displaying patterns on the fretboard.
//  Step mode plays through the pattern frame by frame (play / pause /
//  frame forward / frame back / loop); Full mode shows everything at once.
//

import SwiftUI

struct PatternView: View {
    let pattern: Pattern
    var initialShowBlocks: Bool = false
    var initialBlockTypes: Set<BlockType> = []

    // MARK: Display state

    @StateObject private var player = PatternPlayer()
    @State private var selectedPosition: FretboardPosition?
    @State private var showBlocks: Bool = false
    @State private var selectedBlockTypes: Set<BlockType> = []
    @State private var didApplyInitialBlocks = false

    private let audioService = AudioService.shared
    private let maxDisplayFret = 12

    private var blocks: [Block] {
        switch player.displayMode {
        case .full:
            BlockGenerator.tiledBlocks(for: pattern.key, maxFret: maxDisplayFret)
        case .step:
            BlockGenerator.visibleTiledBlocks(
                for: pattern.key,
                maxFret: maxDisplayFret,
                atRunIndex: max(0, player.clampedStep)
            )
        }
    }
    
    private var blockCaption: String {
        guard showBlocks, !blocks.isEmpty else { return "" }
        return blocks.map { RSOGConceptInfo.blockTitle($0.type) }.joined(separator: " · ")
    }

    private var boardSize: CGSize {
        CGSize(
            width: CGFloat(maxDisplayFret + 1) * fretWidth,
            height: CGFloat(Constants.numberOfStrings) * stringSpacing
        )
    }

    @State private var fretWidth: CGFloat = 40
    @State private var stringSpacing: CGFloat = 30

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

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            header

            if !pattern.chordGroups.isEmpty {
                RSOGChordLegendView(groups: pattern.chordGroups)
                    .padding(.horizontal)
            }

            blockControls

            fretboardArea

            if player.isStepMode {
                PatternPlayerPanel(player: player, blockCaption: blockCaption)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            applyInitialBlocksIfNeeded()
            player.load(pattern)
        }
        .onChange(of: pattern.id) { _, _ in
            player.load(pattern)
        }
        .onDisappear {
            player.stop()
        }
    }

    // MARK: Header & controls

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text(pattern.name)
                    .font(.headline)
                Spacer()
                Text("\(pattern.positions.count) positions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            PatternDisplayModePicker(player: player)
                .padding(.horizontal)
        }
    }

    private var blockControls: some View {
        VStack(spacing: 8) {
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

            if showBlocks || !selectedBlockTypes.isEmpty {
                RSOGBlockLegendView(selectedTypes: $selectedBlockTypes, compact: true)
                    .padding(.horizontal)
                    .onChange(of: selectedBlockTypes) { _, newValue in
                        if !newValue.isEmpty && !showBlocks {
                            showBlocks = true
                        } else if newValue.isEmpty && showBlocks {
                            showBlocks = false
                        }
                    }
            }
        }
    }

    // MARK: Fretboard

    private var fretboardArea: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            TimelineView(
                .animation(minimumInterval: 1.0 / 24.0, paused: !(player.displayMode == .step && player.isPlaying))
            ) { timeline in
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
                            selectedTypes: selectedBlockTypes,
                            showLabels: true
                        )
                    }

                    switch player.displayMode {
                    case .step:
                        let cycle: Double = 1.2
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: cycle) / cycle
                        FretboardRenderer.drawPatternPlayer(
                            context: &context,
                            layout: layout,
                            pattern: pattern,
                            steps: player.steps,
                            currentStep: player.clampedStep,
                            pulsePhase: phase
                        )

                    case .full:
                        FretboardRenderer.drawPattern(context: &context, layout: layout, pattern: pattern)

                        if let selected = selectedPosition {
                            FretboardRenderer.fillCircle(
                                context: &context,
                                center: layout.point(for: selected),
                                radius: 12,
                                color: RSOGPalette.selectedNote.opacity(0.55)
                            )
                        }
                    }
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
        .frame(minHeight: 240)
    }

    // MARK: Interaction

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
        guard let hit = layout.hitTest(at: location) else { return }

        switch player.displayMode {
        case .step:
            if let index = PatternSequencer.stepIndex(
                at: FretboardPosition(string: hit.string, fret: hit.fret, note: .C),
                in: player.steps
            ) {
                player.seek(index)
            }

        case .full:
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
}

#Preview {
    NavigationStack {
        ScrollView {
            let pattern = FretboardCalculator.spiralMappingPattern(for: .C)
            PatternView(pattern: pattern)
        }
    }
}
