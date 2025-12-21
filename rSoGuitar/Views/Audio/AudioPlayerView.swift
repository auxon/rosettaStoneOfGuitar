//
//  AudioPlayerView.swift
//  rSoGuitar
//
//  Audio player component for lesson content
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let audioURL: URL
    @StateObject private var audioService = AudioService.shared
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if isPlaying {
                    audioService.stopAll()
                    isPlaying = false
                } else {
                    audioService.playAudio(from: audioURL)
                    isPlaying = true
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio Example")
                    .font(.headline)
                Text("Tap to play")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onChange(of: audioService.isPlaying) { _, newValue in
            if !newValue {
                isPlaying = false
            }
        }
    }
}

#Preview {
    AudioPlayerView(audioURL: URL(string: "https://example.com/audio.mp3")!)
}

