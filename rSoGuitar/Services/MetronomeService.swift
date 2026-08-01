//
//  MetronomeService.swift
//  rSoGuitar
//
//  Sample-accurate metronome click scheduling + beat publishing.
//

import Foundation
import AVFoundation
import Combine

final class MetronomeService: ObservableObject {
    static let shared = MetronomeService()
    
    @Published private(set) var isRunning = false
    /// Current subdivision slot within the bar (0-based).
    @Published private(set) var currentSlot: Int = 0
    /// Current beat within the bar (0-based).
    @Published private(set) var currentBeat: Int = 0
    
    var bpm: Double = 80 {
        didSet { bpm = min(240, max(40, bpm)) }
    }
    var timeSignature: TimeSignature = .fourFour
    var subdivision: RhythmSubdivision = .quarter
    var accentEnabled = true
    /// When true, advance visuals but do not audibly click.
    var isClickMuted = false
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let audioFormat: AVAudioFormat
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var accentBuffer: AVAudioPCMBuffer?
    private var clickBuffer: AVAudioPCMBuffer?
    private var schedulingTimer: DispatchSourceTimer?
    private var nextSlotHostTime: AVAudioTime?
    private var nextSlotToSchedule: Int = 0
    /// Queue-local running flag (avoid publishing from a background thread).
    private var running = false
    private let schedulingQueue = DispatchQueue(label: "com.rsoguitar.metronome", qos: .userInteractive)
    
    private init() {
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        accentBuffer = Self.makeClickBuffer(frequency: 1200, duration: 0.04, format: audioFormat)
        clickBuffer = Self.makeClickBuffer(frequency: 800, duration: 0.035, format: audioFormat)
        setupEngine()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Transport
    
    func start() {
        schedulingQueue.async { [weak self] in
            self?.startLocked()
        }
    }
    
    func stop() {
        schedulingQueue.async { [weak self] in
            self?.stopLocked()
        }
    }
    
    func toggle() {
        if running || isRunning { stop() } else { start() }
    }
    
    // MARK: - Engine
    
    private func setupEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }
    
    private func ensureEngineRunning() throws {
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    private func startLocked() {
        guard !running else { return }
        
        NotificationCenter.default.post(name: .metronomeWillStart, object: nil)
        
        do {
            try ensureEngineRunning()
        } catch {
            print("Metronome failed to start audio: \(error)")
            return
        }
        
        nextSlotToSchedule = 0
        let nowHost = mach_absolute_time()
        nextSlotHostTime = AVAudioTime(hostTime: nowHost &+ Self.hostTicks(forSeconds: 0.05))
        running = true
        
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = true
            self?.currentSlot = 0
            self?.currentBeat = 0
        }
        
        scheduleAhead()
        startSchedulingTimer()
    }
    
    private func stopLocked() {
        schedulingTimer?.cancel()
        schedulingTimer = nil
        playerNode.stop()
        playerNode.reset()
        running = false
        nextSlotHostTime = nil
        nextSlotToSchedule = 0
        
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
        }
    }
    
    private func startSchedulingTimer() {
        schedulingTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: schedulingQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(30), leeway: .milliseconds(5))
        timer.setEventHandler { [weak self] in
            self?.scheduleAhead()
        }
        timer.resume()
        schedulingTimer = timer
    }
    
    /// Keep ~2 bars of clicks scheduled ahead of the playhead.
    private func scheduleAhead() {
        guard running, let startTime = nextSlotHostTime else { return }
        
        let slotsPerBeat = max(1, subdivision.slotsPerBeat)
        let slotsPerBar = max(1, timeSignature.beatsPerBar * slotsPerBeat)
        let slotDuration = BeatClock.slotDurationSeconds(bpm: bpm, slotsPerBeat: slotsPerBeat)
        guard slotDuration > 0 else { return }
        
        let horizonHost = mach_absolute_time() + Self.hostTicks(forSeconds: slotDuration * Double(slotsPerBar) * 2)
        
        var slot = nextSlotToSchedule
        var nextTime = startTime
        
        while nextTime.hostTime < horizonHost {
            let accent = accentEnabled && BeatClock.isAccent(slot: slot, slotsPerBeat: slotsPerBeat)
            if !isClickMuted, let buffer = accent ? accentBuffer : clickBuffer {
                playerNode.scheduleBuffer(buffer, at: nextTime, options: [])
            }
            
            let publishedSlot = slot
            let publishedBeat = BeatClock.beatIndex(slot: slot, slotsPerBeat: slotsPerBeat)
            let fireDelay = Self.seconds(untilHostTime: nextTime.hostTime)
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, fireDelay)) { [weak self] in
                guard let self, self.isRunning else { return }
                self.currentSlot = publishedSlot
                self.currentBeat = publishedBeat
            }
            
            slot = BeatClock.nextSlot(current: slot, slotsPerBar: slotsPerBar)
            nextTime = nextTime.addingHostSeconds(slotDuration)
        }
        
        nextSlotToSchedule = slot
        nextSlotHostTime = nextTime
    }
    
    // MARK: - Click synthesis
    
    private static func makeClickBuffer(
        frequency: Double,
        duration: Double,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else { return nil }
        let data = channels[0]
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 40)
            let sample = sin(2 * Double.pi * frequency * t) * envelope * 0.7
            data[i] = Float(sample)
        }
        return buffer
    }
    
    // MARK: - Host time helpers
    
    private static func hostTicks(forSeconds seconds: Double) -> UInt64 {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let nanos = seconds * 1_000_000_000
        return UInt64(nanos * Double(info.denom) / Double(info.numer))
    }
    
    private static func seconds(untilHostTime hostTime: UInt64) -> Double {
        let now = mach_absolute_time()
        if hostTime <= now { return 0 }
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let delta = hostTime - now
        let nanos = Double(delta) * Double(info.numer) / Double(info.denom)
        return nanos / 1_000_000_000
    }
}

private extension AVAudioTime {
    func addingHostSeconds(_ seconds: Double) -> AVAudioTime {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let nanos = seconds * 1_000_000_000
        let ticks = UInt64(nanos * Double(info.denom) / Double(info.numer))
        return AVAudioTime(hostTime: hostTime &+ ticks)
    }
}

extension Notification.Name {
    static let metronomeWillStart = Notification.Name("com.rsoguitar.metronomeWillStart")
}
