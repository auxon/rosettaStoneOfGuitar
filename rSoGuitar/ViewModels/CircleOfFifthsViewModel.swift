//
//  CircleOfFifthsViewModel.swift
//  rSoGuitar
//
//  ViewModel for the Circle of Fifths trainer
//

import Foundation
import SwiftUI
import Combine

class CircleOfFifthsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedKey: CircleKey?
    @Published var showMinorKeys: Bool = true
    @Published var isQuizMode: Bool = false
    @Published var quizQuestion: QuizQuestion?
    @Published var quizScore: Int = 0
    @Published var quizTotal: Int = 0
    @Published var showAnswer: Bool = false
    @Published var lastAnswerCorrect: Bool = false
    @Published var highlightedKeys: Set<String> = []
    @Published var showChordProgression: Bool = false
    @Published var selectedProgression: ChordProgression?
    
    // MARK: - Circle of Fifths Data
    
    /// Major keys arranged clockwise by fifths
    static let majorKeys: [CircleKey] = [
        CircleKey(name: "C", position: 0, sharpsFlats: 0, relativeMinor: "Am", notes: ["C", "D", "E", "F", "G", "A", "B"]),
        CircleKey(name: "G", position: 1, sharpsFlats: 1, relativeMinor: "Em", notes: ["G", "A", "B", "C", "D", "E", "F#"]),
        CircleKey(name: "D", position: 2, sharpsFlats: 2, relativeMinor: "Bm", notes: ["D", "E", "F#", "G", "A", "B", "C#"]),
        CircleKey(name: "A", position: 3, sharpsFlats: 3, relativeMinor: "F#m", notes: ["A", "B", "C#", "D", "E", "F#", "G#"]),
        CircleKey(name: "E", position: 4, sharpsFlats: 4, relativeMinor: "C#m", notes: ["E", "F#", "G#", "A", "B", "C#", "D#"]),
        CircleKey(name: "B", position: 5, sharpsFlats: 5, relativeMinor: "G#m", notes: ["B", "C#", "D#", "E", "F#", "G#", "A#"]),
        CircleKey(name: "F#/Gb", position: 6, sharpsFlats: 6, relativeMinor: "D#m/Ebm", notes: ["F#", "G#", "A#", "B", "C#", "D#", "E#"]),
        CircleKey(name: "Db", position: 7, sharpsFlats: -5, relativeMinor: "Bbm", notes: ["Db", "Eb", "F", "Gb", "Ab", "Bb", "C"]),
        CircleKey(name: "Ab", position: 8, sharpsFlats: -4, relativeMinor: "Fm", notes: ["Ab", "Bb", "C", "Db", "Eb", "F", "G"]),
        CircleKey(name: "Eb", position: 9, sharpsFlats: -3, relativeMinor: "Cm", notes: ["Eb", "F", "G", "Ab", "Bb", "C", "D"]),
        CircleKey(name: "Bb", position: 10, sharpsFlats: -2, relativeMinor: "Gm", notes: ["Bb", "C", "D", "Eb", "F", "G", "A"]),
        CircleKey(name: "F", position: 11, sharpsFlats: -1, relativeMinor: "Dm", notes: ["F", "G", "A", "Bb", "C", "D", "E"])
    ]
    
    /// Minor keys (inner circle)
    static let minorKeys: [CircleKey] = [
        CircleKey(name: "Am", position: 0, sharpsFlats: 0, relativeMinor: "C", notes: ["A", "B", "C", "D", "E", "F", "G"], isMinor: true),
        CircleKey(name: "Em", position: 1, sharpsFlats: 1, relativeMinor: "G", notes: ["E", "F#", "G", "A", "B", "C", "D"], isMinor: true),
        CircleKey(name: "Bm", position: 2, sharpsFlats: 2, relativeMinor: "D", notes: ["B", "C#", "D", "E", "F#", "G", "A"], isMinor: true),
        CircleKey(name: "F#m", position: 3, sharpsFlats: 3, relativeMinor: "A", notes: ["F#", "G#", "A", "B", "C#", "D", "E"], isMinor: true),
        CircleKey(name: "C#m", position: 4, sharpsFlats: 4, relativeMinor: "E", notes: ["C#", "D#", "E", "F#", "G#", "A", "B"], isMinor: true),
        CircleKey(name: "G#m", position: 5, sharpsFlats: 5, relativeMinor: "B", notes: ["G#", "A#", "B", "C#", "D#", "E", "F#"], isMinor: true),
        CircleKey(name: "D#m/Ebm", position: 6, sharpsFlats: 6, relativeMinor: "F#/Gb", notes: ["D#", "E#", "F#", "G#", "A#", "B", "C#"], isMinor: true),
        CircleKey(name: "Bbm", position: 7, sharpsFlats: -5, relativeMinor: "Db", notes: ["Bb", "C", "Db", "Eb", "F", "Gb", "Ab"], isMinor: true),
        CircleKey(name: "Fm", position: 8, sharpsFlats: -4, relativeMinor: "Ab", notes: ["F", "G", "Ab", "Bb", "C", "Db", "Eb"], isMinor: true),
        CircleKey(name: "Cm", position: 9, sharpsFlats: -3, relativeMinor: "Eb", notes: ["C", "D", "Eb", "F", "G", "Ab", "Bb"], isMinor: true),
        CircleKey(name: "Gm", position: 10, sharpsFlats: -2, relativeMinor: "Bb", notes: ["G", "A", "Bb", "C", "D", "Eb", "F"], isMinor: true),
        CircleKey(name: "Dm", position: 11, sharpsFlats: -1, relativeMinor: "F", notes: ["D", "E", "F", "G", "A", "Bb", "C"], isMinor: true)
    ]
    
    /// Common chord progressions
    static let chordProgressions: [ChordProgression] = [
        ChordProgression(name: "I-IV-V-I", description: "Classic Rock/Blues", degrees: [1, 4, 5, 1]),
        ChordProgression(name: "I-V-vi-IV", description: "Pop Progression", degrees: [1, 5, 6, 4]),
        ChordProgression(name: "ii-V-I", description: "Jazz Standard", degrees: [2, 5, 1]),
        ChordProgression(name: "I-vi-IV-V", description: "'50s Progression", degrees: [1, 6, 4, 5]),
        ChordProgression(name: "vi-IV-I-V", description: "Axis Progression", degrees: [6, 4, 1, 5]),
        ChordProgression(name: "I-IV-vi-V", description: "Singer-Songwriter", degrees: [1, 4, 6, 5])
    ]
    
    // MARK: - Methods
    
    func selectKey(_ key: CircleKey) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedKey?.name == key.name {
                selectedKey = nil
                highlightedKeys.removeAll()
            } else {
                selectedKey = key
                updateHighlightedKeys(for: key)
            }
        }
    }
    
    private func updateHighlightedKeys(for key: CircleKey) {
        highlightedKeys.removeAll()
        highlightedKeys.insert(key.name)
        
        // Highlight relative major/minor
        highlightedKeys.insert(key.relativeMinor)
        
        // Highlight the fifth (next key clockwise)
        let fifthIndex = (key.position + 1) % 12
        if key.isMinor {
            highlightedKeys.insert(Self.minorKeys[fifthIndex].name)
        } else {
            highlightedKeys.insert(Self.majorKeys[fifthIndex].name)
        }
        
        // Highlight the fourth (next key counter-clockwise)
        let fourthIndex = (key.position + 11) % 12
        if key.isMinor {
            highlightedKeys.insert(Self.minorKeys[fourthIndex].name)
        } else {
            highlightedKeys.insert(Self.majorKeys[fourthIndex].name)
        }
    }
    
    func getChordsForKey(_ key: CircleKey) -> [String] {
        if key.isMinor {
            // Minor key: i, ii°, III, iv, v, VI, VII
            return [
                "\(key.notes[0])m",     // i
                "\(key.notes[1])°",     // ii°
                "\(key.notes[2])",      // III
                "\(key.notes[3])m",     // iv
                "\(key.notes[4])m",     // v
                "\(key.notes[5])",      // VI
                "\(key.notes[6])"       // VII
            ]
        } else {
            // Major key: I, ii, iii, IV, V, vi, vii°
            return [
                key.notes[0],           // I
                "\(key.notes[1])m",     // ii
                "\(key.notes[2])m",     // iii
                key.notes[3],           // IV
                key.notes[4],           // V
                "\(key.notes[5])m",     // vi
                "\(key.notes[6])°"      // vii°
            ]
        }
    }
    
    func getProgressionChords(for key: CircleKey, progression: ChordProgression) -> [String] {
        let chords = getChordsForKey(key)
        return progression.degrees.map { degree in
            chords[degree - 1]
        }
    }
    
    // MARK: - Quiz Mode
    
    func startQuiz() {
        isQuizMode = true
        quizScore = 0
        quizTotal = 0
        showAnswer = false
        generateNewQuestion()
    }
    
    func endQuiz() {
        isQuizMode = false
        quizQuestion = nil
        showAnswer = false
    }
    
    func generateNewQuestion() {
        showAnswer = false
        let questionTypes: [QuizQuestionType] = [.fifthOf, .fourthOf, .relativeMajor, .relativeMinor, .sharpsFlats]
        let type = questionTypes.randomElement()!
        
        switch type {
        case .fifthOf:
            let key = Self.majorKeys.randomElement()!
            let fifthIndex = (key.position + 1) % 12
            let answer = Self.majorKeys[fifthIndex].name
            quizQuestion = QuizQuestion(
                type: type,
                questionText: "What is the fifth of \(key.name)?",
                correctAnswer: answer,
                options: generateOptions(correctAnswer: answer, from: Self.majorKeys.map { $0.name })
            )
            
        case .fourthOf:
            let key = Self.majorKeys.randomElement()!
            let fourthIndex = (key.position + 11) % 12
            let answer = Self.majorKeys[fourthIndex].name
            quizQuestion = QuizQuestion(
                type: type,
                questionText: "What is the fourth of \(key.name)?",
                correctAnswer: answer,
                options: generateOptions(correctAnswer: answer, from: Self.majorKeys.map { $0.name })
            )
            
        case .relativeMajor:
            let key = Self.minorKeys.randomElement()!
            let answer = key.relativeMinor // relativeMinor field stores relative major for minor keys
            quizQuestion = QuizQuestion(
                type: type,
                questionText: "What is the relative major of \(key.name)?",
                correctAnswer: answer,
                options: generateOptions(correctAnswer: answer, from: Self.majorKeys.map { $0.name })
            )
            
        case .relativeMinor:
            let key = Self.majorKeys.randomElement()!
            let answer = key.relativeMinor
            quizQuestion = QuizQuestion(
                type: type,
                questionText: "What is the relative minor of \(key.name)?",
                correctAnswer: answer,
                options: generateOptions(correctAnswer: answer, from: Self.minorKeys.map { $0.name })
            )
            
        case .sharpsFlats:
            let key = Self.majorKeys.filter { $0.sharpsFlats != 0 }.randomElement()!
            let answer: String
            if key.sharpsFlats > 0 {
                answer = "\(key.sharpsFlats) sharp\(key.sharpsFlats > 1 ? "s" : "")"
            } else {
                answer = "\(abs(key.sharpsFlats)) flat\(abs(key.sharpsFlats) > 1 ? "s" : "")"
            }
            quizQuestion = QuizQuestion(
                type: type,
                questionText: "How many sharps/flats in the key of \(key.name)?",
                correctAnswer: answer,
                options: ["0", "1 sharp", "2 sharps", "3 sharps", "4 sharps", "5 sharps", "1 flat", "2 flats", "3 flats", "4 flats", "5 flats"].shuffled().prefix(4).map { String($0) }
            )
        }
    }
    
    private func generateOptions(correctAnswer: String, from pool: [String]) -> [String] {
        var options = Set<String>()
        options.insert(correctAnswer)
        
        let filtered = pool.filter { $0 != correctAnswer }
        while options.count < 4 && options.count < pool.count {
            if let option = filtered.randomElement() {
                options.insert(option)
            }
        }
        
        return Array(options).shuffled()
    }
    
    func submitAnswer(_ answer: String) {
        guard let question = quizQuestion else { return }
        
        quizTotal += 1
        lastAnswerCorrect = answer == question.correctAnswer
        
        if lastAnswerCorrect {
            quizScore += 1
        }
        
        showAnswer = true
        
        // Auto-advance after showing answer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.generateNewQuestion()
        }
    }
    
    // MARK: - Helper Methods
    
    func angleForPosition(_ position: Int) -> Angle {
        // Start from top (12 o'clock) and go clockwise
        // Each position is 30 degrees apart (360 / 12)
        return Angle(degrees: Double(position) * 30 - 90)
    }
    
    func sharpsFlatsDescription(_ key: CircleKey) -> String {
        if key.sharpsFlats == 0 {
            return "No sharps or flats"
        } else if key.sharpsFlats > 0 {
            return "\(key.sharpsFlats) sharp\(key.sharpsFlats > 1 ? "s" : "")"
        } else {
            return "\(abs(key.sharpsFlats)) flat\(abs(key.sharpsFlats) > 1 ? "s" : "")"
        }
    }
}

// MARK: - Supporting Types

struct CircleKey: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let position: Int           // 0-11 clockwise from C
    let sharpsFlats: Int        // Positive = sharps, negative = flats
    let relativeMinor: String   // For major keys: relative minor, for minor keys: relative major
    let notes: [String]         // Scale notes
    var isMinor: Bool = false
    
    static func == (lhs: CircleKey, rhs: CircleKey) -> Bool {
        lhs.name == rhs.name && lhs.isMinor == rhs.isMinor
    }
}

struct ChordProgression: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let degrees: [Int]          // Scale degrees (1-7)
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let type: QuizQuestionType
    let questionText: String
    let correctAnswer: String
    let options: [String]
}

enum QuizQuestionType {
    case fifthOf
    case fourthOf
    case relativeMajor
    case relativeMinor
    case sharpsFlats
}
