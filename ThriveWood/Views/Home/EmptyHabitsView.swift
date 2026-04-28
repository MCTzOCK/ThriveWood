//
//  EmptyHabitsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 22.04.26.
//


import SwiftUI

struct EmptyHabitsView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor.gradient)
            Text("Starte deinen Wald")
                .font(.title3.weight(.semibold))
            Text("Lege deinen ersten Habit an und sammle Punkte, um Bäume zu pflanzen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onCreate) {
                Label("Habit erstellen", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.m)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}
