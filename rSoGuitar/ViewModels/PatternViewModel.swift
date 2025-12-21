//
//  PatternViewModel.swift
//  rSoGuitar
//
//  ViewModel for pattern learning
//

import Foundation
import SwiftUI
import Combine

class PatternViewModel: ObservableObject {
    @Published var currentPattern: Pattern?
    @Published var selectedKey: Key = .C
    @Published var patternType: PatternType = .spiralMapping
    @Published var isLoading = false
    
    private let contentService = ContentService.shared
    private let progressService = ProgressService.shared
    private let audioService = AudioService.shared
    
    func loadPattern(type: PatternType, key: Key, startPosition: FretboardPosition? = nil) {
        isLoading = true
        currentPattern = contentService.generatePattern(
            type: type,
            key: key,
            startPosition: startPosition
        )
        isLoading = false
    }
    
    func updateKey(_ key: Key) {
        selectedKey = key
        loadPattern(type: patternType, key: key)
    }
    
    func updatePatternType(_ type: PatternType) {
        patternType = type
        loadPattern(type: type, key: selectedKey)
    }
    
    func playPatternNotes() {
        guard let pattern = currentPattern else { return }
        
        // Play root notes first, then other notes
        let rootNotes = pattern.positions.filter { $0.isRoot }
        let otherNotes = pattern.positions.filter { !$0.isRoot }
        
        Task {
            for position in rootNotes {
                audioService.playNote(position.note)
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            }
            
            for position in otherNotes.prefix(10) { // Limit to 10 notes
                audioService.playNote(position.note)
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
        }
    }
    
    func toggleBookmark() {
        guard let pattern = currentPattern else { return }
        progressService.toggleBookmark(pattern.id)
    }
    
    func isBookmarked() -> Bool {
        guard let pattern = currentPattern else { return false }
        return progressService.isPatternBookmarked(pattern.id)
    }
}

