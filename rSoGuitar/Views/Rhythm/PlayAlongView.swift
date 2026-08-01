//
//  PlayAlongView.swift
//  rSoGuitar
//
//  Visual rhythm / strumming pattern grid synced to the metronome.
//

import SwiftUI

struct PlayAlongView: View {
    @ObservedObject var viewModel: RhythmViewModel
    let isPremiumUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            patternPicker
            
            if let pattern = viewModel.selectedPattern {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(pattern.name)
                            .font(.title3.weight(.bold))
                        if pattern.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Spacer()
                        Text(pattern.timeSignature.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(pattern.subdivision.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(pattern.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                RhythmBeatGridView(
                    pattern: pattern,
                    currentSlot: viewModel.isRunning ? viewModel.currentSlot : -1
                )
                .padding(.horizontal)
                
                legend
                    .padding(.horizontal)
            }
            
            transportBar
                .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .onAppear {
            viewModel.syncMetronomeConfig()
        }
        .onChange(of: viewModel.section) { _, newValue in
            if newValue == .playAlong {
                viewModel.syncMetronomeConfig()
            }
        }
    }
    
    private var patternPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.content.patterns) { pattern in
                    let selected = pattern.id == viewModel.selectedPatternID
                    let locked = pattern.isPremium && !isPremiumUser
                    Button {
                        viewModel.selectPattern(pattern, isPremiumUser: isPremiumUser)
                    } label: {
                        HStack(spacing: 4) {
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                            }
                            Text(pattern.name)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                        .foregroundColor(selected ? .accentColor : .primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var legend: some View {
        HStack(spacing: 12) {
            ForEach([RhythmEventKind.down, .up, .mute, .rest, .accent], id: \.self) { kind in
                HStack(spacing: 4) {
                    Text(kind.glyph)
                        .font(.caption.weight(.bold))
                    Text(kind.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var transportBar: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.bumpBPM(by: -5)
            } label: {
                Image(systemName: "minus")
            }
            
            Text("\(Int(viewModel.bpm)) BPM")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .frame(minWidth: 72)
            
            Button {
                viewModel.bumpBPM(by: 5)
            } label: {
                Image(systemName: "plus")
            }
            
            Spacer()
            
            Button {
                viewModel.toggleTransport()
            } label: {
                Label(
                    viewModel.isRunning ? "Stop" : "Start",
                    systemImage: viewModel.isRunning ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(viewModel.isRunning ? Color.red : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Beat Grid

struct RhythmBeatGridView: View {
    let pattern: RhythmPattern
    let currentSlot: Int
    
    var body: some View {
        let slots = pattern.slotsPerBar
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 28), spacing: 6),
            count: min(slots, 8)
        )
        
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<slots, id: \.self) { slot in
                let kind = pattern.event(at: slot)
                let active = slot == currentSlot
                let beat = BeatClock.beatIndex(slot: slot, slotsPerBeat: pattern.subdivision.slotsPerBeat)
                let isDownbeat = BeatClock.isAccent(slot: slot, slotsPerBeat: pattern.subdivision.slotsPerBeat)
                
                VStack(spacing: 4) {
                    Text(kind.glyph)
                        .font(.title3.weight(.bold))
                        .foregroundColor(active ? .white : color(for: kind))
                    Text(beatLabel(slot: slot, beat: beat))
                        .font(.caption2)
                        .foregroundColor(active ? .white.opacity(0.85) : .secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(active ? Color.accentColor : Color.secondary.opacity(isDownbeat ? 0.16 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(active ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .scaleEffect(active ? 1.04 : 1)
                .animation(.easeOut(duration: 0.07), value: currentSlot)
            }
        }
    }
    
    private func color(for kind: RhythmEventKind) -> Color {
        switch kind {
        case .down, .accent: return .primary
        case .up: return .accentColor
        case .mute: return .orange
        case .rest: return .secondary
        }
    }
    
    private func beatLabel(slot: Int, beat: Int) -> String {
        let slotsPerBeat = pattern.subdivision.slotsPerBeat
        if slotsPerBeat == 1 {
            return "\(beat + 1)"
        }
        let sub = slot % slotsPerBeat
        if sub == 0 { return "\(beat + 1)" }
        if slotsPerBeat == 2 { return "&" }
        // 16ths: e & a
        switch sub {
        case 1: return "e"
        case 2: return "&"
        case 3: return "a"
        default: return ""
        }
    }
}
