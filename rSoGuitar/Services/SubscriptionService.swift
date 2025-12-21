//
//  SubscriptionService.swift
//  rSoGuitar
//
//  Manages StoreKit 2 subscriptions and premium status
//

import Foundation
import StoreKit
import SwiftData
import Combine

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var isPremium: Bool = false
    @Published var availableProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Debug mode: Enable premium features in debug builds
    #if DEBUG
    @Published var debugPremiumEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(debugPremiumEnabled, forKey: "debugPremiumEnabled")
        }
    }
    #endif
    
    private var modelContext: ModelContext?
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        #if DEBUG
        // Load debug premium setting
        debugPremiumEnabled = UserDefaults.standard.bool(forKey: "debugPremiumEnabled")
        #endif
        
        // Load initial subscription status
        Task { @MainActor in
            await loadSubscriptionStatus()
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    /// Set the model context for SwiftData
    @MainActor
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task { @MainActor in
            await loadSubscriptionStatus()
        }
    }
    
    /// Load available products from StoreKit
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIds = [
                Constants.ProductIDs.monthlySubscription,
                Constants.ProductIDs.yearlySubscription,
                Constants.ProductIDs.lifetimePurchase
            ]
            
            let products = try await Product.products(for: productIds)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    /// Purchase a product
    @MainActor
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
            case .userCancelled:
                errorMessage = "Purchase cancelled"
            case .pending:
                errorMessage = "Purchase pending approval"
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Restore purchases
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Check if user has premium access
    var isPremiumUser: Bool {
        #if DEBUG
        // In debug mode, allow debug override
        if debugPremiumEnabled {
            return true
        }
        #endif
        return isPremium
    }
    
    #if DEBUG
    /// Toggle debug premium mode (debug builds only)
    func toggleDebugPremium() {
        debugPremiumEnabled.toggle()
    }
    #endif
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadSubscriptionStatus() async {
        guard let modelContext = modelContext else {
            // Check UserDefaults as fallback
            isPremium = UserDefaults.standard.bool(forKey: "isPremium")
            return
        }
        
        let descriptor = FetchDescriptor<Subscription>()
        if let subscription = try? modelContext.fetch(descriptor).first {
            isPremium = subscription.isPremium
            
            // Check expiration if applicable
            if let expiration = subscription.expirationDate, expiration < Date() {
                isPremium = false
                subscription.isPremium = false
            }
        } else {
            // Create default subscription
            let subscription = Subscription()
            modelContext.insert(subscription)
            isPremium = false
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                } else if transaction.productType == .nonConsumable {
                    // Lifetime purchase
                    hasActiveSubscription = true
                }
            } catch {
                print("Error verifying transaction: \(error)")
            }
        }
        
        isPremium = hasActiveSubscription
        
        // Update SwiftData model
        if let modelContext = modelContext {
            let descriptor = FetchDescriptor<Subscription>()
            if let subscription = try? modelContext.fetch(descriptor).first {
                subscription.isPremium = hasActiveSubscription
                subscription.purchaseDate = Date()
                if hasActiveSubscription {
                    // Set expiration for subscriptions (1 year from now for yearly, 1 month for monthly)
                    subscription.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
                }
            } else {
                let subscription = Subscription(
                    isPremium: hasActiveSubscription,
                    purchaseDate: Date(),
                    expirationDate: hasActiveSubscription ? Calendar.current.date(byAdding: .year, value: 1, to: Date()) : nil
                )
                modelContext.insert(subscription)
            }
        }
        
        // Also update UserDefaults as backup
        UserDefaults.standard.set(hasActiveSubscription, forKey: "isPremium")
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
}

enum SubscriptionError: Error {
    case unverifiedTransaction
    case purchaseFailed
    case restoreFailed
}

