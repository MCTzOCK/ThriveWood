//
//  SportViewV2.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.07.26.
//

import SwiftUI

struct SportViewV2: View {
    
    @Environment(AppEnvironment.self) private var env
    
    @State private var workouts: [Workout] = []
    
    
    var body: some View {
        NavigationStack {
            Group {
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    
    private func reload() {
        do {
            workouts = try env.workoutService.allWorkouts()
        } catch {
            
        }
    }

}
