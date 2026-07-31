//
//  rSoGuitarTests.swift
//  rSoGuitarTests
//
//  Suite smoke test — detailed coverage lives in:
//  RSOGTemplateTests, PatternGeneratorTests, FretboardRendererTests,
//  RSOGConceptInfoTests, and RSOGValidationTests (Phase 6).
//

import Testing
@testable import rSoGuitar

struct rSoGuitarTests {
    
    @Test func suiteCanAccessAppModule() {
        #expect(Constants.numberOfStrings == 6)
        #expect(Key.allCases.count == 12)
        #expect(!RSOGConceptInfo.allConcepts.isEmpty)
    }
}
