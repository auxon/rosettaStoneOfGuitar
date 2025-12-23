//
//  CircleOfFifthsTrainerView.swift
//  rSoGuitar
//
//  Interactive Circle of Fifths trainer for learning key relationships
//

import SwiftUI

struct CircleOfFifthsTrainerView: View {
    @StateObject private var viewModel = CircleOfFifthsViewModel()
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.04, green: 0.04, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isQuizMode {
                            quizModeView
                        } else {
                            explorationModeView
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Circle of Fifths")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            if viewModel.isQuizMode {
                                viewModel.endQuiz()
                            } else {
                                viewModel.startQuiz()
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isQuizMode ? "xmark.circle" : "questionmark.circle")
                            Text(viewModel.isQuizMode ? "Exit Quiz" : "Quiz")
                                .font(.subheadline)
                        }
                        .foregroundColor(.cyan)
                    }
                }
            }
        }
    }
    
    // MARK: - Exploration Mode
    
    private var explorationModeView: some View {
        VStack(spacing: 24) {
            // Circle of Fifths Visualization
            circleVisualization
            
            // Toggle for minor keys
            Toggle(isOn: $viewModel.showMinorKeys) {
                HStack {
                    Image(systemName: "circle.circle")
                        .foregroundColor(.cyan)
                    Text("Show Minor Keys")
                        .foregroundColor(.white)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .cyan))
            .padding(.horizontal, 24)
            
            // Selected key details
            if let key = viewModel.selectedKey {
                keyDetailsCard(key)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Chord progressions section
            if let key = viewModel.selectedKey {
                chordProgressionsSection(key)
            }
            
            // Instructions
            if viewModel.selectedKey == nil {
                instructionsCard
            }
        }
    }
    
    // MARK: - Circle Visualization
    
    private var circleVisualization: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, 360)
            let center = CGPoint(x: geometry.size.width / 2, y: size / 2)
            let outerRadius = (size / 2) - 30
            let innerRadius = outerRadius * 0.65
            
            ZStack {
                // Outer ring background
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 50)
                    .frame(width: outerRadius * 2 - 25, height: outerRadius * 2 - 25)
                
                // Inner ring background (for minor keys)
                if viewModel.showMinorKeys {
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 40)
                        .frame(width: innerRadius * 2 - 20, height: innerRadius * 2 - 20)
                }
                
                // Connection lines for highlighted keys
                if !viewModel.highlightedKeys.isEmpty {
                    connectionLines(center: center, outerRadius: outerRadius - 25, innerRadius: innerRadius - 20)
                }
                
                // Major keys (outer circle)
                ForEach(CircleOfFifthsViewModel.majorKeys) { key in
                    keyButton(key: key, radius: outerRadius - 25, center: center, isMajor: true)
                }
                
                // Minor keys (inner circle)
                if viewModel.showMinorKeys {
                    ForEach(CircleOfFifthsViewModel.minorKeys) { key in
                        keyButton(key: key, radius: innerRadius - 20, center: center, isMajor: false)
                    }
                }
                
                // Center decoration
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Center label
                VStack(spacing: 2) {
                    Text("5ths")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
            .frame(width: geometry.size.width, height: size)
        }
        .frame(height: 360)
        .padding(.horizontal)
    }
    
    private func keyButton(key: CircleKey, radius: CGFloat, center: CGPoint, isMajor: Bool) -> some View {
        let angle = viewModel.angleForPosition(key.position)
        let x = cos(angle.radians) * radius
        let y = sin(angle.radians) * radius
        
        let isSelected = viewModel.selectedKey?.name == key.name
        let isHighlighted = viewModel.highlightedKeys.contains(key.name)
        
        return Button(action: {
            viewModel.selectKey(key)
        }) {
            ZStack {
                Circle()
                    .fill(buttonBackground(isSelected: isSelected, isHighlighted: isHighlighted, isMajor: isMajor))
                    .frame(width: isMajor ? 46 : 38, height: isMajor ? 46 : 38)
                    .shadow(color: isSelected ? .cyan.opacity(0.5) : .clear, radius: 8)
                
                Circle()
                    .stroke(buttonStroke(isSelected: isSelected, isHighlighted: isHighlighted), lineWidth: 2)
                    .frame(width: isMajor ? 46 : 38, height: isMajor ? 46 : 38)
                
                Text(key.name.replacingOccurrences(of: "/Gb", with: "").replacingOccurrences(of: "/Ebm", with: ""))
                    .font(isMajor ? .system(size: 14, weight: .bold) : .system(size: 11, weight: .semibold))
                    .foregroundColor(textColor(isSelected: isSelected, isHighlighted: isHighlighted))
                    .minimumScaleFactor(0.7)
            }
        }
        .offset(x: x, y: y)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func buttonBackground(isSelected: Bool, isHighlighted: Bool, isMajor: Bool) -> Color {
        if isSelected {
            return .cyan
        } else if isHighlighted {
            return isMajor ? .orange.opacity(0.6) : .purple.opacity(0.6)
        } else {
            return isMajor ? Color(white: 0.2) : Color(white: 0.15)
        }
    }
    
    private func buttonStroke(isSelected: Bool, isHighlighted: Bool) -> Color {
        if isSelected {
            return .white
        } else if isHighlighted {
            return .orange
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func textColor(isSelected: Bool, isHighlighted: Bool) -> Color {
        if isSelected {
            return .black
        } else if isHighlighted {
            return .white
        } else {
            return .white.opacity(0.9)
        }
    }
    
    private func connectionLines(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) -> some View {
        Canvas { context, size in
            guard let selected = viewModel.selectedKey else { return }
            
            let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
            let selectedAngle = viewModel.angleForPosition(selected.position)
            let selectedRadius = selected.isMinor ? innerRadius : outerRadius
            let selectedPoint = CGPoint(
                x: centerPoint.x + cos(selectedAngle.radians) * selectedRadius,
                y: centerPoint.y + sin(selectedAngle.radians) * selectedRadius
            )
            
            // Draw lines to related keys
            for keyName in viewModel.highlightedKeys where keyName != selected.name {
                // Find the key
                if let majorKey = CircleOfFifthsViewModel.majorKeys.first(where: { $0.name == keyName }) {
                    let angle = viewModel.angleForPosition(majorKey.position)
                    let point = CGPoint(
                        x: centerPoint.x + cos(angle.radians) * outerRadius,
                        y: centerPoint.y + sin(angle.radians) * outerRadius
                    )
                    
                    var path = Path()
                    path.move(to: selectedPoint)
                    path.addLine(to: point)
                    
                    context.stroke(path, with: .color(.cyan.opacity(0.4)), lineWidth: 2)
                }
                
                if let minorKey = CircleOfFifthsViewModel.minorKeys.first(where: { $0.name == keyName }) {
                    let angle = viewModel.angleForPosition(minorKey.position)
                    let point = CGPoint(
                        x: centerPoint.x + cos(angle.radians) * innerRadius,
                        y: centerPoint.y + sin(angle.radians) * innerRadius
                    )
                    
                    var path = Path()
                    path.move(to: selectedPoint)
                    path.addLine(to: point)
                    
                    context.stroke(path, with: .color(.purple.opacity(0.4)), lineWidth: 2)
                }
            }
        }
    }
    
    // MARK: - Key Details Card
    
    private func keyDetailsCard(_ key: CircleKey) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(key.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text(key.isMinor ? "Minor Key" : "Major Key")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sharps/Flats badge
                Text(viewModel.sharpsFlatsDescription(key))
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(key.sharpsFlats > 0 ? Color.orange : (key.sharpsFlats < 0 ? Color.blue : Color.gray))
                    )
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Scale notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Scale Notes")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    ForEach(Array(key.notes.enumerated()), id: \.offset) { index, note in
                        Text(note)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(index == 0 ? .black : .white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(index == 0 ? Color.cyan : Color.white.opacity(0.1))
                            )
                    }
                }
            }
            
            // Relative key
            HStack {
                Text(key.isMinor ? "Relative Major:" : "Relative Minor:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(key.relativeMinor)
                    .font(.subheadline.bold())
                    .foregroundColor(.cyan)
                
                Spacer()
            }
            
            // Chords in key
            VStack(alignment: .leading, spacing: 8) {
                Text("Chords in Key")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                
                let chords = viewModel.getChordsForKey(key)
                let degrees = key.isMinor ? ["i", "ii°", "III", "iv", "v", "VI", "VII"] : ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(zip(degrees, chords)), id: \.0) { degree, chord in
                            VStack(spacing: 4) {
                                Text(chord)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text(degree)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Chord Progressions Section
    
    private func chordProgressionsSection(_ key: CircleKey) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Progressions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CircleOfFifthsViewModel.chordProgressions) { progression in
                        progressionCard(key: key, progression: progression)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func progressionCard(key: CircleKey, progression: ChordProgression) -> some View {
        let chords = viewModel.getProgressionChords(for: key, progression: progression)
        let isSelected = viewModel.selectedProgression?.id == progression.id
        
        return Button(action: {
            withAnimation(.spring()) {
                viewModel.selectedProgression = isSelected ? nil : progression
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(progression.name)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(progression.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .gray)
                
                HStack(spacing: 4) {
                    ForEach(chords, id: \.self) { chord in
                        Text(chord)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isSelected ? .black : .cyan)
                    }
                }
            }
            .padding(12)
            .frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cyan : Color.white.opacity(0.08))
            )
        }
    }
    
    // MARK: - Instructions Card
    
    private var instructionsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap.fill")
                .font(.largeTitle)
                .foregroundColor(.cyan.opacity(0.7))
            
            Text("Tap any key to explore")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionRow(icon: "circle.fill", color: .orange, text: "Outer circle: Major keys")
                instructionRow(icon: "circle.fill", color: .purple, text: "Inner circle: Minor keys")
                instructionRow(icon: "arrow.clockwise", color: .cyan, text: "Clockwise: Up a 5th")
                instructionRow(icon: "arrow.counterclockwise", color: .cyan, text: "Counter-clockwise: Up a 4th")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
    
    private func instructionRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Quiz Mode View
    
    private var quizModeView: some View {
        VStack(spacing: 24) {
            // Score display
            HStack {
                VStack(alignment: .leading) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(viewModel.quizScore)/\(viewModel.quizTotal)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Accuracy percentage
                if viewModel.quizTotal > 0 {
                    let percentage = Double(viewModel.quizScore) / Double(viewModel.quizTotal) * 100
                    VStack(alignment: .trailing) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.0f%%", percentage))
                            .font(.title.bold())
                            .foregroundColor(percentage >= 70 ? .green : (percentage >= 50 ? .orange : .red))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal)
            
            // Small reference circle
            circleVisualization
                .scaleEffect(0.7)
                .frame(height: 252)
            
            // Question card
            if let question = viewModel.quizQuestion {
                quizQuestionCard(question)
            }
        }
    }
    
    private func quizQuestionCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            Text(question.questionText)
                .font(.title3.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Answer options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    quizOptionButton(option: option, question: question)
                }
            }
            
            // Feedback
            if viewModel.showAnswer {
                HStack {
                    Image(systemName: viewModel.lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(viewModel.lastAnswerCorrect ? "Correct!" : "Incorrect. Answer: \(question.correctAnswer)")
                }
                .font(.headline)
                .foregroundColor(viewModel.lastAnswerCorrect ? .green : .red)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((viewModel.lastAnswerCorrect ? Color.green : Color.red).opacity(0.2))
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private func quizOptionButton(option: String, question: QuizQuestion) -> some View {
        let isCorrect = option == question.correctAnswer
        let showResult = viewModel.showAnswer
        
        return Button(action: {
            if !viewModel.showAnswer {
                viewModel.submitAnswer(option)
            }
        }) {
            Text(option)
                .font(.headline)
                .foregroundColor(showResult && isCorrect ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonColor(option: option, isCorrect: isCorrect, showResult: showResult))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showResult && isCorrect ? Color.green : Color.gray.opacity(0.3), lineWidth: showResult && isCorrect ? 2 : 1)
                )
        }
        .disabled(viewModel.showAnswer)
    }
    
    private func buttonColor(option: String, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult {
            if isCorrect {
                return .green
            } else if option == viewModel.quizQuestion?.correctAnswer {
                return .green.opacity(0.3)
            } else {
                return Color.white.opacity(0.05)
            }
        }
        return Color.white.opacity(0.1)
    }
}

#Preview {
    CircleOfFifthsTrainerView()
        .preferredColorScheme(.dark)
}
