//
//  UnauthenticatedView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI

struct UnauthenticatedView: View {
    
    let onLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(Color(UIColor.tertiaryLabel))
            
            Text("Anmeldung erforderlich")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Bitte melde dich mit Face-ID an, um deine Daten zu schützen.")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                onLogin()
            } label: {
                Label("Face-ID", systemImage: "faceid")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
    }
    
}

