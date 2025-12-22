//
//  TunerViewModel.swift
//  rSoGuitar
//
//  ViewModel for the guitar tuner feature
//

import Foundation
import AVFoundation
import Combine
import Accelerate

class TunerViewModel: ObservableObject {
    @Published var currentFrequency: Double = 0.0
    @Published var currentNote: String = "--"
    @Published var currentOctave: Int = 0
    @Published var centsOff: Double = 0.0
    @Published var isListening: Bool = false
    @Published var selectedTuning: GuitarTuning = .standard
    @Published var targetStrings: [TunerString] = []
    @Published var closestString: TunerString?
    @Published var hasPermission: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var referencePitch: Double = 440.0  // A4 reference pitch (can be adjusted)
    @Published var centsFromTarget: Double = 0.0   // Cents offset from target string
    @Published var responsiveness: TunerResponsiveness = .fast  // Detection speed setting
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var actualSampleRate: Double = 44100.0  // Will be updated from audio format
    
    // Buffer size affects latency vs accuracy tradeoff
    // Smaller = faster response, larger = more accurate for low notes
    private var bufferSize: AVAudioFrameCount {
        responsiveness.bufferSize
    }
    
    // Standard tuning frequencies (in Hz)
    static let noteFrequencies: [(note: String, frequency: Double)] = [
        ("C", 16.35), ("C#", 17.32), ("D", 18.35), ("D#", 19.45),
        ("E", 20.60), ("F", 21.83), ("F#", 23.12), ("G", 24.50),
        ("G#", 25.96), ("A", 27.50), ("A#", 29.14), ("B", 30.87)
    ]
    
    init() {
        updateTargetStrings()
    }
    
    deinit {
        stopListening()
    }
    
    func updateTargetStrings() {
        targetStrings = selectedTuning.strings
    }
    
