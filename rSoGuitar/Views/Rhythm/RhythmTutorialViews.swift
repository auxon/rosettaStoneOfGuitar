//
//  RhythmTutorialViews.swift
//  rSoGuitar
//
//  Rhythm tutorials list + detail with premium gating.
//

import SwiftUI

struct RhythmTutorialListContent: View {
    @ObservedObject var viewModel: RhythmViewModel
    let isPremiumUser: Bool
    
    var body: some View {
        List {
            Section {
                Text("Short guided lessons for the metronome and strumming patterns. Open a pattern in Play Along when you’re ready to loop it.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            }
            
            Section("Tutorials") {
                ForEach(viewModel.content.allTutorialsSorted) { tutorial in
                    let locked = tutorial.isPremium && !isPremiumUser
                    if locked {
                        Button {
                            viewModel.showingPremiumGate = true
                        } label: {
                            tutorialRow(tutorial, locked: true)
                        }
                    } else {
                        NavigationLink {
                            RhythmTutorialDetailView(
                                tutorial: tutorial,
                                viewModel: viewModel,
                                isPremiumUser: isPremiumUser
                            )
                        } label: {
                            tutorialRow(tutorial, locked: false)
                        }
                    }
                }
            }
        }
    }
    
    private func tutorialRow(_ tutorial: RhythmTutorial, locked: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tutorial.isPremium ? "crown.fill" : "metronome.fill")
                .foregroundColor(tutorial.isPremium ? .yellow : .accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(tutorial.title)
                    .font(.headline)
                Text(tutorial.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RhythmTutorialDetailView: View {
    let tutorial: RhythmTutorial
    @ObservedObject var viewModel: RhythmViewModel
    let isPremiumUser: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(tutorial.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(tutorial.sections.enumerated()), id: \.offset) { _, section in
                    sectionView(section)
                }
            }
            .padding()
        }
        .navigationTitle(tutorial.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func sectionView(_ section: RhythmTutorialSection) -> some View {
        switch section {
        case .text(let text):
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .tip(let tip):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text(tip)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case .pattern(let id):
            if let pattern = viewModel.content.pattern(id: id) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(pattern.name)
                        .font(.headline)
                    RhythmBeatGridView(pattern: pattern, currentSlot: -1)
                    Button {
                        viewModel.openPlayAlong(for: pattern, isPremiumUser: isPremiumUser)
                    } label: {
                        Label("Open in Play Along", systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}
