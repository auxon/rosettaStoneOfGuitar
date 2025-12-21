//
//  PremiumGateView.swift
//  rSoGuitar
//
//  View shown when user tries to access premium content
//

import SwiftUI

struct PremiumGateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 40)
                
                // Title
                Text("Unlock Premium")
                    .font(.largeTitle)
                    .bold()
                
                // Description
                Text("Get access to all lessons, advanced patterns, and exclusive features")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "book.fill", text: "All Premium Lessons")
                    FeatureRow(icon: "music.note.list", text: "Advanced Patterns")
                    FeatureRow(icon: "keyboard", text: "Key Changes & Modes")
                    FeatureRow(icon: "guitars.fill", text: "Exotic Scales")
                    FeatureRow(icon: "chart.bar.fill", text: "Progress Tracking")
                    FeatureRow(icon: "bookmark.fill", text: "Bookmarks & Favorites")
                }
                .padding()
                
                Spacer()
                
                // CTA Button
                Button(action: {
                    showingSubscription = true
                }) {
                    Text("View Subscription Options")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    PremiumGateView()
        .environmentObject(SubscriptionService.shared)
}

