//
//  MasteryGameView.swift
//  rSoGuitar
//
//  Fretboard Mastery game view
//

import SwiftUI

struct MasteryGameView: View {
    @StateObject private var viewModel = MasteryGameViewModel()
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Score header
                    scoreHeader
                    
                    // Question area
                    questionArea
                    
                    // Fretboard display
                    fretboardDisplay
                    
                    // Answer options
                    answerOptions
                    
                    // Result/Next button
                    if viewModel.showingResult {
                        resultView
                    }
                }
                .padding()
            }
            .navigationTitle("Mode Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.startNewGame() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
        }
    }
    
    // MARK: - Score Header
    
    private var scoreHeader: some View {
        HStack {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(viewModel.scoreText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }
            
            Spacer()
            
            // Streak
            if !viewModel.streakText.isEmpty {
                VStack(spacing: 2) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.streakText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Timer (hard mode)
            if viewModel.timerActive {
                VStack(spacing: 2) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(viewModel.timeRemaining)s")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.timeRemaining <= 10 ? .red : .green)
                }
            }
            
            Spacer()
            
            // Difficulty badge
            Text(viewModel.difficulty.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(difficultyColor)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var difficultyColor: Color {
        switch viewModel.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    // MARK: - Question Area
    
    private var questionArea: some View {
        VStack(spacing: 8) {
            if let question = viewModel.currentQuestion {
                Text("What mode is this?")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Key:")
                        .foregroundColor(.gray)
                    Text(question.rootNote.rawValue)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                .font(.subheadline)
                
                if !question.hint.isEmpty && !viewModel.hasAnswered {
                    Text("💡 \(question.hint)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Fretboard Display
    
    private var fretboardDisplay: some View {
        GeometryReader { geometry in
            let fretWidth: CGFloat = 35
            let stringSpacing: CGFloat = 22
            let labelOffset: CGFloat = 20
            
            ScrollView(.horizontal, showsIndicators: false) {
                Canvas { context, size in
                    // Draw fretboard background
                    drawFretboardBackground(context: context, size: size, fretWidth: fretWidth, stringSpacing: stringSpacing, labelOffset: labelOffset)
                    
                    // Draw mode positions
                    drawModePositions(context: context, fretWidth: fretWidth, stringSpacing: stringSpacing, labelOffset: labelOffset)
                }
                .frame(width: CGFloat(viewModel.maxFret + 1) * fretWidth + labelOffset, height: CGFloat(Constants.numberOfStrings) * stringSpacing)
            }
        }
        .frame(height: 160)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func drawFretboardBackground(context: GraphicsContext, size: CGSize, fretWidth: CGFloat, stringSpacing: CGFloat, labelOffset: CGFloat) {
        // Draw strings
        for string in 0..<Constants.numberOfStrings {
            let y = CGFloat(string) * stringSpacing + stringSpacing / 2
            var path = Path()
            path.move(to: CGPoint(x: labelOffset, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: string < 3 ? 1 : 2)
        }
        
        // Draw frets
        for fret in 0...viewModel.maxFret {
            let x = CGFloat(fret) * fretWidth + labelOffset
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(Constants.numberOfStrings) * stringSpacing))
            context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: fret == 0 ? 3 : 1)
        }
        
        // Draw fret markers
        let markerFrets = [3, 5, 7, 9, 12]
        for fret in markerFrets where fret <= viewModel.maxFret {
            let x = CGFloat(fret) * fretWidth + fretWidth / 2 + labelOffset
            let y = CGFloat(Constants.numberOfStrings) * stringSpacing / 2
            
            let markerSize: CGFloat = fret == 12 ? 6 : 5
            context.fill(
                Path(ellipseIn: CGRect(x: x - markerSize/2, y: y - markerSize/2, width: markerSize, height: markerSize)),
                with: .color(.gray.opacity(0.4))
            )
        }
    }
    
    private func drawModePositions(context: GraphicsContext, fretWidth: CGFloat, stringSpacing: CGFloat, labelOffset: CGFloat) {
        for position in viewModel.displayedPositions {
            guard position.fret >= 0 && position.fret <= viewModel.maxFret else { continue }
            guard position.string >= 1 && position.string <= Constants.numberOfStrings else { continue }
            
            let x = CGFloat(position.fret) * fretWidth + fretWidth / 2 + labelOffset
            let y = (CGFloat(position.string - 1) + 0.5) * stringSpacing
            
            // Color based on whether it's the root
            let fillColor: Color = position.isRoot ? 
                Color(red: 0.9, green: 0.3, blue: 0.5) :  // Pink for root
                Color(red: 0.5, green: 0.3, blue: 0.8)    // Purple for others
            
            let radius: CGFloat = position.isRoot ? 10 : 7
            
            context.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                with: .color(fillColor.opacity(0.9))
            )
            
            context.stroke(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                with: .color(.white),
                lineWidth: 1.5
            )
            
            // Draw "R" on root notes
            if position.isRoot {
                let text = Text("R")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                context.draw(text, at: CGPoint(x: x, y: y))
            }
        }
    }
    
    // MARK: - Answer Options
    
    private var answerOptions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let question = viewModel.currentQuestion {
                ForEach(question.options, id: \.self) { mode in
                    AnswerButton(
                        mode: mode,
                        isSelected: viewModel.selectedAnswer == mode,
                        isCorrect: viewModel.hasAnswered && mode == question.correctAnswer,
                        isWrong: viewModel.hasAnswered && viewModel.selectedAnswer == mode && mode != question.correctAnswer,
                        isDisabled: viewModel.hasAnswered
                    ) {
                        viewModel.submitAnswer(mode)
                    }
                }
            }
        }
    }
    
    // MARK: - Result View
    
    private var resultView: some View {
        VStack(spacing: 12) {
            // Result message
            HStack {
                Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.isCorrect ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text(viewModel.isCorrect ? "Correct!" : "Not quite...")
                        .font(.headline)
                        .foregroundColor(viewModel.isCorrect ? .green : .red)
                    
                    if !viewModel.isCorrect, let question = viewModel.currentQuestion {
                        Text("The answer was \(question.correctAnswer.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Mode info
            if let question = viewModel.currentQuestion {
                Text(question.correctAnswer.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Next button
            Button(action: { viewModel.nextQuestion() }) {
                HStack {
                    Text("Next Question")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Settings Sheet
    
    private var settingsSheet: some View {
        NavigationView {
            Form {
                Section("Difficulty") {
                    ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            viewModel.setDifficulty(difficulty)
                            showSettings = false
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(difficulty.rawValue)
                                        .foregroundColor(.primary)
                                    Text(difficulty.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.difficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Total Questions")
                        Spacer()
                        Text("\(viewModel.totalQuestions)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Current Score")
                        Spacer()
                        Text("\(viewModel.score)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Best Streak")
                        Spacer()
                        Text("\(viewModel.bestStreak)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Toggle("Include All Keys", isOn: $viewModel.includeAllKeys)
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
        }
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let mode: Mode
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mode.romanNumeral)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(mode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.3)
        } else if isWrong {
            return Color.red.opacity(0.3)
        } else if isSelected {
            return Color.purple.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else {
            return .white
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return .purple
        } else {
            return .gray.opacity(0.5)
        }
    }
}

#Preview {
    MasteryGameView()
        .preferredColorScheme(.dark)
}

