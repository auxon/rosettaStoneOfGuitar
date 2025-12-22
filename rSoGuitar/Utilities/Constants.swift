//
//  Constants.swift
//  rSoGuitar
//
//  App-wide constants and configuration
//

import Foundation
import Combine

enum Constants {
    // Standard guitar tuning indexed by string number (1=high E, 6=low E)
    // String 1: E (high), String 2: B, String 3: G, String 4: D, String 5: A, String 6: E (low)
    static let standardTuning: [Note] = [.E, .B, .G, .D, .A, .E]
    
    // Number of strings
    static let numberOfStrings = 6
    
    // Number of frets to display
    static let defaultFretCount = 24
    
    // String names (for display) - indexed by string number (1=high E, 6=low E)
    static let stringNames = ["e", "B", "G", "D", "A", "E"]
    
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

