//
//  SubscriptionViewModel.swift
//  rSoGuitar
//
//  ViewModel for subscription management
//

import Foundation
import SwiftUI
import StoreKit
import Combine

class SubscriptionViewModel: ObservableObject {
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress = false
    
    private let subscriptionService = SubscriptionService.shared
    
    init() {
        loadProducts()
    }
    
    func loadProducts() {
        Task {
            await subscriptionService.loadProducts()
            availableProducts = subscriptionService.availableProducts
        }
    }
    
    func purchase(_ product: Product) {
        purchaseInProgress = true
        errorMessage = nil
        
        Task {
            do {
                try await subscriptionService.purchase(product)
                await MainActor.run {
                    purchaseInProgress = false
                    if subscriptionService.isPremium {
                        // Purchase successful
                        errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    purchaseInProgress = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await subscriptionService.restorePurchases()
            await MainActor.run {
                isLoading = false
                if subscriptionService.errorMessage != nil {
                    errorMessage = subscriptionService.errorMessage
                }
            }
        }
    }
    
    var isPremium: Bool {
        subscriptionService.isPremiumUser
    }
    
    func formatPrice(_ product: Product) -> String {
        return product.displayPrice
    }
}

