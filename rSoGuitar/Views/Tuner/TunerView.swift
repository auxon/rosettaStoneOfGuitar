//
//  TunerView.swift
//  rSoGuitar
//
//  Guitar tuner view with pitch detection
//

import SwiftUI

struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Tuning selector
                    tuningSelector
                    
                    // Main tuner display
                    tunerDisplay
                    
                    // String indicators
                    stringIndicators
                    
                    // Start/Stop button
                    controlButton
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Tuner")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.requestPermission()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
    
    // MARK: - Tuning Selector
    
    private var tuningSelector: some View {
        VStack(spacing: 12) {
            // Tuning preset selector
            Menu {
                ForEach(GuitarTuning.allCases, id: \.self) { tuning in
                    Button(action: {
                        viewModel.selectTuning(tuning)
                    }) {
                        HStack {
                            Text(tuning.rawValue)
                            if viewModel.selectedTuning == tuning {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedTuning.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Reference pitch selector (A4)
            HStack(spacing: 16) {
                Text("A4 =")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button(action: { viewModel.setReferencePitch(viewModel.referencePitch - 1) }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.cyan)
                }
                
                Text("\(Int(viewModel.referencePitch)) Hz")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 70)
                
                Button(action: { viewModel.setReferencePitch(viewModel.referencePitch + 1) }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cyan)
                }
                
                Button(action: { viewModel.setReferencePitch(440.0) }) {
                    Text("Reset")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Tuner Display
    
    private var tunerDisplay: some View {
        VStack(spacing: 16) {
            // Note display
            ZStack {
                Circle()
                    .stroke(tuningColor, lineWidth: 4)
                    .frame(width: 160, height: 160)
                
                // Tuning indicator arc - use cents from target for better accuracy
                Circle()
                    .trim(from: 0, to: min(abs(viewModel.centsFromTarget) / 50.0, 1.0))
                    .stroke(
                        tuningColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(viewModel.centsOff >= 0 ? -90 : -90 - (abs(viewModel.centsOff) / 50.0 * 180)))
                
                VStack(spacing: 4) {
                    Text(viewModel.currentNote)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if viewModel.currentNote != "--" {
                        Text("\(viewModel.currentOctave)")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Cents indicator - show cents from target string for accurate tuning
            HStack(spacing: 40) {
                Text("♭")
                    .font(.title)
                    .foregroundColor(viewModel.centsFromTarget < -5 ? .orange : .gray)
                
                VStack {
                    Text(String(format: "%+.0f", viewModel.centsFromTarget))
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(tuningColor)
                    Text("cents")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("♯")
                    .font(.title)
                    .foregroundColor(viewModel.centsFromTarget > 5 ? .orange : .gray)
            }
            
            // Frequency display
            if viewModel.currentFrequency > 0 {
                Text(String(format: "%.1f Hz", viewModel.currentFrequency))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // Target string indicator
            if let targetString = viewModel.closestString {
                HStack {
                    Text("Target:")
                        .foregroundColor(.gray)
                    Text("String \(targetString.number) (\(targetString.note))")
                        .foregroundColor(.cyan)
                        .fontWeight(.semibold)
                    Text(String(format: "%.1f Hz", targetString.frequency))
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - String Indicators
    
    private var stringIndicators: some View {
        VStack(spacing: 12) {
            Text("Strings")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ForEach(viewModel.targetStrings) { string in
                    stringIndicator(string)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func stringIndicator(_ string: TunerString) -> some View {
        let isTarget = viewModel.closestString?.id == string.id
        let isInTune = isTarget && abs(viewModel.centsOff) < 5
        
        return VStack(spacing: 6) {
            Circle()
                .fill(isInTune ? Color.green : (isTarget ? Color.cyan : Color.gray.opacity(0.3)))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(string.note)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isTarget ? .black : .white)
                )
                .overlay(
                    Circle()
                        .stroke(isTarget ? Color.cyan : Color.clear, lineWidth: 2)
                )
            
            Text("\(string.number)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Control Button
    
    private var controlButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.toggleListening()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                        .font(.title2)
                    Text(viewModel.isListening ? "Stop" : "Start Tuning")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    viewModel.isListening ?
                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(25)
                .shadow(color: viewModel.isListening ? .red.opacity(0.4) : .cyan.opacity(0.4), radius: 10)
            }
            
            if viewModel.permissionDenied {
                Text("Microphone access denied. Please enable in Settings.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.isListening {
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cyan)
                            .frame(width: 4, height: CGFloat.random(in: 8...24))
                            .animation(
                                Animation.easeInOut(duration: 0.3)
                                    .repeatForever()
                                    .delay(Double(i) * 0.1),
                                value: viewModel.isListening
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var tuningColor: Color {
        let cents = abs(viewModel.centsFromTarget)
        if viewModel.currentNote == "--" || viewModel.closestString == nil {
            return .gray
        } else if cents < 5 {
            return .green
        } else if cents < 15 {
            return .yellow
        } else if cents < 30 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    TunerView()
        .preferredColorScheme(.dark)
}

