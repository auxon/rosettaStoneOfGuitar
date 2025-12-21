//
//  NavigationBar.swift
//  rSoGuitar
//
//  Custom navigation bar components
//

import SwiftUI

struct NavigationBar: View {
    let title: String
    let showPremiumBadge: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            if showPremiumBadge {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    NavigationBar(title: "Lessons", showPremiumBadge: true)
}

