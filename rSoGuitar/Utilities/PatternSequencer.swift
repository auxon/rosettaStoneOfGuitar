//
//  PatternSequencer.swift
//  rSoGuitar
//
//  Converts a Pattern into an ordered sequence of reveal steps for
//  step-through playback (play / frame forward / frame backward / loop).
//

import SwiftUI

/// One frame of a pattern walkthrough.
struct PatternStep: Identifiable, Equatable {
    /// 0-based index in the sequence.
    let id: Int
    /// Short label, e.g. "C" (note name) or "Papa" (family name).
    let title: String
    /// Context line, e.g. "String 5 · Fret 3" or "I · shape 2/6".
    let subtitle: String
    /// Notes newly introduced at this step.
    let positions: [FretboardPosition]
    /// Chord-role used to pick the step's accent color; nil for plain note steps.
    let chordRole: ChordRole?

    var accentColor: SwiftUI.Color {
        RSOGPalette.color(for: chordRole)
    }
}

enum PatternSequencer {

    /// Ordered reveal steps for any pattern type.
    /// Note-path patterns (Spiral Mapping, Jumping) → one step per note.
    /// Chord patterns (Family of Chords, Familial Hierarchy) → one step per triad shape.
    static func steps(for pattern: Pattern) -> [PatternStep] {
        pattern.chordGroups.isEmpty ? noteSteps(for: pattern) : voicingSteps(for: pattern)
    }

    // MARK: Spiral Mapping / Jumping — one step per note along the path

    private static func noteSteps(for pattern: Pattern) -> [PatternStep] {
        pattern.positions.enumerated().map { index, position in
            PatternStep(
                id: index,
                title: position.note.rawValue,
                subtitle: "String \(position.string) · Fret \(position.fret)\(position.isRoot ? " · Root" : "")",
                positions: [position],
                chordRole: nil
            )
        }
    }

    // MARK: Family of Chords / Familial Hierarchy — one step per triad shape

    private static func voicingSteps(for pattern: Pattern) -> [PatternStep] {
        var steps: [PatternStep] = []

        for group in pattern.chordGroups {
            let shapes = group.voicings.isEmpty
                ? [ChordVoicing(positions: group.positions)]
                : group.voicings

            for (shapeIndex, voicing) in shapes.enumerated() where !voicing.positions.isEmpty {
                steps.append(PatternStep(
                    id: steps.count,
                    title: group.familyName,
                    subtitle: "\(group.romanNumeral) · shape \(shapeIndex + 1)/\(shapes.count)",
                    positions: voicing.positions,
                    chordRole: group.chordRole
                ))
            }
        }
        return steps
    }

    // MARK: Reveal helpers

    /// All coordinates revealed after `stepIndex` (inclusive), deduplicated,
    /// in walk order. `stepIndex = -1` reveals nothing.
    static func revealedPositions(steps: [PatternStep], through stepIndex: Int) -> [FretboardPosition] {
        guard !steps.isEmpty else { return [] }
        var seen: Set<String> = []
        var result: [FretboardPosition] = []
        for step in steps.prefix(max(0, stepIndex + 1)) {
            for position in step.positions where seen.insert(position.coordinateKey).inserted {
                result.append(position)
            }
        }
        return result
    }

    /// Coordinate keys not yet revealed at `stepIndex` (for ghost rendering).
    static func ghostPositions(
        pattern: Pattern,
        steps: [PatternStep],
        through stepIndex: Int
    ) -> [FretboardPosition] {
        let revealed = Set(revealedPositions(steps: steps, through: stepIndex).map(\.coordinateKey))
        return pattern.positions.filter { !revealed.contains($0.coordinateKey) }
    }

    /// Index of the first step containing the given coordinate, if any.
    static func stepIndex(at position: FretboardPosition, in steps: [PatternStep]) -> Int? {
        steps.first { step in
            step.positions.contains { $0.string == position.string && $0.fret == position.fret }
        }?.id
    }
}
