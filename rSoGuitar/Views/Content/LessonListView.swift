//
//  LessonListView.swift
//  rSoGuitar
//
//  List view of all available lessons
//

import SwiftUI

struct LessonListView: View {
    @StateObject private var viewModel = LessonViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showingPremiumGate = false
    
    var body: some View {
        List {
            Section("Free Lessons") {
                ForEach(viewModel.getFreeLessons()) { lesson in
                    LessonRowView(lesson: lesson, viewModel: viewModel)
                }
            }
            
            Section("Premium Lessons") {
                ForEach(viewModel.getPremiumLessons()) { lesson in
                    LessonRowView(lesson: lesson, viewModel: viewModel)
                        .opacity(subscriptionService.isPremiumUser ? 1.0 : 0.6)
                }
            }
        }
        .navigationTitle("Lessons")
        .sheet(isPresented: $showingPremiumGate) {
            PremiumGateView()
        }
    }
}

struct LessonRowView: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LessonViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showingPremiumGate = false
    
    var body: some View {
        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(lesson.title)
                            .font(.headline)
                        if lesson.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(lesson.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(Int(lesson.estimatedTime / 60)) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isLessonCompleted(lesson.id) {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                if lesson.isPremium && !subscriptionService.isPremiumUser {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            .contentShape(Rectangle())
        }
        .onTapGesture {
            if lesson.isPremium && !subscriptionService.isPremiumUser {
                showingPremiumGate = true
            }
        }
        .sheet(isPresented: $showingPremiumGate) {
            PremiumGateView()
        }
    }
}

#Preview {
    NavigationView {
        LessonListView()
            .environmentObject(SubscriptionService.shared)
    }
}

