//
//  AllSessionsView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 26.04.26.
//


import SwiftUI

struct AllSessionsView: View {
    let sessions: [WorkoutSession]

    private var grouped: [(String, [WorkoutSession])] {
        let groups = Dictionary(grouping: sessions) { session in
            session.startedAt.formatted(.dateTime.month(.wide).year())
        }
        return groups.sorted { ($0.value.first?.startedAt ?? .distantPast) > ($1.value.first?.startedAt ?? .distantPast) }
            .map { ($0.key, $0.value.sorted { $0.startedAt > $1.startedAt }) }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { month, list in
                Section(month) {
                    ForEach(list) { s in
                        NavigationLink {
                            WorkoutSessionDetailView(session: s)
                        } label: {
                            SessionRow(session: s)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trainings-Historie")
        .navigationBarTitleDisplayMode(.inline)
    }
}

