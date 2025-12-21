//
//  Subscription.swift
//  rSoGuitar
//
//  Subscription model for premium features
//

import Foundation
import SwiftData

@Model
final class Subscription {
    var isPremium: Bool
    var purchaseDate: Date?
    var expirationDate: Date?
    var productId: String?
    
    init(
        isPremium: Bool = false,
        purchaseDate: Date? = nil,
        expirationDate: Date? = nil,
        productId: String? = nil
    ) {
        self.isPremium = isPremium
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.productId = productId
    }
}