    func selectTuning(_ tuning: GuitarTuning) {
        selectedTuning = tuning
        updateTargetStrings()
    }
    
    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                self?.permissionDenied = !granted
                if granted {
                    self?.setupAudioEngine()
                }
            }
        }
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func startListening() {
        guard hasPermission else {
            requestPermission()
            return
        }
        
        setupAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Failed to start audio engine: \(error)")
            isListening = false
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        isListening = false
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        // Get the actual sample rate from the hardware
        actualSampleRate = format.sampleRate
        print("Tuner: Using sample rate: \(actualSampleRate) Hz")
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Convert to array
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        // Check if there's enough signal
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        guard rms > 0.01 else {
            DispatchQueue.main.async {
                self.currentNote = "--"
                self.currentFrequency = 0
                self.centsOff = 0
                self.closestString = nil
            }
            return
        }
        
        // Detect pitch using autocorrelation with actual sample rate
        if let frequency = detectPitch(samples: samples, sampleRate: Float(actualSampleRate)) {
            DispatchQueue.main.async {
                self.updateWithFrequency(Double(frequency))
            }
        }
    }
    
    private func detectPitch(samples: [Float], sampleRate: Float) -> Float? {
        let frameCount = samples.count
        
        // Normalized autocorrelation-based pitch detection (McLeod Pitch Method inspired)
        var autocorrelation = [Float](repeating: 0, count: frameCount)
        var nsdf = [Float](repeating: 0, count: frameCount)  // Normalized Square Difference Function
        
        // Calculate autocorrelation and normalization factor
        for lag in 0..<frameCount {
            var acSum: Float = 0
            var norm: Float = 0
            for i in 0..<(frameCount - lag) {
                acSum += samples[i] * samples[i + lag]
                norm += samples[i] * samples[i] + samples[i + lag] * samples[i + lag]
            }
            autocorrelation[lag] = acSum
            // NSDF: ranges from -1 to 1, with 1 being perfect correlation
            nsdf[lag] = norm > 0 ? (2 * acSum / norm) : 0
        }
        
        // Frequency range for guitar: ~60 Hz (below low E) to ~1400 Hz (high frets)
        let minLag = Int(sampleRate / 1400)  // ~1400 Hz max
        let maxLag = min(Int(sampleRate / 60), frameCount - 2)  // ~60 Hz min
        
        guard maxLag > minLag else { return nil }
        
        // Find the first significant peak in the NSDF
        // A peak is where nsdf[i] > nsdf[i-1] and nsdf[i] > nsdf[i+1]
        var bestLag: Int = -1
        var bestValue: Float = 0.0
        let threshold: Float = 0.5  // Minimum correlation threshold
        
        var i = minLag
        while i < maxLag {
            // Look for zero crossings (positive going)
            if i > 0 && nsdf[i-1] < 0 && nsdf[i] >= 0 {
                // Find the peak after this zero crossing
                var peakLag = i
                var peakValue = nsdf[i]
                
                while peakLag < maxLag - 1 && nsdf[peakLag + 1] > nsdf[peakLag] {
                    peakLag += 1
                    peakValue = nsdf[peakLag]
                }
                
                // Check if this is a significant peak
                if peakValue > threshold && peakValue > bestValue * 0.9 {
                    if bestLag < 0 || peakValue > bestValue {
                        bestLag = peakLag
                        bestValue = peakValue
                    }
                    // Take the first good peak (fundamental frequency)
                    if bestValue > 0.8 {
                        break
                    }
                }
            }
            i += 1
        }
        
        // Fallback: find the maximum peak if no zero-crossing peak found
        if bestLag < 0 {
            for lag in minLag..<maxLag {
                if nsdf[lag] > bestValue {
                    bestValue = nsdf[lag]
                    bestLag = lag
                }
            }
        }
        
        guard bestLag > 0 && bestValue > 0.3 else { return nil }
        
        // Parabolic interpolation for sub-sample accuracy
        // This is crucial for accurate pitch detection
        let refinedLag: Float
        if bestLag > 0 && bestLag < frameCount - 1 {
            let y0 = nsdf[bestLag - 1]
            let y1 = nsdf[bestLag]
            let y2 = nsdf[bestLag + 1]
            
            // Parabolic interpolation: find the true peak between samples
            let denominator = y0 - 2 * y1 + y2
            if abs(denominator) > 0.0001 {
                let delta = (y0 - y2) / (2 * denominator)
                refinedLag = Float(bestLag) + delta
            } else {
                refinedLag = Float(bestLag)
            }
        } else {
            refinedLag = Float(bestLag)
        }
        
        // Convert lag to frequency
        let frequency = sampleRate / refinedLag
        
        // Filter out unreasonable frequencies
        guard frequency >= 60 && frequency <= 1400 else { return nil }
        
        return frequency
    }
    
    private func updateWithFrequency(_ frequency: Double) {
        currentFrequency = frequency
        
        // Find the closest note
        let (note, octave, cents) = frequencyToNote(frequency)
        currentNote = note
        currentOctave = octave
        centsOff = cents
        
        // Find closest target string and calculate cents from target
        closestString = findClosestString(frequency: frequency)
        
        if let target = closestString {
            // Calculate cents relative to the target string frequency
            centsFromTarget = 1200.0 * log2(frequency / target.frequency)
            
            // Debug output
            print("Tuner Debug: detected=\(String(format: "%.2f", frequency))Hz, target=\(target.note)@\(String(format: "%.2f", target.frequency))Hz, centsFromTarget=\(String(format: "%.1f", centsFromTarget)), sampleRate=\(actualSampleRate)")
        } else {
            centsFromTarget = 0
        }
    }
    
    private func frequencyToNote(_ frequency: Double) -> (note: String, octave: Int, cents: Double) {
        // Use the configurable reference pitch (default A4 = 440 Hz)
        let semitonesFromA4 = 12.0 * log2(frequency / referencePitch)
        let nearestSemitone = round(semitonesFromA4)
        let cents = (semitonesFromA4 - nearestSemitone) * 100.0
        
        // A4 is the 49th key on piano (0-indexed: 48)
        // Note index: 0 = C, 1 = C#, etc.
        let noteIndex = Int((nearestSemitone + 9 + 120).truncatingRemainder(dividingBy: 12))
        let octave = Int((nearestSemitone + 9 + 48) / 12)
        
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let note = notes[noteIndex]
        
        return (note, octave, cents)
    }
    
    func setReferencePitch(_ pitch: Double) {
        referencePitch = pitch
        // Recalculate target strings based on new reference
        updateTargetStrings()
    }
    
    func setResponsiveness(_ newResponsiveness: TunerResponsiveness) {
        let wasListening = isListening
        if wasListening {
            stopListening()
        }
        responsiveness = newResponsiveness
        if wasListening {
            startListening()
        }
    }
    
    private func findClosestString(frequency: Double) -> TunerString? {
        var closestString: TunerString?
        var minDifference = Double.infinity
        
        for string in targetStrings {
            let difference = abs(frequency - string.frequency)
            // Also check octaves
            let octaveUp = abs(frequency - string.frequency * 2)
            let octaveDown = abs(frequency - string.frequency / 2)
            
            let minOctaveDiff = min(difference, octaveUp, octaveDown)
            
            if minOctaveDiff < minDifference {
                minDifference = minOctaveDiff
                closestString = string
            }
        }
        
        // Only return if reasonably close (within a major third)
        if minDifference < closestString!.frequency * 0.26 {
            return closestString
        }
        
        return nil
    }
}

// MARK: - Tuning Models

enum GuitarTuning: String, CaseIterable {
    case standard = "Standard (EADGBE)"
    case dropD = "Drop D (DADGBE)"
    case openG = "Open G (DGDGBD)"
    case openD = "Open D (DADF#AD)"
    case dadgad = "DADGAD"
    case halfStepDown = "Half Step Down (Eb)"
    
