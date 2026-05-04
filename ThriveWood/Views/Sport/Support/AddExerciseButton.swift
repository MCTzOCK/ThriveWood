//
//  AddExerciseButton.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//
import SwiftUI


struct AddExerciseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Übung hinzufügen")
            }
            .font(.headline)
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .strokeBorder(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }
}
