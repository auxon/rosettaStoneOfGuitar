//
//  FretboardRendererTests.swift
//  rSoGuitarTests
//
//  Phase 4: shared layout / coordinate system tests.
//

import Testing
import CoreGraphics
@testable import rSoGuitar

struct FretboardRendererTests {
    
    @Test func stringOneIsAboveStringSix() {
        let layout = FretboardLayout(
            maxFret: 12,
            fretWidth: 40,
            stringSpacing: 30,
            labelOffset: 24
        )
        
        let y1 = layout.stringY(1)
        let y6 = layout.stringY(6)
        #expect(y1 < y6)
        #expect(y1 == 15) // 0.5 * 30
        #expect(y6 == 165) // 5.5 * 30
    }
    
    @Test func hitTestRoundTripsStringAndFret() {
        let layout = FretboardLayout(
            maxFret: 12,
            fretWidth: 40,
            stringSpacing: 30,
            labelOffset: 0
        )
        
        let point = layout.point(string: 2, fret: 3)
        let hit = layout.hitTest(at: point)
        #expect(hit?.string == 2)
        #expect(hit?.fret == 3)
    }
    
    @Test func hitTestAccountsForLabelOffset() {
        let layout = FretboardLayout(
            maxFret: 12,
            fretWidth: 40,
            stringSpacing: 30,
            labelOffset: 24
        )
        
        let point = layout.point(string: 1, fret: 0)
        let hit = layout.hitTest(at: point)
        #expect(hit?.string == 1)
        #expect(hit?.fret == 0)
    }
    
    @Test func regionRectCoversBlockRanges() {
        let layout = FretboardLayout(
            maxFret: 12,
            fretWidth: 40,
            stringSpacing: 30,
            labelOffset: 0
        )
        let rect = layout.regionRect(stringRange: 1...2, fretRange: 0...3, padding: 0)
        
        #expect(rect.minY < layout.stringY(1))
        #expect(rect.maxY > layout.stringY(2))
        #expect(rect.minX <= layout.fretLineX(0))
        #expect(rect.maxX >= layout.fretLineX(3))
    }
    
    @Test func blockCoordinateKeysIncludeSelectedOnly() {
        let head = BlockGenerator.headBlock(for: .C, maxFret: 12)
        let bridge = BlockGenerator.bridgeBlock(for: .C, maxFret: 12)
        let keys = FretboardRenderer.blockCoordinateKeys(
            blocks: [head, bridge],
            selectedTypes: [.headBlock]
        )
        
        #expect(!keys.isEmpty)
        #expect(keys.contains("1,0"))
        #expect(!keys.contains("4,0")) // bridge note not selected
    }
    
    @Test func patternViewAndFretboardShareOrientation() {
        // PatternView uses labelOffset 0; FretboardView uses 24 — Y axis must still
        // place string 1 above string 6 in both.
        let lessonLayout = FretboardLayout(maxFret: 12, fretWidth: 40, stringSpacing: 30, labelOffset: 0)
        let explorerLayout = FretboardLayout(maxFret: 24, fretWidth: 40, stringSpacing: 30, labelOffset: 24)
        
        #expect(lessonLayout.stringY(1) < lessonLayout.stringY(6))
        #expect(explorerLayout.stringY(1) < explorerLayout.stringY(6))
        #expect(lessonLayout.stringY(3) == explorerLayout.stringY(3))
    }
}
