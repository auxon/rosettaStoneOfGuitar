//
//  RhythmContentService.swift
//  rSoGuitar
//
//  Seeded rhythm patterns and tutorials for the Rhythm tab.
//

import Foundation

final class RhythmContentService {
    static let shared = RhythmContentService()
    
    // Stable IDs for tests and deep-links from tutorials.
    enum PatternID {
        static let straight8ths = UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!
        static let downstrokes = UUID(uuidString: "A1000001-0000-4000-8000-000000000002")!
        static let boomChuck = UUID(uuidString: "A1000001-0000-4000-8000-000000000003")!
        static let reggaeSkank = UUID(uuidString: "A1000001-0000-4000-8000-000000000004")!
        static let waltz = UUID(uuidString: "A1000001-0000-4000-8000-000000000005")!
        static let funkSixteenths = UUID(uuidString: "A1000001-0000-4000-8000-000000000006")!
    }
    
    enum TutorialID {
        static let metronomeBasics = UUID(uuidString: "B1000001-0000-4000-8000-000000000001")!
        static let straight8ths = UUID(uuidString: "B1000001-0000-4000-8000-000000000002")!
        static let downstrokes = UUID(uuidString: "B1000001-0000-4000-8000-000000000003")!
        static let boomChuck = UUID(uuidString: "B1000001-0000-4000-8000-000000000004")!
        static let reggae = UUID(uuidString: "B1000001-0000-4000-8000-000000000005")!
        static let funk = UUID(uuidString: "B1000001-0000-4000-8000-000000000006")!
    }
    
    private(set) var patterns: [RhythmPattern]
    private(set) var tutorials: [RhythmTutorial]
    
    private init() {
        patterns = Self.makePatterns()
        tutorials = Self.makeTutorials()
    }
    
    func pattern(id: UUID) -> RhythmPattern? {
        patterns.first { $0.id == id }
    }
    
    func tutorial(id: UUID) -> RhythmTutorial? {
        tutorials.first { $0.id == id }
    }
    
    var freePatterns: [RhythmPattern] { patterns.filter { !$0.isPremium } }
    var premiumPatterns: [RhythmPattern] { patterns.filter(\.isPremium) }
    var freeTutorials: [RhythmTutorial] { tutorials.filter { !$0.isPremium }.sorted { $0.order < $1.order } }
    var allTutorialsSorted: [RhythmTutorial] { tutorials.sorted { $0.order < $1.order } }
    
    // MARK: - Seed Data
    
    private static func events(_ kinds: [RhythmEventKind]) -> [RhythmEvent] {
        kinds.enumerated().map { RhythmEvent(slotIndex: $0.offset, kind: $0.element) }
    }
    
    private static func makePatterns() -> [RhythmPattern] {
        [
            // Free — Straight 8ths rock: D D U U D U (slots for 8 eighths in 4/4)
            RhythmPattern(
                id: PatternID.straight8ths,
                name: "Straight 8ths",
                summary: "Classic rock strum: down on the beat, ups on the offbeat with a common D-D-U-U-D-U feel.",
                timeSignature: .fourFour,
                subdivision: .eighth,
                events: events([
                    .down, .down, .up, .up, .down, .up, .down, .up
                ]),
                difficulty: .beginner,
                isPremium: false
            ),
            // Free — Downstrokes
            RhythmPattern(
                id: PatternID.downstrokes,
                name: "Downstrokes",
                summary: "All downstrokes on every 8th — builds right-hand consistency.",
                timeSignature: .fourFour,
                subdivision: .eighth,
                events: events(Array(repeating: .down, count: 8)),
                difficulty: .beginner,
                isPremium: false
            ),
            // Premium — Boom-chuck
            RhythmPattern(
                id: PatternID.boomChuck,
                name: "Boom-Chuck",
                summary: "Bass note on the beat, chuck/mute on the offbeat — country & folk staple.",
                timeSignature: .fourFour,
                subdivision: .eighth,
                events: events([
                    .down, .mute, .down, .mute, .down, .mute, .down, .mute
                ]),
                difficulty: .intermediate,
                isPremium: true
            ),
            // Premium — Reggae skank
            RhythmPattern(
                id: PatternID.reggaeSkank,
                name: "Reggae Skank",
                summary: "Upstroke chops on the offbeats; rests on the downbeats.",
                timeSignature: .fourFour,
                subdivision: .eighth,
                events: events([
                    .rest, .up, .rest, .up, .rest, .up, .rest, .up
                ]),
                difficulty: .intermediate,
                isPremium: true
            ),
            // Premium — Waltz
            RhythmPattern(
                id: PatternID.waltz,
                name: "Waltz",
                summary: "3/4 downstrokes — strong on one, lighter on two and three.",
                timeSignature: .threeFour,
                subdivision: .quarter,
                events: events([.accent, .down, .down]),
                difficulty: .beginner,
                isPremium: true
            ),
            // Premium — 16th funk stub
            RhythmPattern(
                id: PatternID.funkSixteenths,
                name: "16th Funk Stub",
                summary: "Sparse 16th-note funk hits — mute the rest and lock to the grid.",
                timeSignature: .fourFour,
                subdivision: .sixteenth,
                events: events([
                    .down, .rest, .mute, .rest,
                    .rest, .up, .rest, .mute,
                    .down, .rest, .rest, .up,
                    .mute, .rest, .up, .rest
                ]),
                difficulty: .advanced,
                isPremium: true
            )
        ]
    }
    
