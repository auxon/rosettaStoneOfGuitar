//
//  RSOGLegendViews.swift
//  rSoGuitar
//
//  Shared legends and block detail sheet for rSoG UI.
//

import SwiftUI

// MARK: - Block Legend

struct RSOGBlockLegendView: View {
    var selectedTypes: Set<BlockType> = Set(RSOGConceptInfo.allBlockTypes)
    var compact: Bool = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 8 : 12) {
                ForEach(RSOGConceptInfo.allBlockTypes, id: \.self) { type in
                    let active = selectedTypes.isEmpty || selectedTypes.contains(type)
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(RSOGPalette.blockColor(type).opacity(active ? 1 : 0.35))
                            .frame(width: compact ? 10 : 12, height: compact ? 10 : 12)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(RSOGConceptInfo.blockTitle(type))
                                .font(compact ? .caption2.weight(.bold) : .caption.weight(.bold))
                            if !compact {
                                Text(RSOGConceptInfo.blockSubtitle(type))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .opacity(active ? 1 : 0.45)
                    .padding(.horizontal, compact ? 6 : 8)
                    .padding(.vertical, compact ? 4 : 6)
                    .background(RSOGPalette.blockColor(type).opacity(active ? 0.14 : 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Chord Legend

struct RSOGChordLegendView: View {
    let groups: [ChordGroup]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(groups) { group in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(RSOGPalette.color(for: group))
                            .frame(width: 10, height: 10)
                        Text(group.romanNumeral)
                            .font(.caption.weight(.semibold))
                        Text(group.root.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSOGPalette.color(for: group).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Concept blurb

struct RSOGConceptHeaderView: View {
    let type: PatternType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(RSOGConceptInfo.title(for: type))
                .font(.headline)
            Text(RSOGConceptInfo.shortDescription(for: type))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Block detail sheet

struct BlockDetailSheet: View {
    let block: Block
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(RSOGPalette.blockColor(block.type))
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.name)
                                .font(.title2.bold())
                            Text(RSOGConceptInfo.blockSubtitle(block.type))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(block.description)
                        .font(.body)
                    
                    Text(RSOGConceptInfo.blockDescription(block.type))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        labeledRow("Strings", "\(block.stringRange.lowerBound)–\(block.stringRange.upperBound)")
                        labeledRow("Frets", "\(block.fretRange.lowerBound)–\(block.fretRange.upperBound)")
                        labeledRow("Anchor fret", "\(block.anchorFret)")
                        labeledRow("Notes", "\(block.positions.count)")
                        labeledRow("Sequence #", "\(block.sequenceIndex)")
                    }
                    
                    if !block.positions.isEmpty {
                        Text("Positions")
                            .font(.headline)
                            .padding(.top, 4)
                        ForEach(block.positions.sorted(by: {
                            $0.string < $1.string || ($0.string == $1.string && $0.fret < $1.fret)
                        })) { pos in
                            HStack {
                                Text("String \(pos.string)")
                                Text("Fret \(pos.fret)")
                                Spacer()
                                Text(pos.note.rawValue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Block Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