    var strings: [TunerString] {
        switch self {
        case .standard:
            // Standard tuning frequencies based on A4 = 440 Hz
            // E4 = 440 * 2^(-5/12) = 329.628 Hz
            // B3 = 440 * 2^(-10/12) = 246.942 Hz
            // G3 = 440 * 2^(-14/12) = 195.998 Hz
            // D3 = 440 * 2^(-19/12) = 146.832 Hz
            // A2 = 440 * 2^(-24/12) = 110.000 Hz
            // E2 = 440 * 2^(-29/12) = 82.407 Hz
            return [
                TunerString(number: 1, note: "E", frequency: 329.628, octave: 4),
                TunerString(number: 2, note: "B", frequency: 246.942, octave: 3),
                TunerString(number: 3, note: "G", frequency: 195.998, octave: 3),
                TunerString(number: 4, note: "D", frequency: 146.832, octave: 3),
                TunerString(number: 5, note: "A", frequency: 110.000, octave: 2),
                TunerString(number: 6, note: "E", frequency: 82.407, octave: 2)
            ]
        case .dropD:
            // Drop D: same as standard but low E dropped to D
            return [
                TunerString(number: 1, note: "E", frequency: 329.628, octave: 4),
                TunerString(number: 2, note: "B", frequency: 246.942, octave: 3),
                TunerString(number: 3, note: "G", frequency: 195.998, octave: 3),
                TunerString(number: 4, note: "D", frequency: 146.832, octave: 3),
                TunerString(number: 5, note: "A", frequency: 110.000, octave: 2),
                TunerString(number: 6, note: "D", frequency: 73.416, octave: 2)  // D2
            ]
        case .openG:
            // Open G: D-G-D-G-B-D
            return [
                TunerString(number: 1, note: "D", frequency: 293.665, octave: 4),  // D4
                TunerString(number: 2, note: "B", frequency: 246.942, octave: 3),
                TunerString(number: 3, note: "G", frequency: 195.998, octave: 3),
                TunerString(number: 4, note: "D", frequency: 146.832, octave: 3),
                TunerString(number: 5, note: "G", frequency: 97.999, octave: 2),   // G2
                TunerString(number: 6, note: "D", frequency: 73.416, octave: 2)
            ]
        case .openD:
            // Open D: D-A-D-F#-A-D
            return [
                TunerString(number: 1, note: "D", frequency: 293.665, octave: 4),
                TunerString(number: 2, note: "A", frequency: 220.000, octave: 3),
                TunerString(number: 3, note: "F#", frequency: 184.997, octave: 3), // F#3
                TunerString(number: 4, note: "D", frequency: 146.832, octave: 3),
                TunerString(number: 5, note: "A", frequency: 110.000, octave: 2),
                TunerString(number: 6, note: "D", frequency: 73.416, octave: 2)
            ]
        case .dadgad:
            // DADGAD tuning
            return [
                TunerString(number: 1, note: "D", frequency: 293.665, octave: 4),
                TunerString(number: 2, note: "A", frequency: 220.000, octave: 3),
                TunerString(number: 3, note: "G", frequency: 195.998, octave: 3),
                TunerString(number: 4, note: "D", frequency: 146.832, octave: 3),
                TunerString(number: 5, note: "A", frequency: 110.000, octave: 2),
                TunerString(number: 6, note: "D", frequency: 73.416, octave: 2)
            ]
        case .halfStepDown:
            // Half step down (Eb tuning): Eb-Ab-Db-Gb-Bb-Eb
            // Each string is 1 semitone lower (divide by 2^(1/12) ≈ 0.9439)
            return [
                TunerString(number: 1, note: "Eb", frequency: 311.127, octave: 4),  // Eb4
                TunerString(number: 2, note: "Bb", frequency: 233.082, octave: 3),  // Bb3
                TunerString(number: 3, note: "Gb", frequency: 184.997, octave: 3),  // Gb3
                TunerString(number: 4, note: "Db", frequency: 138.591, octave: 3),  // Db3
                TunerString(number: 5, note: "Ab", frequency: 103.826, octave: 2),  // Ab2
                TunerString(number: 6, note: "Eb", frequency: 77.782, octave: 2)    // Eb2
            ]
        }
    }
}

struct TunerString: Identifiable {
    let id = UUID()
    let number: Int      // 1-6 (1 = high E, 6 = low E)
    let note: String
    let frequency: Double
    let octave: Int
    
    var displayName: String {
        "\(number): \(note)"
    }
}

enum TunerResponsiveness: String, CaseIterable {
    case fast = "Fast"
    case balanced = "Balanced"
    case accurate = "Accurate"
    
    var bufferSize: AVAudioFrameCount {
        switch self {
        case .fast:
            return 1024      // ~21ms at 48kHz - very responsive
        case .balanced:
            return 2048      // ~43ms at 48kHz - good balance
        case .accurate:
            return 4096      // ~85ms at 48kHz - best for low notes
        }
    }
    
    var description: String {
        switch self {
        case .fast:
            return "Fastest response, may be less stable"
        case .balanced:
            return "Good balance of speed and accuracy"
        case .accurate:
            return "Most accurate, slight delay"
        }
    }
}

