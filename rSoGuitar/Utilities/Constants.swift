//
//  Constants.swift
//  rSoGuitar
//
//  App-wide constants and configuration
//

import Foundation
import Combine

enum Constants {
    // Standard guitar tuning (E-A-D-G-B-E)
    static let standardTuning: [Note] = [.E, .A, .D, .G, .B, .E]
    
    // Number of strings
    static let numberOfStrings = 6
    
    // Number of frets to display
    static let defaultFretCount = 24
    
    // String names (for display)
    static let stringNames = ["E", "A", "D", "G", "B", "E"]
    
    // StoreKit Product IDs
    enum ProductIDs {
        static let monthlySubscription = "com.rsoguitar.premium.monthly"
        static let yearlySubscription = "com.rsoguitar.premium.yearly"
        static let lifetimePurchase = "com.rsoguitar.premium.lifetime"
    }
    
    // UserDefaults Keys
    enum UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastSelectedKey = "lastSelectedKey"
        static let lastSelectedPattern = "lastSelectedPattern"
    }
}

