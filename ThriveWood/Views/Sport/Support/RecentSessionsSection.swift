//
//  RecentSessionsSection.swift
//  ThriveWood
//
//  Created by Ben Siebert on 04.05.26.
//

import SwiftUI

struct RecentSessionsSection: View {
    let sessions: [WorkoutSession]
    let onSelect: (WorkoutSession) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("Letzte Trainings").font(.headline)
                Spacer()
                if sessions.count > 5 {
                    NavigationLink("Alle") {
                        AllSessionsView(sessions: sessions)
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            VStack(spacing: Theme.Spacing.s) {
                ForEach(sessions.prefix(5)) { s in
                    Button { onSelect(s) } label: {
                        SessionRow(session: s)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
