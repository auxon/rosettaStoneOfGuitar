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
    private var playerNode: AVAudioPlayerNode
    private var audioSession: AVAudioSession
    private var audioFormat: AVAudioFormat
    
    @Published var isPlaying = false
    @Published var currentNote: Note?
    @Published var isSoundEnabled = true
    @Published var volume: Float = 0.7
    
    // Standard tuning A4 = 440 Hz
    private let a4Frequency: Double = 440.0
    
    private init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioSession = AVAudioSession.sharedInstance()
        
        // Create audio format: 44.1kHz, mono, 32-bit float
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            // Attach and connect player node
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            
            // Start the engine
            try audioEngine.start()
        } catch {
            print("Failed to setup audio engine: \(error)")
        }
    }
    
    /// Get frequency for a note (based on A4 = 440 Hz)
    private func frequency(for note: Note, octave: Int = 4) -> Double {
        // Semitones from A4 for each note
        let semitonesFromA: [Note: Int] = [
            .C: -9, .CSharp: -8, .D: -7, .DSharp: -6,
            .E: -5, .F: -4, .FSharp: -3, .G: -2,
            .GSharp: -1, .A: 0, .ASharp: 1, .B: 2
        ]
        
        let semitones = semitonesFromA[note] ?? 0
        let octaveOffset = (octave - 4) * 12
        let totalSemitones = Double(semitones + octaveOffset)
        
        return a4Frequency * pow(2.0, totalSemitones / 12.0)
    }
    
    /// Generate a guitar-like tone buffer
    private func generateToneBuffer(frequency: Double, duration: Double = 0.8) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        // Generate a plucked string sound using Karplus-Strong-like synthesis
        // Combine fundamental with harmonics and apply envelope
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            
            // ADSR envelope for guitar-like decay
            let attackTime = 0.005
            let decayTime = 0.1
            let sustainLevel: Double = 0.3
            let releaseStart = duration - 0.1
            
            var envelope: Double
            if time < attackTime {
                envelope = time / attackTime  // Attack
            } else if time < attackTime + decayTime {
                let decayProgress = (time - attackTime) / decayTime
                envelope = 1.0 - (1.0 - sustainLevel) * decayProgress  // Decay
            } else if time < releaseStart {
                envelope = sustainLevel * exp(-2.0 * (time - attackTime - decayTime))  // Gradual decay
            } else {
                let releaseProgress = (time - releaseStart) / 0.1
                envelope = sustainLevel * exp(-2.0 * (releaseStart - attackTime - decayTime)) * (1.0 - releaseProgress)  // Release
            }
            
            // Generate waveform with harmonics (guitar-like timbre)
            let fundamental = sin(2.0 * .pi * frequency * time)
            let harmonic2 = 0.5 * sin(2.0 * .pi * frequency * 2.0 * time)
            let harmonic3 = 0.25 * sin(2.0 * .pi * frequency * 3.0 * time)
            let harmonic4 = 0.125 * sin(2.0 * .pi * frequency * 4.0 * time)
            let harmonic5 = 0.0625 * sin(2.0 * .pi * frequency * 5.0 * time)
            
            // Add slight detuning for richness
            let detune = 0.1 * sin(2.0 * .pi * (frequency * 1.002) * time)
            
            let sample = (fundamental + harmonic2 + harmonic3 + harmonic4 + harmonic5 + detune) / 2.5
            channelData[frame] = Float(sample * envelope * Double(volume))
        }
        
        return buffer
    }
    
    /// Play a note by name
    func playNote(_ note: Note, octave: Int = 3) {
        guard isSoundEnabled else { return }
        
        DispatchQueue.main.async {
            self.currentNote = note
            self.isPlaying = true
        }
        
        // Stop any currently playing sound
        playerNode.stop()
        
        // Generate and play the tone
        let freq = frequency(for: note, octave: octave)
        
        if let buffer = generateToneBuffer(frequency: freq, duration: 0.8) {
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    self?.currentNote = nil
                }
            })
            playerNode.play()
        }
    }
    
    /// Play a note at a specific string and fret (determines octave automatically)
    func playNoteAt(string: Int, fret: Int) {
        guard isSoundEnabled else { return }
        
        let note = FretboardCalculator.noteAt(string: string, fret: fret)
        
        // Determine octave based on string and fret
        // String 6 (low E) = E2, String 1 (high E) = E4
        let baseOctaves = [4, 3, 3, 3, 2, 2]  // Octaves for open strings 1-6
        let baseOctave = string >= 1 && string <= 6 ? baseOctaves[string - 1] : 3
        let octave = baseOctave + (fret / 12)
        
        playNote(note, octave: octave)
    }
    
    /// Play a chord (arpeggio style)
    func playChord(_ chord: Chord) {
        guard isSoundEnabled else { return }
        
        Task {
            for (index, position) in chord.positions.prefix(6).enumerated() {
                playNoteAt(string: position.string, fret: position.fret)
                // Strum delay between notes
                try? await Task.sleep(nanoseconds: UInt64(50_000_000 + index * 10_000_000))
            }
        }
    }
    
    /// Play multiple notes simultaneously
    func playNotes(_ positions: [FretboardPosition]) {
        guard isSoundEnabled else { return }
        
        Task {
            for position in positions.prefix(6) {
                playNoteAt(string: position.string, fret: position.fret)
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
    }
    
    /// Toggle sound on/off
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    /// Set volume (0.0 to 1.0)
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
    }
    
    func stopAll() {
        playerNode.stop()
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentNote = nil
        }
    }
}
