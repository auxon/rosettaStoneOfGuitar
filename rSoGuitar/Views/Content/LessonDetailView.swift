//
//  LessonDetailView.swift
//  rSoGuitar
//
//  Detailed view for a single lesson
//

import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    @StateObject private var viewModel = LessonViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showingPremiumGate = false
    @State private var selectedKey: Key = .C
    
    private var hasFretboardContent: Bool {
        lesson.content.contains { item in
            switch item {
            case .fretboardDemo: return true
            case .exercise(let exercise): return exercise.pattern != nil
            default: return false
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(lesson.title)
                            .font(.largeTitle)
                            .bold()
                        
                        if lesson.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(lesson.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Label("\(Int(lesson.estimatedTime / 60)) minutes", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                if hasFretboardContent {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Key")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Key.allCases, id: \.self) { key in
                                    Button {
                                        selectedKey = key
                                    } label: {
                                        Text(key.rootNote.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedKey == key ? Color.accentColor : Color(.systemGray5))
                                            .foregroundStyle(selectedKey == key ? Color.white : Color.primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        Text("The pattern is the same in every key — only its place on the neck moves.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                ForEach(Array(lesson.content.enumerated()), id: \.offset) { _, content in
                    contentView(for: displayed(content))
                }
                
                if !viewModel.isLessonCompleted(lesson.id) {
                    Button(action: {
                        viewModel.completeLesson(lesson.id)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Mark as Completed")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Lesson Completed")
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if lesson.isPremium && !subscriptionService.isPremiumUser {
                showingPremiumGate = true
            }
        }
        .sheet(isPresented: $showingPremiumGate) {
            PremiumGateView()
        }
    }
    
    @ViewBuilder
    private func contentView(for content: LessonContent) -> some View {
        switch content {
        case .text(let text):
            Text(text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
        
        case .fretboardDemo(let pattern):
            VStack(alignment: .leading, spacing: 8) {
                Text("Interactive Fretboard Demo")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("Blocks: " + RSOGConceptInfo.demoBlocks(for: pattern.type)
                    .map { RSOGConceptInfo.blockTitle($0) }
                    .sorted()
                    .joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                PatternView(
                    pattern: pattern,
                    initialShowBlocks: true,
                    initialBlockTypes: RSOGConceptInfo.demoBlocks(for: pattern.type)
                )
                .id(pattern.id)
                .frame(minHeight: 420)
            }
        
        case .audioExample(let urlString):
            if let url = URL(string: urlString) {
                AudioPlayerView(audioURL: url)
                    .padding(.horizontal)
            }
        
        case .exercise(let exercise):
            VStack(alignment: .leading, spacing: 12) {
                Text(exercise.title)
                    .font(.headline)
                Text(exercise.instructions)
                    .font(.body)
                
                if let pattern = exercise.pattern {
                    PatternView(
                        pattern: pattern,
                        initialShowBlocks: true,
                        initialBlockTypes: RSOGConceptInfo.demoBlocks(for: pattern.type)
                    )
                    .id(pattern.id)
                    .frame(minHeight: 380)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private func displayed(_ content: LessonContent) -> LessonContent {
        switch content {
        case .fretboardDemo(let pattern):
            return .fretboardDemo(ContentService.shared.pattern(pattern, in: selectedKey))
        case .exercise(let exercise):
            guard let pattern = exercise.pattern else { return content }
            return .exercise(Exercise(
                id: exercise.id,
                title: exercise.title,
                instructions: exercise.instructions,
                pattern: ContentService.shared.pattern(pattern, in: selectedKey),
                correctAnswers: exercise.correctAnswers
            ))
        default:
            return content
        }
    }
}

#Preview {
    let lesson = Lesson(
        title: "Introduction to rSoGuitar",
        description: "Learn the fundamentals",
        content: [.text("Welcome!")],
        isPremium: false,
        order: 1,
        estimatedTime: 300
    )
    
    NavigationView {
        LessonDetailView(lesson: lesson)
            .environmentObject(SubscriptionService.shared)
    }
}
