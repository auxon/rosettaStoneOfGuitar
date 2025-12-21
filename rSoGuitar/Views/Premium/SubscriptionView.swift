//
//  SubscriptionView.swift
//  rSoGuitar
//
//  Subscription purchase and management view
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Choose Your Plan")
                            .font(.title)
                            .bold()
                        
                        if subscriptionService.isPremiumUser {
                            Text("You have an active subscription")
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                    
                    // Products
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.availableProducts.isEmpty {
                        Text("No products available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.availableProducts, id: \.id) { product in
                            ProductCard(product: product, viewModel: viewModel)
                        }
                    }
                    
                    // Restore purchases
                    Button(action: {
                        viewModel.restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By purchasing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            Button("Terms") {
                                // Open terms
                            }
                            .font(.caption)
                            
                            Button("Privacy") {
                                // Open privacy policy
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }
}

struct ProductCard: View {
    let product: Product
    @ObservedObject var viewModel: SubscriptionViewModel
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.title2)
                    .bold()
            }
            
            Button(action: {
                isPurchasing = true
                viewModel.purchase(product)
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Subscribe")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isPurchasing || viewModel.purchaseInProgress)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionService.shared)
}

