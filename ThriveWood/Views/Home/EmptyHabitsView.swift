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
        PremiumEmptyState(
            icon: "leaf.circle.fill",
            title: "Starte deinen Wald",
            message: "Lege deinen ersten Habit an und sammle Punkte, um Bäume zu pflanzen.",
            actionTitle: "Habit erstellen",
            action: onCreate
        )
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
