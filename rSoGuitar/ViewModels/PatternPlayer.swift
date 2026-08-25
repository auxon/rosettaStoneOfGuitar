//
//  PatternPlayer.swift
//  rSoGuitar
//
//  Shared step-through player used by lesson PatternView and the Fretboard tab.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PatternPlayer: ObservableObject {
    enum DisplayMode: String, CaseIterable {
        case step = "Step-by-step"
        case full = "Full pattern"
    }
    
    @Published var displayMode: DisplayMode = .step
    @Published private(set) var steps: [PatternStep] = []
    @Published var currentStep: Int = -1
    @Published var isPlaying: Bool = false
    @Published var loops: Bool = true
    @Published var speed: Double = 1.0
    
    static let speedOptions: [Double] = [0.5, 1.0, 1.5, 2.0]
    
    /// Seconds between frames at 1× speed.
    private let baseInterval: Double = 0.9
    private let audioService = AudioService.shared
    private var playbackTask: Task<Void, Never>?
    
    var clampedStep: Int {
        guard !steps.isEmpty else { return -1 }
        return min(max(currentStep, -1), steps.count - 1)
    }
    
    var isStepMode: Bool {
        displayMode == .step && !steps.isEmpty
    }
    
    func load(_ pattern: Pattern?) {
        steps = pattern.map { PatternSequencer.steps(for: $0) } ?? []
        stop()
        currentStep = -1
    }
    
    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        if mode == .step {
            currentStep = steps.isEmpty ? -1 : 0
            playCurrentStepAudio()
        } else {
            stop()
        }
    }
    
    func playPause() {
        if isPlaying {
            stop()
            return
        }
        guard !steps.isEmpty else { return }
        if currentStep >= steps.count - 1 { currentStep = -1 }
        isPlaying = true
        runLoop()
    }
    
    func stop() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }
    
    func seek(_ step: Int) {
        stop()
        guard !steps.isEmpty else {
            currentStep = -1
            return
        }
        currentStep = min(max(step, -1), steps.count - 1)
        playCurrentStepAudio()
    }
    
    func goToStart() {
        stop()
        currentStep = -1
    }
    
    func goToEnd() {
        stop()
        guard !steps.isEmpty else { return }
        currentStep = steps.count - 1
        playCurrentStepAudio()
    }
    
    func stepForward() {
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
    
    func stepBackward() {
        guard !steps.isEmpty else { return }
        currentStep = max(-1, currentStep - 1)
        if currentStep >= 0 {
            playCurrentStepAudio()
        }
    }
    
    func setSpeed(_ value: Double) {
        speed = value
        if isPlaying { runLoop() }
    }
    
    func playCurrentStepAudio() {
        guard clampedStep >= 0, clampedStep < steps.count else { return }
        let positions = steps[clampedStep].positions
        if positions.count == 1 {
            audioService.playNoteAt(string: positions[0].string, fret: positions[0].fret)
        } else {
            audioService.playNotes(positions)
        }
    }
    
    private func runLoop() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                try? await Task.sleep(for: .seconds(self.baseInterval / self.speed))
                guard !Task.isCancelled else { return }
                guard self.isPlaying else { return }
                
                if self.currentStep >= self.steps.count - 1 {
                    if self.loops {
                        self.currentStep = -1
                    } else {
                        self.stop()
                        return
                    }
                }
                self.stepForward()
            }
        }
    }
}
