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

    @State private var selectedPosition: FretboardPosition?
    @State private var showBlocks: Bool = false
    @State private var selectedBlockTypes: Set<BlockType> = []
    @State private var didApplyInitialBlocks = false

    // MARK: Step-player state

    enum DisplayMode: String, CaseIterable {
        case step = "Step-by-step"
        case full = "Full pattern"
    }

    @State private var displayMode: DisplayMode = .step
    @State private var steps: [PatternStep] = []
    @State private var currentStep: Int = -1
    @State private var isPlaying: Bool = false
    @State private var loops: Bool = true
    @State private var speed: Double = 1.0

    private let audioService = AudioService.shared
    private let maxDisplayFret = 12
    /// Seconds between frames at 1× speed.
    private let baseInterval: Double = 0.9

    private static let speedOptions: [Double] = [0.5, 1.0, 1.5, 2.0]

    private var blocks: [Block] {
        // Spiral-run tiling so HEAD/BRIDGE/TRIPLE align with the step player path.
        BlockGenerator.tiledBlocks(for: pattern.key, maxFret: maxDisplayFret)
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

    private var clampedStep: Int {
        guard !steps.isEmpty else { return -1 }
        return min(max(currentStep, -1), steps.count - 1)
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

            if displayMode == .step && !steps.isEmpty {
                playerPanel
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            applyInitialBlocksIfNeeded()
            rebuildSteps()
        }
        .onChange(of: pattern.id) { _, _ in
            rebuildSteps()
        }
        .task(id: taskIdentity) {
            await runPlaybackLoopIfNeeded()
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

            Picker("Display", selection: $displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: displayMode) { _, newMode in
                if newMode == .step {
                    currentStep = steps.isEmpty ? -1 : 0
                    playCurrentStepAudio()
                } else {
                    stopPlayback()
                }
            }
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
                .animation(minimumInterval: 1.0 / 24.0, paused: !(displayMode == .step && isPlaying))
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
                        // Outlines only during playback — label chips collide with
                        // pulse rings / note names; captions live in the player panel.
                        FretboardRenderer.drawBlocks(
                            context: &context,
                            layout: layout,
                            blocks: blocks,
                            selectedTypes: selectedBlockTypes,
                            showLabels: displayMode == .full
                        )
                    }

                    switch displayMode {
                    case .step:
                        let cycle: Double = 1.2
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: cycle) / cycle
                        FretboardRenderer.drawPatternPlayer(
                            context: &context,
                            layout: layout,
                            pattern: pattern,
                            steps: steps,
                            currentStep: clampedStep,
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

    // MARK: Player panel

    private var playerPanel: some View {
        VStack(spacing: 10) {
            // Progress
            HStack(spacing: 10) {
                Text("\(max(0, clampedStep) + 1)/\(steps.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(minWidth: 52, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { Double(max(0, clampedStep)) },
                        set: { newValue in
                            stopPlayback()
                            currentStep = Int(newValue)
                            playCurrentStepAudio()
                        }
                    ),
                    in: 0...Double(max(0, steps.count - 1)),
                    step: 1
                )
            }
            .padding(.horizontal)

            // Step caption
            Group {
                if clampedStep >= 0 {
                    Text(steps[clampedStep].subtitle.isEmpty
                         ? steps[clampedStep].title
                         : "\(steps[clampedStep].title) — \(steps[clampedStep].subtitle)")
                        .font(.subheadline.weight(.medium))
                } else {
                    Text("Press play to walk the pattern")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            // Transport
            HStack(spacing: 18) {
                Button {
                    stopPlayback()
                    currentStep = -1
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                .disabled(clampedStep <= -1)

                Button {
                    stopPlayback()
                    stepBackward()
                } label: {
                    Image(systemName: "backward.frame")
                }
                .disabled(clampedStep <= -1)

                Button {
                    if isPlaying {
                        stopPlayback()
                    } else {
                        if clampedStep >= steps.count - 1 { currentStep = -1 }
                        isPlaying = true
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color.accentColor))
                }

                Button {
                    stopPlayback()
                    stepForward()
                } label: {
                    Image(systemName: "forward.frame")
                }
                .disabled(clampedStep >= steps.count - 1)

                Button {
                    stopPlayback()
                    currentStep = steps.count - 1
                    playCurrentStepAudio()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .disabled(clampedStep >= steps.count - 1)
            }
            .font(.body.weight(.semibold))

            // Loop + speed row
            HStack {
                Button {
                    loops.toggle()
                } label: {
                    Label("Loop", systemImage: "repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(loops ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(loops ? Color.accentColor : Color(.systemGray5))
                        )
                }

                Spacer()

                Menu {
                    ForEach(Self.speedOptions, id: \.self) { option in
                        Button {
                            speed = option
                        } label: {
                            if speed == option {
                                Label(formatSpeed(option), systemImage: "checkmark")
                            } else {
                                Text(formatSpeed(option))
                            }
                        }
                    }
                } label: {
                    Label(formatSpeed(speed), systemImage: "gauge")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.systemGray5)))
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
    }

    // MARK: Playback engine

    /// Re-running the task whenever any of these change keeps timing exact.
    private var taskIdentity: String {
        "\(pattern.id.uuidString)|\(isPlaying)|\(speed)|\(loops)"
    }

    private func runPlaybackLoopIfNeeded() async {
        guard isPlaying, !steps.isEmpty else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(baseInterval / speed))
            guard !Task.isCancelled, isPlaying else { return }

            if currentStep >= steps.count - 1 {
                if loops {
                    currentStep = -1
                } else {
                    isPlaying = false
                    return
                }
            }
            stepForward()
        }
    }

    private func stepForward() {
        guard !steps.isEmpty else { return }
        if currentStep >= steps.count - 1 {
            if loops {
                currentStep = 0
            } else {
                currentStep = steps.count - 1
                return
            }
        } else {
            currentStep += 1
        }
        playCurrentStepAudio()
    }

    private func stepBackward() {
        guard !steps.isEmpty else { return }
        currentStep = max(-1, currentStep - 1)
        if currentStep >= 0 {
            playCurrentStepAudio()
        }
    }

    private func playCurrentStepAudio() {
        guard clampedStep >= 0, clampedStep < steps.count else { return }
        let positions = steps[clampedStep].positions
        if positions.count == 1 {
            audioService.playNoteAt(string: positions[0].string, fret: positions[0].fret)
        } else {
            audioService.playNotes(positions)
        }
    }

    private func stopPlayback() {
        isPlaying = false
    }

    private func formatSpeed(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f×", value) : String(format: "%.1f×", value)
    }

    private func rebuildSteps() {
        steps = PatternSequencer.steps(for: pattern)
        stopPlayback()
        currentStep = -1
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

        switch displayMode {
        case .step:
            // Jump to the frame containing the tapped note.
            if let index = PatternSequencer.stepIndex(
                at: FretboardPosition(string: hit.string, fret: hit.fret, note: .C),
                in: steps
            ) {
                stopPlayback()
                currentStep = index
                playCurrentStepAudio()
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
