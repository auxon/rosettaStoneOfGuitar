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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Lesson header
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
                
                // Lesson content
                ForEach(Array(lesson.content.enumerated()), id: \.offset) { index, content in
                    contentView(for: content)
                }
                
                // Complete button
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
                
                PatternView(pattern: pattern)
                    .frame(height: 300)
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
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
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

