//
//  MainTabView.swift
//  rSoGuitar
//
//  Main tab-based navigation — rSoG concepts front and center.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var subscriptionService: SubscriptionService
    @StateObject private var progressService = ProgressService.shared
    
    var body: some View {
        TabView {
            // Lessons
            NavigationView {
                LessonListView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            // Fretboard Explorer — primary rSoG workspace
            NavigationView {
                FretboardView()
            }
            .tabItem {
                Label("Fretboard", systemImage: "guitars.fill")
            }
            
            // Concepts (before Tuner so methodology stays front-of-mind)
            NavigationView {
                ConceptsListView()
            }
            .tabItem {
                Label("Concepts", systemImage: "brain.head.profile")
            }
            
            // Rhythm — metronome, play-alongs, tutorials
            NavigationView {
                RhythmRootView()
            }
            .tabItem {
                Label("Rhythm", systemImage: "metronome.fill")
            }
            
            // Tuner
            TunerView()
            .tabItem {
                Label("Tuner", systemImage: "tuningfork")
            }
            
            // Profile
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .onAppear {
            subscriptionService.setModelContext(modelContext)
            progressService.setModelContext(modelContext)
        }
    }
}

struct ConceptsListView: View {
    var body: some View {
        List {
            Section {
                Text(RSOGConceptInfo.methodBlurb)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                Link(destination: RSOGConceptInfo.siteURL) {
                    Label("rSoGuitar lessons online", systemImage: "safari")
                }
            } header: {
                Text("The Rosetta Stone of Guitar")
            }
            
            Section("Four Core Concepts") {
                ForEach(RSOGConceptInfo.allConcepts, id: \.self) { type in
                    NavigationLink(destination: ConceptView(conceptType: type)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(RSOGConceptInfo.title(for: type), systemImage: icon(for: type))
                                .font(.body.weight(.semibold))
                            Text(RSOGConceptInfo.shortDescription(for: type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section("Fretboard Blocks") {
                ForEach(RSOGConceptInfo.allBlockTypes, id: \.self) { type in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSOGPalette.blockColor(type))
                            .frame(width: 16, height: 16)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RSOGConceptInfo.blockTitle(type))
                                .font(.subheadline.weight(.bold))
                            Text(RSOGConceptInfo.blockSubtitle(type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(RSOGConceptInfo.blockDescription(type))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Concepts")
    }
    
    private func icon(for type: PatternType) -> String {
        switch type {
        case .spiralMapping: return "arrow.triangle.2.circlepath"
        case .jumping: return "arrow.left.arrow.right"
        case .familyOfChords: return "music.note.list"
        case .familialHierarchy: return "chart.bar.fill"
        }
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
                
                Link(destination: RSOGConceptInfo.siteURL) {
                    Label("rsoguitar.com lessons", systemImage: "link")
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
