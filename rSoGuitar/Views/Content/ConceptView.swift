//
//  ConceptView.swift
//  rSoGuitar
//
//  View for learning specific concepts
//

import SwiftUI

struct ConceptView: View {
    let conceptType: PatternType
    @StateObject private var viewModel = PatternViewModel()
    @State private var selectedKey: Key = .C
    
    var body: some View {
        VStack(spacing: 20) {
            // Key selector
            Picker("Key", selection: $selectedKey) {
                ForEach(Key.allCases, id: \.self) { key in
                    Text(key.rootNote.rawValue).tag(key)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedKey) { _, newKey in
                viewModel.updateKey(newKey)
            }
            
            // Pattern visualization
            if let pattern = viewModel.currentPattern {
                PatternView(pattern: pattern)
                    .frame(height: 400)
            } else {
                ProgressView()
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
                .padding()
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
            .padding()
        }
        .navigationTitle(conceptTitle)
        .onAppear {
            viewModel.updatePatternType(conceptType)
            viewModel.updateKey(selectedKey)
        }
    }
    
    private var conceptTitle: String {
        switch conceptType {
        case .spiralMapping:
            return "Spiral Mapping"
        case .jumping:
            return "Jumping"
        case .familyOfChords:
            return "Family of Chords"
        case .familialHierarchy:
            return "Familial Hierarchy"
        }
    }
}

#Preview {
    NavigationView {
        ConceptView(conceptType: .spiralMapping)
    }
}

