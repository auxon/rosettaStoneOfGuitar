//
//  MainTabView.swift
//  rSoGuitar
//
//  Main tab-based navigation
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var subscriptionService: SubscriptionService
    @StateObject private var progressService = ProgressService.shared
    
    var body: some View {
        TabView {
            // Lessons Tab
            NavigationView {
                LessonListView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            // Fretboard Explorer Tab
            NavigationView {
                FretboardView()
            }
            .tabItem {
                Label("Fretboard", systemImage: "guitars.fill")
            }
            
            // Concepts Tab
            NavigationView {
                ConceptsListView()
            }
            .tabItem {
                Label("Concepts", systemImage: "brain.head.profile")
            }
            
            // Profile/Settings Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .onAppear {
            // Setup services
            subscriptionService.setModelContext(modelContext)
            progressService.setModelContext(modelContext)
        }
    }
}

struct ConceptsListView: View {
    var body: some View {
        List {
            NavigationLink(destination: ConceptView(conceptType: .spiralMapping)) {
                Label("Spiral Mapping", systemImage: "arrow.triangle.2.circlepath")
            }
            
            NavigationLink(destination: ConceptView(conceptType: .jumping)) {
                Label("Jumping", systemImage: "arrow.left.arrow.right")
            }
            
            NavigationLink(destination: ConceptView(conceptType: .familyOfChords)) {
                Label("Family of Chords", systemImage: "music.note.list")
            }
            
            NavigationLink(destination: ConceptView(conceptType: .familialHierarchy)) {
                Label("Familial Hierarchy", systemImage: "chart.bar.fill")
            }
        }
        .navigationTitle("Concepts")
    }
}

struct ProfileView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @StateObject private var progressService = ProgressService.shared
    @State private var showingSubscription = false
    
    var body: some View {
        List {
            Section("Subscription") {
                HStack {
                    Text("Premium Status")
                    Spacer()
                    if subscriptionService.isPremiumUser {
                        #if DEBUG
                        if subscriptionService.debugPremiumEnabled {
                            Label("Debug Active", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                        } else {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        #else
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        #endif
                    } else {
                        Label("Free", systemImage: "xmark.circle.fill")
                        .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showingSubscription = true
                }) {
                    HStack {
                        Text(subscriptionService.isPremiumUser ? "Manage Subscription" : "Upgrade to Premium")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section("Progress") {
                if let progress = progressService.userProgress {
                    HStack {
                        Text("Completed Lessons")
                        Spacer()
                        Text("\(progress.completedLessons.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bookmarked Patterns")
                        Spacer()
                        Text("\(progress.bookmarkedPatterns.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Practice Time")
                        Spacer()
                        Text(formatTime(progress.totalPracticeTime))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            #if DEBUG
            Section("Debug") {
                Toggle("Enable Premium (Debug)", isOn: Binding(
                    get: { subscriptionService.debugPremiumEnabled },
                    set: { _ in subscriptionService.toggleDebugPremium() }
                ))
                .foregroundColor(.orange)
                
                Text("Debug mode: Premium features enabled for testing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            #endif
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionService.shared)
}

