//
//  AudioService.swift
//  rSoGuitar
//
//  Handles audio playback for notes and chords
//

import Foundation
import AVFoundation
import AudioToolbox
import Combine

class AudioService: ObservableObject {
    static let shared = AudioService()
    
    private var audioEngine: AVAudioEngine
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioSession: AVAudioSession
    
    @Published var isPlaying = false
    @Published var currentNote: Note?
    
    private init() {
        audioEngine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Play a note by name
    @MainActor
    func playNote(_ note: Note) {
        currentNote = note
        isPlaying = true
        
        // In a real implementation, you would load audio files from Resources/Audio/
        // For now, we'll use system sounds or generate tones
        playSystemSound(for: note)
        
        // Reset after a short delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isPlaying = false
            currentNote = nil
        }
    }
    
    /// Play a chord
    @MainActor
    func playChord(_ chord: Chord) {
        // Play all notes in the chord
        Task { @MainActor in
            for position in chord.positions.prefix(6) { // Limit to 6 notes
                playNote(position.note)
                // Small delay between notes
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    
    /// Play audio from URL
    @MainActor
    func playAudio(from url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            audioPlayers[url.absoluteString] = player
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    private func playSystemSound(for note: Note) {
        // Use system sound as placeholder
        // In production, load actual guitar note samples
        AudioServicesPlaySystemSound(1104) // Default system sound
    }
    
    @MainActor
    func stopAll() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
        isPlaying = false
        currentNote = nil
    }
}

