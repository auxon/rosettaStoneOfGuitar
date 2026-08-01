//
//  RhythmTests.swift
//  rSoGuitarTests
//
//  Beat clock math + seeded rhythm content invariants.
//

import Testing
@testable import rSoGuitar

struct RhythmTests {
    
    @Test func nextSlotWrapsWithinBar() {
        #expect(BeatClock.nextSlot(current: 0, slotsPerBar: 8) == 1)
        #expect(BeatClock.nextSlot(current: 7, slotsPerBar: 8) == 0)
        #expect(BeatClock.nextSlot(current: 3, slotsPerBar: 4) == 0)
    }
    
    @Test func beatIndexMatchesSubdivision() {
        #expect(BeatClock.beatIndex(slot: 0, slotsPerBeat: 2) == 0)
        #expect(BeatClock.beatIndex(slot: 1, slotsPerBeat: 2) == 0)
        #expect(BeatClock.beatIndex(slot: 2, slotsPerBeat: 2) == 1)
        #expect(BeatClock.beatIndex(slot: 5, slotsPerBeat: 4) == 1)
    }
    
    @Test func accentIsOnlySlotZero() {
        #expect(BeatClock.isAccent(slot: 0, slotsPerBeat: 2))
        #expect(!BeatClock.isAccent(slot: 2, slotsPerBeat: 2))
        #expect(!BeatClock.isAccent(slot: 4, slotsPerBeat: 1))
    }
    
    @Test func slotDurationScalesWithBPMAndSubdivision() {
        let quarter = BeatClock.slotDurationSeconds(bpm: 60, slotsPerBeat: 1)
        let eighth = BeatClock.slotDurationSeconds(bpm: 60, slotsPerBeat: 2)
        #expect(abs(quarter - 1.0) < 0.0001)
        #expect(abs(eighth - 0.5) < 0.0001)
    }
    
    @Test func patternsHaveEventCountsMatchingSlots() {
        let content = RhythmContentService.shared
        for pattern in content.patterns {
            #expect(pattern.events.count == pattern.slotsPerBar, "\(pattern.name) event count")
            #expect(Set(pattern.events.map(\.slotIndex)).count == pattern.slotsPerBar)
            for event in pattern.events {
                #expect(event.slotIndex >= 0 && event.slotIndex < pattern.slotsPerBar)
            }
        }
    }
    
    @Test func freeContentIDsAreStable() {
        let content = RhythmContentService.shared
        
        #expect(content.pattern(id: RhythmContentService.PatternID.straight8ths)?.isPremium == false)
        #expect(content.pattern(id: RhythmContentService.PatternID.downstrokes)?.isPremium == false)
        #expect(content.pattern(id: RhythmContentService.PatternID.boomChuck)?.isPremium == true)
        
        #expect(content.tutorial(id: RhythmContentService.TutorialID.metronomeBasics)?.isPremium == false)
        #expect(content.tutorial(id: RhythmContentService.TutorialID.straight8ths)?.isPremium == false)
        #expect(content.tutorial(id: RhythmContentService.TutorialID.downstrokes)?.isPremium == false)
        #expect(content.tutorial(id: RhythmContentService.TutorialID.boomChuck)?.isPremium == true)
        
        #expect(content.freeTutorials.count == 3)
        #expect(content.freePatterns.count == 2)
    }
    
    @Test func tutorialsReferenceExistingPatterns() {
        let content = RhythmContentService.shared
        for tutorial in content.tutorials {
            for id in tutorial.patternIds {
                #expect(content.pattern(id: id) != nil, "Missing pattern \(id) for \(tutorial.title)")
            }
            for section in tutorial.sections {
                if case .pattern(let id) = section {
                    #expect(content.pattern(id: id) != nil)
                }
            }
        }
    }
}