    private static func makeTutorials() -> [RhythmTutorial] {
        [
            RhythmTutorial(
                id: TutorialID.metronomeBasics,
                title: "Metronome Basics",
                description: "Learn to start, feel the pulse, and practice with accent clicks.",
                sections: [
                    .text("The metronome is your timing anchor. Set a comfortable BPM (try 70–90 to start), pick 4/4, and tap Start."),
                    .text("Watch the beat dots light up. Beat 1 is accented — that’s the downbeat of the bar."),
                    .tip("Practice muting the click (visual-only) once you can feel the pulse internally."),
                    .text("When you’re ready, switch to Play Along and lock a simple pattern to the same click.")
                ],
                patternIds: [],
                isPremium: false,
                order: 1
            ),
            RhythmTutorial(
                id: TutorialID.straight8ths,
                title: "Straight 8ths Strum",
                description: "The essential rock strumming pattern synced to the click.",
                sections: [
                    .text("Straight 8ths divide each beat into two equal parts. Downs land on the beat; ups fill the offbeats."),
                    .pattern(PatternID.straight8ths),
                    .tip("Keep your strumming hand moving even on rests — the motion stays even, the strings decide when to sound."),
                    .text("Open Play Along with Straight 8ths and loop at a slow BPM until the grid highlights feel automatic.")
                ],
                patternIds: [PatternID.straight8ths],
                isPremium: false,
                order: 2
            ),
            RhythmTutorial(
                id: TutorialID.downstrokes,
                title: "Downstroke Consistency",
                description: "Build a solid right hand with continuous downstrokes.",
                sections: [
                    .text("Play only downstrokes on every 8th note. Focus on even volume and locking to beat 1."),
                    .pattern(PatternID.downstrokes),
                    .tip("If you rush, drop the BPM by 10 and regain the pocket before speeding up.")
                ],
                patternIds: [PatternID.downstrokes],
                isPremium: false,
                order: 3
            ),
            RhythmTutorial(
                id: TutorialID.boomChuck,
                title: "Boom-Chuck Groove",
                description: "Alternate bass hits and muted chucks.",
                sections: [
                    .text("Boom on the beat, chuck (mute) on the offbeat. Think country train beat."),
                    .pattern(PatternID.boomChuck),
                    .tip("Mute with the fretting hand lightly resting on the strings for the chuck.")
                ],
                patternIds: [PatternID.boomChuck],
                isPremium: true,
                order: 4
            ),
            RhythmTutorial(
                id: TutorialID.reggae,
                title: "Reggae Skank",
                description: "Offbeat upstrokes that define the skank feel.",
                sections: [
                    .text("Rest on the downbeats; chop short upstrokes on the offbeats."),
                    .pattern(PatternID.reggaeSkank),
                    .tip("Keep the chops short — release immediately after the upstroke.")
                ],
                patternIds: [PatternID.reggaeSkank],
                isPremium: true,
                order: 5
            ),
            RhythmTutorial(
                id: TutorialID.funk,
                title: "16th Funk Stub",
                description: "Sparse 16th-note funk against a tight grid.",
                sections: [
                    .text("Most slots are rests or mutes. Only a few hits speak — accuracy matters more than speed."),
                    .pattern(PatternID.funkSixteenths),
                    .tip("Start at 60–70 BPM. Count 16ths out loud: 1 e & a 2 e & a…")
                ],
                patternIds: [PatternID.funkSixteenths],
                isPremium: true,
                order: 6
            )
        ]
    }
}
