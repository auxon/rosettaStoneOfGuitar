//
//  Rhythm.swift
//  rSoGuitar
//
//  Models for metronome, play-along patterns, and rhythm tutorials.
//

import Foundation

// MARK: - Time Signature

struct TimeSignature: Codable, Equatable, Hashable, Identifiable {
    var id: String { "\(beatsPerBar)/\(beatUnit)" }
    
    /// Beats per bar (numerator), e.g. 4 in 4/4.
    let beatsPerBar: Int
    /// Note value that gets one beat (denominator), e.g. 4 = quarter note.
    let beatUnit: Int
    
    static let fourFour = TimeSignature(beatsPerBar: 4, beatUnit: 4)
    static let threeFour = TimeSignature(beatsPerBar: 3, beatUnit: 4)
    static let sixEight = TimeSignature(beatsPerBar: 6, beatUnit: 8)
    
    static let presets: [TimeSignature] = [.fourFour, .threeFour, .sixEight]
    
    var displayName: String { "\(beatsPerBar)/\(beatUnit)" }
}

// MARK: - Subdivision

enum RhythmSubdivision: Int, Codable, CaseIterable, Identifiable {
    case quarter = 1
    case eighth = 2
    case sixteenth = 4
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .quarter: return "Quarter"
        case .eighth: return "8th"
        case .sixteenth: return "16th"
        }
    }
    
    /// Slots per beat at this subdivision.
    var slotsPerBeat: Int { rawValue }
}

// MARK: - Event Kind

enum RhythmEventKind: String, Codable, CaseIterable {
    case down
    case up
    case mute
    case rest
    case accent
    
    var glyph: String {
        switch self {
        case .down: return "↓"
        case .up: return "↑"
        case .mute: return "✕"
        case .rest: return "·"
        case .accent: return ">"
        }
    }
    
    var label: String {
        switch self {
        case .down: return "Down"
        case .up: return "Up"
        case .mute: return "Mute"
        case .rest: return "Rest"
        case .accent: return "Accent"
        }
    }
}

// MARK: - Rhythm Event

struct RhythmEvent: Identifiable, Codable, Equatable {
    let id: UUID
    /// Index within the bar at the pattern's subdivision (0-based).
    let slotIndex: Int
    let kind: RhythmEventKind
    
    init(id: UUID = UUID(), slotIndex: Int, kind: RhythmEventKind) {
        self.id = id
        self.slotIndex = slotIndex
        self.kind = kind
    }
}

// MARK: - Pattern

enum RhythmDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

struct RhythmPattern: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let summary: String
    let timeSignature: TimeSignature
    let subdivision: RhythmSubdivision
    let events: [RhythmEvent]
    let difficulty: RhythmDifficulty
    let isPremium: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        summary: String,
        timeSignature: TimeSignature,
        subdivision: RhythmSubdivision,
        events: [RhythmEvent],
        difficulty: RhythmDifficulty,
        isPremium: Bool
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.timeSignature = timeSignature
        self.subdivision = subdivision
        self.events = events
        self.difficulty = difficulty
        self.isPremium = isPremium
    }
    
    /// Total subdivision slots in one bar.
    var slotsPerBar: Int {
        timeSignature.beatsPerBar * subdivision.slotsPerBeat
    }
    
    /// Event for a slot, or `.rest` if unspecified.
    func event(at slotIndex: Int) -> RhythmEventKind {
        events.first(where: { $0.slotIndex == slotIndex })?.kind ?? .rest
    }
}

// MARK: - Tutorials

enum RhythmTutorialSection: Codable, Equatable {
    case text(String)
    case pattern(UUID)
    case tip(String)
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    enum SectionType: String, Codable {
        case text, pattern, tip
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SectionType.self, forKey: .type)
        switch type {
        case .text:
            self = .text(try container.decode(String.self, forKey: .value))
        case .pattern:
            self = .pattern(try container.decode(UUID.self, forKey: .value))
        case .tip:
            self = .tip(try container.decode(String.self, forKey: .value))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode(SectionType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        case .pattern(let value):
            try container.encode(SectionType.pattern, forKey: .type)
            try container.encode(value, forKey: .value)
        case .tip(let value):
            try container.encode(SectionType.tip, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

struct RhythmTutorial: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let sections: [RhythmTutorialSection]
    let patternIds: [UUID]
    let isPremium: Bool
    let order: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        sections: [RhythmTutorialSection],
        patternIds: [UUID],
        isPremium: Bool,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.sections = sections
        self.patternIds = patternIds
        self.isPremium = isPremium
        self.order = order
    }
}

// MARK: - Pure beat math (unit-testable)

enum BeatClock {
    /// Next slot index wrapping within a bar.
    static func nextSlot(current: Int, slotsPerBar: Int) -> Int {
        guard slotsPerBar > 0 else { return 0 }
        return (current + 1) % slotsPerBar
    }
    
    /// Beat number within the bar (0-based) for a subdivision slot.
    static func beatIndex(slot: Int, slotsPerBeat: Int) -> Int {
        guard slotsPerBeat > 0 else { return 0 }
        return slot / slotsPerBeat
    }
    
    /// Whether this slot is the accent (downbeat of the bar).
    static func isAccent(slot: Int, slotsPerBeat: Int) -> Bool {
        slot == 0
    }
    
    /// Seconds between subdivision clicks at a given BPM.
    static func slotDurationSeconds(bpm: Double, slotsPerBeat: Int) -> Double {
        guard bpm > 0, slotsPerBeat > 0 else { return 0 }
        let beatDuration = 60.0 / bpm
        return beatDuration / Double(slotsPerBeat)
    }
}
