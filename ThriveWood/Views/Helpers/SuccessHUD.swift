//
//  SuccessHUD.swift
//  ThriveWood
//
//  Created by Ben Siebert on 07.05.26.
//
import SwiftUI

struct SuccessHUD: View {
    var message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark")
                .font(.system(size: 48, weight: .semibold))
            
            Text(message)
                .font(.headline)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
        // Hier entsteht der typische Apple "Graue Overlay" Glas-Effekt
        .background(.regularMaterial) 
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        // Passende Haptik hinzufügen (iOS 17+)
        .sensoryFeedback(.success, trigger: true) 
    }
}
