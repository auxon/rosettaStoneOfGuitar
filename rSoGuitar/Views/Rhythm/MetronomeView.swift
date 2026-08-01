//
//  MetronomeView.swift
//  rSoGuitar
//
//  Metronome controls: BPM, time signature, accents, transport.
//

import SwiftUI

struct MetronomeView: View {
    @ObservedObject var viewModel: RhythmViewModel
    
    var body: some View {
        VStack(spacing: 28) {
            beatDots
            
            Text("\(Int(viewModel.bpm))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            Text("BPM")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button {
                    viewModel.bumpBPM(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                }
                .accessibilityLabel("Decrease BPM")
                
                Slider(value: $viewModel.bpm, in: 40...240, step: 1)
                
                Button {
                    viewModel.bumpBPM(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                }
                .accessibilityLabel("Increase BPM")
            }
            .padding(.horizontal)
            
            Picker("Time Signature", selection: $viewModel.timeSignature) {
                ForEach(TimeSignature.presets) { sig in
                    Text(sig.displayName).tag(sig)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Toggle("Accent beat 1", isOn: $viewModel.accentEnabled)
                .padding(.horizontal)
            
            Toggle("Mute click (visual only)", isOn: $viewModel.isClickMuted)
                .padding(.horizontal)
            
            Button {
                viewModel.toggleTransport()
            } label: {
                Label(
                    viewModel.isRunning ? "Stop" : "Start",
                    systemImage: viewModel.isRunning ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isRunning ? Color.red : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .onAppear {
            viewModel.syncMetronomeConfig()
        }
    }
    
    private var beatDots: some View {
        HStack(spacing: 14) {
            ForEach(0..<viewModel.timeSignature.beatsPerBar, id: \.self) { beat in
                let active = viewModel.isRunning && viewModel.currentBeat == beat
                Circle()
                    .fill(active ? (beat == 0 ? Color.orange : Color.accentColor) : Color.secondary.opacity(0.25))
                    .frame(width: active ? 22 : 16, height: active ? 22 : 16)
                    .animation(.easeOut(duration: 0.08), value: viewModel.currentBeat)
            }
        }
        .frame(height: 28)
        .accessibilityLabel("Beat \(viewModel.currentBeat + 1) of \(viewModel.timeSignature.beatsPerBar)")
    }
}
