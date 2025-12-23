//
//  MasteryGameViewModel.swift
//  rSoGuitar
//
//  ViewModel for the Fretboard Mastery game
//

import Foundation
import SwiftUI
import Combine

class MasteryGameViewModel: ObservableObject {
    // Game state
    @Published var currentQuestion: MasteryQuestion?
    @Published var selectedAnswer: Mode?
    @Published var hasAnswered: Bool = false
    @Published var isCorrect: Bool = false
    @Published var showingResult: Bool = false
    
    // Score tracking
    @Published var score: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var streak: Int = 0
    @Published var bestStreak: Int = 0
    
    // Game settings
    @Published var difficulty: GameDifficulty = .medium
    @Published var gameMode: MasteryGameMode = .identifyMode
    @Published var includeAllKeys: Bool = false
    
    // Fretboard display
    @Published var displayedPositions: [FretboardPosition] = []
    @Published var displayedRootNote: Note = .C
    @Published var maxFret: Int = 12
    
    // Timer
    @Published var timeRemaining: Int = 0
    @Published var timerActive: Bool = false
    private var timer: Timer?
    
    // Audio
    private let audioService = AudioService.shared
    
    init() {
        generateNewQuestion()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Game Control
    
    func startNewGame() {
        score = 0
        totalQuestions = 0
        streak = 0
        hasAnswered = false
        showingResult = false
        selectedAnswer = nil
        generateNewQuestion()
    }
    
    func generateNewQuestion() {
        hasAnswered = false
        showingResult = false
        selectedAnswer = nil
        
        // Select random key
        let keys = includeAllKeys ? Key.allCases : [.C, .G, .D, .A, .E, .F]
        let randomKey = keys.randomElement() ?? .C
        displayedRootNote = randomKey.rootNote
        
        // Select random correct mode
        let correctMode = Mode.allCases.randomElement() ?? .ionian
        
        // Generate the mode shape
        let shape = ModeGenerator.modeFromRoot(correctMode, rootNote: displayedRootNote, maxFret: maxFret)
        
        // Filter positions based on difficulty
        displayedPositions = filterPositionsForDifficulty(shape.positions)
        
        // Generate answer options
        let options = generateAnswerOptions(correctAnswer: correctMode)
        
        // Create question
        currentQuestion = MasteryQuestion(
            id: UUID(),
            mode: gameMode,
            correctAnswer: correctMode,
            options: options,
            rootNote: displayedRootNote,
            hint: generateHint(for: correctMode)
        )
        
        // Start timer if enabled
        if difficulty == .hard {
            startTimer()
        }
        
        totalQuestions += 1
    }
    
    private func filterPositionsForDifficulty(_ positions: [FretboardPosition]) -> [FretboardPosition] {
        switch difficulty {
        case .easy:
            // Show all positions, limited fret range
            return positions.filter { $0.fret <= 7 }
        case .medium:
            // Show positions in a typical box pattern
            return positions.filter { $0.fret <= 12 }
        case .hard:
            // Show all positions, full fretboard
            return positions
        }
    }
    
    private func generateAnswerOptions(correctAnswer: Mode) -> [Mode] {
        var options: [Mode] = [correctAnswer]
        
        // Add wrong answers
        let wrongAnswers = Mode.allCases.filter { $0 != correctAnswer }.shuffled()
        let numberOfOptions = difficulty == .easy ? 3 : 4
        
        options.append(contentsOf: wrongAnswers.prefix(numberOfOptions - 1))
        
        return options.shuffled()
    }
    
    private func generateHint(for mode: Mode) -> String {
        switch difficulty {
        case .easy:
            return "This is a \(mode.quality.lowercased()) mode."
        case .medium:
            return "Look for the characteristic interval."
        case .hard:
            return ""  // No hint in hard mode
        }
    }
    
    // MARK: - Answer Handling
    
    func submitAnswer(_ answer: Mode) {
        guard !hasAnswered, let question = currentQuestion else { return }
        
        selectedAnswer = answer
        hasAnswered = true
        isCorrect = answer == question.correctAnswer
        
        if isCorrect {
            score += pointsForCorrectAnswer()
            streak += 1
            bestStreak = max(bestStreak, streak)
            
            // Play success sound
            playFeedbackSound(correct: true)
        } else {
            streak = 0
            
            // Play error sound
            playFeedbackSound(correct: false)
        }
        
        stopTimer()
        showingResult = true
    }
    
    private func pointsForCorrectAnswer() -> Int {
        var points = 10
        
        // Bonus for difficulty
        switch difficulty {
        case .easy: points += 0
        case .medium: points += 5
        case .hard: points += 10
        }
        
        // Bonus for streak
        points += min(streak * 2, 20)
        
        // Bonus for time remaining (hard mode)
        if difficulty == .hard {
            points += timeRemaining
        }
        
        return points
    }
    
    private func playFeedbackSound(correct: Bool) {
        // Play a note to indicate correct/incorrect
        if correct {
            audioService.playNote(.C, octave: 5)  // Higher note for correct
        } else {
            audioService.playNote(.C, octave: 2)  // Lower note for incorrect
        }
    }
    
    func nextQuestion() {
        generateNewQuestion()
    }
    
    func useHint() {
        // Could deduct points or limit hints
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timeRemaining = 30  // 30 seconds for hard mode
        timerActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timeExpired()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerActive = false
    }
    
    private func timeExpired() {
        stopTimer()
        
        if !hasAnswered {
            hasAnswered = true
            isCorrect = false
            streak = 0
            showingResult = true
        }
    }
    
    // MARK: - Settings
    
    func setDifficulty(_ newDifficulty: GameDifficulty) {
        difficulty = newDifficulty
        startNewGame()
    }
    
    func setGameMode(_ mode: MasteryGameMode) {
        gameMode = mode
        startNewGame()
    }
    
    // MARK: - Statistics
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions * 10) * 100
    }
    
    var scoreText: String {
        "\(score) pts"
    }
    
    var streakText: String {
        streak > 0 ? "🔥 \(streak)" : ""
    }
}

// MARK: - Supporting Types

struct MasteryQuestion: Identifiable {
    let id: UUID
    let mode: MasteryGameMode
    let correctAnswer: Mode
    let options: [Mode]
    let rootNote: Note
    let hint: String
}

enum GameDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var description: String {
        switch self {
        case .easy: return "3 options, hints, limited frets"
        case .medium: return "4 options, partial hints"
        case .hard: return "4 options, timer, no hints"
        }
    }
}

enum MasteryGameMode: String, CaseIterable {
    case identifyMode = "Identify Mode"
    case identifyRoot = "Identify Root"
    case identifyInterval = "Identify Interval"
    
    var description: String {
        switch self {
        case .identifyMode: return "Name the mode shown on the fretboard"
        case .identifyRoot: return "Find the root note of the pattern"
        case .identifyInterval: return "Identify the characteristic interval"
        }
    }
}

