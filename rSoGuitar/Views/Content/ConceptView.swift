//
//  ConceptView.swift
//  rSoGuitar
//
//  View for learning specific rSoG concepts
//

import SwiftUI

struct ConceptView: View {
    let conceptType: PatternType
    @StateObject private var viewModel = PatternViewModel()
    @State private var selectedKey: Key = .C
    
    private var demoBlocks: Set<BlockType> {
        RSOGConceptInfo.demoBlocks(for: conceptType)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RSOGConceptHeaderView(type: conceptType)
                
                Text(RSOGConceptInfo.detailDescription(for: conceptType))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Block legend for the concept's suggested milestones
                VStack(alignment: .leading, spacing: 6) {
                    Text("Related blocks")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    RSOGBlockLegendView(selectedTypes: demoBlocks, compact: false)
                }
                
                // Key selector
                Picker("Key", selection: $selectedKey) {
                    ForEach(Key.allCases, id: \.self) { key in
                        Text(key.rootNote.rawValue).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedKey) { _, newKey in
                    viewModel.updateKey(newKey)
                }
                
                // Pattern visualization with concept-appropriate blocks preselected
                if let pattern = viewModel.currentPattern {
                    PatternView(
                        pattern: pattern,
                        initialShowBlocks: true,
                        initialBlockTypes: demoBlocks
                    )
                    .frame(minHeight: 380)
                } else {
                    ProgressView()
                        .padding()
                }
                
                // Chord legend when family/hierarchy
                if let groups = viewModel.currentPattern?.chordGroups, !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chord family")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        RSOGChordLegendView(groups: groups)
                    }
                }
                
                // Description
                if let pattern = viewModel.currentPattern {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pattern.description)
                        if !pattern.chordGroups.isEmpty {
                            Text("Chords: " + pattern.chordGroups.map(\.romanNumeral).joined(separator: " · "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !pattern.connections.isEmpty {
                            Text("\(pattern.connections.count) path connections")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.playPatternNotes()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play Pattern")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.toggleBookmark()
                    }) {
                        Image(systemName: viewModel.isBookmarked() ? "bookmark.fill" : "bookmark")
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationTitle(RSOGConceptInfo.title(for: conceptType))
        .onAppear {
            viewModel.updatePatternType(conceptType)
            viewModel.updateKey(selectedKey)
        }
    }
}

#Preview {
    NavigationView {
        ConceptView(conceptType: .spiralMapping)
    }
}
