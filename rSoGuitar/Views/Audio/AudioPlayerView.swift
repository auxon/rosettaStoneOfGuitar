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
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    
    private let audioService = AudioService.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                togglePlayback()
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
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            playAudio()
        }
    }
    
    private func playAudio() {
        // Try to load and play the audio file
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
        }
    }
}

#Preview {
    AudioPlayerView(audioURL: URL(string: "https://example.com/audio.mp3")!)
}

