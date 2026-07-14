//
//  AllSessionsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//

import SwiftUI

struct AllSessionsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var refreshID = UUID()

    private var sessions: [WorkoutSession] {
        _ = refreshID
        return (try? env.sessionRepo.fetchAll()) ?? []
    }

    private var grouped: [(String, [WorkoutSession])] {
        let groups = Dictionary(grouping: sessions) { session in
            session.startedAt.formatted(.dateTime.month(.wide).year())
        }
        return groups.sorted { ($0.value.first?.startedAt ?? .distantPast) > ($1.value.first?.startedAt ?? .distantPast) }
            .map { ($0.key, $0.value.sorted { $0.startedAt > $1.startedAt }) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                if grouped.isEmpty {
                    PremiumEmptyState(
                        icon: "calendar.badge.exclamationmark",
                        title: "Keine Sessions",
                        message: "Starte dein erstes Workout, um deine Trainings-Historie zu sehen."
                    )
                    .padding(.top, Theme.Spacing.xxl)
                } else {
                    ForEach(grouped, id: \.0) { month, list in
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text(month)
                                .font(Theme.Typography.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, Theme.Spacing.l)

                            VStack(spacing: Theme.Spacing.s) {
                                ForEach(list) { s in
                                    NavigationLink {
                                        WorkoutSessionDetailView(session: s)
                                    } label: {
                                        SessionRow(session: s)
                                    }
                                    .buttonStyle(PressScaleStyle())
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                        }
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.l)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { refreshID = UUID() }
        .navigationTitle("Trainings-Historie")
        .navigationBarTitleDisplayMode(.inline)
    }
}
