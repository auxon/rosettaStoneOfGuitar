//
//  PatternPlayerPanel.swift
//  rSoGuitar
//
//  Transport + scrubber shared by lesson PatternView and Fretboard Explorer.
//

import SwiftUI

struct PatternPlayerPanel: View {
    @ObservedObject var player: PatternPlayer
    var blockCaption: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("\(max(0, player.clampedStep) + 1)/\(player.steps.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(minWidth: 52, alignment: .leading)
                
                Slider(
                    value: Binding(
                        get: { Double(max(0, player.clampedStep)) },
                        set: { player.seek(Int($0)) }
                    ),
                    in: 0...Double(max(0, player.steps.count - 1)),
                    step: 1
                )
            }
            .padding(.horizontal)
            
            Group {
                if player.clampedStep >= 0 {
                    VStack(spacing: 2) {
                        let step = player.steps[player.clampedStep]
                        Text(step.subtitle.isEmpty ? step.title : "\(step.title) — \(step.subtitle)")
                            .font(.subheadline.weight(.medium))
                        if !blockCaption.isEmpty {
                            Text(blockCaption)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Press play to walk the pattern")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            HStack(spacing: 18) {
                Button {
                    player.goToStart()
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                .disabled(player.clampedStep <= -1)
                
                Button {
                    player.stop()
                    player.stepBackward()
                } label: {
                    Image(systemName: "backward.frame")
                }
                .disabled(player.clampedStep <= -1)
                
                Button {
                    player.playPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color.accentColor))
                }
                .accessibilityLabel(player.isPlaying ? "Pause pattern" : "Play pattern")
                
                Button {
                    player.stop()
                    player.stepForward()
                } label: {
                    Image(systemName: "forward.frame")
                }
                .disabled(player.clampedStep >= player.steps.count - 1)
                
                Button {
                    player.goToEnd()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .disabled(player.clampedStep >= player.steps.count - 1)
            }
            .font(.body.weight(.semibold))
            
            HStack {
                Button {
                    player.loops.toggle()
                } label: {
                    Label("Loop", systemImage: "repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(player.loops ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(player.loops ? Color.accentColor : Color(.systemGray5))
                        )
                }
                
                Spacer()
                
                Menu {
                    ForEach(PatternPlayer.speedOptions, id: \.self) { option in
                        Button {
                            player.setSpeed(option)
                        } label: {
                            if player.speed == option {
                                Label(formatSpeed(option), systemImage: "checkmark")
                            } else {
                                Text(formatSpeed(option))
                            }
                        }
                    }
                } label: {
                    Label(formatSpeed(player.speed), systemImage: "gauge")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.systemGray5)))
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
    }
    
    private func formatSpeed(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f×", value) : String(format: "%.1f×", value)
    }
}

struct PatternDisplayModePicker: View {
    @ObservedObject var player: PatternPlayer
    
    var body: some View {
        Picker("Display", selection: Binding(
            get: { player.displayMode },
            set: { player.setDisplayMode($0) }
        )) {
            ForEach(PatternPlayer.DisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
