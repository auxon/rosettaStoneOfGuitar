//
//  RhythmViewModel.swift
//  rSoGuitar
//
//  Shared transport + pattern state for the Rhythm tab.
//

import Foundation
import Combine

enum RhythmTabSection: String, CaseIterable, Identifiable {
    case metronome = "Metronome"
    case playAlong = "Play Along"
    case tutorials = "Tutorials"
    
    var id: String { rawValue }
}

@MainActor
final class RhythmViewModel: ObservableObject {
    @Published var section: RhythmTabSection = .metronome
    @Published var bpm: Double = 80 {
        didSet {
            let clamped = min(240, max(40, bpm.rounded()))
            if clamped != bpm {
                bpm = clamped
                return
            }
            metronome.bpm = bpm
        }
    }
    @Published var timeSignature: TimeSignature = .fourFour {
        didSet { metronome.timeSignature = timeSignature }
    }
    @Published var accentEnabled = true {
        didSet { metronome.accentEnabled = accentEnabled }
    }
    @Published var isClickMuted = false {
        didSet { metronome.isClickMuted = isClickMuted }
    }
    @Published var selectedPatternID: UUID?
    @Published var showingPremiumGate = false
    
    let content = RhythmContentService.shared
    private let metronome = MetronomeService.shared
    
    @Published private(set) var isRunning = false
    @Published private(set) var currentSlot = 0
    @Published private(set) var currentBeat = 0
    
    var selectedPattern: RhythmPattern? {
        guard let selectedPatternID else { return content.patterns.first }
        return content.pattern(id: selectedPatternID) ?? content.patterns.first
    }
    
    init() {
        selectedPatternID = content.patterns.first?.id
        syncMetronomeConfig()
        
        metronome.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)
        metronome.$currentSlot
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSlot)
        metronome.$currentBeat
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentBeat)
    }
    
    func syncMetronomeConfig() {
        metronome.bpm = bpm
        metronome.timeSignature = timeSignature
        metronome.accentEnabled = accentEnabled
        metronome.isClickMuted = isClickMuted
        // Play-along drives subdivision from the selected pattern; metronome tab uses quarters.
        if section == .playAlong, let pattern = selectedPattern {
            metronome.subdivision = pattern.subdivision
            metronome.timeSignature = pattern.timeSignature
            timeSignature = pattern.timeSignature
        } else {
            metronome.subdivision = .quarter
        }
    }
    
    func selectPattern(_ pattern: RhythmPattern, isPremiumUser: Bool) {
        if pattern.isPremium && !isPremiumUser {
            showingPremiumGate = true
            return
        }
        selectedPatternID = pattern.id
        if section == .playAlong {
            let wasRunning = isRunning
            if wasRunning { metronome.stop() }
            syncMetronomeConfig()
            if wasRunning { metronome.start() }
        }
    }
    
    func openPlayAlong(for pattern: RhythmPattern, isPremiumUser: Bool) {
        selectPattern(pattern, isPremiumUser: isPremiumUser)
        guard selectedPatternID == pattern.id else { return }
        section = .playAlong
        syncMetronomeConfig()
    }
    
    func toggleTransport() {
        syncMetronomeConfig()
        metronome.toggle()
    }
    
    func start() {
        syncMetronomeConfig()
        metronome.start()
    }
    
    func stop() {
        metronome.stop()
    }
    
    func bumpBPM(by delta: Double) {
        bpm = min(240, max(40, bpm + delta))
    }
    
    func canAccess(pattern: RhythmPattern, isPremiumUser: Bool) -> Bool {
        !pattern.isPremium || isPremiumUser
    }
    
    func canAccess(tutorial: RhythmTutorial, isPremiumUser: Bool) -> Bool {
        !tutorial.isPremium || isPremiumUser
    }
}
