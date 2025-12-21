//
//  rSoGuitarApp.swift
//  rSoGuitar
//
//  Created on iOS 17+
//

import SwiftUI
import SwiftData

@main
struct rSoGuitarApp: App {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(subscriptionService)
                .modelContainer(for: [Subscription.self, UserProgress.self])
        }
    }
}

