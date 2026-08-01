//
//  RhythmRootView.swift
//  rSoGuitar
//
//  Top-level Rhythm tab: Metronome | Play Along | Tutorials.
//

import SwiftUI

struct RhythmRootView: View {
    @StateObject private var viewModel = RhythmViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $viewModel.section) {
                ForEach(RhythmTabSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Group {
                switch viewModel.section {
                case .metronome:
                    MetronomeView(viewModel: viewModel)
                case .playAlong:
                    PlayAlongView(
                        viewModel: viewModel,
                        isPremiumUser: subscriptionService.isPremiumUser
                    )
                case .tutorials:
                    RhythmTutorialListContent(
                        viewModel: viewModel,
                        isPremiumUser: subscriptionService.isPremiumUser
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Rhythm")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.section) { _, newValue in
            if newValue != .playAlong && newValue != .metronome {
                viewModel.stop()
            } else {
                viewModel.syncMetronomeConfig()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $viewModel.showingPremiumGate) {
            PremiumGateView()
                .environmentObject(subscriptionService)
        }
    }
}

#Preview {
    NavigationView {
        RhythmRootView()
            .environmentObject(SubscriptionService.shared)
    }
}
