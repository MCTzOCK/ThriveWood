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
            BentoSectionHeader(title: Text("Letzte Trainings")) {
                if sessions.count > 5 {
                    NavigationLink {
                        AllSessionsView()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Alle")
                            Image(systemName: "chevron.right")
                        }
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }

            VStack(spacing: Theme.Spacing.s) {
                ForEach(sessions.prefix(5)) { s in
                    Button { onSelect(s) } label: {
                        SessionRow(session: s)
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }
}
